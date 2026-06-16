import { api } from '@/utils/api'

/**
 * 智囊阁知识共享API
 */

// ==================== 文章管理 ====================

/**
 * 获取文章列表
 * @param {Object} params - 查询参数
 * @param {number} params.pageNum - 页码
 * @param {number} params.pageSize - 每页数量
 * @param {string} params.status - 状态（published/pending/draft/rejected）
 * @returns {Promise}
 */
export const getArticleList = (params = {}) => {
  return api.get('/train/knowledge/article/list', { params })
}

/**
 * 搜索文章
 * @param {string} keyword - 搜索关键词
 * @param {Object} params - 分页参数
 * @returns {Promise}
 */
export const searchArticles = (keyword, params = {}) => {
  return api.get('/train/knowledge/article/search', { 
    params: { keyword, ...params } 
  })
}

/**
 * 获取我的文章列表
 * @param {string} status - 状态筛选
 * @param {Object} params - 分页参数
 * @returns {Promise}
 */
export const getMyArticles = (status = null, params = {}) => {
  return api.get('/train/knowledge/article/my', { 
    params: { status, ...params } 
  })
}

/**
 * 获取文章详情
 * @param {number} articleId - 文章ID
 * @returns {Promise}
 */
export const getArticleDetail = (articleId) => {
  return api.get(`/train/knowledge/article/${articleId}`)
}

/**
 * 创建文章
 * @param {Object} article - 文章数据
 * @param {string} article.title - 标题
 * @param {string} article.content - 内容（富文本HTML）
 * @param {string} article.coverImage - 封面图片URL
 * @param {Array<string>} article.images - 文章图片URL列表
 * @param {string} article.status - 状态（draft/pending）
 * @returns {Promise}
 */
export const createArticle = (article) => {
  return api.post('/train/knowledge/article', article)
}

/**
 * 更新文章
 * @param {Object} article - 文章数据（必须包含articleId）
 * @returns {Promise}
 */
export const updateArticle = (article) => {
  return api.put('/train/knowledge/article', article)
}

/**
 * 删除文章
 * @param {number} articleId - 文章ID
 * @returns {Promise}
 */
export const deleteArticle = (articleId) => {
  return api.delete(`/train/knowledge/article/${articleId}`)
}

/**
 * 增加文章浏览次数
 * @param {number} articleId - 文章ID
 * @returns {Promise}
 */
export const incrementArticleView = (articleId) => {
  return api.post(`/train/knowledge/article/${articleId}/view`)
}

// ==================== 互动功能 ====================

/**
 * 点赞/取消点赞
 * @param {number} articleId - 文章ID
 * @returns {Promise<{isLiked: boolean, likeCount: number}>}
 */
export const toggleLike = (articleId) => {
  return api.post(`/train/knowledge/like/${articleId}`)
}

/**
 * 收藏/取消收藏
 * @param {number} articleId - 文章ID
 * @returns {Promise<{isFavorited: boolean, favoriteCount: number}>}
 */
export const toggleFavorite = (articleId) => {
  return api.post(`/train/knowledge/favorite/${articleId}`)
}

/**
 * 获取我的收藏列表
 * @param {Object} params - 分页参数
 * @returns {Promise}
 */
export const getMyFavorites = (params = {}) => {
  return api.get('/train/knowledge/favorite/my', { params })
}

// ==================== 评论功能 ====================

/**
 * 获取文章评论列表
 * @param {number} articleId - 文章ID
 * @param {Object} params - 分页参数
 * @returns {Promise}
 */
export const getComments = (articleId, params = {}) => {
  return api.get(`/train/knowledge/comment/${articleId}`, { params })
}

/**
 * 添加评论
 * @param {Object} comment - 评论数据
 * @param {number} comment.articleId - 文章ID
 * @param {string} comment.content - 评论内容
 * @returns {Promise}
 */
export const addComment = (comment) => {
  return api.post('/train/knowledge/comment', comment)
}

/**
 * 删除评论
 * @param {number} commentId - 评论ID
 * @returns {Promise}
 */
export const deleteComment = (commentId) => {
  return api.delete(`/train/knowledge/comment/${commentId}`)
}

// ==================== 审核管理（管理员） ====================

/**
 * 获取待审核文章列表
 * @param {Object} params - 分页参数
 * @returns {Promise}
 */
export const getPendingArticles = (params = {}) => {
  return api.get('/train/knowledge/review/pending', { params })
}

/**
 * 审核通过
 * @param {number} articleId - 文章ID
 * @returns {Promise}
 */
export const approveArticle = (articleId) => {
  return api.post(`/train/knowledge/review/${articleId}/approve`)
}

/**
 * 审核拒绝
 * @param {number} articleId - 文章ID
 * @param {string} rejectReason - 拒绝原因
 * @returns {Promise}
 */
export const rejectArticle = (articleId, rejectReason) => {
  return api.post(`/train/knowledge/review/${articleId}/reject`, rejectReason)
}

// ==================== 统计功能（管理员） ====================

/**
 * 获取统计数据
 * @returns {Promise}
 */
export const getStatistics = () => {
  return api.get('/train/knowledge/statistics')
}

/**
 * 获取热门文章
 * @param {string} type - 类型（view: 按浏览量, like: 按点赞数）
 * @param {number} limit - 数量限制
 * @returns {Promise}
 */
export const getHotArticles = (type = 'view', limit = 10) => {
  return api.get('/train/knowledge/statistics/hot', { 
    params: { type, limit } 
  })
}

/**
 * 获取活跃作者
 * @param {number} limit - 数量限制
 * @returns {Promise}
 */
export const getActiveAuthors = (limit = 10) => {
  return api.get('/train/knowledge/statistics/authors', { 
    params: { limit } 
  })
}
