<template>
  <header v-if="isPrimaryHeader" class="header">
    <div class="header-left">
      <img :src="currentLogo" alt="Logo" class="logo-img" />
      <span class="company-name">{{ companyName }}</span>
    </div>

    <!-- 桌面端导航 -->
    <nav class="nav desktop-nav">
      <!-- 岗位培训中心 -->
      <div class="nav-dropdown" @mouseenter="openDropdown('training')" @mouseleave="closeDropdown('training')">
        <span class="nav-dropdown-trigger" :class="{ active: isTrainingActive }">
          岗位培训中心 <i class="fas fa-angle-down"></i>
        </span>
        <div class="nav-dropdown-menu" v-show="dropdowns.training">
          <router-link to="/study" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fa fa-star"></i> OTA特训营
          </router-link>
          <router-link to="/department-training" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-users"></i> 技能工坊
          </router-link>
          <router-link to="/green-hotel" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-leaf"></i> 绿色饭店
          </router-link>
        </div>
      </div>
      
      <!-- 刷题&PK -->
      <div class="nav-dropdown" @mouseenter="openDropdown('practice')" @mouseleave="closeDropdown('practice')">
        <span class="nav-dropdown-trigger" data-guide="practice-nav-trigger" :class="{ active: isPracticeActive }">
          刷题&amp;PK <i class="fas fa-angle-down"></i>
        </span>
        <div class="nav-dropdown-menu" v-show="dropdowns.practice">
          <router-link to="/online" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-pencil-alt"></i> 在线刷题
          </router-link>
          <router-link to="/online-exam" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-file-alt"></i> 在线考试
          </router-link>
          <router-link to="/ranking" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-trophy"></i> 学习排名
          </router-link>
          <router-link to="/answer-record" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-history"></i> 答题记录
          </router-link>
          <router-link to="/learning-plans" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-road"></i> 学习路径
          </router-link>
        </div>
      </div>
      
      <!-- AI学习助手 -->
      <router-link to="/AI" class="nav-link" :class="{ active: route.path === '/AI' }">
        <i class="fas fa-robot"></i> AI学习助手
      </router-link>

      <!-- 智囊阁 -->
      <div class="nav-dropdown" @mouseenter="openDropdown('knowledge')" @mouseleave="closeDropdown('knowledge')">
        <span class="nav-dropdown-trigger" :class="{ active: isKnowledgeActive }">
          智囊阁 <i class="fas fa-angle-down"></i>
        </span>
        <div class="nav-dropdown-menu" v-show="dropdowns.knowledge">
          <router-link to="/knowledge" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-book"></i> 知识广场
          </router-link>
          <router-link to="/knowledge/my" class="dropdown-item" @click="closeAllDropdowns">
            <i class="far fa-file-alt"></i> 我的文章
          </router-link>
          <router-link to="/knowledge/favorites" class="dropdown-item" @click="closeAllDropdowns">
            <i class="far fa-star"></i> 我的收藏
          </router-link>
          <router-link to="/knowledge/edit" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-edit"></i> 发布文章
          </router-link>
        </div>
      </div>
      
      <!-- 酒店文化 -->
      <div class="nav-dropdown" @mouseenter="openDropdown('culture')" @mouseleave="closeDropdown('culture')">
        <span class="nav-dropdown-trigger" :class="{ active: isCultureActive }">
          酒店文化 <i class="fas fa-angle-down"></i>
        </span>
        <div class="nav-dropdown-menu" v-show="dropdowns.culture">
          <router-link to="/hotel" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-building"></i> 酒店介绍
          </router-link>
          <router-link to="/corporate-culture" class="dropdown-item" @click="closeAllDropdowns">
            <i class="fas fa-university"></i> 企业文化
          </router-link>
          <router-link v-if="canViewHotelCultureDocuments" to="/hotel-culture/documents" class="dropdown-item" @click="closeAllDropdowns">
            <i class="far fa-file-pdf"></i> 员工手册与制度
          </router-link>
        </div>
      </div>
      
      <span class="spacer"></span>
      
      <!-- 通知公告 -->
      <div v-if="isLoggedIn" class="notification-wrapper">
        <button class="notification-btn" @click="toggleNotification" :class="{ 'has-unread': hasUnreadNotice }">
          <i class="fas fa-bell"></i>
          <span v-if="hasUnreadNotice" class="notification-badge"></span>
        </button>
        <teleport to="body">
          <div v-if="showNotification" class="notification-panel" :style="notificationPanelStyle" @click.stop>
            <div class="notification-header">
              <h3>系统公告</h3>
              <button class="close-btn" @click="showNotification = false">
                <i class="fas fa-times"></i>
              </button>
            </div>
            <div class="notification-content">
              <div v-if="notices.length === 0" class="no-notice">
                <i class="fas fa-inbox"></i>
                <p>暂无公告</p>
              </div>
              <div v-else class="notice-list">
                <div v-for="notice in notices" :key="notice.noticeId" class="notice-item" @click="viewNotice(notice)">
                  <div class="notice-icon">
                    <i :class="getNoticeIcon(notice.noticeType)"></i>
                  </div>
                  <div class="notice-info">
                    <div class="notice-title">{{ notice.noticeTitle }}</div>
                    <div class="notice-time">{{ formatTime(notice.createTime) }}</div>
                  </div>
                  <span v-if="!readNoticeIds.has(notice.noticeId)" class="unread-dot"></span>
                </div>
              </div>
            </div>
          </div>
        </teleport>
      </div>
      
      <!-- 未登录状态 -->
      <template v-if="!isLoggedIn">
        <a href="#login" class="action-btn login-btn" @click.prevent="handleLoginClick">
          <i class="fas fa-user-circle"></i>
          <span>登录</span>
        </a>
      </template>
      
      <!-- 已登录状态 -->
      <template v-else>
        <div class="user-info">
          <div class="user-dropdown" @click="toggleUserMenu">
            <span class="username-text">{{ getUserDisplayName() }}</span>
            <button class="user-avatar">
              <i class="fas fa-user-circle"></i>
            </button>
            <teleport to="body">
              <div v-if="showUserMenu" class="dropdown-menu user-menu" :style="userMenuStyle" @click.stop>
                <router-link to="/personal" class="dropdown-item" @click="showUserMenu = false">
                  <i class="fas fa-user"></i> 个人中心
                </router-link>
                <router-link to="/member-center" class="dropdown-item" @click="showUserMenu = false">
                  <i class="fas fa-crown text-yellow-500"></i> 会员中心
                </router-link>
                <router-link to="/mall" class="dropdown-item" @click="showUserMenu = false">
                  <i class="fas fa-gift text-indigo-500"></i> 积分商城
                </router-link>
                <div class="dropdown-item" @click="openGuidePanel">
                  <i class="fas fa-circle-question"></i> 新手引导
                </div>
                <div class="dropdown-item" @click="handleSwitchAccount">
                  <i class="fas fa-exchange-alt"></i> 切换账户
                </div>
                <a
                  v-if="canAccessAdmin"
                  :href="adminUrl"
                  target="_blank"
                  rel="noopener"
                  class="dropdown-item"
                  @click="showUserMenu = false"
                >
                  <i class="fas fa-cog"></i> 管理端
                </a>
                <div class="dropdown-item" @click="handleLogout">
                  <i class="fas fa-sign-out-alt"></i> 退出登录
                </div>
              </div>
            </teleport>
          </div>
        </div>
      </template>
    </nav>

    <div class="header-utility-actions">
      <GuideHelpEntry />
      <button class="mobile-menu-btn" @click="toggleMobileMenu" :class="{ active: showMobileMenu }">
        <span></span>
        <span></span>
        <span></span>
      </button>
    </div>
    
    <!-- 移动端导航菜单 -->
    <div class="mobile-nav" :class="{ active: showMobileMenu }">
      <div class="mobile-nav-content">
        <!-- 岗位培训中心 -->
        <div class="mobile-nav-group">
          <div class="mobile-nav-title" @click="toggleMobileGroup('training')">
            <span>岗位培训中心</span>
            <i class="fa" :class="mobileGroups.training ? 'fa-angle-up' : 'fa-angle-down'"></i>
          </div>
          <div class="mobile-nav-items" v-show="mobileGroups.training">
            <router-link to="/study" @click="closeMobileMenu">OTA特训营</router-link>
            <router-link to="/department-training" @click="closeMobileMenu">技能工坊</router-link>
            <router-link to="/green-hotel" @click="closeMobileMenu">绿色饭店</router-link>
          </div>
        </div>
        
        <!-- 刷题&PK -->
        <div class="mobile-nav-group">
          <div class="mobile-nav-title" data-guide="practice-nav-trigger" @click="toggleMobileGroup('practice')">
            <span>刷题&amp;PK</span>
            <i class="fa" :class="mobileGroups.practice ? 'fa-angle-up' : 'fa-angle-down'"></i>
          </div>
          <div class="mobile-nav-items" v-show="mobileGroups.practice">
            <router-link to="/online" @click="closeMobileMenu">在线刷题</router-link>
            <router-link to="/online-exam" @click="closeMobileMenu">在线考试</router-link>
            <router-link to="/ranking" @click="closeMobileMenu">学习排名</router-link>
            <router-link to="/answer-record" @click="closeMobileMenu">答题记录</router-link>
            <router-link to="/learning-plans" @click="closeMobileMenu">学习路径</router-link>
          </div>
        </div>
        
        <!-- AI学习助手 -->
        <router-link to="/AI" class="mobile-nav-link" @click="closeMobileMenu">
          <i class="fas fa-robot"></i> AI学习助手
        </router-link>

        <!-- 会员中心 -->
        <router-link to="/member-center" class="mobile-nav-link" @click="closeMobileMenu">
          <i class="fas fa-crown text-yellow-500"></i> 会员中心
        </router-link>
        
        <!-- 智囊阁 -->
        <div class="mobile-nav-group">
          <div class="mobile-nav-title" @click="toggleMobileGroup('knowledge')">
            <span>智囊阁</span>
            <i class="fa" :class="mobileGroups.knowledge ? 'fa-angle-up' : 'fa-angle-down'"></i>
          </div>
          <div class="mobile-nav-items" v-show="mobileGroups.knowledge">
            <router-link to="/knowledge" @click="closeMobileMenu">知识广场</router-link>
            <router-link to="/knowledge/my" @click="closeMobileMenu">我的文章</router-link>
            <router-link to="/knowledge/favorites" @click="closeMobileMenu">我的收藏</router-link>
            <router-link to="/knowledge/edit" @click="closeMobileMenu">发布文章</router-link>
          </div>
        </div>
        
        <!-- 酒店文化 -->
        <div class="mobile-nav-group">
          <div class="mobile-nav-title" @click="toggleMobileGroup('culture')">
            <span>酒店文化</span>
            <i class="fa" :class="mobileGroups.culture ? 'fa-angle-up' : 'fa-angle-down'"></i>
          </div>
          <div class="mobile-nav-items" v-show="mobileGroups.culture">
            <router-link to="/hotel" @click="closeMobileMenu">酒店介绍</router-link>
            <router-link to="/corporate-culture" @click="closeMobileMenu">企业文化</router-link>
            <router-link v-if="canViewHotelCultureDocuments" to="/hotel-culture/documents" @click="closeMobileMenu">员工手册与制度</router-link>
          </div>
        </div>
        
        <!-- 我的 -->
        <div class="mobile-nav-group">
          <div class="mobile-nav-title" @click="toggleMobileGroup('mine')">
            <span>我的</span>
            <i class="fa" :class="mobileGroups.mine ? 'fa-angle-up' : 'fa-angle-down'"></i>
          </div>
          <div class="mobile-nav-items" v-show="mobileGroups.mine">
            <router-link to="/personal" @click="closeMobileMenu">个人中心</router-link>
            <router-link to="/mall" @click="closeMobileMenu">积分商城</router-link>
          </div>
        </div>
        
        <div class="mobile-nav-divider"></div>
        
        <a v-if="canAccessAdmin" :href="adminUrl" target="_blank" rel="noopener" class="mobile-admin-btn" @click="closeMobileMenu">
          <i class="fas fa-cog"></i> 管理端
        </a>
        
        <template v-if="!isLoggedIn">
          <a href="#login" class="mobile-login-btn" @click.prevent="handleMobileLogin">
            <i class="fas fa-user-circle"></i> 登录
          </a>
        </template>
        
        <template v-else>
          <div class="mobile-user-info">
            <div class="mobile-user-avatar">
              <i class="fas fa-user-circle"></i>
            </div>
            <div class="mobile-user-details">
              <div class="mobile-username">{{ getUserDisplayName() }}</div>
              <div class="mobile-user-actions">
                <a href="#" @click.prevent="openGuidePanel">新手引导</a>
                <span>·</span>
                <a href="#" @click.prevent="handleLogout">退出登录</a>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>
    
    <!-- 移动端菜单遮罩 -->
    <div class="mobile-menu-overlay" :class="{ active: showMobileMenu }" @click="closeMobileMenu"></div>
  </header>
  
  <LoginModal :show="showLogin" @close="showLogin = false" @to-register="handleToRegister" />
  <RegisterModal :show="showRegister" :initialType="registerInitialType" @close="showRegister = false" @to-login="handleToLogin" />
  <!-- 公告详情弹窗 -->
  <teleport to="body">
    <div v-if="showNoticeDetail && selectedNotice" class="notice-modal-overlay" @click="showNoticeDetail = false">
      <div class="notice-modal" @click.stop>
        <div class="notice-modal-header">
          <h3>{{ selectedNotice.noticeTitle }}</h3>
          <button class="close-btn" @click="showNoticeDetail = false">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="notice-modal-body" v-html="safeNoticeContent"></div>
        <div class="notice-modal-footer">
          <span class="notice-time">发布时间：{{ selectedNotice.createTime }}</span>
        </div>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import logger from '@/utils/logger';
