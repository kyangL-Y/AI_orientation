import axios from 'axios'
import logger from '@/utils/logger'
import { getTenantId } from '@/utils/tenantContext'

// Single axios instance for the app
// In dev, rely on devServer proxy rules (vue.config.js). Use root as base to
// avoid强制加上 /api 前缀导致 `/api/system/**` 404。

const BACKEND_BASE =
  (typeof window !== 'undefined' && window.__BACKEND_BASE__) ||
  (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_BACKEND_BASE) ||
  (typeof process !== 'undefined' && process.env && process.env.BACKEND_BASE) ||
  '/' 

const FALLBACK_BACKEND_BASE =
  (typeof window !== 'undefined' && window.__FALLBACK_BACKEND_BASE__) ||
  (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_FALLBACK_BACKEND_BASE) ||
  (typeof process !== 'undefined' && process.env && process.env.FALLBACK_BACKEND_BASE) ||
  'http://127.0.0.1:9090'

const getRuntimeBackendOverride = () => {
  try {
    if (typeof localStorage === 'undefined') return null
    return localStorage.getItem('backend_base') || localStorage.getItem('BACKEND_BASE') || null
  } catch {
    return null
  }
}

const shouldTryFallback = (requestUrl) => {
  if (!requestUrl) return false
  return (
    requestUrl === '/login' ||
    requestUrl === '/smsLogin' ||
    requestUrl === '/emailLogin' ||
    requestUrl === '/checkPhone' ||
    requestUrl === '/resetPwd' ||
    requestUrl.startsWith('/train') ||
    requestUrl.startsWith('/system') ||
    requestUrl.startsWith('/auth') ||
    requestUrl.startsWith('/open') ||
    requestUrl.startsWith('/dev-api') ||
    requestUrl.startsWith('/api')
  )
}

const getFallbackBases = () => {
  const runtimeOverride = getRuntimeBackendOverride()
  const bases = [runtimeOverride, '/api', '/dev-api', FALLBACK_BACKEND_BASE].filter(Boolean)
  const unique = []
  for (const b of bases) {
    if (!unique.includes(b)) unique.push(b)
  }
  return unique
}

const getNextFallbackBase = (config) => {
  try {
    const tried = Array.isArray(config?.__fallbackBasesTried) ? config.__fallbackBasesTried : []
    const currentBase = config?.baseURL || api.defaults.baseURL
    const candidates = getFallbackBases()
    for (const base of candidates) {
      if (!base) continue
      if (base === currentBase) continue
      if (tried.includes(base)) continue
      return { base, tried: [...tried, base] }
    }
    return null
  } catch {
    return null
  }
}

const isHtmlResponse = (response) => {
  try {
    const ct = response?.headers?.['content-type'] || response?.headers?.['Content-Type'] || ''
    if (typeof ct === 'string' && ct.includes('text/html')) return true
    const data = response?.data
    if (typeof data === 'string') {
      const head = data.slice(0, 200).toLowerCase()
      return head.includes('<!doctype html') || head.includes('<html')
    }
    return false
  } catch {
    return false
  }
}

const isProxyErrorResponse = (response) => {
  try {
    const status = response?.status
    if (typeof status === 'number' && status < 500) return false
    const data = response?.data
    if (typeof data !== 'string') return false
    const s = data.toLowerCase()
    return (
      s.includes('proxy error') ||
      s.includes('etimedout') ||
      s.includes('econnrefused') ||
      s.includes('enotfound') ||
      s.includes('socket hang up')
    )
  } catch {
    return false
  }
}

export const api = axios.create({
  baseURL: BACKEND_BASE,
  timeout: 60000, // 增加超时时间到30秒，适应AI API调用
  headers: { 'Content-Type': 'application/json' }
})

const getCookie = (name) => {
  try {
    if (typeof document === 'undefined' || !document.cookie) return null
    const encodedName = encodeURIComponent(name) + '='
    const parts = document.cookie.split(';')
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i].trim()
      if (part.startsWith(encodedName)) {
        const value = part.substring(encodedName.length)
        return decodeURIComponent(value)
      }
    }
    return null
  } catch {
    return null
  }
}

const getAnyToken = () => {
  try {
    const ls = typeof localStorage !== 'undefined' ? localStorage : null
    const authToken = ls ? ls.getItem('authToken') : null
    if (authToken) return authToken

    const adminTokenLs = ls ? ls.getItem('admin_token') : null
    if (adminTokenLs) return adminTokenLs

    const adminTokenCookie = getCookie('Admin-Token')
    if (adminTokenCookie) return adminTokenCookie

    const tokenLs = ls ? ls.getItem('token') : null
    if (tokenLs) return tokenLs

    return null
  } catch {
    return null
  }
}

api.interceptors.request.use((config) => {
  try {
    const runtimeOverride = getRuntimeBackendOverride()
    if (runtimeOverride) {
      config.baseURL = runtimeOverride
    }

    const token = config.__skipAuth ? null : getAnyToken()
    if (token) {
      // 只使用 Authorization 头（根据后端配置）
      config.headers.Authorization = `Bearer ${token}`
    }
    
    // 添加统一租户ID请求头
    const tenantId = config.__skipTenantHeader ? null : getTenantId()
    if (tenantId) {
      config.headers['Tenant-Id'] = tenantId
    }
  } catch (error) {
    logger.error('设置认证token失败:', error)
  }
  return config
})

