import { api } from '@/utils/api';

/**
 * 获取课程列表
 */
export function getCourseList(params) {
  return api.get('/train/course/list', { params });
}

/**
 * 获取课程详情
 */
export function getCourseDetail(courseId) {
  return api.get(`/train/course/${courseId}`);
}

/**
 * 开始学习课程
 */
export function startCourse(courseId) {
  return api.post(`/train/course/${courseId}/start`);
}

/**
 * 更新学习进度
 */
export function updateProgress(data) {
  return api.post('/train/course/progress', data);
}

/**
 * 完成课程
 */
export function completeCourse(courseId) {
  return api.post(`/train/course/${courseId}/complete`);
}
