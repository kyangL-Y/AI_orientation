import { api } from '@/utils/api';

/**
 * 获取个人排行榜
 */
export function getPersonalRanking(params) {
  return api.get('/train/ranking/personal', { params });
}

/**
 * 获取部门排行榜
 */
export function getDepartmentRanking(params) {
  return api.get('/train/ranking/department', { params });
}

/**
 * 获取结课测验排行榜
 */
export function getCourseQuizRanking(params) {
  return api.get('/train/ranking/courseQuiz', { params });
}

/**
 * 获取我的排名信息
 */
export function getMyRanking(params) {
  return api.get('/train/ranking/my', { params });
}
