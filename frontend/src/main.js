import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import ElementPlus from 'element-plus'
import { ElMessage } from 'element-plus'
import 'element-plus/dist/index.css'
import './styles/tailwind.css' // 引入全局样式
import '@fortawesome/fontawesome-free/css/all.min.css'
import './utils/clearTestData.js' // 引入清理测试数据的工具
import logger, { setupProductionLogs } from './utils/logger.js'

// 将 ElMessage 挂载到 window 上，供 axios 拦截器使用
window.ElMessage = ElMessage

// 生产环境日志控制：只显示重要日志（警告、错误、带特殊标记的关键信息），过滤敏感信息
if (import.meta.env.PROD) {
  setupProductionLogs()
}

// ========== 防止localStorage冲突 ==========
// 清除后台管理系统的数据,避免和前台用户系统冲突
// 后台管理系统运行在 localhost:80
// 前台(training-agent-user)运行在 localhost:8084
// 虽然端口不同,但localStorage是按domain共享的!
const adminKeys = [
  'Admin-Token', 
  'Admin-Token-Name', 
  'admin_token',  // 管理员登录token
  'sidebarStatus', 
  'size',
  'layout-setting',
  'dynamicRoutes',
  'username',  // 记住的用户名
  'password',  // 记住的密码
  'rememberMe'  // 记住密码标记
]

// 检测并清除后台管理系统的数据
let hasAdminData = false
adminKeys.forEach(key => {
  if (localStorage.getItem(key)) {
    hasAdminData = true
    logger.warn(`检测到后台管理系统数据 [${key}]，正在清除...`)
    localStorage.removeItem(key)
  }
})

// 同时清除Cookie中的后台数据（如果存在）
try {
  const cookies = document.cookie.split(';')
  const adminCookies = ['Admin-Token', 'username', 'password', 'rememberMe']
  adminCookies.forEach(cookieName => {
    if (document.cookie.includes(cookieName)) {
      document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`
      logger.warn(`清除 Cookie [${cookieName}]`)
    }
  })
} catch (error) {
  logger.warn('清除 Cookie 失败:', error)
}

// 如果检测到后台数据,同时清除可能冲突的用户数据
if (hasAdminData) {
  logger.warn('检测到后台管理系统数据已清除：建议重新登录前台账号以避免冲突')
  // 不自动清除用户数据,让用户自己决定是否重新登录
}

const app = createApp(App)
app.use(router)
app.use(ElementPlus, { zIndex: 200000 })
app.mount('#app')
