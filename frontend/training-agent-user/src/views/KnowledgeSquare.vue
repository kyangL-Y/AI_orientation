<template>
  <div class="knowledge-page">
    <HeaderBar />
    
    <div class="page-container">
      <div class="main-layout">
        
        <!-- 左侧导航 (与其他智囊阁页面统一) -->
        <aside class="left-sidebar" data-guide="knowledge-square-nav">
          <div class="nav-menu">
            <div class="menu-item active" data-guide="knowledge-nav-square">
              <i class="fas fa-compass"></i>
              <span>知识广场</span>
            </div>
            <div class="menu-item" data-guide="knowledge-nav-my" @click="goToMy">
              <i class="fas fa-user"></i>
              <span>我的文章</span>
            </div>
            <div class="menu-item" data-guide="knowledge-nav-favorites" @click="goToFav">
              <i class="fas fa-bookmark"></i>
              <span>我的收藏</span>
            </div>
          </div>
          
          <div class="topic-box">
             <div class="box-title">推荐话题</div>
             <div class="topic-list">
               <div v-for="topic in ['服务技巧', 'OTA运营', '安全管理', '团队建设']" :key="topic" 
                     class="topic-tag" @click="selectTopic(topic)">
                 # {{ topic }}
               </div>
             </div>
          </div>
        </aside>

        <!-- 中间内容流 -->
        <main class="content-feed">
          <!-- 搜索与Banner -->
          <div class="feed-header-banner" data-guide="knowledge-square-banner">
             <div class="header-content">
               <h2>智囊阁</h2>
               <p>分享知识，共同成长</p>
             </div>
             <div class="header-search">
               <i class="fas fa-search"></i>
               <input v-model="keyword" @keyup.enter="doSearch" placeholder="搜索文章..." />
               <button @click="doSearch">搜索</button>
             </div>
          </div>

          <!-- 筛选Tab -->
          <div class="filter-tabs-wrapper">
            <div class="filter-tabs">
              <span 
                :class="['tab-item', { active: sortType === 'new' }]"
                @click="sortType = 'new'"
              >
                最新发布
              </span>
              <span 
                :class="['tab-item', { active: sortType === 'hot' }]"
                @click="sortType = 'hot'"
              >
                热门精选
              </span>
            </div>
            <button class="create-btn-sm" @click="goToCreate">
              <i class="fas fa-pen"></i> 发布
            </button>
          </div>

          <!-- 文章列表 -->
          <div class="article-list" data-guide="knowledge-square-list">
            <div v-if="loading" class="loading-skeleton">
              <div class="skeleton-item" v-for="i in 3" :key="i"></div>
            </div>

            <div v-else-if="list.length === 0" class="empty-state">
              <img src="https://cdn-icons-png.flaticon.com/512/7486/7486747.png" alt="Empty" />
              <h3>暂无相关文章</h3>
              <p>换个关键词试试，或者发布第一篇文章</p>
              <button class="btn-primary" @click="goToCreate">发布文章</button>
            </div>

            <template v-else>
              <div 
                v-for="(item, index) in list" 
                :key="item.articleId"
                :data-guide="index === 0 ? 'knowledge-square-first-article' : null"
                class="article-card"
                @click="toDetail(item.articleId)"
              >
                <div class="card-content">
                  <div class="author-row">
                    <div class="author-avatar">{{ getAvatar(item.authorName) }}</div>
                    <span class="author-name">{{ item.authorName }}</span>
                    <span class="dot">·</span>
                    <span class="publish-time">{{ timeAgo(item.createTime) }}</span>
                    <span v-if="item.isTop" class="top-badge">置顶</span>
                  </div>
                  
                  <h2 class="article-title">{{ item.title }}</h2>
                  <p class="article-summary">{{ getSummary(item.content) }}</p>
                  
                  <div class="card-footer">
                    <div class="stat-group">
                      <span class="stat-item"><i class="far fa-eye"></i> {{ item.viewCount || 0 }}</span>
                      <span class="stat-item"><i class="far fa-thumbs-up"></i> {{ item.likeCount || 0 }}</span>
                      <span class="stat-item"><i class="far fa-comment-alt"></i> {{ item.commentCount || 0 }}</span>
                    </div>
                  </div>
                </div>
                
                <div v-if="item.coverImage" class="card-cover">
                  <img :src="item.coverImage" :alt="item.title" loading="lazy" />
                </div>
              </div>

              <!-- 加载更多 -->
              <div v-if="hasMore" class="load-more-wrap">
                <button class="btn-load-more" @click="loadMore">
                  {{ loadingMore ? '加载中...' : '查看更多' }}
                </button>
              </div>
            </template>
          </div>
        </main>

        <!-- 右侧边栏 -->
        <aside class="right-sidebar">
          
          <!-- 热门排行 -->
          <div class="sidebar-card">
            <div class="card-header">
              <i class="fas fa-fire" style="color: #ef4444;"></i>
              <span>热门排行</span>
            </div>
            <div class="hot-list">
              <div v-for="(h, i) in hotList" :key="h.articleId" class="hot-item" @click="toDetail(h.articleId)">
                <span class="rank-num" :class="{ top: i < 3 }">{{ i + 1 }}</span>
                <span class="hot-title">{{ h.title }}</span>
              </div>
            </div>
          </div>

          <!-- 活跃作者 -->
          <div class="sidebar-card">
            <div class="card-header">
              <i class="fas fa-users" style="color: #f59e0b;"></i>
              <span>活跃作者</span>
            </div>
            <div class="author-list">
              <div v-for="a in authors" :key="a.id" class="author-item">
                <div class="author-avatar-sm">{{ getAvatar(a.name) }}</div>
                <div class="author-info">
                  <div class="name">{{ a.name }}</div>
                  <div class="desc">发布了 {{ a.count }} 篇文章</div>
                </div>
              </div>
            </div>
          </div>

        </aside>

      </div>
    </div>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import { ref, onMounted, watch, computed } from 'vue'
