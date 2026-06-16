import { api } from '@/utils/api'

/**
 * 答题记录相关API
 */

// 获取用户答题记录列表
export const getAnswerRecords = (params = {}) => {
  return api.get('/train/attempt/list', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取答题记录失败')
    }
  })
}

// 获取用户答题统计
export const getAnswerStatistics = (params = {}) => {
  return api.get('/train/attempt/statistics', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取答题统计失败')
    }
  })
}

// 获取用户答题详情
export const getAnswerDetail = (recordId) => {
  return api.get(`/train/attempt/detail/${recordId}`).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取答题详情失败')
    }
  })
}

// 提交答题记录
export const submitAnswer = (data) => {
  return api.post('/train/attempt/submit', data).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '提交答题失败')
    }
  })
}

// 获取错题记录
export const getWrongAnswers = (params = {}) => {
  return api.get('/train/attempt/wrong', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取错题记录失败')
    }
  })
}

// 获取答题趋势数据
export const getAnswerTrend = (params = {}) => {
  return api.get('/train/attempt/trend', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取答题趋势失败')
    }
  })
}

// 获取答题排行榜（个人）
export const getPersonalRanking = (params = {}) => {
  return api.get('/train/attempt/ranking', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取个人排名失败')
    }
  })
}

// 获取排行榜（所有用户）
export const getLeaderboard = (params = {}) => {
  return api.get('/train/attempt/leaderboard', { params }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取排行榜失败')
    }
  })
}

// 导出答题记录
export const exportAnswerRecords = (params = {}) => {
  return api.get('/train/attempt/export', { 
    params,
    responseType: 'blob'
  }).then(response => {
    return response
  })
}

// 获取答题记录筛选选项
export const getAnswerFilters = () => {
  return api.get('/train/attempt/filters')
}
