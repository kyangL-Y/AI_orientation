<template>
  <div class="knowledge-page">
    <HeaderBar />
    
    <div class="page-container">
      <div class="main-layout">
        
        <!-- 左侧导航 -->
        <aside class="left-sidebar" data-guide="knowledge-square-nav">
          <div class="nav-menu">
            <div class="menu-item" data-guide="knowledge-nav-square" @click="goToSquare">
              <i class="fas fa-compass"></i>
              <span>知识广场</span>
            </div>
            <div class="menu-item" data-guide="knowledge-nav-my" @click="goToMy">
              <i class="fas fa-user"></i>
              <span>我的文章</span>
            </div>
            <div class="menu-item active" data-guide="knowledge-nav-favorites">
              <i class="fas fa-bookmark"></i>
              <span>我的收藏</span>
            </div>
          </div>
          
          <div class="topic-box">
             <div class="box-title">收藏概览</div>
             <div class="mini-stats">
               <div class="mini-stat-item">
                 <span class="num">{{ total }}</span>
                 <span class="label">收藏总数</span>
               </div>
             </div>
          </div>
        </aside>

        <!-- 主内容区 -->
        <main class="content-feed">
          <!-- 页面标题 -->
          <div class="feed-header" data-guide="knowledge-favorites-header">
            <div class="header-title">
              <h2>我的收藏</h2>
              <span class="count-badge">{{ total }}</span>
            </div>
            <button class="create-btn outline" @click="goToSquare">
              <i class="fas fa-compass"></i> <span>去发现</span>
            </button>
          </div>

          <!-- 文章列表 -->
          <div class="article-list" data-guide="knowledge-favorites-list">
            <div v-if="loading" class="loading-skeleton">
              <div class="skeleton-item" v-for="i in 3" :key="i"></div>
            </div>

            <div v-else-if="articles.length === 0" class="empty-state">
              <img src="https://cdn-icons-png.flaticon.com/512/7486/7486747.png" alt="Empty" />
              <h3>暂无收藏</h3>
              <p>去发现优质文章并收藏吧</p>
              <button class="btn-primary" @click="goToSquare">去发现</button>
            </div>

            <template v-else>
              <div 
                v-for="article in articles" 
                :key="article.articleId"
                class="article-card"
                @click="goToDetail(article.articleId)"
              >
                <div class="card-content">
                  <div class="author-row">
                    <div class="author-avatar">{{ getAvatar(article.authorName) }}</div>
                    <span class="author-name">{{ article.authorName }}</span>
                    <span class="dot">·</span>
                    <span class="publish-time">{{ timeAgo(article.createTime) }}</span>
                  </div>
                  
                  <h2 class="article-title">{{ article.title }}</h2>
                  <p class="article-summary">{{ getSummary(article.content) }}</p>
                  
                  <div class="card-footer">
                    <div class="stat-group">
                      <span class="stat-item"><i class="far fa-eye"></i> {{ article.viewCount || 0 }}</span>
                      <span class="stat-item"><i class="far fa-thumbs-up"></i> {{ article.likeCount || 0 }}</span>
                      <span class="stat-item"><i class="far fa-comment-alt"></i> {{ article.commentCount || 0 }}</span>
                    </div>
                    <button 
                      class="btn-icon danger" 
                      @click.stop="handleUnfavorite(article.articleId)"
                      title="取消收藏"
                    >
                      <i class="fas fa-star"></i>
                    </button>
                  </div>
                </div>
                
                <div v-if="article.coverImage" class="card-cover">
                  <img :src="article.coverImage" :alt="article.title" loading="lazy" />
                </div>
              </div>

              <!-- 分页 -->
              <div v-if="total > pageSize" class="pagination-wrap">
                <el-pagination
                  v-model:current-page="pageNum"
                  :page-size="pageSize"
                  :total="total"
                  layout="prev, pager, next"
                  @current-change="handlePageChange"
                  background
                  small
                />
              </div>
            </template>
          </div>
        </main>

        <!-- 右侧边栏 -->
        <aside class="right-sidebar">
          <!-- 小提示 -->
          <div class="sidebar-card">
            <div class="card-header">
              <i class="fas fa-lightbulb" style="color: #ffa502;"></i>
              <span>收藏贴士</span>
            </div>
            <ul class="tips-list">
              <li>点击星标可取消收藏</li>
              <li>收藏的文章方便随时查阅</li>
              <li>发现好文章记得收藏哦</li>
            </ul>
          </div>
        </aside>
      </div>
    </div>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import HeaderBar from '@/components/HeaderBar.vue'
