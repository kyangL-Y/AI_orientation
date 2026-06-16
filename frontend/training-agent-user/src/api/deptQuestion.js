/**
 * 部门培训题目API
 */
import { api } from '@/utils/api'

const BASE_URL = '/train/dept-question'

/**
 * 根据部门类型获取题目列表
 */
export function getDeptQuestions(params = {}, scope = 'self') {
  return api.get(`${BASE_URL}/list-by-dept`, {
    params: {
      ...params,
      scope
    }
  })
}

/**
 * 获取部门题目分类统计
 */
export function getDeptQuestionCategories(params = {}, scope = 'self') {
  return api.get(`${BASE_URL}/categories`, {
    params: {
      ...params,
      scope
    }
  })
}

/**
 * 获取所有有题目的部门类型
 */
export function getDeptTypes(scope = 'self') {
  return api.get(`${BASE_URL}/dept-types`, { params: { scope } })
}

/**
 * 获取按课程整理后的部门专项分类
 */
export function getDeptCourseCategories(scope = 'self') {
  return api.get(`${BASE_URL}/course-categories`, { params: { scope } })
}

/**
 * 获取题目详情
 */
export function getDeptQuestionDetail(id) {
  return api.get(`${BASE_URL}/${id}`)
}

/**
 * 提交答题结果
 */
export function submitDeptAnswer(data) {
  return api.post(`${BASE_URL}/answer`, data)
}

/**
 * 收藏题目
 */
export function favoriteDeptQuestion(questionId) {
  return api.post(`${BASE_URL}/${questionId}/favorite`)
}

/**
 * 取消收藏
 */
export function unfavoriteDeptQuestion(questionId) {
  return api.delete(`${BASE_URL}/${questionId}/unfavorite`)
}

/**
 * 获取用户收藏的题目
 */
export function getDeptFavorites(deptType) {
  return api.get(`${BASE_URL}/favorites`, { params: { deptType } })
}

/**
 * 获取用户错题
 */
export function getDeptWrongQuestions(deptType) {
  return api.get(`${BASE_URL}/wrong-questions`, { params: { deptType } })
}

/**
 * 获取用户答题统计
 */
export function getDeptStats(deptType) {
  return api.get(`${BASE_URL}/stats`, { params: { deptType } })
}

/**
 * 获取每日练习题目（添加时间戳避免缓存）
 */
export function getDeptDailyQuestions(params = {}, category, limit = 10, scope = 'self') {
  return api.get(`${BASE_URL}/daily`, { 
    params: { 
      ...params,
      category, 
      limit,
      scope,
      _t: Date.now()  // 添加时间戳避免浏览器缓存
    } 
  })
}

/**
 * 根据分类获取题目
 */
export function getDeptQuestionsByCategory(category, params = {}, scope = 'self') {
  return api.get(`${BASE_URL}/category/${category}`, {
    params: {
      ...params,
      scope
    }
  })
}

/**
 * 根据课程专项获取题目
 */
export function getDeptQuestionsByCourse(params = {}, scope = 'self') {
  return api.get(`${BASE_URL}/list-by-course`, {
    params: {
      ...params,
      scope
    }
  })
}