import { onMounted, onUnmounted, ref, reactive, computed, nextTick, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import GuideHelpEntry from './GuideHelpEntry.vue'
import LoginModal from './modals/LoginModal.vue'
import RegisterModal from './modals/RegisterModal.vue'
import { getUserInfo } from '@/api/auth'
import { getHotelCultureDocumentAccess } from '@/api/hotelCultureDocuments'
import { getPublicNoticeList } from '@/api/notice'
import { sanitizeHtml } from '@/utils/security'
import {
  clearTenantContext,
  getStoredTenantCustomization,
  syncTenantContextFromUser
} from '@/utils/tenantContext'

const route = useRoute()
const HEADER_PRIMARY_KEY = '__training_user_primary_header__'
const headerInstanceId = `header-${Date.now()}-${Math.random().toString(36).slice(2)}`
const isPrimaryHeader = ref(false)
const showLogin = ref(false)
const showRegister = ref(false)
const showUserMenu = ref(false)
const showMobileMenu = ref(false)
const userInfo = ref(null)
const isLoggedIn = computed(() => !!userInfo.value)
const canViewHotelCultureDocuments = ref(false)
const userMenuStyle = ref({})
const registerInitialType = ref('email')

// 下拉菜单状态
const dropdowns = reactive({
  training: false,
  practice: false,
  knowledge: false,
  culture: false,
  mine: false
})

// 移动端分组展开状态
const mobileGroups = reactive({
  training: true,
  practice: false,
  knowledge: false,
  culture: false,
  mine: false
})

// 判断当前路由是否在某个分组内
const isTrainingActive = computed(() => ['/study', '/department-training', '/green-hotel'].includes(route.path))
const isPracticeActive = computed(() => ['/online', '/online-exam', '/ranking', '/answer-record', '/learning-plans'].includes(route.path))
const isKnowledgeActive = computed(() => route.path.startsWith('/knowledge'))
const isCultureActive = computed(() => ['/hotel', '/corporate-culture', '/hotel-culture/documents'].includes(route.path))
const canAccessAdmin = computed(() => {
  const roles = Array.isArray(userInfo.value?.roles) ? userInfo.value.roles : []
  const roleKeys = roles.map((role) => {
    if (typeof role === 'string') return role
    return role?.roleKey || ''
  })
  return Boolean(userInfo.value?.canAccessAdmin) || roleKeys.some((roleKey) =>
    ['admin', 'platform', 'company_admin', 'tenant_admin'].includes(roleKey)
  )
})

// 下拉菜单控制
const openDropdown = (name) => { dropdowns[name] = true }
const closeDropdown = (name) => { dropdowns[name] = false }
const closeAllDropdowns = () => {
  Object.keys(dropdowns).forEach(k => dropdowns[k] = false)
}

// 移动端分组切换
const toggleMobileGroup = (name) => {
  mobileGroups[name] = !mobileGroups[name]
}

// 通知公告相关
const showNotification = ref(false)
const notices = ref([])
const notificationPanelStyle = ref({})
const readNoticeIds = ref(new Set())
const showNoticeDetail = ref(false)
const selectedNotice = ref(null)
const safeNoticeContent = computed(() => sanitizeHtml(selectedNotice.value?.noticeContent || '暂无内容'))

const hasUnreadNotice = computed(() => notices.value.some(n => !readNoticeIds.value.has(n.noticeId)))

const loadNotices = async () => {
  try {
    let tenantId = null, deptId = null, companyId = null
    const storedUserInfo = localStorage.getItem('userInfo')
    if (storedUserInfo) {
      try {
        const parsed = JSON.parse(storedUserInfo)
        tenantId = parsed.tenantId
        deptId = parsed.deptId
        if (parsed.dept && parsed.dept.parentId) companyId = parsed.dept.parentId
      } catch (e) {}
    }
    const response = await getPublicNoticeList(tenantId, deptId, companyId)
    if (response.data && response.data.code === 200) {
      notices.value = response.data.data || []
    }
  } catch (error) {
    logger.warn('加载公告失败:', error)
  }
}

const toggleNotification = (event) => {
  if (!showNotification.value) {
    const btn = event.currentTarget
    const rect = btn.getBoundingClientRect()
    notificationPanelStyle.value = {
      position: 'fixed',
      top: (rect.bottom + 8) + 'px',
      right: (window.innerWidth - rect.right) + 'px',
      zIndex: 99999
    }
  }
  showNotification.value = !showNotification.value
}

const viewNotice = (notice) => {
  readNoticeIds.value.add(notice.noticeId)
  localStorage.setItem('readNoticeIds', JSON.stringify([...readNoticeIds.value]))
  selectedNotice.value = notice
  showNoticeDetail.value = true
}

const getNoticeIcon = (type) => type === '1' ? 'fas fa-bell text-blue-500' : 'fas fa-bullhorn text-orange-500'

const formatTime = (time) => {
  if (!time) return ''
  const date = new Date(time)
  const now = new Date()
  const diff = now - date
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))
  if (days === 0) return '今天'
  if (days === 1) return '昨天'
  if (days < 7) return `${days}天前`
  return `${date.getMonth() + 1}/${date.getDate()}`
}

