<template>
  <div class="detail-page">
    <HeaderBar />
    
    <div class="page-container">
      <div v-if="loading" class="loading-state">
        <div class="loading-spinner"></div>
      </div>
      
      <div v-else-if="article" class="main-wrapper">
        <!-- 左侧悬浮操作栏 -->
        <div class="action-bar" data-guide="knowledge-detail-actions">
          <div class="action-sticky">
            <button 
              :class="['action-btn', { active: article.isLiked }]" 
              @click="doLike"
              data-guide="knowledge-detail-like"
              title="点赞"
            >
              <i :class="article.isLiked ? 'fas fa-thumbs-up' : 'far fa-thumbs-up'"></i>
              <span>{{ article.likeCount || 0 }}</span>
            </button>
            <button 
              :class="['action-btn', { active: article.isFavorited }]" 
              @click="doFav"
              data-guide="knowledge-detail-favorite"
              title="收藏"
            >
              <i :class="article.isFavorited ? 'fas fa-star' : 'far fa-star'"></i>
              <span>{{ article.favoriteCount || 0 }}</span>
            </button>
            <button class="action-btn" @click="toComments" data-guide="knowledge-detail-comment-trigger" title="评论">
              <i class="far fa-comment"></i>
              <span>{{ article.commentCount || 0 }}</span>
            </button>
            <div class="action-divider"></div>
            <button class="action-btn small" @click="toTop" title="回到顶部">
              <i class="fas fa-arrow-up"></i>
            </button>
          </div>
        </div>

        <!-- 主内容区 -->
        <div class="content-main">
          <article class="article-container" data-guide="knowledge-detail-article">
            <!-- 返回按钮 -->
            <button class="back-link" @click="goBack">
              <i class="fas fa-arrow-left"></i>
              <span>返回列表</span>
            </button>

            <!-- 文章标题 -->
            <h1 class="article-title">{{ article.title }}</h1>

            <!-- 作者信息 -->
            <div class="author-bar">
              <div class="author-avatar">{{ getAvatar(article.authorName) }}</div>
              <div class="author-detail">
                <span class="author-name">{{ article.authorName }}</span>
                <div class="article-meta">
                  <span>{{ formatDate(article.createTime) }}</span>
                  <span class="meta-dot">·</span>
                  <span>阅读 {{ article.viewCount }}</span>
                </div>
              </div>
            </div>

            <!-- 文章内容 -->
            <div class="article-content" v-html="safeArticleContent"></div>

            <!-- 移动端操作栏 -->
            <div class="mobile-actions" data-guide="knowledge-detail-mobile-actions">
              <button :class="{ active: article.isLiked }" @click="doLike" data-guide="knowledge-detail-like">
                <i :class="article.isLiked ? 'fas fa-thumbs-up' : 'far fa-thumbs-up'"></i>
                <span>{{ article.likeCount }}</span>
              </button>
              <button :class="{ active: article.isFavorited }" @click="doFav" data-guide="knowledge-detail-favorite">
                <i :class="article.isFavorited ? 'fas fa-star' : 'far fa-star'"></i>
                <span>{{ article.favoriteCount }}</span>
              </button>
              <button @click="toComments" data-guide="knowledge-detail-comment-trigger">
                <i class="far fa-comment"></i>
                <span>{{ article.commentCount }}</span>
              </button>
            </div>
          </article>

          <!-- 评论区 -->
          <section id="comments" class="comments-section" data-guide="knowledge-detail-comments">
            <div class="section-header">
              <h3>评论</h3>
              <span class="comment-count">{{ article.commentCount || 0 }}</span>
            </div>

            <!-- 评论输入 -->
            <div class="comment-editor">
              <div class="editor-avatar">我</div>
              <div class="editor-input">
                <textarea 
                  v-model="commentText" 
                  placeholder="写下你的评论..."
                  data-guide="knowledge-detail-comment-input"
                  rows="3"
                ></textarea>
                <div class="editor-footer">
                  <span class="char-count">{{ commentText.length }}/500</span>
                  <button 
                    class="btn-submit" 
                    data-guide="knowledge-detail-comment-submit"
                    :disabled="!commentText.trim()" 
                    @click="submitComment"
                  >
                    发表评论
                  </button>
                </div>
              </div>
            </div>

            <!-- 评论列表 -->
            <div class="comment-list">
              <div v-for="c in comments" :key="c.commentId" class="comment-item">
                <div class="comment-avatar">{{ getAvatar(c.userName) }}</div>
                <div class="comment-body">
                  <div class="comment-header">
                    <span class="commenter-name">{{ c.userName }}</span>
                    <span class="comment-time">{{ timeAgo(c.createTime) }}</span>
                  </div>
                  <p class="comment-text">{{ c.content }}</p>
                </div>
              </div>
              <div v-if="comments.length === 0" class="empty-comments">
                <i class="far fa-comments"></i>
                <p>暂无评论，快来抢沙发吧</p>
              </div>
            </div>
          </section>
        </div>

        <!-- 右侧边栏 -->
        <aside class="sidebar">
          <!-- 作者卡片 -->
          <div class="sidebar-card author-card">
            <div class="author-avatar-lg">{{ getAvatar(article.authorName) }}</div>
            <div class="author-name-lg">{{ article.authorName }}</div>
            <div class="author-label">文章作者</div>
          </div>

          <!-- 相关推荐 -->
          <div class="sidebar-card" data-guide="knowledge-detail-related">
            <div class="card-header">
              <span class="header-title">相关推荐</span>
            </div>
            <div class="related-list">
              <div 
                v-for="r in related" 
                :key="r.articleId" 
                class="related-item"
                data-guide="knowledge-detail-related-item"
                @click="toArticle(r.articleId)"
              >
                <span class="related-title">{{ r.title }}</span>
                <span class="related-views">{{ r.viewCount }} 阅读</span>
              </div>
              <div v-if="related.length === 0" class="empty-tip">暂无相关推荐</div>
            </div>
          </div>
        </aside>
      </div>
    </div>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import HeaderBar from '@/components/HeaderBar.vue'
