/**
 * 绿色饭店题目API
 */
import { api } from '@/utils/api'

const BASE_URL = '/train/green-hotel-question'

export function getGreenHotelCategories() {
  return api.get(`${BASE_URL}/user/categories`)
}

export function getGreenHotelQuestions(category, courseId) {
  return api.get(`${BASE_URL}/user/list`, { params: { category, courseId } })
}

export function getGreenHotelQuestionDetail(id) {
  return api.get(`${BASE_URL}/user/detail/${id}`)
}

export function getGreenHotelStats() {
  return api.get(`${BASE_URL}/user/stats`)
}
