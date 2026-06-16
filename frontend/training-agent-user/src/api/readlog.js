import { api } from '@/utils/api'

// 开始阅读文章
export function startReading(articleId) {
  return api.post('/train/knowledge/readlog/start', null, { params: { articleId } })
}

// 更新阅读时长
export function updateReadDuration(logId, duration) {
  return api.put('/train/knowledge/readlog/update', null, { params: { logId, duration } })
}

// 结束阅读
export function endReading(logId, duration) {
  return api.put('/train/knowledge/readlog/end', null, { params: { logId, duration } })
}