import { getMyFavorites, toggleFavorite } from '@/api/knowledge'

export default {
  name: 'MyFavorites',
  components: { HeaderBar },
  setup() {
    const router = useRouter()
    
    const articles = ref([])
    const loading = ref(false)
    const pageNum = ref(1)
    const pageSize = ref(10)
    const total = ref(0)

    const loadFavorites = async () => {
      loading.value = true
      try {
        const params = { pageNum: pageNum.value, pageSize: pageSize.value }
        const response = await getMyFavorites(params)
        if (response.data.code === 200) {
          articles.value = response.data.rows || []
          total.value = response.data.total || 0
        } else {
          ElMessage.error(response.data.msg || '加载失败')
        }
      } catch (error) {
        logger.error('加载收藏失败:', error)
        ElMessage.error('加载失败，请稍后重试')
      } finally {
        loading.value = false
      }
    }

    const handleUnfavorite = async (articleId) => {
      try {
        await ElMessageBox.confirm('确定要取消收藏这篇文章吗？', '确认取消', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        })
        const response = await toggleFavorite(articleId)
        if (response.data.code === 200) {
          ElMessage.success('已取消收藏')
          loadFavorites()
        } else {
          ElMessage.error(response.data.msg || '操作失败')
        }
      } catch (error) {
        if (error !== 'cancel') {
          logger.error('取消收藏失败:', error)
          ElMessage.error('操作失败')
        }
      }
    }

    const handlePageChange = (page) => {
      pageNum.value = page
      loadFavorites()
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }

    const goToDetail = (articleId) => router.push(`/knowledge/${articleId}`)
    const goToSquare = () => router.push('/knowledge')
    const goToMy = () => router.push('/knowledge/my')

    const getAvatar = (name) => (name || 'U').charAt(0).toUpperCase()
    
    const getSummary = (html) => {
      if (!html) return ''
      const parser = new DOMParser()
      const doc = parser.parseFromString(String(html), 'text/html')
      const text = doc.body.textContent || ''
      return text.length > 120 ? text.slice(0, 120) + '...' : text
    }

    const timeAgo = (str) => {
      if (!str) return ''
      const diff = Math.floor((Date.now() - new Date(str)) / 1000)
      if (diff < 60) return '刚刚'
      if (diff < 3600) return Math.floor(diff / 60) + '分钟前'
      if (diff < 86400) return Math.floor(diff / 3600) + '小时前'
      if (diff < 604800) return Math.floor(diff / 86400) + '天前'
      return new Date(str).toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' })
    }

    onMounted(() => {
      loadFavorites()
    })

    return {
      articles, loading, pageNum, pageSize, total,
      handleUnfavorite, handlePageChange,
      goToDetail, goToSquare, goToMy,
      getAvatar, getSummary, timeAgo
    }
  }
}
</script>


