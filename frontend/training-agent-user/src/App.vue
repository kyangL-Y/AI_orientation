<template>
  <div id="app" :style="appStyle">
    <HeaderBar v-if="showGlobalHeader" />
    <!-- 使用keep-alive缓存页面，避免返回时重新刷新 -->
    <router-view v-slot="{ Component }">
      <keep-alive :include="cachedViews">
        <component :is="Component" />
      </keep-alive>
    </router-view>
    <CompleteProfileModal
      :show="showForcedCompleteProfile"
      :can-close="false"
      @success="handleProfileCompleted"
    />
    <GuideTourOverlay />
  </div>
</template>

<script>
import logger from '@/utils/logger';
import HeaderBar from '@/components/HeaderBar.vue'
import GuideTourOverlay from '@/components/GuideTourOverlay.vue'
import CompleteProfileModal from '@/components/modals/CompleteProfileModal.vue'
import { useGuideTour } from '@/composables/useGuideTour'
import { getUserInfo as fetchCurrentUserInfo } from '@/api/auth'
import { getMyCustomization, getDefaultCustomization } from '@/api/customization'
import {
  clearTenantContext,
  getStoredTenantCustomization,
  getTenantId,
  hasBrandingPayload,
  setTenantCustomization,
  syncTenantContextFromUser
} from '@/utils/tenantContext'
import { getUserInfo as getStoredUserInfo, setUserInfo as persistUserInfo } from '@/utils/userStorage'

