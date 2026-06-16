<template>
  <div class="culture-page">
    <HeaderBar />
    <PageVisitTracker pageName="企业文化" />
    
    <!-- 顶部 Hero 区域 -->
    <div class="hero-header">
      <div class="hero-bg-pattern"></div>
      <div class="hero-container">
        <div class="hero-content">
          <div class="brand-tag">HUAWISE CULTURE</div>
          <h1 class="main-title">企业文化手册</h1>
          <p class="sub-title">以情服务 · 用心做事 · 追求卓越</p>
        </div>
        <div class="hero-decoration">
          <div class="deco-circle c1"></div>
          <div class="deco-circle c2"></div>
        </div>
      </div>
    </div>

    <div class="main-container">
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <span>正在加载文化篇章...</span>
      </div>

      <div v-else-if="sections.length > 0" class="content-layout">
        <!-- 左侧导航栏 (Sticky) -->
        <aside class="side-nav">
          <div class="nav-card">
            <div class="nav-title">
              <i class="fas fa-list-ul"></i> 目录导航
            </div>
            <ul class="nav-list">
              <li 
                v-for="(section, idx) in sections" 
                :key="idx"
                :class="{ active: activeSection === idx }"
                @click="scrollToSection(idx)"
              >
                <span class="nav-icon"><i :class="getIcon(section.title)"></i></span>
                <span class="nav-text">{{ section.title }}</span>
              </li>
            </ul>
          </div>
          
          <!-- 快速引用卡片 -->
          <div class="quote-card">
            <i class="fas fa-quote-left quote-icon"></i>
            <p>顾客利益第一<br>酒店声誉第一</p>
          </div>
        </aside>

        <!-- 右侧内容区 -->
        <main class="content-stream">
          <section 
            v-for="(section, idx) in sections" 
            :key="idx"
            :id="'section-' + idx"
            class="culture-section"
            :class="{ 'animate-in': true }"
          >
            <div class="section-header">
              <div class="section-icon" :style="{ background: getGradient(idx) }">
                <i :class="getIcon(section.title)"></i>
              </div>
              <h2 class="section-title">{{ section.title }}</h2>
            </div>
            <div class="section-body typography" v-html="section.content"></div>
            <div class="section-footer">
              <span class="read-mark">HUAWISE CULTURE</span>
            </div>
          </section>
        </main>
      </div>

      <!-- 空状态 -->
      <div v-else class="empty-state">
        <div class="empty-img">📚</div>
        <h3>暂无企业文化内容</h3>
        <p>内容正在精心编撰中，敬请期待...</p>
      </div>
    </div>

    <!-- 底部 -->
    <footer class="page-footer">
      <div class="footer-content">
        <p>© 华智酒店集团 | 企业文化中心</p>
      </div>
    </footer>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import HeaderBar from '@/components/HeaderBar.vue'
import PageVisitTracker from '@/components/PageVisitTracker.vue'
import { getCustomization, getMyCustomization } from '@/api/customization'
import { sanitizeHtml } from '@/utils/security'
import { getTenantId } from '@/utils/tenantContext'

const loading = ref(true)
const sections = ref([])
const activeSection = ref(0)

// 渐变色配置 - 更加稳重、高级的配色 (金/深蓝/雅灰)
const gradients = [
  'linear-gradient(135deg, #C5A065 0%, #B8860B 100%)', // 香槟金
  'linear-gradient(135deg, #2C3E50 0%, #4CA1AF 100%)', // 深蓝灰
  'linear-gradient(135deg, #614385 0%, #516395 100%)', // 雅致紫
  'linear-gradient(135deg, #1f4037 0%, #99f2c8 100%)', // 翡翠绿 (安全)
  'linear-gradient(135deg, #cc2b5e 0%, #753a88 100%)', // 勃艮第红 (热情)
]

function getGradient(idx) {
  return gradients[idx % gradients.length]
}