// 响应拦截器处理认证失败
api.interceptors.response.use(
  (response) => {
    try {
      const requestUrl = response?.config?.url || ''
      if (response?.config && api.defaults.baseURL === '/' && shouldTryFallback(requestUrl) && (isHtmlResponse(response) || isProxyErrorResponse(response))) {
        const next = getNextFallbackBase(response.config)
        if (next) {
          const retryConfig = { ...response.config, baseURL: next.base, __fallbackBasesTried: next.tried }
          return api.request(retryConfig)
        }
      }
    } catch {}
    return response
  },
  (error) => {
    try {
      const requestUrl = error?.config?.url || ''
      const htmlLike = error?.response ? isHtmlResponse(error.response) : false
      const proxyLike = error?.response ? isProxyErrorResponse(error.response) : false
      if (error?.config && api.defaults.baseURL === '/' && shouldTryFallback(requestUrl) && (!error.response || htmlLike || proxyLike)) {
        const next = getNextFallbackBase(error.config)
        if (next) {
          const retryConfig = { ...error.config, baseURL: next.base, __fallbackBasesTried: next.tried }
          return api.request(retryConfig)
        }
      }
    } catch {}
    if (error.response && error.response.status === 403) {
      const payload = error.response.data || {}
      const requiresProfileCompletion = payload?.needsProfileCompletion === true ||
        payload?.profileCompletionRequired === true ||
        payload?.data?.needsProfileCompletion === true ||
        payload?.data?.profileCompletionRequired === true

      if (requiresProfileCompletion) {
        if (typeof window !== 'undefined' && window.ElMessage) {
          window.ElMessage({
            message: payload?.msg || '请先完善姓名和所在信息',
            type: 'warning',
            duration: 3000,
            showClose: true
          })
        }

        try {
          window.dispatchEvent(new CustomEvent('userProfileRefreshRequired', {
            detail: {
              profileCompletion: payload?.profileCompletion || payload?.data?.profileCompletion || null,
              needsProfileCompletion: true,
              profileCompletionRequired: true
            }
          }))
        } catch {}
      }
    }
    if (error.response && error.response.status === 401) {
      const errorMsg = error.response.data?.msg || ''
      const requestUrl = error.config?.url || ''
      
      // 可选接口列表（这些接口401不应该触发登出或提示）
      const optionalEndpoints = ['/statistics', '/leaderboard', '/ranking', '/favorite/my', '/membership/my']
      const isOptionalEndpoint = optionalEndpoints.some(endpoint => requestUrl.includes(endpoint))
      
      if (isOptionalEndpoint) {
        // 静默处理可选接口的401错误
        logger.info('该功能需要登录后使用')
      } else {
        const hasToken = localStorage.getItem('authToken')
        const isTokenExpired = errorMsg.includes('token') || errorMsg.includes('Token') ||
                               errorMsg.includes('令牌') || errorMsg.includes('登录已过期')

        if (hasToken || isTokenExpired) {
          // 401 表示当前登录态已经不可用，包括账号被删除、停用或 token 过期。
          localStorage.removeItem('authToken')
          localStorage.removeItem('userInfo')
          
          // 显示友好的提示
          if (typeof window !== 'undefined' && window.ElMessage) {
            window.ElMessage({
              message: '登录状态已失效，请重新登录',
              type: 'warning',
              duration: 3000,
              showClose: true
            })
          }
          
          // 触发全局登出事件
          window.dispatchEvent(new CustomEvent('userLogout'))
          
          // 延迟弹出登录框
          setTimeout(() => {
            try {
              window.dispatchEvent(new CustomEvent('showLoginModal'))
            } catch {}
          }, 1500)
        } else {
          // 未登录或权限不足
          logger.info('需要登录才能访问该功能')
          
          // 如果用户确实未登录（没有token），显示友好提示
          if (!hasToken && typeof window !== 'undefined' && window.ElMessage) {
            window.ElMessage({
              message: '请先登录后再使用该功能',
              type: 'info',
              duration: 2500,
              showClose: true
            })
          }
          if (!hasToken) {
            setTimeout(() => {
              try {
                window.dispatchEvent(new CustomEvent('showLoginModal'))
              } catch {}
            }, 50)
          }
        }
      }
    }
    return Promise.reject(error)
  }
)

export default api

// Admin side client (separate base, separate token)
const ADMIN_BASE =
  (typeof window !== 'undefined' && window.__ADMIN_BASE__) ||
  (typeof import.meta !== 'undefined' && import.meta.env && import.meta.env.VITE_ADMIN_BASE) ||
  (typeof process !== 'undefined' && process.env && process.env.ADMIN_BASE) ||
  '/admin-api'

export const adminApi = axios.create({
  baseURL: ADMIN_BASE,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' }
})

adminApi.interceptors.request.use((config) => {
  try {
    const token = localStorage.getItem('admin_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
  } catch {}
  return config
})