import { emitGuideEvent } from '@/composables/useGuideTour'
import { getArticleDetail, incrementArticleView, toggleLike, toggleFavorite, getComments, addComment, getArticleList } from '@/api/knowledge'
import { startReading, updateReadDuration, endReading } from '@/api/readlog'
import { sanitizeHtml } from '@/utils/security'

export default {
  name: 'KnowledgeDetail',
  components: { HeaderBar },
  setup() {
    const router = useRouter()
    const route = useRoute()
    const article = ref(null)
    const comments = ref([])
    const related = ref([])
    const loading = ref(false)
    const commentText = ref('')
    const safeArticleContent = computed(() => sanitizeHtml(article.value?.content || ''))
    
    // 阅读时长记录相关
    const readLogId = ref(null)
    const readStartTime = ref(null)
    const readDuration = ref(0)
    let updateTimer = null

    const load = async () => {
      loading.value = true
      try {
        const res = await getArticleDetail(route.params.id)
        if (res.data.code === 200) {
          article.value = res.data.data
          await incrementArticleView(route.params.id)
          loadComments()
          loadRelated()
          // 开始记录阅读时长
          startReadingLog()
        }
      } catch (e) { 
        ElMessage.error('加载失败') 
      } finally { 
        loading.value = false 
      }
    }

    const resetReadingState = () => {
      readLogId.value = null
      readStartTime.value = null
      readDuration.value = 0
    }

    const resetPageState = () => {
      article.value = null
      comments.value = []
      related.value = []
      commentText.value = ''
    }
    
    // 开始记录阅读
    const startReadingLog = async () => {
      try {
        const res = await startReading(route.params.id)
        if (res.code === 200) {
          readLogId.value = res.data
          readStartTime.value = Date.now()
          readDuration.value = 0
          // 每30秒更新一次阅读时长
          updateTimer = setInterval(updateReadingLog, 30000)
        }
      } catch (e) {
        logger.error('开始记录阅读失败:', e)
      }
    }
    
    // 更新阅读时长
    const updateReadingLog = async () => {
      if (!readLogId.value || !readStartTime.value) return
      
      readDuration.value = Math.floor((Date.now() - readStartTime.value) / 1000)
      
      try {
        await updateReadDuration(readLogId.value, readDuration.value)
      } catch (e) {
        logger.error('更新阅读时长失败:', e)
      }
    }
    
    // 结束阅读记录
    const endReadingLog = async () => {
      // 清除定时器
      if (updateTimer) {
        clearInterval(updateTimer)
        updateTimer = null
      }

      if (!readLogId.value || !readStartTime.value) {
        resetReadingState()
        return
      }

      // 计算最终阅读时长
      readDuration.value = Math.floor((Date.now() - readStartTime.value) / 1000)
      
      try {
        await endReading(readLogId.value, readDuration.value)
      } catch (e) {
        logger.error('结束阅读记录失败:', e)
      } finally {
        resetReadingState()
      }
    }
    
    // 组件卸载时结束阅读记录
    onBeforeUnmount(() => {
      endReadingLog()
    })

    const loadComments = async () => {
      try { 
        const res = await getComments(route.params.id)
        if (res.data.code === 200) comments.value = res.data.rows || [] 
      } catch (e) {}
    }

    const loadRelated = async () => {
      try {
        const res = await getArticleList({ pageNum: 1, pageSize: 6, status: 'published' })
        if (res.data.code === 200) {
          related.value = (res.data.rows || [])
            .filter(a => a.articleId !== article.value?.articleId)
            .slice(0, 5)
        }
      } catch (e) {}
    }

    const doLike = async () => {
      try { 
        const res = await toggleLike(article.value.articleId)
        if (res.data.code === 200) { 
          article.value.isLiked = res.data.data.isLiked
          article.value.likeCount = res.data.data.likeCount 
          emitGuideEvent('guide:knowledge-detail-liked', {
            articleId: article.value.articleId,
            isLiked: article.value.isLiked
          })
        } 
      } catch (e) { 
        ElMessage.error('操作失败') 
      }
    }

    const doFav = async () => {
      try { 
        const res = await toggleFavorite(article.value.articleId)
        if (res.data.code === 200) { 
          article.value.isFavorited = res.data.data.isFavorited
          article.value.favoriteCount = res.data.data.favoriteCount 
          emitGuideEvent('guide:knowledge-detail-favorited', {
            articleId: article.value.articleId,
            isFavorited: article.value.isFavorited
          })
        } 
      } catch (e) { 
        ElMessage.error('操作失败') 
      }
    }

    const submitComment = async () => {
      if (!commentText.value.trim()) return
      try {
        const res = await addComment({ articleId: article.value.articleId, content: commentText.value })
        if (res.data.code === 200) { 
          ElMessage.success('评论成功')
          commentText.value = ''
          loadComments()
          article.value.commentCount++ 
          emitGuideEvent('guide:knowledge-detail-comment-submitted', {
            articleId: article.value.articleId
          })
        } else {
          ElMessage.error(res.data.msg || '评论失败')
        }
      } catch (e) { 
        ElMessage.error('评论失败') 
      }
    }

    const toComments = () => document.getElementById('comments')?.scrollIntoView({ behavior: 'smooth' })
    const toTop = () => window.scrollTo({ top: 0, behavior: 'smooth' })
    const goBack = () => router.back()
    const toArticle = async (id) => {
      if (!id || String(id) === String(route.params.id)) return
      await router.push(`/knowledge/${id}`)
      emitGuideEvent('guide:knowledge-detail-related-opened', { articleId: id })
    }
    const getAvatar = n => (n || 'U').charAt(0).toUpperCase()
    const formatDate = s => s ? new Date(s).toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric' }) : ''
    const timeAgo = s => {
      if (!s) return ''
      const d = Math.floor((Date.now() - new Date(s)) / 1000)
      if (d < 60) return '刚刚'
      if (d < 3600) return Math.floor(d / 60) + '分钟前'
      if (d < 86400) return Math.floor(d / 3600) + '小时前'
      return new Date(s).toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' })
    }

    onMounted(load)

    watch(
      () => route.params.id,
      async (nextId, prevId) => {
        if (!nextId || nextId === prevId) {
          return
        }
        await endReadingLog()
        resetPageState()
        window.scrollTo({ top: 0, behavior: 'auto' })
        await load()
      }
    )
    
    return { 
      article, comments, related, loading, commentText, safeArticleContent,
      doLike, doFav, submitComment, toComments, toTop, 
      goBack, toArticle, getAvatar, formatDate, timeAgo 
    }
  }
}
</script>


