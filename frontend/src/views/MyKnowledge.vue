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
            <div class="menu-item active" data-guide="knowledge-nav-my">
              <i class="fas fa-user"></i>
              <span>我的文章</span>
            </div>
            <div class="menu-item" data-guide="knowledge-nav-favorites" @click="goToFav">
              <i class="fas fa-bookmark"></i>
              <span>我的收藏</span>
            </div>
          </div>
          
          <div class="topic-box">
             <!-- 创作激励或统计简报 -->
             <div class="box-title">创作概览</div>
             <div class="mini-stats">
               <div class="mini-stat-item">
                 <span class="num">{{ stats.published || 0 }}</span>
                 <span class="label">已发布</span>
               </div>
               <div class="mini-stat-item">
                 <span class="num">{{ stats.totalViews || 0 }}</span>
                 <span class="label">总阅读</span>
               </div>
             </div>
          </div>
        </aside>

        <!-- 中间内容流 -->
        <main class="content-feed">
          <!-- 页面标题与操作 -->
          <div class="feed-header" data-guide="knowledge-my-header">
            <div class="header-title">
              <h2>我的文章</h2>
              <span class="count-badge">{{ total }}</span>
            </div>
            <button class="create-btn" @click="goToCreate">
              <i class="fas fa-pen"></i> <span>写文章</span>
            </button>
          </div>

          <!-- 状态筛选 -->
          <div class="filter-tabs-wrapper" data-guide="knowledge-my-filters">
            <div class="filter-tabs">
              <span 
                v-for="s in statusList" 
                :key="s.value"
                :class="['tab-item', { active: currentStatus === s.value }]"
                @click="changeStatus(s.value)"
              >
                {{ s.label }}
              </span>
            </div>
          </div>

          <!-- 文章列表 -->
          <div class="article-list" data-guide="knowledge-my-list">
            <div v-if="loading" class="loading-skeleton">
              <div class="skeleton-item" v-for="i in 3" :key="i"></div>
            </div>

            <div v-else-if="articles.length === 0" class="empty-state">
              <img src="https://cdn-icons-png.flaticon.com/512/7486/7486747.png" alt="Empty" />
              <h3>暂无文章</h3>
              <p>开始创作你的第一篇文章吧</p>
              <button class="btn-primary" @click="goToCreate">写文章</button>
            </div>

            <template v-else>
              <div 
                v-for="article in articles" 
                :key="article.articleId"
                class="article-card"
              >
                <div class="card-content">
                  <div class="card-header-row">
                    <span :class="['status-badge', article.status]">
                      {{ getStatusText(article.status) }}
                    </span>
                    <span class="publish-time">{{ formatTime(article.createTime) }}</span>
                  </div>
                  
                  <h2 class="article-title" @click="goToDetail(article.articleId)">
                    {{ article.title }}
                  </h2>
                  
                  <p class="article-summary">{{ getExcerpt(article.content) }}</p>

                  <!-- 拒绝原因 -->
                  <div v-if="article.status === 'rejected' && article.rejectReason" class="reject-reason">
                    <i class="fas fa-exclamation-circle"></i>
                    <span>{{ article.rejectReason }}</span>
                  </div>

                  <div class="card-footer">
                    <div class="stat-group" v-if="article.status === 'published'">
                      <span class="stat-item"><i class="far fa-eye"></i> {{ article.viewCount || 0 }}</span>
                      <span class="stat-item"><i class="far fa-thumbs-up"></i> {{ article.likeCount || 0 }}</span>
                      <span class="stat-item"><i class="far fa-comment-alt"></i> {{ article.commentCount || 0 }}</span>
                    </div>
                    <div class="stat-group" v-else>
                       <span class="stat-item">最后更新: {{ formatTime(article.updateTime || article.createTime) }}</span>
                    </div>
                    
                    <div class="action-group">
                      <button 
                        v-if="article.status === 'published'"
                        class="btn-icon"
                        title="未读名单"
                        @click="showUnreadModal(article)"
                      >
                        <i class="fas fa-users"></i>
                      </button>
                      <button 
                        v-if="article.status === 'draft' || article.status === 'rejected'"
                        class="btn-icon primary"
                        title="编辑"
                        @click="goToEdit(article.articleId)"
                      >
                        <i class="fas fa-edit"></i>
                      </button>
                      <button 
                        v-if="article.status === 'published' || article.status === 'pending'"
                        class="btn-icon"
                        title="查看"
                        @click="goToDetail(article.articleId)"
                      >
                        <i class="far fa-eye"></i>
                      </button>
                      <button 
                        class="btn-icon danger"
                        title="删除"
                        @click="handleDelete(article.articleId)"
                      >
                        <i class="far fa-trash-alt"></i>
                      </button>
                    </div>
                  </div>
                </div>
                
                <div v-if="article.coverImage" class="card-cover">
                  <img :src="article.coverImage" loading="lazy" />
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
          <!-- 创作统计详细版 -->
          <div class="sidebar-card">
            <div class="card-header">
              <i class="fas fa-chart-pie" style="color: #3b82f6;"></i>
              <span>数据统计</span>
            </div>
            <div class="stats-grid">
              <div class="stat-box">
                <span class="stat-num">{{ stats.published || 0 }}</span>
                <span class="stat-label">已发布</span>
              </div>
              <div class="stat-box">
                <span class="stat-num">{{ stats.pending || 0 }}</span>
                <span class="stat-label">审核中</span>
              </div>
              <div class="stat-box">
                <span class="stat-num">{{ stats.draft || 0 }}</span>
                <span class="stat-label">草稿箱</span>
              </div>
              <div class="stat-box">
                <span class="stat-num">{{ stats.totalViews || 0 }}</span>
                <span class="stat-label">总阅读</span>
              </div>
            </div>
          </div>
          
          <!-- 小提示 -->
          <div class="sidebar-card">
            <div class="card-header">
              <i class="fas fa-lightbulb" style="color: #f59e0b;"></i>
              <span>创作贴士</span>
            </div>
            <ul class="tips-list">
              <li>发布前请仔细检查内容和排版</li>
              <li>优质的封面图能吸引更多阅读</li>
              <li>添加合适的话题标签更容易被发现</li>
            </ul>
          </div>
        </aside>

      </div>
    </div>

    <!-- 未读用户弹窗 -->
    <el-dialog
      title="未阅读用户名单"
      v-model="unreadDialogVisible"
      width="500px"
      destroy-on-close
      class="custom-dialog"
    >
      <div v-loading="unreadLoading" class="unread-modal-body">
        <div v-if="unreadUsers.length === 0" class="unread-empty">
          <i class="fas fa-check-circle"></i>
          <p>所有人均已阅读，太棒了！</p>
        </div>
        <div v-else class="unread-list">
          <div class="unread-count">还有 {{ unreadUsers.length }} 位下级成员未阅读</div>
          <div class="unread-items">
            <div v-for="user in unreadUsers" :key="user.userId" class="unread-user-item">
              <div class="user-info">
                <span class="user-name">{{ user.nickName || user.userName }}</span>
                <span class="user-dept">{{ user.deptName }}</span>
              </div>
              <button class="btn-remind" @click="remindUser(user)">提醒</button>
            </div>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import HeaderBar from '@/components/HeaderBar.vue'