// 图标映射
function getIcon(title) {
  const map = {
    '服务宣言': 'fas fa-bullhorn',
    '企业文化核心理念': 'far fa-gem',
    '核心价值观': 'fas fa-heart',
    '愿景': 'far fa-eye',
    '使命': 'fas fa-flag',
    '安全篇': 'fas fa-shield-alt',
    '服务篇': 'fas fa-concierge-bell',
    '管理篇': 'fas fa-tasks',
    '作风篇': 'fas fa-user-tie',
    '人才篇': 'fas fa-user-graduate',
    '创新篇': 'far fa-lightbulb',
    '历史': 'fas fa-history'
  }
  // 简单的关键词匹配兜底
  if (!map[title]) {
    if (title.includes('服务')) return 'fas fa-concierge-bell'
    if (title.includes('安全')) return 'fas fa-shield-alt'
    if (title.includes('管理')) return 'fas fa-tasks'
    if (title.includes('人')) return 'fas fa-user'
  }
  return map[title] || 'fas fa-bookmark'
}

// 滚动定位
function scrollToSection(idx) {
  activeSection.value = idx
  const el = document.getElementById('section-' + idx)
  if (el) {
    const offset = 100 // header height + padding
    const top = el.getBoundingClientRect().top + window.pageYOffset - offset
    window.scrollTo({ top, behavior: 'smooth' })
  }
}

// 监听滚动更新当前激活项
const handleScroll = () => {
  const scrollPosition = window.scrollY + 150
  
  // 倒序遍历找到当前所在的 section
  for (let i = sections.value.length - 1; i >= 0; i--) {
    const el = document.getElementById('section-' + i)
    if (el && el.offsetTop <= scrollPosition) {
      activeSection.value = i
      break
    }
  }
}

