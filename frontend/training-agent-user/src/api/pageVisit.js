import { api } from '@/utils/api'

/**
 * 页面访问记录相关API
 */

const hasAuthToken = () => {
  try {
    return !!(localStorage.getItem('authToken') || localStorage.getItem('token') || localStorage.getItem('admin_token'))
  } catch {
    return false
  }
}

const skippedOk = (msg) => ({
  skipped: true,
  data: { code: 200, msg: msg || 'skipped', data: null }
})

// 记录页面访问时长
export const recordPageVisit = (pageName, duration) => {
  if (!hasAuthToken()) return Promise.resolve(skippedOk('not logged in'))
  return api.post('/train/page/visit', {
    pageName, 
    duration: Math.floor(duration)
  }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '记录页面访问失败')
    }
  })
}

// 获取学习时长统计
export const getLearningTime = (days = 30) => {
  if (!hasAuthToken()) return Promise.resolve(skippedOk('not logged in'))
  return api.get('/train/page/learning-time', {
    params: { days }
  }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习时长失败')
    }
  })
}

// 获取学习时长趋势
export const getLearningTrend = (days = 30) => {
  if (!hasAuthToken()) return Promise.resolve(skippedOk('not logged in'))
  return api.get('/train/page/learning-trend', {
    params: { days }
  }).then(response => {
    if (response.data.code === 200) {
      return response
    } else {
      throw new Error(response.data.msg || '获取学习时长趋势失败')
    }
  })
}