<style scoped>
/* 基础布局 */
.detail-page {
  min-height: 100vh;
  background: #fafafa;
}

.page-container {
  padding-top: 60px;
  min-height: calc(100vh - 60px);
}

.main-wrapper {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px 20px;
  display: flex;
  gap: 24px;
}

/* 加载状态 */
.loading-state {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 400px;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #f2f3f5;
  border-top-color: #1e80ff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* 左侧操作栏 */
.action-bar {
  width: 60px;
  flex-shrink: 0;
}

.action-sticky {
  position: sticky;
  top: 84px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.action-btn {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  border: 1px solid #e4e6eb;
  background: #fff;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #8a919f;
  transition: all 0.2s;
}

.action-btn:hover {
  border-color: #1e80ff;
  color: #1e80ff;
}

.action-btn.active {
  background: #1e80ff;
  border-color: #1e80ff;
  color: #fff;
}

.action-btn i {
  font-size: 18px;
}

.action-btn span {
  font-size: 11px;
  margin-top: 2px;
}

.action-btn.small {
  width: 36px;
  height: 36px;
}

.action-btn.small i {
  font-size: 14px;
}

.action-divider {
  width: 24px;
  height: 1px;
  background: #e4e6eb;
  margin: 8px 0;
}

/* 主内容区 */
.content-main {
  flex: 1;
  min-width: 0;
}

.article-container {
  background: #fff;
  border-radius: 8px;
  padding: 32px;
  margin-bottom: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  min-width: 0;
}

.back-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 0;
  background: none;
  border: none;
  color: #8a919f;
  font-size: 14px;
  cursor: pointer;
  margin-bottom: 20px;
  transition: color 0.2s;
}

.back-link:hover {
  color: #1e80ff;
}

.article-title {
  font-size: clamp(1.6rem, 2.6vw, 1.9rem);
  font-weight: 700;
  color: #252933;
  line-height: 1.4;
  margin: 0 0 24px;
  word-break: break-word;
}

.author-bar {
  display: flex;
  align-items: center;
  gap: 14px;
  padding-bottom: 24px;
  border-bottom: 1px solid #f2f3f5;
  margin-bottom: 32px;
}

.author-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  font-size: 20px;
  font-weight: 500;
  display: flex;
  align-items: center;
  justify-content: center;
}