// 加载数据
async function loadData() {
  loading.value = true
  try {
    let res
    const tokenExists = !!localStorage.getItem('authToken')
    const loggedIn = tokenExists
    const tenantId = getTenantId()

    logger.debug('[企业文化] 开始加载', {
      loggedIn,
      tokenExists,
      tenantId
    })

    if (tokenExists) {
      try {
        res = await getMyCustomization()
      } catch (e) {
        logger.warn('[企业文化] 获取当前租户配置失败，回退公开配置', e)
        res = await getCustomization(tenantId)
      }
    } else {
      res = await getCustomization(tenantId)
    }
    
    // 尝试多种数据格式解析
    let config = null
    
    // 格式1: { data: { code: 200, data: {...} } }
    if (res.data?.code === 200 && res.data.data) {
      config = res.data.data
    }
    // 格式2: { data: { tenantId: '...', customPagesConfig: '...' } }
    else if (res.data?.tenantId) {
      config = res.data
    }
    // 格式3: { code: 200, data: {...} }
    else if (res.code === 200 && res.data) {
      config = res.data
    }
    // 格式4: 直接就是配置对象
    else if (res.customPagesConfig || res.custom_pages_config) {
      config = res
    }

    if (config) {
      logger.debug('[企业文化] 配置对象字段', Object.keys(config))
      // 支持驼峰和下划线两种字段名
      let pagesConfigStr = config.customPagesConfig || config.custom_pages_config
      
      if (pagesConfigStr) {
        let pages = null
        
        // 如果是字符串，需要解析JSON
        if (typeof pagesConfigStr === 'string') {
          try {
            pages = JSON.parse(pagesConfigStr)
          } catch (e) {
            // JSON解析失败，可能是因为转义字符，尝试清理后再解析
            const cleaned = pagesConfigStr
              .replace(/\\r/g, '')
              .replace(/\\n/g, '')
              .replace(/\\\\/g, '\\')
            pages = JSON.parse(cleaned)
          }
        } else {
          pages = pagesConfigStr
        }
        
        logger.debug('[企业文化] customPagesConfig 解析结果字段', pages ? Object.keys(pages) : [])
        let html = pages.corporateCultureHtml || ''
        
        // 清理HTML中可能残留的转义字符
        if (html && typeof html === 'string') {
          html = html
            .replace(/\\r\\n/g, '\n')
            .replace(/\\n/g, '\n')
            .replace(/\\r/g, '')
            .replace(/\\"/g, '"')
            .replace(/\\\\/g, '\\')
            .trim()
        }

        if (html) {
          // 提取 h2 作为章节
          const regex = /<h2>(.*?)<\/h2>/gi
          const matches = []
          let m
          while ((m = regex.exec(html)) !== null) {
            matches.push({ idx: m.index, title: m[1], end: m.index + m[0].length })
          }

          if (matches.length > 0) {
            sections.value = matches.map((cur, i) => {
              const next = matches[i + 1]
              let content = html.substring(cur.end, next ? next.idx : html.length).trim()
              content = content.replace(/<hr\s*\/?>/gi, '') // 移除 hr
              return {
                title: cur.title.replace(/<[^>]+>/g, '').trim(),
                content: sanitizeHtml(content)
              }
            })
          } else if (html.trim()) {
            // 如果没有 h2，整个作为一章
            sections.value = [{ title: '企业文化', content: sanitizeHtml(html) }]
          }
          logger.debug('[企业文化] 解析完成', {
            htmlLength: html.length,
            sections: sections.value.length
          })
        } else {
          logger.warn('[企业文化] corporateCultureHtml 为空')
        }
      } else {
        logger.warn('[企业文化] customPagesConfig 为空')
      }
    } else {
      logger.warn('[企业文化] 未获取到配置对象')
    }
  } catch (e) {
    logger.error('[企业文化] 加载失败:', e)
  } finally {
    loading.value = false
    nextTick(() => {
      window.addEventListener('scroll', handleScroll)
    })
  }
}

onMounted(loadData)

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<style scoped>
.culture-page {
  min-height: 100vh;
  background-color: #f8f9fa;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

/* Hero Header */
.hero-header {
  position: relative;
  height: 360px;
  /* 替换为更高级的深色背景 */
  background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
  color: white;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  padding-top: 60px; /* Header space */
}

.hero-bg-pattern {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  /* 使用更优雅的几何纹理 */
  background-image: 
    radial-gradient(circle at 10% 20%, rgba(197, 160, 101, 0.1) 0%, transparent 20%),
    radial-gradient(circle at 90% 80%, rgba(197, 160, 101, 0.1) 0%, transparent 20%);
  opacity: 1;
}

.hero-container {
  position: relative;
  text-align: center;
  z-index: 1;
  animation: fadeInDown 0.8s ease-out;
}

.brand-tag {
  display: inline-block;
  padding: 6px 16px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(197, 160, 101, 0.3); /* 金色边框 */
  border-radius: 30px;
  font-size: 12px;
  letter-spacing: 3px;
  margin-bottom: 20px;
  backdrop-filter: blur(5px);
  color: #d4af37; /* 香槟金文字 */
  font-weight: 600;
}

.main-title {
  font-size: 48px;
  font-weight: 700;
  margin: 0 0 16px;
  letter-spacing: 2px;
  /* 更加柔和的白色 */
  color: #f8fafc;
  text-shadow: 0 4px 12px rgba(0,0,0,0.3);
}

.sub-title {
  font-size: 18px;
  color: #cbd5e1; /* 浅灰 */
  font-weight: 300;
  letter-spacing: 1px;
}

/* Layout */
.main-container {
  max-width: 1200px;
  margin: -60px auto 40px; /* Overlap hero */
  padding: 0 24px;
  position: relative;
  z-index: 2;
}

.content-layout {
  display: flex;
  gap: 32px;
}

/* Sidebar */
.side-nav {
  width: 260px;
  flex-shrink: 0;
  position: sticky;
  top: 100px; /* Header + padding */
  height: fit-content;
  display: none; /* Mobile default hidden */
}

@media (min-width: 992px) {
  .side-nav {
    display: block;
  }
}

.nav-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.05);
  overflow: hidden;
  margin-bottom: 24px;
}

