/**
 * 清理测试数据的工具函数
 */
import logger from '@/utils/logger'

// 清理localStorage中的测试数据
export const clearTestData = () => {
  try {
    const storedUserInfo = localStorage.getItem('userInfo')
    if (storedUserInfo) {
      const parsedUserInfo = JSON.parse(storedUserInfo)
      
      // 检查是否是测试数据
      const isTestData = 
        parsedUserInfo.email === 'zhangsan@huazhi.com' || 
        parsedUserInfo.userName === 'zhangsan' ||
        parsedUserInfo.nickName === '张三' ||
        parsedUserInfo.email === 'test@example.com' ||
        parsedUserInfo.userName === 'test' ||
        parsedUserInfo.nickName === '测试用户'
      
      if (isTestData) {
        logger.info('检测到测试数据，正在清除...')
        localStorage.removeItem('authToken')
        localStorage.removeItem('userInfo')
        logger.success('测试数据已清除')
        return true
      }
    }
    
    // 检查是否有无效的token
    const token = localStorage.getItem('authToken')
    if (token && token === 'test-token') {
      logger.info('检测到测试token，正在清除...')
      localStorage.removeItem('authToken')
      localStorage.removeItem('userInfo')
      logger.success('测试token已清除')
      return true
    }
    
    return false
  } catch (error) {
    logger.error('清理测试数据时出错:', error)
    return false
  }
}

// 清理所有用户数据
export const clearAllUserData = () => {
  try {
    localStorage.removeItem('authToken')
    localStorage.removeItem('userInfo')
    logger.success('所有用户数据已清除')
    return true
  } catch (error) {
    logger.error('清理用户数据时出错:', error)
    return false
  }
}

// 检查是否有测试数据
export const hasTestData = () => {
  try {
    const storedUserInfo = localStorage.getItem('userInfo')
    if (storedUserInfo) {
      const parsedUserInfo = JSON.parse(storedUserInfo)
      
      return (
        parsedUserInfo.email === 'zhangsan@huazhi.com' || 
        parsedUserInfo.userName === 'zhangsan' ||
        parsedUserInfo.nickName === '张三' ||
        parsedUserInfo.email === 'test@example.com' ||
        parsedUserInfo.userName === 'test' ||
        parsedUserInfo.nickName === '测试用户'
      )
    }
    
    const token = localStorage.getItem('authToken')
    return token === 'test-token'
  } catch (error) {
    logger.error('检查测试数据时出错:', error)
    return false
  }
}

// 在浏览器控制台中提供清理命令
if (typeof window !== 'undefined') {
  window.clearTestData = clearTestData
  window.clearAllUserData = clearAllUserData
  window.hasTestData = hasTestData
  
  logger.info('清理工具已加载，可以使用以下命令：')
  logger.info('- clearTestData() - 清理测试数据')
  logger.info('- clearAllUserData() - 清理所有用户数据')
  logger.info('- hasTestData() - 检查是否有测试数据')
}
