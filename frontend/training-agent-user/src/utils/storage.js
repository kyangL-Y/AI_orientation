/**
 * LocalStorage工具类
 * 使用user_前缀避免和后台管理系统冲突
 */
import logger from '@/utils/logger'

const PREFIX = 'user_'

export const storage = {
  // 设置值
  set(key, value) {
    try {
      const prefixedKey = PREFIX + key
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value)
      localStorage.setItem(prefixedKey, stringValue)
    } catch (error) {
      logger.error(`设置localStorage失败 [${key}]:`, error)
    }
  },

  // 获取值
  get(key, defaultValue = null) {
    try {
      const prefixedKey = PREFIX + key
      const value = localStorage.getItem(prefixedKey)
      
      // 如果没有找到,尝试读取旧的无前缀版本(兼容性)
      if (value === null) {
        const oldValue = localStorage.getItem(key)
        if (oldValue !== null) {
          logger.warn(`检测到旧版localStorage key: ${key}, 建议迁移到: ${prefixedKey}`)
          // 自动迁移到新key
          localStorage.setItem(prefixedKey, oldValue)
          localStorage.removeItem(key)
          return oldValue
        }
        return defaultValue
      }
      
      return value
    } catch (error) {
      logger.error(`获取localStorage失败 [${key}]:`, error)
      return defaultValue
    }
  },

  // 获取并解析JSON
  getJSON(key, defaultValue = null) {
    try {
      const value = this.get(key)
      if (value === null) return defaultValue
      return JSON.parse(value)
    } catch (error) {
      logger.error(`解析JSON失败 [${key}]:`, error)
      return defaultValue
    }
  },

  // 删除值
  remove(key) {
    try {
      const prefixedKey = PREFIX + key
      localStorage.removeItem(prefixedKey)
      // 同时删除旧的无前缀版本
      localStorage.removeItem(key)
    } catch (error) {
      logger.error(`删除localStorage失败 [${key}]:`, error)
    }
  },

  // 清除所有user_前缀的数据
  clear() {
    try {
      const keys = Object.keys(localStorage)
      keys.forEach(key => {
        if (key.startsWith(PREFIX)) {
          localStorage.removeItem(key)
        }
      })
      logger.success('已清除所有用户数据')
    } catch (error) {
      logger.error('清除localStorage失败:', error)
    }
  },

  // 检查key是否存在
  has(key) {
    const prefixedKey = PREFIX + key
    return localStorage.getItem(prefixedKey) !== null || localStorage.getItem(key) !== null
  }
}

// 导出常用的key名称常量
export const STORAGE_KEYS = {
  AUTH_TOKEN: 'authToken',
  USER_INFO: 'userInfo',
  ANSWERED_QUESTIONS: 'answeredQuestions',
  PRACTICE_PROGRESS: 'practiceProgress'
}

