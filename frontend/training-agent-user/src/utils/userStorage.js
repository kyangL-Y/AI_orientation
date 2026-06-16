/**
 * 用户信息 localStorage 工具函数
 * 统一处理用户信息的存储和读取，避免JSON解析错误
 */
import logger from '@/utils/logger'

/**
 * 安全地获取用户信息
 * @returns {Object|null} 用户信息对象，如果不存在或解析失败返回null
 */
export function getUserInfo() {
  try {
    const storedUserInfo = localStorage.getItem('userInfo')
    
    if (!storedUserInfo) {
      return null
    }
    
    // 检查是否是无效的值
    if (storedUserInfo === 'userInfo' || storedUserInfo === 'null' || storedUserInfo === 'undefined' || storedUserInfo.trim() === '') {
      logger.warn('userInfo格式错误，已清除:', storedUserInfo)
      localStorage.removeItem('userInfo')
      return null
    }
    
    // 尝试解析JSON
    const userInfo = JSON.parse(storedUserInfo)
    return userInfo
    
  } catch (error) {
    logger.error('解析userInfo失败:', error)
    // 清除错误的数据
    localStorage.removeItem('userInfo')
    return null
  }
}

/**
 * 安全地保存用户信息
 * @param {Object} userInfo 用户信息对象
 */
export function setUserInfo(userInfo) {
  try {
    if (!userInfo || typeof userInfo !== 'object') {
      logger.warn('无效的用户信息，不保存')
      return false
    }
    
    localStorage.setItem('userInfo', JSON.stringify(userInfo))
    logger.success('用户信息已保存')
    return true
    
  } catch (error) {
    logger.error('保存userInfo失败:', error)
    return false
  }
}

/**
 * 清除用户信息
 */
export function clearUserInfo() {
  localStorage.removeItem('userInfo')
  localStorage.removeItem('authToken')
  logger.info('用户信息已清除')
}

/**
 * 获取用户ID
 * @returns {number|null} 用户ID，不存在返回null
 */
export function getUserId() {
  const userInfo = getUserInfo()
  return userInfo?.userId || userInfo?.id || null
}

/**
 * 获取用户昵称
 * @returns {string} 用户昵称，不存在返回空字符串
 */
export function getUserNickName() {
  const userInfo = getUserInfo()
  return userInfo?.nickName || userInfo?.userName || ''
}

/**
 * 检查是否已登录
 * @returns {boolean} 是否已登录
 */
export function isLoggedIn() {
  const token = localStorage.getItem('authToken')
  const userInfo = getUserInfo()
  return !!(token && userInfo)
}