import { useRouter } from 'vue-router'
import HeaderBar from '@/components/HeaderBar.vue'
import { getArticleList, searchArticles } from '@/api/knowledge'

export default {
  name: 'KnowledgeSquare',
  components: { HeaderBar },
  setup() {
    const router = useRouter()
    const list = ref([])
    const hotList = ref([])
    const loading = ref(false)
    const loadingMore = ref(false)
    const keyword = ref('')
    const sortType = ref('new')
    const page = ref(1)
    const total = ref(0)
    
    const hasMore = computed(() => list.value.length < total.value)
    
    const authors = computed(() => {
      const map = {}
      list.value.forEach(item => {
        if (item.authorId) {
          if (!map[item.authorId]) map[item.authorId] = { id: item.authorId, name: item.authorName, count: 0 }
          map[item.authorId].count++
        }
      })
      return Object.values(map).sort((a, b) => b.count - a.count).slice(0, 5)
    })

    const fetchList = async (append = false) => {
      if (append) loadingMore.value = true
      else loading.value = true
      try {
        const params = { pageNum: page.value, pageSize: 10, status: 'published' }
        // 根据排序类型调整参数 (实际需后端支持，这里仅做示意)
        if (sortType.value === 'hot') {
            // params.orderBy = 'viewCount desc' 
        }
        
        const res = keyword.value ? await searchArticles(keyword.value, params) : await getArticleList(params)
        if (res.data.code === 200) {
          const rows = res.data.rows || []
          
          // 前端模拟热门排序 (如果后端不支持)
          if (!append && sortType.value === 'hot' && !keyword.value) {
             rows.sort((a, b) => {
               const topDiff = (b.isTop ? 1 : 0) - (a.isTop ? 1 : 0)
               if (topDiff !== 0) return topDiff
               return (b.viewCount + b.likeCount) - (a.viewCount + a.likeCount)
             })
          }

          list.value = append ? [...list.value, ...rows] : rows
          total.value = res.data.total || 0
        }
      } catch (e) { logger.error(e) }
      finally { loading.value = false; loadingMore.value = false }
    }

    const fetchHot = async () => {
      try {
        const res = await getArticleList({ pageNum: 1, pageSize: 20, status: 'published' })
        if (res.data.code === 200) {
          hotList.value = (res.data.rows || []).sort((a, b) => (b.viewCount + b.likeCount * 3) - (a.viewCount + a.likeCount * 3)).slice(0, 6)
        }
      } catch (e) {}
    }

    const doSearch = () => { page.value = 1; fetchList() }
    const selectTopic = (topic) => { keyword.value = topic; doSearch() }
    const loadMore = () => { page.value++; fetchList(true) }
    const toDetail = id => router.push(`/knowledge/${id}`)
    const goToCreate = () => router.push('/knowledge/edit')
    const goToMy = () => router.push('/knowledge/my')
    const goToFav = () => router.push('/knowledge/favorites')
    
    const getAvatar = name => (name || 'U').charAt(0).toUpperCase()
    
    const getSummary = html => {
      if (!html) return ''
      const parser = new DOMParser()
      const doc = parser.parseFromString(String(html), 'text/html')
      const text = doc.body.textContent || ''
      return text.length > 100 ? text.slice(0, 100) + '...' : text
    }
    
    const timeAgo = str => {
      if (!str) return ''
      const diff = Math.floor((Date.now() - new Date(str)) / 1000)
      if (diff < 60) return '刚刚'
      if (diff < 3600) return Math.floor(diff / 60) + '分钟前'
      if (diff < 86400) return Math.floor(diff / 3600) + '小时前'
      if (diff < 604800) return Math.floor(diff / 86400) + '天前'
      return new Date(str).toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' })
    }

    watch(sortType, () => { page.value = 1; fetchList() })
    onMounted(() => { fetchList(); fetchHot() })

    return { 
      list, hotList, authors, loading, loadingMore, keyword, sortType, hasMore, 
      doSearch, selectTopic, loadMore, toDetail, goToCreate, goToMy, goToFav, 
      getAvatar, getSummary, timeAgo 
    }
  }
}
</script>

