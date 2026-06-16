import logger from '@/utils/logger';
import { api } from '@/utils/api'
import { getUserId } from '@/utils/userStorage'

/**
 * 考试记录相关API
 */

const getCurrentUserId = () => getUserId()

// 获取我的考试记录列表
export const getMyExamRecords = (params = {}) => {
  const userId = getCurrentUserId()
  if (!userId) {
    logger.warn('⚠️ 无法获取用户ID，考试记录查询可能失败')
  }
  return api.get('/train/quiz/my-records', {
    params: { ...params, userId }
  }).then(response => response).catch(error => {
    logger.error('❌ 获取考试记录失败:', error)
    throw error
  })
}

// 获取我的考试统计（平均分等）
export const getMyExamStats = () => {
  const userId = getCurrentUserId()
  return api.get('/train/quiz/my-stats', { params: { userId } }).then(response => {
    return response
  }).catch(error => {
    logger.error('❌ 获取考试统计失败:', error)
    throw error
  })
}

// 获取我的按类型统计的考试信息（考试和测验分开）
export const getMyExamStatsByType = () => {
  const userId = getCurrentUserId()
  return api.get('/train/quiz/my-stats-by-type', { params: { userId } }).then(response => {
    return response
  }).catch(error => {
    logger.error('❌ 获取分类型统计失败:', error)
    throw error
  })
}

// 获取考试详情（用于回看）
export const getExamDetail = (attemptId) => {
  return api.get(`/train/quiz/detail/${attemptId}`).then(response => {
    return response
  }).catch(error => {
    logger.error('❌ 获取考试详情失败:', error)
    throw error
  })
}

// 提交考试结果
export const submitExamResult = (data) => {
  const userId = getCurrentUserId()
  return api.post('/train/quiz', {
    ...data,
    userId: userId
  }).then(response => {
    return response
  }).catch(error => {
    logger.error('❌ 提交考试结果失败:', error)
    throw error
  })
}

