import logger from '@/utils/logger';
import { api } from '@/utils/api'

export const getMyPoints = () => api.get('/train/points/my')

export const getPointRecords = () => api.get('/train/points/records')

export const addDailyCheckInPoints = (data) => api.post('/train/points/checkin', data)

// 获取知识点列表（题目分类）- 从 train_question 表的 category 字段
export const getKnowledgePoints = () => {
  return api.get('/train/exercises/categories').then(response => {
    if (response.data && response.data.code === 200) {
      const categories = response.data.data || [];
      return {
        data: {
          code: 200,
          rows: categories
        }
      };
    }
    logger.error('❌ 加载分类失败:', response);
    return response;
  }).catch(error => {
    logger.error('❌ 加载分类出错:', error);
    throw error;
  });
}