const loadReadStatus = () => {
  try {
    const stored = localStorage.getItem('readNoticeIds')
    if (stored) readNoticeIds.value = new Set(JSON.parse(stored))
  } catch (e) {}
}

// Logo和公司名
const defaultLogo = `/favicon1.png?t=${Date.now()}`
const defaultCompanyName = '华智酒店及度假村'
const customization = ref(null)
const currentLogo = computed(() => customization.value?.logoUrl || defaultLogo)
const companyName = computed(() => customization.value?.companyName || defaultCompanyName)

const loadCustomization = () => {
  customization.value = getStoredTenantCustomization()
}

const refreshHotelCultureDocumentAccess = async () => {
  canViewHotelCultureDocuments.value = false
  if (!localStorage.getItem('authToken')) {
    return
  }
  try {
    const response = await getHotelCultureDocumentAccess()
    canViewHotelCultureDocuments.value = response.data?.data?.visible === true
  } catch (error) {
    canViewHotelCultureDocuments.value = false
  }
}

const handleCustomizationLoaded = (event) => { customization.value = event.detail }

const adminUrl = (typeof window !== 'undefined' && window.__ADMIN_URL__) || `${import.meta.env.BASE_URL}admin/`

const handleToRegister = (type = 'email') => {
  registerInitialType.value = type
  showLogin.value = false
  showRegister.value = true
}

