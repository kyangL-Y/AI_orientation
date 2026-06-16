import { createRouter, createWebHistory } from 'vue-router'
// 首页改为学习推荐
import AIinterview from '../views/AIinterview.vue'
import Study from '../views/Study.vue'
import PersonalCenter from '../views/PersonalCenter.vue'

// 导入在线考试模块配置（TS导出默认为JS对象）
import onlineExam from '@/modules/onlineExam'
// 为避免某些环境下的懒加载分块加载失败，改为直接导入关键考试页面
import ExamStart from '@/modules/onlineExam/views/ExamStart.vue'
import ExamReview from '@/modules/onlineExam/views/ExamReview.vue'




const routes = [
  { path: '/', name: 'Study', component: Study },
  { path: '/AI', component: AIinterview},
  { path: '/study', component: Study},
  { path: '/register', name: 'RegisterEntry', component: () => import('@/views/RegisterEntry.vue')},
  { path: '/invite-register', name: 'InviteRegisterEntry', component: () => import('@/views/RegisterEntry.vue')},
  { path: '/personal', component: PersonalCenter},
  // 会员中心
  { path: '/member-center', name: 'MemberCenter', component: () => import('@/views/MemberCenter.vue')},
  { path: '/learning-plans', name: 'LearningPlans', component: () => import('@/views/LearningPaths.vue')},
  { path: '/learning-plans/:planId/monitor', name: 'LearningPlanMonitor', component: () => import('@/views/LearningPlanMonitor.vue')},
  { path: '/learning-path/:pathId', name: 'LearningPathDetail', component: () => import('@/views/LearningPathDetail.vue')},
  { path: '/network-test', component: () => import('@/views/NetworkTest.vue')},
  // 在线刷题界面
  { path: '/online', component: () => import('@/views/OnlineTest.vue') },
  // 刷题界面（历史路径）
  { path: '/practice', component: () => import('@/views/OnlineTest.vue') },
  { path: '/online-test', redirect: (to) => ({ path: '/online-exam/start', query: to.query }) },
  // 每日练习刷题界面
  { path: '/daily-practice', component: () => import('@/views/PracticeQuestionsOptimized.vue') },
  // 练习题目界面（支持分类参数）
  { path: '/practice-questions', component: () => import('@/views/PracticeQuestionsOptimized.vue') },
  // 学习排名与积分奖励页面
  { path: '/ranking', component: () => import('@/views/RankingOptimized.vue') },
  // 积分兑换商城
  { path: '/mall', name: 'PointsMall', component: () => import('@/views/PointsMall.vue') },
  // 我的答题记录页面
  { path: '/answer-record', component: () => import('@/views/AnswerRecordPage.vue') },
  // 错题本与复习
  { path: '/wrong-book', name: 'WrongBook', component: () => import('@/views/WrongBook.vue') },
  // 分类课程页面
  { path: '/category-courses', name: 'CategoryCourses', component: () => import('@/views/CategoryCourses.vue') },
  // 绿色饭店培训模块
  { path: '/green-hotel', name: 'GreenHotelTraining', component: () => import('@/views/GreenHotelTraining.vue') },
  // 绿色饭店课程中心（可承载大规模课程）
  { path: '/green-hotel/courses', name: 'GreenHotelCourses', component: () => import('@/views/GreenHotelCourses.vue') },
  // 酒店展示页面
  { path: '/hotel', name: 'HotelShowcase', component: () => import('@/views/HotelShowcase.vue') },
  // 企业文化页面
  { path: '/corporate-culture', name: 'CorporateCulture', component: () => import('@/views/CorporateCulture.vue') },
  // 酒店文化资料
  { path: '/hotel-culture/documents', name: 'HotelCultureDocuments', component: () => import('@/views/HotelCultureDocuments.vue'), meta: { requiresAuth: true } },
  // 部门培训页面
  { path: '/department-training', name: 'DepartmentTraining', component: () => import('@/views/DepartmentTraining.vue') },
  // 智囊阁知识共享
  { path: '/knowledge', name: 'KnowledgeSquare', component: () => import('@/views/KnowledgeSquare.vue') },
  { path: '/knowledge/:id', name: 'KnowledgeDetail', component: () => import('@/views/KnowledgeDetail.vue') },
  { path: '/knowledge/edit', name: 'KnowledgeCreate', component: () => import('@/views/KnowledgeEdit.vue') },
  { path: '/knowledge/edit/:id', name: 'KnowledgeEdit', component: () => import('@/views/KnowledgeEdit.vue') },
  { path: '/knowledge/my', name: 'MyKnowledge', component: () => import('@/views/MyKnowledge.vue') },
  { path: '/knowledge/favorites', name: 'MyFavorites', component: () => import('@/views/MyFavorites.vue') },
  // 学习报告页面
  { path: '/learning-report', name: 'LearningReport', component: () => import('@/views/LearningReport.vue') },
  { path: '/learning-report-demo', name: 'LearningReportDemo', component: () => import('@/views/LearningReport.vue') },
  // 在线考试模块
  { path: '/online-exam', name: 'QuestionList', component: onlineExam.route.component, meta: { requiresAuth: true } },
  // 正式考试与结果页面
  { path: '/online-exam/start', name: 'ExamStart', component: ExamStart, meta: { requiresAuth: true } },
  // 考试回看页面
  { path: '/online-exam/review/:attemptId', name: 'ExamReview', component: ExamReview, meta: { requiresAuth: true } }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior() {
    // 始终滚动到顶部
    return { top: 0 }
  },
  // 只使用精确匹配的激活类
  linkActiveClass: '',
  linkExactActiveClass: 'router-link-exact-active'
})

const parseStoredUserInfo = () => {
  const raw = localStorage.getItem('userInfo')
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch {
    return null
  }
}

const hasValidAuthState = () => {
  const token = localStorage.getItem('authToken')
  if (!token) return false
  const userInfo = parseStoredUserInfo()
  return !!(userInfo && typeof userInfo === 'object' && (userInfo.userId || userInfo.id))
}

router.beforeEach((to) => {
  if (!to.matched.some(record => record.meta?.requiresAuth)) {
    return true
  }

  if (hasValidAuthState()) {
    return true
  }

  return {
    path: '/study',
    query: { redirect: to.fullPath }
  }
})

export default router
