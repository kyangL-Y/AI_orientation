import request from '@/utils/request'

/**
 * 获取题目分类列表
 */
export function getCategoryList() {
  return request({
    url: '/api/practice/categories',
    method: 'get'
  })
}

/**
 * 获取指定分类的题目列表
 * @param {Number} categoryId - 分类ID
 */
export function getQuestionsByCategory(categoryId) {
  return request({
    url: `/api/practice/questions/${categoryId}`,
    method: 'get'
  })
}

/**
 * 提交答案
 * @param {Object} data - 答题数据
 */
export function submitAnswer(data) {
  return request({
    url: '/api/practice/submit',
    method: 'post',
    data
  })
}

/**
 * 标记题目
 * @param {Number} questionId - 题目ID
 * @param {Boolean} marked - 是否标记
 */
export function markQuestion(questionId, marked) {
  return request({
    url: '/api/practice/mark',
    method: 'post',
    data: { questionId, marked }
  })
}

/**
 * 收藏题目
 * @param {Number} questionId - 题目ID
 * @param {Boolean} collected - 是否收藏
 */
export function collectQuestion(questionId, collected) {
  return request({
    url: '/api/practice/collect',
    method: 'post',
    data: { questionId, collected }
  })
}

/**
 * 获取练习统计
 */
export function getPracticeStats() {
  return request({
    url: '/api/practice/stats',
    method: 'get'
  })
}

/**
 * 保存练习进度
 * @param {Object} progress - 进度数据
 */
export function saveProgress(progress) {
  return request({
    url: '/api/practice/progress',
    method: 'post',
    data: progress
  })
}

/**
 * 获取练习进度
 * @param {Number} categoryId - 分类ID
 */
export function getProgress(categoryId) {
  return request({
    url: `/api/practice/progress/${categoryId}`,
    method: 'get'
  })
}

/**
 * 提交练习（完成整套练习）
 * @param {Object} data - 练习数据
 */
export function submitPractice(data) {
  return request({
    url: '/api/practice/complete',
    method: 'post',
    data
  })
}
