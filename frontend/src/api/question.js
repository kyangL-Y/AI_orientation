import logger from '@/utils/logger';
import { api } from '@/utils/api'

// 获取课程随堂题目
export function getQuestionsByCourseId(courseId) {
  return api.get(`/train/question/course/${courseId}`)
}

// 提交答案（修复：使用正确的API路径）
export function submitAnswer(questionId, answer, isCorrect, questionSource = 'ota') {
  return api.post('/train/attempt/submit', {
    questionId: questionId,
    answer: answer,
    questionSource: questionSource
  }).then(response => {
    if (response.data && response.data.code === 200) {
      return response;
    } else {
      throw new Error(response.data?.msg || '提交答题失败');
    }
  }).catch(error => {
    logger.error('❌ [submitAnswer] 提交失败:', error);
    throw error;
  });
}

// 获取复习列表
export function getReviewList() {
  return api.get('/train/question/review/list')
}

// 更新复习状态
export function updateReviewStatus(data) {
  return api.post('/train/question/review/update', data)
}

// 获取题目列表（OTA题库）
export function getQuestions(params = {}) {
  return api.get('/train/exercises/list', { params })
}

// 获取题目分类列表
export function getQuestionCategories() {
  return api.get('/train/exercises/categories')
}

// 收藏题目
export function favoriteQuestion(questionId) {
  return api.post('/train/exercises/favorite', { questionId })
}

// 取消收藏题目
export function unfavoriteQuestion(questionId) {
  return api.post('/train/exercises/unfavorite', { questionId })
}

// 获取错题列表
export function getWrongQuestions(params = {}) {
  return api.get('/train/exercises/wrong-list', { params })
}

// 获取收藏题目列表
export function getFavoriteQuestions(params = {}) {
  return api.get('/train/exercises/favorite-list', { params })
}

// 获取题目详情
export function getQuestionDetail(questionId) {
  return api.get(`/train/exercises/detail/${questionId}`)
}

// 生成自定义试卷
export function generateCustomPaper(params = {}) {
  return api.post('/train/exercises/generate-paper', params)
}


// 切换收藏状态
export function toggleFavorite(questionId) {
  return api.post('/train/exercises/toggle-favorite', { questionId })
}