const handleToLogin = () => {
  showRegister.value = false
  showLogin.value = true
}

const handleLoginClick = () => { showLogin.value = true }

const toggleMobileMenu = () => { showMobileMenu.value = !showMobileMenu.value }
const closeMobileMenu = () => { showMobileMenu.value = false }
const handleMobileLogin = () => { closeMobileMenu(); showLogin.value = true }

const loadUserInfo = async () => {
  try {
    const token = localStorage.getItem('authToken')
    if (token) {
      const storedUserInfo = localStorage.getItem('userInfo')
      if (storedUserInfo && storedUserInfo !== 'userInfo' && storedUserInfo.trim() !== '') {
        try {
          userInfo.value = JSON.parse(storedUserInfo)
        } catch (e) {
          localStorage.removeItem('userInfo')
        }
      }
      try {
        const response = await getUserInfo()
        if (response.data.code === 200) {
          const apiUserInfo = response.data.user || response.data.data
          if (apiUserInfo && !(apiUserInfo.nickName === '管理员' && apiUserInfo.userName === 'admin' && apiUserInfo.userId === 1)) {
            const cachedProfileCompletion = userInfo.value?.profileCompletion
              || JSON.parse(localStorage.getItem('userInfo') || '{}')?.profileCompletion
              || null
            const mergedUserInfo = {
              ...apiUserInfo,
              profileCompletion: response.data.profileCompletion || apiUserInfo.profileCompletion || cachedProfileCompletion
            }
            userInfo.value = mergedUserInfo
            localStorage.setItem('userInfo', JSON.stringify(mergedUserInfo))
            window.dispatchEvent(new CustomEvent('userLogin', { detail: mergedUserInfo }))
          } else {
            localStorage.removeItem('userInfo')
            localStorage.removeItem('authToken')
            userInfo.value = null
            showLogin.value = true
          }
        } else {
          localStorage.removeItem('userInfo')
          localStorage.removeItem('authToken')
          userInfo.value = null
          showLogin.value = true
        }
      } catch (apiError) {
        const isAuthError = apiError.response?.status === 401 || apiError.response?.status === 403
        if (isAuthError) {
          localStorage.removeItem('userInfo')
          localStorage.removeItem('authToken')
          userInfo.value = null
          showLogin.value = true
        }
      }
      await refreshHotelCultureDocumentAccess()
    }
  } catch (error) {
    logger.error('获取用户信息失败:', error)
  }
}

