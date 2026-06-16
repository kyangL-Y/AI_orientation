/**
 * 企业文化题目API
 */
import { api } from '@/utils/api'

const BASE_URL = '/train/culture-question'

/**
 * 获取企业文化题目分类（用户端）
 */
export function getCultureCategories() {
  return api.get(`${BASE_URL}/user/categories`)
}

/**
 * 获取企业文化题目列表（用户端）
 */
export function getCultureQuestions(category) {
  return api.get(`${BASE_URL}/user/list`, { params: { category } })
}

export function getCultureQuestionDetail(id) {
  return api.get(`${BASE_URL}/user/detail/${id}`)
}

/**
 * 获取企业文化题目统计（用户端）
 */
export function getCultureStats() {
  return api.get(`${BASE_URL}/user/stats`)
}
