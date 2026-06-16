/**
 * 动态获取后端URL的工具函数
 * 支持不同网络环境下的后端访问
 */

/**
 * 判断是否为开发环境
 * @returns {boolean}
 */
import logger from '@/utils/logger'

function isDevelopment() {
  const viteDev = (() => {
    try {
      if (typeof import.meta !== 'undefined' && import.meta.env) return !!import.meta.env.DEV
    } catch {}
    return false
  })()

  return viteDev ||
         (typeof process !== 'undefined' && process.env && process.env.NODE_ENV === 'development') || 
         window.location.hostname === 'localhost' || 
         window.location.hostname === '127.0.0.1' || 
         window.location.port === '8084'
}

/**
 * 获取后端基础URL
 * @returns {string} 后端URL
 */
export function getBackendUrl() {
  // 使用相对路径，通过代理访问后端
  // 开发环境通过 vite/webpack devServer 代理
  // 生产环境通过 nginx 代理
  return ''
}

/**
 * 获取验证码图片URL
 * @returns {string} 验证码图片URL
 */
export function getCaptchaUrl() {
  return `/captchaImage?ts=${Date.now()}`
}

/**
 * 获取完整的API URL
 * @param {string} path API路径
 * @returns {string} 完整的API URL
 */
export function getApiUrl(path) {
  const backendUrl = getBackendUrl()
  const cleanPath = path.startsWith('/') ? path : `/${path}`
  return `${backendUrl}${cleanPath}`
}

/**
 * 测试后端连接
 * @returns {Promise<boolean>} 连接是否成功
 */
export async function testBackendConnection() {
  try {
    const testUrl = '/captchaImage'
    const response = await fetch(testUrl, {
      method: 'GET',
      cache: 'no-store',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    })
    return response.ok
  } catch (error) {
    logger.error('后端连接失败:', error)
    return false
  }
}

/**
 * 获取网络环境信息
 * @returns {object} 网络环境信息
 */
export function getNetworkInfo() {
  return {
    origin: window.location.origin,
    hostname: window.location.hostname,
    protocol: window.location.protocol,
    port: window.location.port,
    backendUrl: getBackendUrl(),
    isDevelopment: isDevelopment()
  }
}

export default {
  getBackendUrl,
  getCaptchaUrl,
  getApiUrl,
  testBackendConnection,
  getNetworkInfo
}
