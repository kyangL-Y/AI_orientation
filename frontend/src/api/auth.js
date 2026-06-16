import { api } from '@/utils/api'

/**
 * 用户认证相关API
 */

// 用户登录
export const login = (loginData) => {
  // 通过统一 api 实例，走 devServer 代理
  return api.post('/login', loginData)
}

// 邮箱验证码登录
export const emailCodeLogin = (loginData) => {
  return api.post('/emailLogin', loginData)
}

// 手机验证码登录
export const smsLogin = (loginData) => {
  return api.post('/smsLogin', loginData)
}

// 检查手机号是否已注册
export const checkPhone = (phone) => {
  return api.get('/checkPhone', { params: { phone } })
}

// 用户注册
export const register = (registerData) => {
  return api.post('/register', registerData)
}

export const registerByInvitation = (registerData) => {
  return api.post('/register/invite', registerData)
}

export const resolveInvitation = (params) => {
  return api.get('/open/invite/resolve', { params })
}

// 发送邮箱验证码（真实接口）
export const sendEmailCode = (email) => {
  return api.post('/auth/sendEmailCode', { email })
}

// 发送手机验证码（真实接口）
export const sendSmsCode = (phone) => {
  return api.post('/auth/sendSmsCode', { phone })
}

// 获取用户信息
export const getUserInfo = () => {
  return api.get('/system/user/profile')
}

// 更新用户信息
export const updateUserInfo = (userData) => {
  return api.put('/system/user/profile', userData)
}

// 获取部门树
export const getDeptTree = (tenantId) => {
  return api.get('/open/org/depts', {
    params: tenantId ? { tenantId } : undefined
  })
}

// 获取租户列表（公开接口，供注册时选择公司/酒店）
export const getTenantOptions = () => {
  return api.get('/system/tenant/options')
}

// 用户登出
export const logout = () => {
  return api.post('/auth/logout')
}

// 刷新token
export const refreshToken = () => {
  return api.post('/auth/refresh')
}

// 重置密码
export const resetPwd = (data) => {
  return api.post('/resetPwd', data)
}