const handleSwitchAccount = () => {
  if (confirm('确定要切换账户吗？')) {
    clearTenantContext()
    userInfo.value = null
    customization.value = null
    showUserMenu.value = false
    window.dispatchEvent(new CustomEvent('userLogout'))
    showLogin.value = true
  }
}

const handleLogout = () => {
  clearTenantContext()
  userInfo.value = null
  customization.value = null
  canViewHotelCultureDocuments.value = false
  window.dispatchEvent(new CustomEvent('userLogout'))
  window.location.reload()
}

const isValidDisplayName = (name) => {
  if (!name || typeof name !== 'string' || name.trim() === '') return false
  if (/^\d+$/.test(name.trim()) && name.length > 5) return false
  if (['管理员', 'admin', 'null', 'undefined', 'userInfo'].includes(name.toLowerCase().trim())) return false
  return true
}

const getUserDisplayName = () => {
  try {
    if (!userInfo.value) {
      const storedUserInfo = localStorage.getItem('userInfo')
      if (storedUserInfo) {
        try {
          const parsed = JSON.parse(storedUserInfo)
          if (isValidDisplayName(parsed.nickName || parsed.nickname)) return parsed.nickName || parsed.nickname
          if (isValidDisplayName(parsed.userName || parsed.username)) return parsed.userName || parsed.username
          if (parsed.email && parsed.email.includes('@')) return parsed.email.split('@')[0]
        } catch (e) {}
      }
      return '用户'
    }
    const userName = userInfo.value.userName || userInfo.value.username
    if (isValidDisplayName(userName)) return userName
    if (userInfo.value.email && userInfo.value.email.includes('@')) return userInfo.value.email.split('@')[0]
    return '用户'
  } catch (error) {
    return '用户'
  }
}

