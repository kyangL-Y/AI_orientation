import { api } from '@/utils/api';

/**
 * 获取考试列表
 */
export function getExamList(params) {
  return api.get('/train/exam/list', { params });
}

/**
 * 获取考试详情
 */
export function getExamDetail(examId) {
  return api.get(`/train/exam/${examId}`);
}

/**
 * 开始考试
 */
export function startExam(examId) {
  return api.post(`/train/exam/${examId}/start`);
}

/**
 * 提交考试答案
 */
export function submitExamAnswers(data) {
  return api.post('/train/exam/submit', data);
}

/**
 * 获取考试结果
 */
export function getExamResult(examId) {
  return api.get(`/train/exam/${examId}/result`);
}

/**
 * 获取错题解析
 */
export function getWrongAnswers(examId) {
  return api.get(`/train/exam/${examId}/wrong-answers`);
}

/**
 * 获取我的待考试列表
 */
export function getMyUpcomingExams(userOrParams = {}, extraParams = {}) {
  const params =
    userOrParams && typeof userOrParams === 'object' && !Array.isArray(userOrParams)
      ? userOrParams
      : { userId: userOrParams, ...extraParams };
  return api.get('/train/exam/my/upcoming', { params });
}

/**
 * 获取我的已完成考试列表
 */
export function getMyCompletedExams(userOrParams = {}, extraParams = {}) {
  const params =
    userOrParams && typeof userOrParams === 'object' && !Array.isArray(userOrParams)
      ? userOrParams
      : { userId: userOrParams, ...extraParams };
  return api.get('/train/exam/my/completed', { params });
}