export default {
  name: 'App',
  components: {
    HeaderBar,
    GuideTourOverlay,
    CompleteProfileModal
  },
  data() {
    return {
      // 需要缓存的页面组件名称
      cachedViews: [
        'Study',           // 学习推荐页面
        'CategoryCourses', // 分类课程页面
        'PersonalCenter',  // 个人中心
        'OnlineTest',      // 在线刷题
        'AIinterview',     // AI指导
        'RankingOptimized',// 学习排名
        'AnswerRecordPage', // 答题记录
        'HotelShowcase',   // 酒店介绍
        'LearningPaths',   // 学习路径
      ],
      // 租户个性化配置
      customization: null,
      showForcedCompleteProfile: false
    }
  },
  computed: {
    showGlobalHeader() {
      const hiddenRouteNames = new Set([
        'RegisterEntry',
        'KnowledgeCreate',
        'KnowledgeEdit',
        'ExamStart'
      ])
      return !hiddenRouteNames.has(this.$route?.name)
    },
    appStyle() {
      const style = {
        '--app-header-height-mobile': '64px',
        '--app-header-height-desktop': '80px',
        '--app-header-height': '80px',
        '--app-sticky-offset': '92px'
      }
      if (this.customization?.themeColor) {
        style['--primary-color'] = this.customization.themeColor
        style['--theme-color'] = this.customization.themeColor
      }
      return style
    }
  },
  mounted() {
    this.hydrateCustomizationFromCache()
    this.loadCustomization()
    this.syncProfileCompletionGate()
    useGuideTour().maybeAutoStart()
    // 监听登录事件，重新加载配置
    window.addEventListener('userLogin', this.loadCustomization)
    window.addEventListener('userLogout', this.clearCustomization)
    window.addEventListener('userLogin', this.handleGuideIdentityChange)
    window.addEventListener('userLogout', this.handleGuideIdentityChange)
    window.addEventListener('userLogin', this.handleAuthStateChange)
    window.addEventListener('userLogout', this.handleAuthStateChange)
    window.addEventListener('userProfileRefreshRequired', this.handleAuthStateChange)
  },
  beforeUnmount() {
    window.removeEventListener('userLogin', this.loadCustomization)
    window.removeEventListener('userLogout', this.clearCustomization)
    window.removeEventListener('userLogin', this.handleGuideIdentityChange)
    window.removeEventListener('userLogout', this.handleGuideIdentityChange)
    window.removeEventListener('userLogin', this.handleAuthStateChange)
    window.removeEventListener('userLogout', this.handleAuthStateChange)
    window.removeEventListener('userProfileRefreshRequired', this.handleAuthStateChange)
  },
  methods: {
    hydrateCustomizationFromCache() {
      const cachedCustomization = getStoredTenantCustomization()
      if (!cachedCustomization) return

      this.customization = cachedCustomization
      this.applyCustomization()
    },
    async loadCustomization() {
      const token = localStorage.getItem('authToken')
      const tenantId = getTenantId()
      
      try {
        let res
        let configType
        if (token) {
          // 已登录：获取用户所属租户的配置
          res = await getMyCustomization()
          configType = '租户'
        } else {
          // 未登录：获取默认配置
          res = await getDefaultCustomization(tenantId || undefined)
          configType = '默认'
        }
        logger.debug('📡 请求' + configType + '配置，响应:', res)
        if (res.data?.code === 200 && res.data?.data) {
          const nextCustomization = setTenantCustomization(res.data.data, { tenantId })
          if (!nextCustomization) return

          if (!hasBrandingPayload(nextCustomization)) {
            const cachedCustomization = getStoredTenantCustomization()
            if (cachedCustomization) {
              this.customization = cachedCustomization
              this.applyCustomization()
              return
            }
          }

          this.customization = nextCustomization
          this.applyCustomization()
          logger.debug('✅ ' + configType + '配置已加载:', this.customization)
          logger.debug('📄 页面标题:', this.customization.pageTitle)
        }
      } catch (error) {
        logger.warn('加载配置失败:', error)
        this.hydrateCustomizationFromCache()
      }
    },
    clearCustomization() {
      this.customization = null
      clearTenantContext()
      this.removeCustomStyles()
    },
    async handleGuideIdentityChange() {
      await this.$nextTick()
      await useGuideTour().handleIdentityChange()
    },
    async handleAuthStateChange(event) {
      await this.syncProfileCompletionGate(event?.detail || null)
    },
    async hydrateCurrentUserProfile() {
      try {
        const response = await fetchCurrentUserInfo()
        if (response?.data?.code === 200) {
          const userInfo = response.data.user || response.data.data || null
          if (userInfo) {
            const mergedUserInfo = {
              ...userInfo,
              profileCompletion: response.data.profileCompletion || userInfo.profileCompletion || null
            }
            persistUserInfo(mergedUserInfo)
            syncTenantContextFromUser(mergedUserInfo)
            return mergedUserInfo
          }
        }
      } catch (error) {
        logger.warn('补全资料校验时获取用户信息失败:', error)
      }
      return getStoredUserInfo()
    },
    extractProfileCompletion(userInfo) {
      if (!userInfo || typeof userInfo !== 'object') {
        return null
      }
      return userInfo.profileCompletion && typeof userInfo.profileCompletion === 'object'
        ? userInfo.profileCompletion
        : null
    },
    isUserProfileComplete(userInfo) {
      if (!userInfo || typeof userInfo !== 'object') {
        return false
      }

      const profileCompletion = this.extractProfileCompletion(userInfo)
      if (profileCompletion) {
        if (typeof profileCompletion.completed === 'boolean') {
          return profileCompletion.completed
        }
        if (typeof profileCompletion.needsProfileCompletion === 'boolean') {
          return !profileCompletion.needsProfileCompletion
        }
      }

      const displayName = userInfo.nickName || userInfo.nickname || userInfo.userName || userInfo.username || ''
      const hasContact = !!((userInfo.phonenumber || userInfo.phoneNumber || '').trim() || (userInfo.email || '').trim())
      return !!(String(displayName).trim() && userInfo.deptId && hasContact)
    },
    async syncProfileCompletionGate(userInfo = null) {
      const token = localStorage.getItem('authToken')
      if (!token) {
        this.showForcedCompleteProfile = false
        return
      }

      let resolvedUserInfo = userInfo || getStoredUserInfo()
      if (!resolvedUserInfo) {
        resolvedUserInfo = await this.hydrateCurrentUserProfile()
      } else if (resolvedUserInfo.authHydrationPending) {
        resolvedUserInfo = await this.hydrateCurrentUserProfile()
      }

      this.showForcedCompleteProfile = !this.isUserProfileComplete(resolvedUserInfo)
    },
    async handleProfileCompleted() {
      await this.syncProfileCompletionGate()
    },
    applyCustomization() {
      if (!this.customization) return
      
      const { themeColor, logoUrl, companyName, welcomeMessage, customCss, pageTitle } = this.customization
      
      // 设置页面标题
      if (pageTitle) {
        document.title = pageTitle
      }
      
      // 应用主题色到CSS变量
      if (themeColor) {
        document.documentElement.style.setProperty('--primary-color', themeColor)
        document.documentElement.style.setProperty('--el-color-primary', themeColor)
        // 生成主题色的浅色变体
        document.documentElement.style.setProperty('--primary-light', themeColor + '20')
      }
      
      // 应用自定义CSS
      if (customCss) {
        let styleEl = document.getElementById('tenant-custom-css')
        if (!styleEl) {
          styleEl = document.createElement('style')
          styleEl.id = 'tenant-custom-css'
          document.head.appendChild(styleEl)
        }
        styleEl.textContent = customCss
      }
      
      // 触发全局事件，通知其他组件配置已更新
      window.dispatchEvent(new CustomEvent('customizationLoaded', { 
        detail: this.customization 
      }))
    },
    removeCustomStyles() {
      const styleEl = document.getElementById('tenant-custom-css')
      if (styleEl) styleEl.remove()
      document.documentElement.style.removeProperty('--primary-color')
      document.documentElement.style.removeProperty('--el-color-primary')
      document.documentElement.style.removeProperty('--primary-light')
    }
  }
};
</script>