const toggleUserMenu = (event) => {
  if (!showUserMenu.value) {
    const btn = event.currentTarget
    const rect = btn.getBoundingClientRect()
    userMenuStyle.value = {
      position: 'fixed',
      top: (rect.bottom + 4) + 'px',
      right: (window.innerWidth - rect.right) + 'px',
      zIndex: 99999
    }
  }
  showUserMenu.value = !showUserMenu.value
}

const openGuidePanel = () => {
  showUserMenu.value = false
  closeMobileMenu()
  window.dispatchEvent(new CustomEvent('guide:open-panel'))
}

const handleUserLogin = async (event) => {
  if (event?.detail) {
    syncTenantContextFromUser(event.detail)
    userInfo.value = event.detail
  } else {
    userInfo.value = null
  }
  if (!userInfo.value) {
    const storedUserInfo = localStorage.getItem('userInfo')
    if (storedUserInfo) {
      try { userInfo.value = JSON.parse(storedUserInfo) } catch (e) {}
    }
  }
  loadCustomization()
  await refreshHotelCultureDocumentAccess()
  await loadNotices()
  await nextTick()
}

const handleUserLogout = () => {
  userInfo.value = null
  customization.value = null
  canViewHotelCultureDocuments.value = false
}

const handleClickOutside = (event) => {
  if (!event.target.closest('.user-dropdown')) showUserMenu.value = false
  if (!event.target.closest('.notification-wrapper') && !event.target.closest('.notification-panel')) showNotification.value = false
}

const registerPrimaryHeader = () => {
  if (typeof window === 'undefined') {
    isPrimaryHeader.value = true
    return true
  }
  if (!window[HEADER_PRIMARY_KEY]) {
    window[HEADER_PRIMARY_KEY] = headerInstanceId
    isPrimaryHeader.value = true
    return true
  }
  isPrimaryHeader.value = window[HEADER_PRIMARY_KEY] === headerInstanceId
  return isPrimaryHeader.value
}

watch(() => route.path, () => {
  if (!isPrimaryHeader.value) {
    return
  }
  closeAllDropdowns()
  showUserMenu.value = false
  showNotification.value = false
  showMobileMenu.value = false
})

onMounted(() => {
  if (!registerPrimaryHeader()) {
    return
  }
  loadUserInfo()
  loadCustomization()
  loadReadStatus()
  loadNotices()
  window.addEventListener('userLogin', handleUserLogin)
  window.addEventListener('userLogout', handleUserLogout)
  document.addEventListener('click', handleClickOutside)
  window.addEventListener('showLoginModal', () => { showLogin.value = true })
  window.addEventListener('customizationLoaded', handleCustomizationLoaded)
})

onUnmounted(() => {
  if (typeof window !== 'undefined' && window[HEADER_PRIMARY_KEY] === headerInstanceId) {
    delete window[HEADER_PRIMARY_KEY]
  }
  if (!isPrimaryHeader.value) {
    return
  }
  window.removeEventListener('userLogin', handleUserLogin)
  window.removeEventListener('userLogout', handleUserLogout)
  document.removeEventListener('click', handleClickOutside)
  window.removeEventListener('customizationLoaded', handleCustomizationLoaded)
})
</script>

<style scoped>
.header {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 24px;
  background: rgba(255,255,255,0.95);
  border-bottom: 1px solid #e5e7eb;
  backdrop-filter: blur(12px);
  font-family: 'Noto Sans SC', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'PingFang SC', 'Microsoft YaHei', sans-serif;
  min-height: var(--app-header-height-desktop, 80px);
  box-sizing: border-box;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.header-utility-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logo-img {
  height: 40px;
  width: auto;
  object-fit: contain;
}

.company-name {
  font-size: 1.1rem;
  font-weight: 600;
  color: #333;
  letter-spacing: 0.5px;
}

/* 桌面端导航 */
.nav {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: 32px;
  flex: 1;
  min-width: 0;
}

/* 下拉菜单容器 */
.nav-dropdown {
  position: relative;
}

.nav-dropdown-trigger {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 8px 16px;
  font-size: 0.9rem;
  font-weight: 500;
  color: #444;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s;
  letter-spacing: 0.3px;
}

.nav-dropdown-trigger:hover,
.nav-dropdown-trigger.active {
  color: #2563eb;
  background: rgba(37, 99, 235, 0.08);
}

.nav-dropdown-trigger i {
  font-size: 0.8rem;
  transition: transform 0.2s;
}

.nav-dropdown:hover .nav-dropdown-trigger i {
  transform: rotate(180deg);
}

/* 下拉菜单 */
.nav-dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  min-width: 160px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.12);
  padding: 8px 0;
  z-index: 1000;
  border: 1px solid #e5e7eb;
}