.author-detail {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.author-name {
  font-size: 16px;
  font-weight: 600;
  color: #252933;
}

.article-meta {
  font-size: 14px;
  color: #8a919f;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.meta-dot {
  color: #c2c8d1;
}

/* 文章内容 */
.article-content {
  font-size: 16px;
  line-height: 1.8;
  color: #333;
}

.article-content :deep(p) {
  margin-bottom: 1.5em;
}

.article-content :deep(img) {
  max-width: 100%;
  border-radius: 8px;
  margin: 1.5em 0;
}

.article-content :deep(h1),
.article-content :deep(h2),
.article-content :deep(h3) {
  margin: 1.8em 0 1em;
  font-weight: 600;
  color: #252933;
}

.article-content :deep(h1) { font-size: 24px; }
.article-content :deep(h2) { font-size: 20px; }
.article-content :deep(h3) { font-size: 18px; }

.article-content :deep(blockquote) {
  border-left: 4px solid #1e80ff;
  padding: 16px 20px;
  margin: 1.5em 0;
  background: #f7f8fa;
  border-radius: 0 8px 8px 0;
  color: #515767;
}

.article-content :deep(code) {
  background: #f2f3f5;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.9em;
  color: #e83e8c;
}

.article-content :deep(pre) {
  background: #282c34;
  color: #abb2bf;
  padding: 20px;
  border-radius: 8px;
  overflow-x: auto;
  margin: 1.5em 0;
}

.article-content :deep(pre code) {
  background: none;
  padding: 0;
  color: inherit;
}

/* 移动端操作栏 */
.mobile-actions {
  display: none;
  padding-top: 24px;
  border-top: 1px solid #f2f3f5;
  margin-top: 32px;
  justify-content: center;
  gap: 32px;
  flex-wrap: wrap;
}

.mobile-actions button {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 20px;
  background: #f7f8fa;
  border: none;
  border-radius: 24px;
  color: #8a919f;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 44px;
}

.mobile-actions button.active {
  background: #e8f3ff;
  color: #1e80ff;
}

/* 评论区 */
.comments-section {
  background: #fff;
  border-radius: 8px;
  padding: 24px 32px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.section-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 20px;
}

.section-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: #252933;
  margin: 0;
}

.comment-count {
  font-size: 14px;
  color: #8a919f;
}

.comment-editor {
  display: flex;
  gap: 14px;
  margin-bottom: 24px;
}

.editor-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #1e80ff;
  color: #fff;
  font-size: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.editor-input {
  flex: 1;
  min-width: 0;
}

.editor-input textarea {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #e4e6eb;
  border-radius: 8px;
  font-size: 14px;
  resize: none;
  outline: none;
  transition: border-color 0.2s;
}

