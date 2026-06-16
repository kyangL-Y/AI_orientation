// 视频播放相关API
import { api } from '@/utils/api'

/**
 * 获取视频播放URL（用户端）
 * @param {String|Number} courseId - 课程ID
 * @returns {Promise}
 */
export const getVideoPlayUrl = (courseId) => {
  return api.get('/train/video/play', {
    params: { courseId: String(courseId) }
  })
}

/**
 * 批量获取视频播放URL
 * @param {Array<String>|String} courseIds - 课程ID数组或逗号分隔的字符串
 * @returns {Promise}
 */
export const getBatchVideoPlayUrls = (courseIds) => {
  const ids = Array.isArray(courseIds) ? courseIds.join(',') : courseIds
  return api.get('/train/video/play/batch', {
    params: { courseIds: ids }
  })
}