.nav-dropdown-menu .dropdown-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 16px;
  font-size: 0.9rem;
  color: #555;
  text-decoration: none;
  transition: all 0.15s;
}

.nav-dropdown-menu .dropdown-item:hover {
  background: #f3f4f6;
  color: #2563eb;
}

.nav-dropdown-menu .dropdown-item.router-link-exact-active {
  background: #eef5ff;
  color: #2563eb;
}

.nav-dropdown-menu .dropdown-item i {
  width: 16px;
  text-align: center;
  color: #888;
}

.nav-dropdown-menu .dropdown-item:hover i {
  color: #2563eb;
}

.nav-dropdown-menu .dropdown-item.router-link-exact-active i {
  color: #2563eb;
}

/* 直接链接 */
.nav-link {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  font-size: 0.95rem;
  font-weight: 500;
  color: #555;
  text-decoration: none;
  border-radius: 6px;
  transition: all 0.2s;
}

.nav-link:hover,
.nav-link.active {
  color: #2563eb;
  background: rgba(37, 99, 235, 0.08);
}

.spacer {
  flex: 1;
}

/* 操作按钮 */
.action-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  font-size: 0.9rem;
  font-weight: 500;
  border-radius: 6px;
  text-decoration: none;
  transition: all 0.2s;
}

.login-btn {
  color: white;
  background: #2563eb;
}

.login-btn:hover {
  background: #1d4ed8;
}

/* 用户信息 */
.user-info {
  display: flex;
  align-items: center;
}

.user-dropdown {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 6px 12px;
  border-radius: 6px;
  transition: background 0.2s;
}

.user-dropdown:hover {
  background: #f3f4f6;
}

.username-text {
  font-size: 0.9rem;
  color: #333;
  font-weight: 500;
}

.user-avatar {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: #2563eb;
  cursor: pointer;
}

.user-menu {
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.12);
  padding: 8px 0;
  min-width: 140px;
  border: 1px solid #e5e7eb;
}

.user-menu .dropdown-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 16px;
  font-size: 0.9rem;
  color: #555;
  cursor: pointer;
  transition: all 0.15s;
}

.user-menu .dropdown-item:hover {
  background: #f3f4f6;
  color: #2563eb;
}

/* 通知按钮 */
.notification-wrapper {
  position: relative;
  margin-right: 8px;
}

.notification-btn {
  position: relative;
  background: none;
  border: none;
  color: #666;
  font-size: 1.2rem;
  cursor: pointer;
  padding: 8px;
  border-radius: 6px;
  transition: all 0.2s;
}

.notification-btn:hover {
  background: #f3f4f6;
  color: #2563eb;
}

.notification-btn.has-unread {
  color: #2563eb;
}

.notification-badge {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 8px;
  height: 8px;
  background: #ef4444;
  border-radius: 50%;
}

.notification-panel {
  background: white;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.15);
  width: 340px;
  max-width: calc(100vw - 24px);
  max-height: 400px;
  overflow: hidden;
  border: 1px solid #e5e7eb;
}

.notification-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  border-bottom: 1px solid #e5e7eb;
  background: #f8fafc;
}

.notification-header h3 {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 600;
}

.notification-header .close-btn {
  background: none;
  border: none;
  color: #999;
  cursor: pointer;
  padding: 4px;
}

.notification-content {
  max-height: 320px;
  overflow-y: auto;
}

.no-notice {
  padding: 40px 20px;
  text-align: center;
  color: #999;
}

.no-notice i {
  font-size: 2.5rem;
  margin-bottom: 10px;
  opacity: 0.5;
}

.notice-list {
  padding: 8px 0;
}

.notice-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  cursor: pointer;
  transition: background 0.2s;
}

.notice-item:hover {
  background: #f8fafc;
}

.notice-icon {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  background: #f0f5ff;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 12px;
}

.notice-info {
  flex: 1;
}

.notice-title {
  font-size: 0.85rem;
  color: #333;
  font-weight: 500;
}

.notice-time {
  font-size: 0.75rem;
  color: #999;
  margin-top: 2px;
}

.unread-dot {
  width: 8px;
  height: 8px;
  background: #2563eb;
  border-radius: 50%;
  margin-left: 8px;
}

/* 移动端菜单按钮 */
.mobile-menu-btn {
  display: none;
  flex-direction: column;
  justify-content: space-around;
  width: 28px;
  height: 28px;
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 0;
  z-index: 1001;
}

.mobile-menu-btn span {
  width: 24px;
  height: 2px;
  background: #333;
  border-radius: 2px;
  transition: all 0.3s;
}

.mobile-menu-btn.active span:first-child {
  transform: rotate(45deg) translate(5px, 5px);
}

.mobile-menu-btn.active span:nth-child(2) {
  opacity: 0;
}

.mobile-menu-btn.active span:last-child {
  transform: rotate(-45deg) translate(5px, -5px);
}