.editor-input textarea:focus {
  border-color: #1e80ff;
}

.editor-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
  gap: 12px;
}

.char-count {
  font-size: 13px;
  color: #8a919f;
}

.btn-submit {
  padding: 8px 20px;
  background: #1e80ff;
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-submit:hover:not(:disabled) {
  background: #0969da;
}

.btn-submit:disabled {
  background: #c2c8d1;
  cursor: not-allowed;
}

/* 评论列表 */
.comment-list {
  border-top: 1px solid #f2f3f5;
  padding-top: 20px;
}

.comment-item {
  display: flex;
  gap: 14px;
  padding: 16px 0;
  border-bottom: 1px solid #f2f3f5;
}

.comment-item:last-child {
  border-bottom: none;
}

.comment-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  font-size: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.comment-body {
  flex: 1;
  min-width: 0;
}

.comment-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
  flex-wrap: wrap;
}

.commenter-name {
  font-size: 14px;
  font-weight: 500;
  color: #252933;
}

.comment-time {
  font-size: 13px;
  color: #8a919f;
}

.comment-text {
  font-size: 14px;
  color: #515767;
  line-height: 1.6;
  margin: 0;
}

.empty-comments {
  text-align: center;
  padding: 48px 20px;
  color: #8a919f;
}

.empty-comments i {
  font-size: 40px;
  margin-bottom: 12px;
  display: block;
  color: #c2c8d1;
}

.empty-comments p {
  margin: 0;
  font-size: 14px;
}

/* 侧边栏 */
.sidebar {
  width: 300px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
  min-width: 0;
}

.sidebar-card {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

/* 作者卡片 */
.author-card {
  text-align: center;
}

.author-avatar-lg {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  font-size: 26px;
  font-weight: 500;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 12px;
}

.author-name-lg {
  font-size: 16px;
  font-weight: 600;
  color: #252933;
  margin-bottom: 4px;
}

.author-label {
  font-size: 13px;
  color: #8a919f;
}

/* 相关推荐 */
.card-header {
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid #f2f3f5;
}

.header-title {
  font-size: 15px;
  font-weight: 600;
  color: #252933;
}

.related-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.related-item {
  cursor: pointer;
}

.related-item:hover .related-title {
  color: #1e80ff;
}

.related-title {
  font-size: 14px;
  color: #515767;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  transition: color 0.2s;
}

.related-views {
  font-size: 12px;
  color: #8a919f;
  display: block;
  margin-top: 4px;
}

.empty-tip {
  text-align: center;
  padding: 20px;
  color: #8a919f;
  font-size: 13px;
}

/* 响应式 */
@media (max-width: 1100px) {
  .action-bar, .sidebar {
    display: none;
  }
  
  .mobile-actions {
    display: flex;
  }
}

@media (max-width: 640px) {
  .main-wrapper {
    padding: 16px 12px 24px;
  }
  
  .article-container {
    padding: 20px 16px;
  }
  
  .article-title {
    font-size: 1.5rem;
  }
  
  .comments-section {
    padding: 20px 16px;
  }

  .author-bar,
  .comment-editor {
    align-items: flex-start;
  }

  .mobile-actions {
    justify-content: stretch;
    gap: 10px;
  }

  .mobile-actions button {
    flex: 1 1 calc(50% - 10px);
    justify-content: center;
    padding: 10px 12px;
  }

  .editor-footer {
    flex-direction: column;
    align-items: stretch;
  }

  .btn-submit {
    width: 100%;
    min-height: 44px;
  }

  .article-meta {
    gap: 4px 8px;
  }

  .comment-item {
    gap: 10px;
  }

  .comment-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
}

@media (max-width: 480px) {
  .back-link {
    font-size: 13px;
    gap: 4px;
  }

  .author-bar,
  .comment-editor {
    flex-direction: column;
  }

  .author-avatar,
  .editor-avatar {
    width: 40px;
    height: 40px;
    font-size: 16px;
  }

  .mobile-actions button {
    flex: 1 1 100%;
  }

  .section-header {
    flex-wrap: wrap;
  }

  .article-content {
    font-size: 15px;
    line-height: 1.85;
  }

  .article-content :deep(h1) { font-size: 22px; }
  .article-content :deep(h2) { font-size: 18px; }
  .article-content :deep(h3) { font-size: 16px; }

  .article-content :deep(blockquote) {
    padding: 14px 12px;
  }
}
</style>

