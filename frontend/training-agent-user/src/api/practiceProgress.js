import { api } from '@/utils/api'

/**
 * 刷题进度API
 */

// 获取刷题进度
export const getPracticeProgress = (mode, categoryId) => {
  const params = {}
  if (mode) params.mode = mode
  if (categoryId) params.categoryId = categoryId
  return api.get('/train/practice/progress/get', { params })
}

// 保存刷题进度
export const savePracticeProgress = (data) => {
  return api.post('/train/practice/progress/save', {
    mode: data.mode,
    categoryId: data.categoryId,
    categoryName: data.categoryName,
    currentIndex: data.currentIndex,
    questionsData: JSON.stringify(data.questions)
  })
}

// 清除刷题进度
export const clearPracticeProgress = (mode, categoryId) => {
  const params = { mode }
  if (categoryId) params.categoryId = categoryId
  return api.delete('/train/practice/progress/clear', { params })
}

// 清除所有进度
export const clearAllPracticeProgress = () => {
  return api.delete('/train/practice/progress/clearAll')
}