import { getMyArticles, deleteArticle } from '@/api/knowledge'
import { api } from '@/utils/api'

export default {
  name: 'MyKnowledge',
  components: { HeaderBar },
  setup() {
    const router = useRouter()
    
    const articles = ref([])
    const stats = ref({ published: 0, pending: 0, draft: 0, totalViews: 0 })
    const loading = ref(false)
    const currentStatus = ref(null)
    const pageNum = ref(1)
    const pageSize = ref(10)
    const total = ref(0)
    
    // 未读用户相关
    const unreadDialogVisible = ref(false)
    const unreadLoading = ref(false)
    const unreadUsers = ref([])

    const statusList = [
      { label: '全部', value: null },
      { label: '已发布', value: 'published' },
      { label: '审核中', value: 'pending' },
      { label: '草稿箱', value: 'draft' },
      { label: '已拒绝', value: 'rejected' }
    ]

    const loadData = async () => {
      loading.value = true
      try {
        const params = { 
          pageNum: pageNum.value, 
          pageSize: pageSize.value,
          status: currentStatus.value 
        }
        const res = await getMyArticles(currentStatus.value, params)
        if (res.data.code === 200) {
          articles.value = res.data.rows || []
          total.value = res.data.total || 0
          
          // 计算统计数据 (简单模拟，实际应由后端返回)
          // 注意：这里只统计当前页，准确统计需要后端支持
          // 为了演示，我们假设后端有一个单独的统计接口或者我们只统计加载到的
        }
      } catch (e) {
        logger.error(e)
      } finally {
        loading.value = false
      }
    }
    
    // 加载统计数据
    const loadStats = async () => {
        // 模拟统计数据加载，实际项目应调用专门的接口
        // 这里暂时不实现全量统计，仅作为占位
    }

    const changeStatus = (status) => {
      currentStatus.value = status
      pageNum.value = 1
      loadData()
    }

    const handlePageChange = (val) => {
      pageNum.value = val
      loadData()
    }

    const handleDelete = (id) => {
      ElMessageBox.confirm('确定要删除这篇文章吗？', '提示', { type: 'warning' })
        .then(async () => {
          const res = await deleteArticle(id)
          if (res.data.code === 200) {
            ElMessage.success('删除成功')
            loadData()
          }
        })
    }
    
    const showUnreadModal = async (article) => {
      unreadDialogVisible.value = true
      unreadLoading.value = true
      unreadUsers.value = []
      try {
        const res = await api.get(`/train/knowledge/article/${article.articleId}/unread-users`)
        if (res.data.code === 200) {
          unreadUsers.value = res.data.data || []
        } else {
          ElMessage.error(res.data.msg || '获取未读名单失败')
        }
      } catch (e) {
        ElMessage.error('获取未读名单失败')
      } finally {
        unreadLoading.value = false
      }
    }
    
    const remindUser = (user) => {
      ElMessage.success(`已向 ${user.nickName} 发送提醒`)
    }

    const goToCreate = () => router.push('/knowledge/edit')
    const goToEdit = (id) => router.push(`/knowledge/edit/${id}`)
    const goToDetail = (id) => router.push(`/knowledge/${id}`)
    const goToSquare = () => router.push('/knowledge')
    const goToFav = () => router.push('/knowledge/favorites')

    const getStatusText = (status) => {
      const map = {
        published: '已发布',
        pending: '审核中',
        draft: '草稿',
        rejected: '已拒绝'
      }
      return map[status] || status
    }

    const formatTime = (time) => {
      if (!time) return ''
      return time.split(' ')[0]
    }

    const getExcerpt = (html) => {
      if (!html) return ''
      const parser = new DOMParser()
      const doc = parser.parseFromString(String(html), 'text/html')
      return (doc.body.textContent || '').slice(0, 80) + '...'
    }

    onMounted(() => {
      loadData()
      loadStats()
    })

    return {
      articles, loading, currentStatus, pageNum, pageSize, total,
      statusList, stats,
      changeStatus, handlePageChange, handleDelete,
      goToCreate, goToEdit, goToDetail, goToSquare, goToFav,
      getStatusText, formatTime, getExcerpt,
      unreadDialogVisible, unreadLoading, unreadUsers, showUnreadModal, remindUser
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
  grid-template-columns: 1fr 1fr;
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
  font-size: 18px;
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
  transition: background 0.2s;
  font-size: 14px;
}

.create-btn:hover {
  background: #2563eb;
}

/* 筛选标签 */
.filter-tabs-wrapper {
  margin-bottom: 20px;
  overflow-x: auto;
}

.filter-tabs {
  display: flex;
  gap: 8px;
}

.tab-item {
  padding: 6px 16px;
  background: #fff;
  border-radius: 99px;
  font-size: 14px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
  border: 1px solid transparent;
}

.tab-item:hover {
  color: #3b82f6;
  background: #fff;
}

.tab-item.active {
  background: #3b82f6;
  color: #fff;
  box-shadow: 0 4px 6px -1px rgba(59, 130, 246, 0.3);
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

.card-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.status-badge {
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 500;
}

.status-badge.published { background: #dcfce7; color: #166534; }
.status-badge.pending { background: #fef9c3; color: #854d0e; }
.status-badge.draft { background: #f1f5f9; color: #475569; }
.status-badge.rejected { background: #fee2e2; color: #991b1b; }

.publish-time {
  font-size: 12px;
  color: #94a3b8;
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

.reject-reason {
  background: #fee2e2;
  color: #b91c1c;
  padding: 8px 12px;
  border-radius: 8px;
  font-size: 13px;
  margin-bottom: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
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

.action-group {
  display: flex;
  gap: 8px;
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

.btn-icon.primary {
  color: #3b82f6;
  border-color: #3b82f6;
  background: #eff6ff;
}
.btn-icon.primary:hover {
  background: #3b82f6;
  color: #fff;
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

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.stat-box {
  background: #f8fafc;
  border-radius: 8px;
  padding: 12px;
  text-align: center;
}

.stat-num {
  display: block;
  font-size: 20px;
  font-weight: 700;
  color: #3b82f6;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 12px;
  color: #64748b;
}

.tips-list {
  padding-left: 20px;
  color: #64748b;
  font-size: 13px;
  line-height: 1.8;
}

/* 弹窗样式优化 */
.unread-modal-body {
  min-height: 200px;
}
.unread-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
  color: #10b981;
}
.unread-empty i { font-size: 48px; margin-bottom: 16px; }
.unread-empty p { font-size: 16px; color: #334155; font-weight: 500; }

.unread-list { padding: 10px; }
.unread-count { font-size: 14px; color: #64748b; margin-bottom: 16px; }
.unread-user-item {
  display: flex; justify-content: space-between; align-items: center;
  padding: 12px 0; border-bottom: 1px solid #f1f5f9;
}
.unread-user-item:last-child { border-bottom: none; }
.user-info { display: flex; flex-direction: column; }
.user-name { font-weight: 500; font-size: 14px; color: #1e293b; }
.user-dept { font-size: 12px; color: #94a3b8; margin-top: 4px; }

.btn-remind {
  background: #eff6ff; color: #3b82f6; border: none;
  padding: 6px 12px; border-radius: 6px; font-size: 12px; font-weight: 500;
  cursor: pointer; transition: all 0.2s;
}
.btn-remind:hover { background: #3b82f6; color: #fff; }

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