<style scoped>
/* 统一风格 CSS - 复制自 MyKnowledge.vue 并做适配 */
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

.menu-item i { width: 20px; text-align: center; }

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

.topic-tag {
  display: inline-block;
  background: #f1f5f9;
  color: #475569;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 13px;
  margin-right: 8px;
  margin-bottom: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.topic-tag:hover {
  background: #e0f2fe;
  color: #0284c7;
}

/* 中间内容流 */
.content-feed {
  min-width: 0; /* 防止grid溢出 */
}

.feed-header-banner {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  border-radius: 16px;
  padding: 32px;
  color: white;
  margin-bottom: 24px;
  box-shadow: 0 4px 6px -1px rgba(59, 130, 246, 0.2);
}

.feed-header-banner h2 { font-size: 24px; font-weight: 700; margin-bottom: 4px; }
.feed-header-banner p { opacity: 0.9; margin-bottom: 20px; font-size: 14px; }

.header-search {
  background: rgba(255,255,255,0.2);
  backdrop-filter: blur(8px);
  border-radius: 8px;
  padding: 4px 4px 4px 16px;
  display: flex;
  align-items: center;
  border: 1px solid rgba(255,255,255,0.3);
}

.header-search i { margin-right: 12px; opacity: 0.8; }
.header-search input {
  background: transparent;
  border: none;
  color: white;
  flex: 1;
  font-size: 15px;
  outline: none;
}
.header-search input::placeholder { color: rgba(255,255,255,0.7); }
.header-search button {
  background: white;
  color: #2563eb;
  border: none;
  padding: 8px 20px;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}
.header-search button:hover { background: #eff6ff; }

.filter-tabs-wrapper {
  background: #fff;
  border-radius: 12px;
  padding: 6px;
  margin-bottom: 16px;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.filter-tabs { display: flex; gap: 4px; }

.tab-item {
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s;
}

.tab-item:hover { background: #f8fafc; color: #334155; }
.tab-item.active { background: #eff6ff; color: #3b82f6; font-weight: 600; }

.create-btn-sm {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: background 0.2s;
}
.create-btn-sm:hover { background: #2563eb; }

/* 文章列表 */
.article-list { display: flex; flex-direction: column; gap: 16px; }

.empty-state {
  background: #fff;
  border-radius: 12px;
  padding: 60px 20px;
  text-align: center;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.empty-state img { width: 80px; opacity: 0.5; margin-bottom: 16px; }
.empty-state h3 { font-size: 18px; color: #334155; margin-bottom: 8px; }
.empty-state p { color: #94a3b8; font-size: 14px; margin-bottom: 24px; }
.btn-primary {
  background: #3b82f6; color: white; border: none; padding: 10px 24px;
  border-radius: 8px; font-weight: 600; cursor: pointer;
}

.article-card {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  display: flex;
  gap: 20px;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  border: 1px solid transparent;
}

.article-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  border-color: #bfdbfe;
}

.card-content { flex: 1; min-width: 0; display: flex; flex-direction: column; }

.author-row {
  display: flex;
  align-items: center;
  font-size: 13px;
  color: #64748b;
  margin-bottom: 8px;
}

.author-avatar {
  width: 20px; height: 20px;
  background: #e0f2fe; color: #0284c7;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 10px; font-weight: 700;
  margin-right: 8px;
}

.author-name { font-weight: 500; color: #334155; }
.dot { margin: 0 6px; }
.top-badge {
  background: #fee2e2; color: #ef4444;
  font-size: 10px; padding: 1px 6px; border-radius: 4px;
  margin-left: 8px; font-weight: 600;
}

.article-title {
  font-size: 18px; font-weight: 700; color: #1e293b;
  margin-bottom: 8px; line-height: 1.4;
  display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden;
}

.article-summary {
  font-size: 14px; color: #64748b; line-height: 1.6;
  margin-bottom: 16px; flex: 1;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}

.card-footer { margin-top: auto; display: flex; justify-content: space-between; align-items: center; }

.stat-group { display: flex; gap: 16px; font-size: 13px; color: #94a3b8; }
.stat-item i { margin-right: 4px; }

.card-cover {
  width: 160px; height: 100px;
  border-radius: 8px; overflow: hidden; flex-shrink: 0;
  background: #f1f5f9;
}
.card-cover img { width: 100%; height: 100%; object-fit: cover; }

.load-more-wrap { text-align: center; margin-top: 24px; }
.btn-load-more {
  background: #fff; border: 1px solid #e2e8f0; color: #64748b;
  padding: 10px 30px; border-radius: 20px; font-size: 14px;
  cursor: pointer; transition: all 0.2s;
}
.btn-load-more:hover { border-color: #cbd5e1; background: #f8fafc; }

/* 右侧边栏 */
.right-sidebar { position: sticky; top: 90px; display: flex; flex-direction: column; gap: 16px; }

.sidebar-card {
  background: #fff;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.card-header {
  display: flex; align-items: center; gap: 8px;
  font-size: 15px; font-weight: 600; color: #334155;
  margin-bottom: 16px; padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.hot-item {
  display: flex; gap: 12px; margin-bottom: 12px;
  cursor: pointer; align-items: flex-start;
}
.hot-item:last-child { margin-bottom: 0; }
.hot-item:hover .hot-title { color: #3b82f6; }

.rank-num {
  width: 18px; height: 18px;
  background: #f1f5f9; color: #94a3b8;
  border-radius: 4px; font-size: 11px; font-weight: 700;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0; margin-top: 2px;
}
.rank-num.top { background: #fee2e2; color: #ef4444; }

.hot-title {
  font-size: 13px; color: #475569; line-height: 1.5;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
  transition: color 0.2s;
}

.author-item {
  display: flex; align-items: center; gap: 12px;
  margin-bottom: 16px;
}
.author-item:last-child { margin-bottom: 0; }

.author-avatar-sm {
  width: 36px; height: 36px;
  background: #f0f9ff; color: #0ea5e9;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 14px; font-weight: 700;
}

.author-info .name { font-size: 14px; font-weight: 600; color: #334155; }
.author-info .desc { font-size: 12px; color: #94a3b8; }

.loading-skeleton { padding: 20px; }
.skeleton-item { height: 120px; background: #e2e8f0; margin-bottom: 16px; border-radius: 8px; animation: pulse 1.5s infinite; }
@keyframes pulse { 0% { opacity: 0.6; } 50% { opacity: 1; } 100% { opacity: 0.6; } }

/* 响应式 */
@media (max-width: 1024px) {
  .main-layout { grid-template-columns: 200px 1fr; }
  .right-sidebar { display: none; }
}

@media (max-width: 768px) {
  .page-container {
    padding-bottom: 24px;
  }
  .main-layout { display: block; gap: 12px; }
  .left-sidebar { 
    position: static; margin-bottom: 12px; 
    display: flex; overflow-x: auto; gap: 8px;
    padding-bottom: 4px; /* Space for scrollbar if visible */
    scrollbar-width: none; /* Firefox */
    -ms-overflow-style: none; /* IE 10+ */
  }
  .left-sidebar::-webkit-scrollbar { 
    display: none; /* Chrome/Safari */
  }
  .nav-menu { 
    width: auto; 
    display: flex; 
    margin-bottom: 0; 
    background: transparent;
    padding: 0;
    box-shadow: none;
    gap: 6px;
  }
  .menu-item { 
    flex: 0 0 auto; 
    justify-content: center; 
    padding: 7px 12px; 
    background: white;
    border-radius: 20px;
    box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    border: 1px solid #f1f5f9;
    font-size: 13px;
  }
  .menu-item.active {
    background: #eff6ff;
    border-color: #bfdbfe;
  }
  .topic-box { display: none; }
  .feed-header-banner {
    padding: 18px 16px;
    margin-bottom: 14px;
  }
  .feed-header-banner h2 {
    font-size: 20px;
    margin-bottom: 2px;
  }
  .feed-header-banner p {
    margin-bottom: 14px;
    font-size: 13px;
  }
  .header-search {
    padding: 4px 4px 4px 12px;
    gap: 8px;
  }
  .header-search i {
    margin-right: 0;
  }
  .header-search input {
    font-size: 14px;
    min-width: 0;
  }
  .header-search button {
    padding: 8px 14px;
    font-size: 13px;
    white-space: nowrap;
  }
  .filter-tabs-wrapper {
    flex-wrap: wrap;
    align-items: stretch;
    gap: 8px;
    padding: 8px;
    margin-bottom: 14px;
  }
  .filter-tabs {
    width: 100%;
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .tab-item {
    text-align: center;
    padding: 9px 10px;
    font-size: 13px;
  }
  .create-btn-sm {
    width: 100%;
    justify-content: center;
    padding: 10px 14px;
  }
  .article-list {
    gap: 12px;
  }
  .article-card {
    flex-direction: column;
    gap: 12px;
    padding: 14px;
  }
  .author-row {
    flex-wrap: wrap;
    row-gap: 6px;
    font-size: 12px;
  }
  .article-title {
    font-size: 16px;
    -webkit-line-clamp: 2;
  }
  .article-summary {
    font-size: 13px;
    line-height: 1.55;
    margin-bottom: 12px;
  }
  .card-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  .stat-group {
    flex-wrap: wrap;
    gap: 10px;
    font-size: 12px;
  }
  .card-cover { width: 100%; height: 160px; order: -1; margin-bottom: 0; }
}

@media (max-width: 420px) {
  .feed-header-banner {
    padding: 16px 14px;
  }
  .header-search {
    flex-wrap: wrap;
    align-items: stretch;
  }
  .header-search input {
    width: 100%;
    order: 1;
  }
  .header-search button {
    width: 100%;
    order: 2;
    justify-content: center;
  }
  .header-search i {
    order: 0;
  }
  .menu-item {
    padding: 7px 10px;
  }
  .article-card {
    padding: 12px;
  }
  .card-cover {
    height: 140px;
  }
}
</style>