<style>
/* 确保app填满整个屏幕 */
html, body, #app {
  height: 100%;
  margin: 0;
  padding: 0;
  background-color: #f9fafb; /* 统一背景色，防止白边 */
}

/* 主题色CSS变量 */
:root {
  --primary-color: #3b82f6;
  --theme-color: #3b82f6;
  --primary-light: rgba(59, 130, 246, 0.1);
}

#app {
  --app-header-height-mobile: 64px;
  --app-header-height-desktop: 80px;
  --app-header-height: var(--app-header-height-desktop);
  --app-sticky-offset: 92px;
}

.knowledge-page .page-container {
  padding-top: var(--app-header-height) !important;
}

.knowledge-page .left-sidebar,
.knowledge-page .right-sidebar {
  top: var(--app-sticky-offset) !important;
}

/* ========== 全局移动端优化 ========== */
@media (max-width: 768px) {
  #app {
    --app-header-height: var(--app-header-height-mobile);
    --app-sticky-offset: calc(var(--app-header-height-mobile) + 12px);
  }

  [class*="h-[56px]"],
  [class*="h-[60px]"],
  [class*="h-[64px]"],
  [class*="h-[72px]"] {
    height: var(--app-header-height) !important;
    min-height: var(--app-header-height) !important;
  }

  /* 容器内边距优化 */
  .container {
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
  }
  
  /* 卡片间距优化 */
  .space-y-8 > * + * {
    margin-top: 1rem !important;
  }
  
  .space-y-6 > * + * {
    margin-top: 0.75rem !important;
  }
  
  .gap-8 {
    gap: 1rem !important;
  }
  
  .gap-6 {
    gap: 0.75rem !important;
  }
  
  /* 卡片内边距优化 */
  .p-8 {
    padding: 1rem !important;
  }
  
  .p-6 {
    padding: 0.75rem !important;
  }
  
  .px-8 {
    padding-left: 1rem !important;
    padding-right: 1rem !important;
  }
  
  .py-8 {
    padding-top: 1rem !important;
    padding-bottom: 1rem !important;
  }
  
  .px-6 {
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
  }
  
  .py-6 {
    padding-top: 0.75rem !important;
    padding-bottom: 0.75rem !important;
  }
  
  /* 标题字体优化 */
  .text-3xl {
    font-size: 1.5rem !important;
    line-height: 2rem !important;
  }
  
  .text-2xl {
    font-size: 1.25rem !important;
    line-height: 1.75rem !important;
  }
  
  .text-xl {
    font-size: 1.125rem !important;
    line-height: 1.75rem !important;
  }
  
  .text-lg {
    font-size: 1rem !important;
    line-height: 1.5rem !important;
  }
  
  /* 圆角优化 */
  .rounded-3xl {
    border-radius: 1rem !important;
  }
  
  .rounded-2xl {
    border-radius: 0.75rem !important;
  }
  
  /* 按钮优化 */
  button, .btn {
    min-height: 2.5rem;
    padding: 0.5rem 1rem !important;
    font-size: 0.875rem !important;
  }
  
  /* 输入框优化 */
  input, textarea, select {
    font-size: 1rem !important; /* 防止iOS自动缩放 */
  }
  
  /* 模态框优化 */
  .el-dialog {
    width: 90% !important;
    margin: 5vh auto !important;
  }
  
  .el-dialog__body {
    padding: 1rem !important;
  }
  
  /* 表格优化 */
  .el-table {
    font-size: 0.75rem !important;
  }
  
  .el-table th,
  .el-table td {
    padding: 0.5rem !important;
  }
  
  /* 网格布局优化 */
  .grid-cols-2 {
    grid-template-columns: repeat(1, minmax(0, 1fr)) !important;
  }
  
  .grid-cols-3 {
    grid-template-columns: repeat(1, minmax(0, 1fr)) !important;
  }
  
  .grid-cols-4 {
    grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
  }
  
  /* 隐藏移动端不必要的元素 */
  .hidden-mobile {
    display: none !important;
  }
  
  /* 移动端显示 */
  .show-mobile {
    display: block !important;
  }
  
  /* 滚动条优化 */
  ::-webkit-scrollbar {
    width: 4px;
    height: 4px;
  }
  
  ::-webkit-scrollbar-thumb {
    background-color: rgba(0, 0, 0, 0.2);
    border-radius: 4px;
  }
  
  /* 触摸反馈优化 */
  button:active,
  .clickable:active {
    transform: scale(0.98);
    transition: transform 0.1s;
  }
  
  /* 防止文本选择（提升触摸体验） */
  .no-select {
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }
  
  /* 图片优化 */
  img {
    max-width: 100%;
    height: auto;
  }
  
  /* 视频优化 */
  video {
    max-width: 100%;
    height: auto;
  }
  
  /* 固定定位元素优化 */
  .fixed {
    position: fixed;
  }
  
  /* 粘性定位优化 */
  .sticky {
    position: sticky;
  }

  .knowledge-page .page-container {
    padding-top: calc(var(--app-header-height) + 8px) !important;
    padding-left: 12px !important;
    padding-right: 12px !important;
    padding-bottom: 20px !important;
  }

  .knowledge-page .feed-header-banner,
  .knowledge-page .filter-tabs-wrapper,
  .knowledge-page .article-card,
  .knowledge-page .sidebar-card,
  .knowledge-page .nav-menu,
  .knowledge-page .topic-box {
    border-radius: 12px !important;
  }
  
  /* 阴影优化（移动端减少阴影） */
  .shadow-2xl {
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1) !important;
  }
  
  .shadow-xl {
    box-shadow: 0 10px 20px -5px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1) !important;
  }
  
  .shadow-lg {
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1) !important;
  }
}

/* ========== 超小屏幕优化 (< 375px) ========== */
@media (max-width: 375px) {
  #app {
    --app-header-height-mobile: 60px;
    --app-header-height: var(--app-header-height-mobile);
    --app-sticky-offset: calc(var(--app-header-height-mobile) + 10px);
  }

  .container {
    padding-left: 0.5rem !important;
    padding-right: 0.5rem !important;
  }
  
  .text-3xl {
    font-size: 1.25rem !important;
  }
  
  .text-2xl {
    font-size: 1.125rem !important;
  }
  
  .text-xl {
    font-size: 1rem !important;
  }
  
  .p-6, .p-8 {
    padding: 0.5rem !important;
  }
}
</style>

