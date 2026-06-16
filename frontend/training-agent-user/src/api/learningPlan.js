import { api } from '@/utils/api'

// 学习计划相关API接口

/**
 * 获取当前用户的学习计划列表
 */
export function getMyLearningPlans() {
  return api.get('/train/plans/my')
}

/**
 * 创建学习计划
 * @param {object} planData 学习计划数据
 */
export function createLearningPlan(planData) {
  return api.post('/train/plans', planData)
}

/**
 * 获取学习计划详情
 * @param {number} planId 计划ID
 */
export function getLearningPlanDetail(planId) {
  return api.get(`/train/plans/${planId}`)
}

/**
 * 标记任务项完成
 * @param {number} itemId 任务项ID
 * @param {object} data 完成数据 {score, feedback}
 */
export function completePlanItem(itemId, data) {
  return api.post(`/train/plan-item-completions/complete/${itemId}`, data)
}

/**
 * 检查任务项完成状态
 * @param {number} itemId 任务项ID
 */
export function checkPlanItemCompletion(itemId) {
  return api.get(`/train/plan-item-completions/check/${itemId}`)
}

/**
 * 获取当前用户的完成记录
 */
export function getMyCompletions() {
  return api.get('/train/plan-item-completions/my')
}

/**
 * 获取培训统计数据
 */
export function getTrainingStats() {
  return api.get('/train/stats')
}

/**
 * 获取用户学习日历
 * @param {number} year 年份
 * @param {number} month 月份
 */
export function getLearningCalendar(year, month) {
  return api.get('/train/plans/calendar', { params: { year, month } })
}

/**
 * 获取用户学习进度统计
 */
export function getProgressStats() {
  return api.get('/train/plans/progress-stats')
}