/* 移动端导航 */
.mobile-nav {
  position: fixed;
  top: 0;
  right: -100%;
  width: min(86vw, 320px);
  height: 100vh;
  background: white;
  box-shadow: -2px 0 10px rgba(0,0,0,0.1);
  transition: right 0.3s;
  z-index: 1000;
  overflow-y: auto;
}

.mobile-nav.active {
  right: 0;
}

.mobile-nav-content {
  padding: 70px 16px 20px;
}

.mobile-nav-group {
  margin-bottom: 8px;
}

.mobile-nav-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  font-size: 0.95rem;
  font-weight: 600;
  color: #333;
  cursor: pointer;
  border-radius: 8px;
  transition: background 0.2s;
}

.mobile-nav-title:hover {
  background: #f3f4f6;
}

.mobile-nav-items {
  padding-left: 16px;
}

.mobile-nav-items a {
  display: block;
  padding: 10px 16px;
  font-size: 0.9rem;
  color: #666;
  text-decoration: none;
  border-radius: 6px;
  transition: all 0.2s;
}

.mobile-nav-items a:hover,
.mobile-nav-items a.router-link-exact-active {
  background: rgba(37, 99, 235, 0.08);
  color: #2563eb;
}

.mobile-nav-link {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  font-size: 0.95rem;
  font-weight: 600;
  color: #333;
  text-decoration: none;
  border-radius: 8px;
  margin-bottom: 8px;
}

.mobile-nav-link:hover {
  background: #f3f4f6;
}

.mobile-nav-divider {
  height: 1px;
  background: #e5e7eb;
  margin: 16px 0;
}

.mobile-admin-btn,
.mobile-login-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  font-size: 0.9rem;
  color: #666;
  text-decoration: none;
  border-radius: 8px;
  margin-bottom: 8px;
}

.mobile-admin-btn:hover,
.mobile-login-btn:hover {
  background: #f3f4f6;
}

.mobile-user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
  background: #f8fafc;
  border-radius: 8px;
  margin-top: 8px;
}

.mobile-user-avatar {
  font-size: 2rem;
  color: #2563eb;
}

.mobile-username {
  font-weight: 600;
  color: #333;
}

.mobile-user-actions a {
  font-size: 0.85rem;
  color: #666;
}

.mobile-menu-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0,0,0,0.3);
  opacity: 0;
  visibility: hidden;
  transition: all 0.3s;
  z-index: 999;
}

.mobile-menu-overlay.active {
  opacity: 1;
  visibility: visible;
}

/* 公告弹窗 */
.notice-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
}

.notice-modal {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  max-height: 80vh;
  overflow: hidden;
}

.notice-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #e5e7eb;
}

.notice-modal-header h3 {
  margin: 0;
  font-size: 1rem;
}

.notice-modal-body {
  padding: 20px;
  max-height: 400px;
  overflow-y: auto;
  line-height: 1.6;
}

.notice-modal-footer {
  padding: 12px 20px;
  border-top: 1px solid #e5e7eb;
  background: #f8fafc;
}

.notice-modal-footer .notice-time {
  font-size: 0.8rem;
  color: #999;
}

/* 响应式 - 笔记本适配 */
@media (max-width: 1400px) {
  .nav {
    gap: 4px;
    margin-left: 16px;
  }
  
  .nav-dropdown-trigger,
  .nav-link {
    padding: 6px 10px;
    font-size: 0.88rem;
  }
  
  .action-btn {
    padding: 6px 10px;
    font-size: 0.85rem;
  }

  .login-btn span {
    display: none;
  }

  .login-btn i {
    margin: 0;
  }
  
  .username-text {
    max-width: 60px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  
  .company-name {
    font-size: 0.95rem;
    max-width: 120px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}

@media (max-width: 1200px) {
  .company-name {
    display: none;
  }
  
  .nav-dropdown-trigger,
  .nav-link {
    padding: 6px 8px;
    font-size: 0.85rem;
  }
  
  .notification-btn {
    padding: 6px;
  }
  
  .user-dropdown {
    padding: 4px 8px;
  }
  
  .username-text {
    display: none;
  }
}

@media (max-width: 1024px) {
  .desktop-nav {
    display: none;
  }

  .mobile-menu-btn {
    display: flex;
  }
}

@media (max-width: 640px) {
  .header {
    padding: 10px 16px;
    min-height: var(--app-header-height-mobile, 64px);
  }
  
  .company-name {
    display: none;
  }
  
  .logo-img {
    height: 36px;
  }

  .notification-panel {
    width: min(92vw, 340px);
  }
}

@media (max-width: 390px) {
  .header {
    padding: 8px 12px;
  }

  .header-left {
    gap: 8px;
  }

  .header-utility-actions {
    gap: 6px;
  }

  .logo-img {
    height: 32px;
  }

  .mobile-menu-btn {
    width: 24px;
    height: 24px;
  }

  .mobile-menu-btn span {
    width: 20px;
  }
}

.text-blue-500 { color: #3b82f6; }
.text-orange-500 { color: #f97316; }
</style>


