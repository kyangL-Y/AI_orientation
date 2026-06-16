import logger from '@/utils/logger';
import { api } from '@/utils/api'

/**
 * 用户相关API
 */

// 获取用户统计信息
export const getUserStats = () => {
  return api.get('/train/user/stats').then(response => {
    // 如果API调用成功，返回真实数据
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取用户统计失败')
    }
  }).catch(error => {
    logger.error('获取用户统计API调用失败:', error.message)
    // API调用失败时抛出错误，不使用模拟数据
    throw error
  })
}

// 获取用户培训记录
export const getUserTrainingRecords = (params = {}) => {
  return api.get('/train/user/records', { params })
}

// 获取用户证书
export const getUserCertificates = () => {
  return api.get('/train/user/certificates')
}

// 获取用户学习进度
export const getUserProgress = () => {
  return api.get('/train/user/progress')
}

// 获取用户学习时长趋势
export function getUserLearningTrend(period = 'daily', days = 30) {
  // 去除可能的空格
  const cleanPeriod = typeof period === 'string' ? period.trim() : period;
  return api.get('/train/user/learning-trend', { 
    params: { period: cleanPeriod, days } 
  })
}

// 获取用户培训分类统计
export const getUserCategoryStats = () => {
  return api.get('/train/user/category-stats')
}

// 更新用户学习进度
export const updateUserProgress = (progressData) => {
  return api.put('/user/progress', progressData)
}

// 更新用户个人资料
export const updateUserProfile = (profileData) => {
  return api.put('/system/user/profile', profileData)
}

// 获取组织架构树形结构（只读放行端点）
export const getOrgTree = () => {
  return api.get('/open/org/treeselect')
}

// 获取部门列表（扁平化，用于选择）
export const getDepartments = () => {
  return api.get('/train/common/depts')
}

// 上传头像
export const uploadAvatar = (file) => {
  const formData = new FormData()
  formData.append('avatarfile', file) // 使用后端期望的参数名
  
  return api.post('/system/user/profile/avatar', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

// 获取用户详细信息
export const getUserDetail = () => {
  return api.get('/system/user/profile')
}

// 修改密码
export const changePassword = (passwordData) => {
  return api.put('/system/user/profile/changePwd', passwordData)
}

// 获取每日学习记录
export const getDailyRecords = (days = 30) => {
  return api.get('/train/user/daily-records', { params: { days } })
}

// 获取用户列表（用于学习计划选择）
export const listUser = (params = {}) => {
  // 尝试多个可能的用户接口
  const tryUserApis = async () => {
    const apis = [
      '/system/user/list',
      '/train/user/list', 
      '/system/user/select',
      '/train/user/select'
    ]
    
    for (const apiPath of apis) {
      try {
        const response = await api.get(apiPath, { params })
        
        // 检查响应是否包含用户数据
        if (response.data && (response.data.rows || response.data.data)) {
          return response
        }
      } catch (error) {
        continue
      }
    }
    
    // 如果所有接口都失败，抛出最后一个错误
    throw new Error('所有用户接口都无法访问，请检查权限配置')
  }
  
  return tryUserApis().catch(error => {
    logger.error('所有用户API调用失败:', error)
    logger.error('错误详情:', error.response?.data)
    
    // 提供更明确的错误信息
    if (error.response?.data?.code === 401) {
      logger.error('认证失败：当前用户没有访问用户列表的权限')
      logger.error('解决方案：1. 检查用户权限 2. 使用管理员账号 3. 配置接口权限')
    }
    
    throw error
  })
}