<style scoped>
/* 全局重置与基础样式 */
.knowledge-page {
  min-height: 100vh;
  background-color: #f8fafc;
  color: #334155;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

.page-container {
  padding-top: 80px;
  padding-bottom: 40px;
  max-width: 1280px;
  margin: 0 auto;
  padding-left: 20px;
  padding-right: 20px;
}

.main-layout {
  display: grid;
  grid-template-columns: 240px 1fr 300px;
  gap: 24px;
  align-items: start;
}

/* 左侧边栏 */
.left-sidebar {
  position: sticky;
  top: 90px;
}

.nav-menu {
  background: #fff;
  border-radius: 12px;
  padding: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  margin-bottom: 16px;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 8px;
  cursor: pointer;
  color: #64748b;
  font-weight: 500;
  transition: all 0.2s;
}

.menu-item:hover {
  background-color: #f1f5f9;
  color: #3b82f6;
}

.menu-item.active {
  background-color: #eff6ff;
  color: #3b82f6;
}

.menu-item i {
  width: 20px;
  text-align: center;
}

.topic-box {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.box-title {
  font-size: 14px;
  font-weight: 600;
  color: #94a3b8;
  margin-bottom: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.mini-stats {
  display: grid;
  grid-template-columns: 1fr;
  gap: 8px;
}

.mini-stat-item {
  text-align: center;
  padding: 10px;
  background: #f8fafc;
  border-radius: 8px;
}

.mini-stat-item .num {
  display: block;
  font-size: 24px;
  font-weight: 700;
  color: #3b82f6;
}

.mini-stat-item .label {
  font-size: 12px;
  color: #64748b;
}

/* 中间内容区 */
.content-feed {
  min-width: 0;
}

.feed-header {
  background: #fff;
  border-radius: 12px;
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.header-title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-title h2 {
  font-size: 18px;
  font-weight: 700;
  color: #1e293b;
  margin: 0;
}

.count-badge {
  background: #eff6ff;
  color: #3b82f6;
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 99px;
  font-weight: 600;
}

.create-btn {
  background: #3b82f6;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 8px 20px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
  font-size: 14px;
}

.create-btn:hover {
  background: #2563eb;
}

.create-btn.outline {
  background: transparent;
  border: 1px solid #3b82f6;
  color: #3b82f6;
}

.create-btn.outline:hover {
  background: #eff6ff;
}

/* 文章列表 */
.article-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.article-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  gap: 24px;
  cursor: pointer;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  transition: transform 0.2s, box-shadow 0.2s;
  position: relative;
}

.article-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05);
}

.card-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.author-row {
  display: flex;
  align-items: center;
  font-size: 13px;
  color: #64748b;
  margin-bottom: 12px;
}

.author-avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: linear-gradient(135deg, #60a5fa, #3b82f6);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: bold;
  margin-right: 8px;
}

.author-name {
  font-weight: 500;
  color: #334155;
}

.dot {
  margin: 0 6px;
  color: #cbd5e1;
}

.article-title {
  font-size: 18px;
  font-weight: 700;
  color: #1e293b;
  margin: 0 0 8px 0;
  line-height: 1.4;
  transition: color 0.2s;
}

.article-title:hover {
  color: #3b82f6;
}

.article-summary {
  font-size: 14px;
  color: #64748b;
  line-height: 1.6;
  margin: 0 0 16px 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  flex: 1;
}

.card-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: auto;
  border-top: 1px solid #f1f5f9;
  padding-top: 12px;
}

.stat-group {
  display: flex;
  gap: 16px;
}

.stat-item {
  font-size: 13px;
  color: #94a3b8;
  display: flex;
  align-items: center;
  gap: 4px;
}

.btn-icon {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background: #fff;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 14px;
}

.btn-icon:hover {
  border-color: #3b82f6;
  color: #3b82f6;
  background: #eff6ff;
}

.btn-icon.danger:hover {
  border-color: #ef4444;
  color: #ef4444;
  background: #fef2f2;
}

.card-cover {
  width: 160px;
  height: 120px;
  border-radius: 8px;
  overflow: hidden;
  flex-shrink: 0;
}

.card-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s;
}

.article-card:hover .card-cover img {
  transform: scale(1.05);
}

/* 空状态 */
.empty-state {
  text-align: center;
  padding: 60px 0;
  background: #fff;
  border-radius: 16px;
}

.empty-state img {
  width: 120px;
  margin-bottom: 20px;
  opacity: 0.5;
}

.empty-state h3 {
  color: #334155;
  margin-bottom: 8px;
}

.empty-state p {
  color: #94a3b8;
  margin-bottom: 24px;
}

.btn-primary {
  background: #3b82f6;
  color: #fff;
  border: none;
  padding: 10px 24px;
  border-radius: 99px;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.2s;
}

/* 右侧边栏 */
.right-sidebar {
  position: sticky;
  top: 90px;
}

.sidebar-card {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  margin-bottom: 16px;
}

.card-header {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.tips-list {
  padding-left: 20px;
  color: #64748b;
  font-size: 13px;
  line-height: 1.8;
}

/* 响应式适配 */
@media (max-width: 1024px) {
  .main-layout {
    grid-template-columns: 200px 1fr;
  }
  .right-sidebar {
    display: none;
  }
}

@media (max-width: 768px) {
  .main-layout {
    display: block;
  }
  .left-sidebar {
    display: none;
  }
  .card-cover {
    width: 100px;
    height: 75px;
  }
}
</style>

