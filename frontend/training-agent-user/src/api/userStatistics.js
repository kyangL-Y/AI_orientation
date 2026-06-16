import logger from '@/utils/logger';
import { api } from '@/utils/api'

/**
 * 用户统计相关API
 */

// 获取用户学习统计概览
export const getUserStatistics = (params = {}) => {
  // 尝试从localStorage获取用户ID
  const userInfo = localStorage.getItem('userInfo')
  let userId = null
  try {
    if (userInfo) {
      const user = JSON.parse(userInfo)
      userId = user.userId || user.id
    }
  } catch (e) {
    logger.warn('解析用户信息失败:', e)
  }

  // 如果有userId，使用带参数的API
  const apiPath = userId ? `/train/ranking/userStats/${userId}` : '/train/ranking/userStats'
  
  return api.get(apiPath, { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取用户统计失败')
    }
  }).catch(error => {
    logger.warn('获取用户统计失败，返回默认数据:', error.message)
    // 返回默认数据作为降级
    return Promise.resolve({
      data: {
        code: 200,
        data: {
          totalCourses: 0,
          totalQuestions: 0,
          completedCourses: 0,
          correctRate: 0,
          studyHours: 0
        }
      }
    })
  })
}

// 获取学习时长统计
export const getLearningDuration = (userId) => {
  return api.get(`/train/statistics/duration/${userId}`).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习时长统计失败')
    }
  })
}

// 获取答题统计
export const getAnswerStatistics = (userId) => {
  return api.get(`/train/statistics/answers/${userId}`).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取答题统计失败')
    }
  })
}

// 获取综合学习统计
export const getComprehensiveStats = (userId) => {
  return api.get(`/train/statistics/comprehensive/${userId}`).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取综合学习统计失败')
    }
  })
}

// 获取用户学习进度趋势
export const getLearningProgress = (params = {}) => {
  return api.get('/train/statistics/progress', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习进度失败')
    }
  })
}

// 获取用户答题正确率趋势
export const getAccuracyTrend = (params = {}) => {
  return api.get('/train/statistics/accuracy', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取正确率趋势失败')
    }
  })
}

// 获取用户学习时长分布
export const getStudyTimeDistribution = (params = {}) => {
  return api.get('/train/statistics/time-distribution', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习时长分布失败')
    }
  })
}

// 获取用户答题类型统计
export const getQuestionTypeStats = (params = {}) => {
  return api.get('/train/statistics/question-types', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取答题类型统计失败')
    }
  })
}

// 获取用户学习成就
export const getUserAchievements = (params = {}) => {
  return api.get('/train/statistics/achievements', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习成就失败')
    }
  })
}

// 获取用户学习建议
export const getLearningSuggestions = (params = {}) => {
  return api.get('/train/statistics/suggestions', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习建议失败')
    }
  })
}

// 获取用户学习报告
export const getLearningReport = (params = {}) => {
  return api.get('/train/statistics/report', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习报告失败')
    }
  })
}

// 导出用户统计数据
export const exportUserStatistics = (params = {}) => {
  return api.get('/train/statistics/export', { 
    params,
    responseType: 'blob'
  })
}

// 获取用户学习目标
export const getLearningGoals = (params = {}) => {
  return api.get('/train/statistics/goals', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习目标失败')
    }
  })
}

// 设置用户学习目标
export const setLearningGoals = (data) => {
  return api.post('/train/statistics/goals', data).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '设置学习目标失败')
    }
  })
}

// 获取用户学习计划
export const getLearningPlan = (params = {}) => {
  return api.get('/train/statistics/plan', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习计划失败')
    }
  })
}

// 更新用户学习计划
export const updateLearningPlan = (data) => {
  return api.put('/train/statistics/plan', data).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '更新学习计划失败')
    }
  })
}

// 获取用户学习提醒
export const getLearningReminders = (params = {}) => {
  return api.get('/train/statistics/reminders', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习提醒失败')
    }
  })
}

// 设置用户学习提醒
export const setLearningReminders = (data) => {
  return api.post('/train/statistics/reminders', data).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '设置学习提醒失败')
    }
  })
}