.nav-title {
  padding: 16px 20px;
  background: #fff;
  border-bottom: 1px solid #f0f0f0;
  font-weight: 600;
  color: #333;
}

.nav-list {
  list-style: none;
  padding: 8px 0;
  margin: 0;
}

.nav-list li {
  padding: 12px 20px;
  cursor: pointer;
  display: flex;
  align-items: center;
  color: #666;
  transition: all 0.3s;
  border-left: 3px solid transparent;
}

.nav-list li:hover {
  background: #fdfbf7; /* 极浅的米金色 */
  color: #b8860b; /* 暗金色 */
}

.nav-list li.active {
  background: #fff9e6; /* 浅金色背景 */
  color: #b8860b;
  border-left-color: #b8860b;
  font-weight: 600;
}

.nav-icon {
  width: 24px;
  margin-right: 8px;
  text-align: center;
}

.quote-card {
  background: linear-gradient(135deg, #1e293b 0%, #334155 100%); /* 深岩灰 */
  color: #f1f5f9;
  padding: 24px;
  border-radius: 12px;
  position: relative;
  overflow: hidden;
  text-align: center;
  box-shadow: 0 8px 24px rgba(30, 41, 59, 0.2);
  border: 1px solid rgba(197, 160, 101, 0.2);
}

.quote-icon {
  font-size: 24px;
  color: #d4af37; /* 金色图标 */
  opacity: 0.8;
  margin-bottom: 12px;
  display: block;
}

.quote-card p {
  margin: 0;
  line-height: 1.6;
  font-weight: 500;
  position: relative;
  z-index: 1;
}

/* Main Content Stream */
.content-stream {
  flex: 1;
  min-width: 0; /* Prevent flex overflow */
}

.culture-section {
  background: white;
  border-radius: 16px;
  padding: 40px;
  margin-bottom: 32px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.04);
  transition: transform 0.3s, box-shadow 0.3s;
}

.culture-section:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.06);
}

.section-header {
  display: flex;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 1px solid #f0f0f0;
}

.section-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 20px;
  margin-right: 16px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.section-title {
  margin: 0;
  font-size: 24px;
  color: #1a1a1a;
  font-weight: 600;
}

.section-body {
  color: #4a4a4a;
  line-height: 1.8;
  font-size: 16px;
}

/* Typography for HTML content */
.section-body :deep(p) {
  margin-bottom: 1em;
}

.section-body :deep(ul), .section-body :deep(ol) {
  padding-left: 20px;
  margin-bottom: 1em;
}

.section-body :deep(li) {
  margin-bottom: 0.5em;
}

.section-body :deep(img) {
  max-width: 100%;
  border-radius: 8px;
  margin: 16px 0;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.section-footer {
  margin-top: 32px;
  text-align: right;
}

.read-mark {
  font-size: 12px;
  color: #ccc;
  letter-spacing: 1px;
  text-transform: uppercase;
}

/* Loading & Empty States */
.loading-state, .empty-state {
  text-align: center;
  padding: 80px 0;
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.05);
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid #b8860b; /* 金色加载条 */
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

.empty-img {
  font-size: 48px;
  margin-bottom: 16px;
}

/* Footer */
.page-footer {
  text-align: center;
  padding: 40px 0;
  color: #999;
  font-size: 14px;
}

/* Animations */
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

@keyframes fadeInDown {
  from { opacity: 0; transform: translateY(-20px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Responsive */
@media (max-width: 768px) {
  .hero-header {
    height: 280px;
  }
  
  .main-title {
    font-size: 32px;
  }
  
  .content-layout {
    flex-direction: column;
  }
  
  .side-nav {
    display: none; /* Hide sidebar on mobile */
  }
  
  .culture-section {
    padding: 24px;
  }
}
</style>

