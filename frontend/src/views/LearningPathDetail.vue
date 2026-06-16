<template>
  <div class="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100">
    <HeaderBar />
    <!-- 导航栏占位符 -->
    <div class="h-[64px] md:h-[72px]"></div>
    
    <!-- 悬浮返回按钮 -->
    <button 
      @click="goBack" 
      class="fixed top-20 md:top-24 left-3 md:left-6 z-50 flex items-center gap-1 md:gap-2 px-2.5 md:px-4 py-1.5 md:py-2 bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-lg hover:from-blue-600 hover:to-blue-700 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 text-xs md:text-sm"
    >
      <svg class="w-3 h-3 md:w-4 md:h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
      </svg>
      <span class="hidden md:inline">返回学习计划</span>
      <span class="md:hidden">返回</span>
    </button>
    
    <main class="container mx-auto px-3 md:px-4 py-4 md:py-6 max-w-6xl main-content" v-loading="loading">
      <!-- 页面标题 -->
      <div class="mb-4 md:mb-8 pt-6 md:pt-8">
        <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 md:gap-6">
          <div>
            <h1 class="text-lg md:text-[clamp(1.5rem,3vw,2.5rem)] font-bold text-gray-800">
              {{ currentPath.pathName }}
            </h1>
            <p class="text-gray-500 mt-1 md:mt-2 text-xs md:text-base">{{ currentPath.pathDescription }}</p>
            
            <div class="flex flex-wrap gap-2 mt-3 md:mt-4">
              <span v-if="currentPath.targetRole" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                <i class="fa fa-user mr-1.5"></i>
                {{ currentPath.targetRole }}
              </span>
              <span v-if="currentPath.difficultyLevel" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
                <i class="fa fa-layer-group mr-1.5"></i>
                {{ currentPath.difficultyLevel }}
              </span>
              <span v-if="currentPath.estimatedDuration" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                <i class="fa fa-clock mr-1.5"></i>
                预计 {{ currentPath.estimatedDuration }} 小时
              </span>
            </div>
          </div>
          
          <!-- 路径进度概览 -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-3 md:p-6 w-full lg:min-w-[400px] lg:max-w-[500px] path-progress-card">
            <div class="flex items-center justify-between gap-3 md:gap-6 md:flex-row progress-summary">
              <!-- 左侧：进度信息 -->
              <div class="flex-shrink-0 text-center">
                <div class="text-xl md:text-3xl font-bold text-blue-600 mb-0.5 md:mb-1">
                  {{ currentPath.progress }}%
                </div>
                <div class="text-xs md:text-sm text-gray-500">路径完成度</div>
                <div class="text-xs md:text-sm text-gray-600 mt-1 md:mt-2 hidden md:block">
                  已完成 {{ completedPlansCount }} / {{ totalPlansCount }} 个学习计划
                </div>
              </div>
              
              <!-- 右侧：进度条 -->
              <div class="flex-1">
                <div class="w-full bg-gray-200 rounded-full h-2 md:h-4">
                  <div 
                    class="bg-gradient-to-r from-blue-500 to-blue-600 h-2 md:h-4 rounded-full transition-all duration-500"
                    :style="{ width: currentPath.progress + '%' }"
                  ></div>
                </div>
                <div class="text-xs text-gray-600 mt-1 md:hidden text-right">
                  {{ completedPlansCount }}/{{ totalPlansCount }} 个计划
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 学习计划列表 -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 plans-shell">
          <div class="flex items-center justify-between mb-6 plans-toolbar">
            <h3 class="text-lg font-semibold text-gray-800">包含的学习计划</h3>
            <div class="flex gap-2 plans-filter">
            <select 
              v-model="statusFilter" 
              class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">全部状态</option>
              <option value="completed">已完成</option>
              <option value="in-progress">进行中</option>
              <option value="not-started">未开始</option>
            </select>
          </div>
        </div>

        <div class="space-y-4">
          <div 
            v-for="(plan, index) in filteredPlans" 
            :key="plan.id"
            class="border border-gray-200 rounded-lg overflow-hidden hover:shadow-md transition-shadow"
          >
            <!-- 学习计划头部 -->
              <div class="p-4 bg-white plan-card-body">
                <div class="flex items-start justify-between plan-card-header">
                  <div class="flex-1 plan-card-content">
                    <div class="flex items-center gap-3 mb-2 plan-title-row">
                    <div class="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center text-sm font-medium text-gray-600">
                      {{ index + 1 }}
                    </div>
                    <h4 class="font-semibold text-gray-800">{{ plan.title }}</h4>
                    <span 
                      class="px-2 py-1 rounded-full text-xs font-medium"
                      :class="getStatusClass(plan.status)"
                    >
                      {{ getStatusText(plan.status) }}
                    </span>
                  </div>
                  
                  <p class="text-gray-600 text-sm mb-3 ml-11 plan-description">{{ plan.description || '暂无描述' }}</p>
                   
                  <div class="flex items-center gap-4 ml-11 text-sm text-gray-500 plan-meta-row">
                    <span class="flex items-center gap-1">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      {{ plan.duration }}
                    </span>
                    <span class="flex items-center gap-1">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                      </svg>
                      {{ plan.coursesCount }} 个任务
                    </span>
                    <span v-if="plan.completedAt" class="flex items-center gap-1 text-green-600">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                      完成于 {{ plan.completedAt }}
                    </span>
                  </div>

                  <div class="ml-11 mt-3 plan-progress-block">
                    <div class="flex items-center justify-between text-xs text-gray-500 mb-1 plan-progress-labels">
                      <span>完成进度</span>
                      <span>{{ getPlanProgress(plan) }}%</span>
                    </div>
                    <div class="progress-track">
                      <div class="progress-fill" :style="{ width: getPlanProgress(plan) + '%' }"></div>
                    </div>
                  </div>
                </div>
                
                  <div class="flex gap-2 ml-4 plan-action-group">
                  <button 
                    v-if="plan.status === 'not-started'"
                    @click="startPlan(plan)"
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm"
                  >
                    开始学习
                  </button>
                  <button 
                    v-else-if="plan.status === 'in-progress'"
                    @click="continuePlan(plan)"
                    class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors text-sm"
                  >
                    继续学习
                  </button>
                  <button 
                    v-else
                    @click="viewPlanDetails(plan)"
                    class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors text-sm"
                  >
                    查看详情
                  </button>
                </div>
              </div>
            </div>

            <!-- 任务列表展开区域 -->
            <div v-if="plan.planItems && plan.planItems.length > 0" class="border-t border-gray-200 bg-gray-50">
              <!-- 展开/折叠按钮 -->
              <div 
                @click="togglePlanTasks(plan.id)"
                class="px-4 py-3 flex items-center justify-between cursor-pointer hover:bg-gray-100 transition-colors task-panel-toggle"
              >
                <div class="flex items-center gap-2 task-panel-title">
                  <i class="fa fa-tasks text-orange-500 text-sm"></i>
                  <span class="text-sm font-semibold text-gray-700">
                    任务清单 ({{ plan.planItems.length }})
                  </span>
                  <span class="text-xs text-gray-500">
                    已完成 {{ getCompletedTasksCount(plan) }} / {{ plan.planItems.length }}
                  </span>
                </div>
                <i 
                  :class="isPlanExpanded(plan.id) ? 'fa fa-chevron-up' : 'fa fa-chevron-down'"
                  class="text-gray-400 transition-transform text-sm"
                ></i>
              </div>

              <!-- 任务列表 -->
              <div v-if="isPlanExpanded(plan.id)" class="px-4 pb-4 space-y-2">
                <div
                  v-for="(item, itemIndex) in plan.planItems"
                  :key="itemIndex"
                  class="flex items-center gap-3 p-3 rounded-lg bg-white border border-gray-100 hover:border-blue-200 hover:shadow-sm transition-all cursor-pointer task-item-row"
                  @click="jumpToTask(item, plan)"
                >
                  <!-- 完成状态图标 -->
                  <span
                    class="flex-shrink-0 text-lg"
                    :class="{
                      'text-green-500': item.status === 'completed' || item.completed === true,
                      'text-blue-500': item.status === 'in_progress' || item.status === 'active',
                      'text-gray-300': !item.status || item.status === 'pending'
                    }"
                  >
                    <i
                      :class="{
                        'fa fa-check-circle': item.status === 'completed' || item.completed === true,
                        'fa fa-clock': item.status === 'in_progress' || item.status === 'active',
                        'fa fa-circle': !item.status || item.status === 'pending'
                      }"
                    ></i>
                  </span>

                  <!-- 任务标题 -->
                  <span
                    class="flex-1 text-sm"
                    :class="{
                      'text-gray-400 line-through': item.status === 'completed' || item.completed === true,
                      'text-gray-700 font-medium': item.status !== 'completed' && !item.completed
                    }"
                  >
                    {{ item.title || item.taskName || item.itemName || '未命名任务' }}
                  </span>

                  <!-- 任务类型标签 -->
                  <span
                    v-if="item.contentType"
                    class="flex-shrink-0 px-2.5 py-1 rounded-full text-xs font-medium"
                    :class="{
                      'bg-blue-50 text-blue-600 border border-blue-200': item.contentType === 'course',
                      'bg-green-50 text-green-600 border border-green-200': item.contentType === 'quiz',
                      'bg-orange-50 text-orange-600 border border-orange-200': item.contentType === 'task',
                      'bg-gray-50 text-gray-600 border border-gray-200': !['course', 'quiz', 'task'].includes(item.contentType)
                    }"
                  >
                    {{ getTaskTypeLabel(item.contentType) }}
                  </span>

                  <!-- 截止日期 -->
                  <span
                    v-if="item.dueDate"
                    class="flex-shrink-0 text-xs flex items-center gap-1.5 px-2 py-1 rounded bg-gray-50"
                    :class="{
                      'text-red-500': isTaskOverdue(item.dueDate) && item.status !== 'completed',
                      'text-gray-500': !isTaskOverdue(item.dueDate) || item.status === 'completed'
                    }"
                  >
                    <i class="fa fa-calendar text-xs"></i>
                    {{ formatTaskDate(item.dueDate) }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import HeaderBar from '@/components/HeaderBar.vue'
import { ElMessage } from 'element-plus'
import { getTrainingPathDetail } from '@/api/trainingPath'
import { api } from '@/utils/api'

const router = useRouter()
const route = useRoute()

// 响应式数据
const loading = ref(false)
const statusFilter = ref('')
const currentPath = ref({
  pathId: null,
  pathName: '',
  pathDescription: '',
  targetRole: '',
  difficultyLevel: '',
  estimatedDuration: 0,
  progress: 0
})

// 学习计划数据
const plans = ref([])

// 展开的学习计划ID集合（默认全部展开）
const expandedPlanIds = ref(new Set())

// 计算属性
const filteredPlans = computed(() => {
  if (!statusFilter.value) return plans.value
  return plans.value.filter(plan => plan.status === statusFilter.value)
})

const totalPlansCount = computed(() => plans.value.length)
const completedPlansCount = computed(() => plans.value.filter(plan => plan.status === 'completed').length)
const inProgressPlansCount = computed(() => plans.value.filter(plan => plan.status === 'in-progress').length)
const notStartedPlansCount = computed(() => plans.value.filter(plan => plan.status === 'not-started').length)

// 方法
const goBack = () => {
  router.push('/learning-plans')
}

const getStatusClass = (status) => {
  switch (status) {
    case 'completed':
      return 'bg-green-100 text-green-800'
    case 'in-progress':
      return 'bg-blue-100 text-blue-800'
    case 'not-started':
      return 'bg-gray-100 text-gray-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

const getStatusText = (status) => {
  switch (status) {
    case 'completed':
      return '已完成'
    case 'in-progress':
      return '进行中'
    case 'not-started':
      return '未开始'
    default:
      return '未知'
  }
}

const startPlan = (plan) => {
  // 开始学习：跳转到第一个任务
  if (plan.planItems && plan.planItems.length > 0) {
    const firstTask = plan.planItems[0]
    jumpToTask(firstTask, plan)
  } else {
    ElMessage.warning('该学习计划暂无学习任务')
  }
}

const continuePlan = (plan) => {
  // 继续学习：跳转到第一个未完成的任务
  if (plan.planItems && plan.planItems.length > 0) {
    // 找到第一个未完成的任务
    const currentTask = plan.planItems.find(item => 
      item.status !== 'completed' && !item.completed
    )
    
    if (currentTask) {
      jumpToTask(currentTask, plan)
    } else {
      // 所有任务都已完成，跳转到第一个任务
      jumpToTask(plan.planItems[0], plan)
    }
  } else {
    ElMessage.warning('该学习计划暂无学习任务')
  }
}

const viewPlanDetails = (plan) => {
  // 查看详情：也跳转到继续学习
  continuePlan(plan)
}

// 跳转到具体任务的详情页
const jumpToTask = async (task, plan) => {
  if (!task) {
    ElMessage.warning('无法找到学习任务')
    return
  }

  logger.debug('🎯 准备跳转到任务详情')
  logger.debug('  ├─ 任务对象:', task)
  logger.debug('  ├─ 任务类型:', task.contentType)
  logger.debug('  ├─ 内容ID:', task.contentId)
  logger.debug('  ├─ 任务ID:', task.itemId)
  logger.debug('  └─ 计划ID:', plan.id)
  
  if (!task.contentId) {
    logger.error('❌ contentId 为空，无法跳转')
    ElMessage.warning('该任务暂无关联内容')
    return
  }
  
  // 根据任务类型跳转到相应的详情页面
  if (task.contentType === 'course') {
    try {
      // 先从后端获取课程分类的完整数据
      logger.debug('📡 正在获取课程详情，ID:', task.contentId)
      const response = await api.get(`/train/course-category/${task.contentId}`)
      logger.debug('📡 课程详情API响应:', response)
      
      if (response && response.data) {
        const courseCategory = response.data.data || response.data
        logger.debug('📚 课程分类数据:', courseCategory)
        logger.debug('📚 knowledgePoints 字段:', courseCategory.knowledgePoints)
        logger.debug('📚 knowledgePoints 长度:', courseCategory.knowledgePoints ? courseCategory.knowledgePoints.length : 0)
        
        // 准备课程数据，使用 knowledge_points 字段作为内容
        const courseData = {
          id: courseCategory.courseCategoryId || task.contentId,
          title: courseCategory.thirdLevelC || courseCategory.mainTitle || task.title || '课程详情',
          content: courseCategory.knowledgePoints || '暂无课程内容',
          category: courseCategory.mainTitle || courseCategory.mainS || '培训课程',
          subCategory: courseCategory.mainS || '',
          specificCategory: courseCategory.specificCategory || '',
          duration: '2小时',
          level: '中级',
          categoryPath: `${courseCategory.mainTitle || '培训中心'} / ${courseCategory.mainS || '课程学习'}`,
          videoApi: 'train/video/play',
          courseType: 'ota'
        }
        
        logger.debug('✅ 设置课程数据到 sessionStorage:', courseData)
        logger.debug('✅ content 字段内容:', courseData.content)
        logger.debug('✅ content 字段长度:', courseData.content ? courseData.content.length : 0)
        sessionStorage.setItem('currentKnowledgeContent', JSON.stringify(courseData))
        
        // 保存返回路径（当前学习路径详情页的URL）
        const returnPath = window.location.href
        logger.debug('✅ 保存返回路径:', returnPath)
        sessionStorage.setItem('knowledgeDetailReturnPath', returnPath)
        
        // 跳转到静态HTML页面
        logger.debug('✅ 跳转到 knowledge-detail.html')
        window.location.href = '/knowledge-detail.html'
      } else {
        logger.error('❌ 课程详情响应数据为空')
        ElMessage.error('无法获取课程详情')
      }
    } catch (error) {
      logger.error('❌ 获取课程详情失败:', error)
      ElMessage.error('获取课程详情失败，请稍后重试')
    }
  } else if (task.contentType === 'quiz' || task.contentType === 'exam') {
    const targetUrl = {
      path: '/online-test',
      query: { 
        id: task.contentId,
        planId: plan.id,
        itemId: task.itemId
      }
    }
    logger.debug('✅ 跳转到考试详情页:', targetUrl)
    router.push(targetUrl)
  } else if (task.contentType === 'task') {
    // 如果是普通任务，可能需要跳转到任务详情页
    ElMessage.info('任务详情功能开发中')
  } else {
    logger.error('❌ 不支持的任务类型:', task.contentType)
    ElMessage.warning(`暂不支持该类型的学习任务：${task.contentType || '未知'}`)
  }
}

// 切换学习计划任务列表展开/折叠
const togglePlanTasks = (planId) => {
  if (expandedPlanIds.value.has(planId)) {
    expandedPlanIds.value.delete(planId)
  } else {
    expandedPlanIds.value.add(planId)
  }
}

// 检查学习计划是否展开（默认全部展开）
const isPlanExpanded = (planId) => {
  return expandedPlanIds.value.has(planId)
}

// 获取已完成任务数量
const getCompletedTasksCount = (plan) => {
  if (!plan.planItems || !Array.isArray(plan.planItems)) return 0
  return plan.planItems.filter(item => 
    item.status === 'completed' || item.completed === true
  ).length
}

const getPlanProgress = (plan) => {
  if (!plan.planItems || !plan.planItems.length) return 0
  const completed = getCompletedTasksCount(plan)
  return Math.round((completed / plan.planItems.length) * 100)
}

// 获取任务类型标签文本
const getTaskTypeLabel = (contentType) => {
  const typeMap = {
    'course': '课程',
    'quiz': '考试',
    'task': '任务',
    'exam': '考试',
    'assignment': '作业'
  }
  return typeMap[contentType] || '其他'
}

// 格式化任务日期
const formatTaskDate = (dateStr) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${month}-${day}`
}

// 检查任务是否逾期
const isTaskOverdue = (dueDate) => {
  if (!dueDate) return false
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const due = new Date(dueDate)
  due.setHours(0, 0, 0, 0)
  return due < today
}

// 加载学习路径详情
const loadPathDetail = async () => {
  const pathId = route.params.pathId || route.query.pathId
  
  if (!pathId) {
    ElMessage.error('缺少学习路径ID')
    router.push('/learning-plans')
    return
  }
  
  loading.value = true
  
  try {
    logger.debug('📚 加载学习路径详情:', pathId)
    const response = await getTrainingPathDetail(pathId)
    logger.debug('📚 学习路径API响应:', response)
    logger.debug('📚 响应数据结构:', response.data)
    
    if (response && response.data) {
      // 处理后端返回的数据结构：{ code: 200, data: { path: {...}, plans: [...] } }
      const responseData = response.data.data || response.data
      logger.debug('📚 实际数据:', responseData)
      const { path, plans: pathPlans } = responseData
      
      if (path) {
        currentPath.value = {
          pathId: path.pathId,
          pathName: path.pathName,
          pathDescription: path.pathDescription,
          targetRole: path.targetRole || '全员',
          difficultyLevel: path.difficultyLevel || 'beginner',
          estimatedDuration: path.estimatedDuration || 0,
          progress: 0 // 进度需要从用户路径表获取
        }
      }
      
      if (pathPlans && Array.isArray(pathPlans)) {
        logger.debug('📋 原始计划数据:', pathPlans)
        // 直接使用数据库返回的数据，不在前端过滤
        plans.value = pathPlans.map(plan => {
          logger.debug(`📋 处理计划: ${plan.title}, planItems数量:`, plan.planItems ? plan.planItems.length : 0)
          if (plan.planItems && plan.planItems.length > 0) {
            logger.debug(`  ├─ 任务列表:`, plan.planItems)
          }
          return {
            id: plan.planId,
            title: plan.title,
            description: plan.description || '暂无描述',
            status: plan.status === 'completed' ? 'completed' : 
                    plan.status === 'active' ? 'in-progress' : 'not-started',
            duration: calculateDuration(plan.startDate, plan.endDate),
            coursesCount: plan.planItems ? plan.planItems.length : 0,
            completedAt: plan.status === 'completed' ? plan.endDate : null,
            planItems: plan.planItems || [] // 保留任务列表数据
          }
        })
        
        logger.debug('📋 处理后的计划数据:', plans.value)
        
        // 默认展开所有学习计划
        expandedPlanIds.value = new Set(plans.value.map(p => p.id))
        logger.debug('📋 展开的计划IDs:', Array.from(expandedPlanIds.value))
        
        // 计算进度
        if (plans.value.length > 0) {
          const completedCount = plans.value.filter(p => p.status === 'completed').length
          currentPath.value.progress = Math.round((completedCount / plans.value.length) * 100)
        }
      }
      
      logger.debug('✅ 学习路径加载成功，最终plans:', plans.value)
    } else {
      ElMessage.warning('未找到学习路径信息')
      router.push('/learning-plans')
    }
  } catch (error) {
    logger.error('❌ 加载学习路径失败:', error)
    ElMessage.error('加载学习路径失败，请稍后重试')
    router.push('/learning-plans')
  } finally {
    loading.value = false
  }
}

// 计算学习时长
const calculateDuration = (startDate, endDate) => {
  if (!startDate || !endDate) return '未设置'
  
  const start = new Date(startDate)
  const end = new Date(endDate)
  const days = Math.ceil((end - start) / (1000 * 60 * 60 * 24))
  
  if (days < 7) {
    return `${days}天`
  } else if (days < 30) {
    return `${Math.ceil(days / 7)}周`
  } else {
    return `${Math.ceil(days / 30)}个月`
  }
}

onMounted(() => {
  loadPathDetail()
})
</script>

<style scoped>
.main-content {
  min-height: calc(100vh - 80px);
}

.progress-track {
  position: relative;
  width: 100%;
  height: 6px;
  border-radius: 999px;
  background: #edf2f7;
  overflow: hidden;
}

.progress-fill {
  position: absolute;
  left: 0;
  top: 0;
  height: 100%;
  background: linear-gradient(90deg, #4f46e5, #06b6d4);
  transition: width 0.3s ease;
}

.path-progress-card,
.progress-summary,
.plans-shell,
.plans-toolbar,
.plans-filter,
.plan-card-body,
.plan-card-header,
.plan-card-content,
.plan-title-row,
.plan-description,
.plan-meta-row,
.plan-progress-block,
.plan-progress-labels,
.plan-action-group,
.task-panel-toggle,
.task-panel-title,
.task-item-row {
  min-width: 0;
}

/* ========== 移动端优化样式 ========== */
@media (max-width: 768px) {
  .main-content {
    min-height: calc(100vh - 64px);
  }

  .main-content {
    padding-left: 0.75rem;
    padding-right: 0.75rem;
  }

  .path-progress-card {
    min-width: 0 !important;
    max-width: none !important;
  }

  .progress-summary,
  .plans-toolbar,
  .plan-card-header,
  .plan-title-row,
  .plan-progress-labels,
  .task-panel-toggle,
  .task-item-row {
    flex-direction: column;
    align-items: flex-start !important;
  }

  .plans-shell {
    padding: 1rem !important;
    border-radius: 0.875rem !important;
  }

  .plans-toolbar {
    gap: 0.875rem !important;
    margin-bottom: 1rem !important;
  }

  .plans-filter,
  .plans-filter select {
    width: 100%;
  }

  .plans-filter select {
    min-height: 44px;
    font-size: 0.875rem !important;
  }

  .plan-card-body {
    padding: 0.875rem !important;
  }

  .plan-card-header,
  .plan-card-content {
    width: 100%;
  }

  .plan-title-row {
    gap: 0.625rem !important;
  }

  .plan-description,
  .plan-meta-row,
  .plan-progress-block {
    margin-left: 0 !important;
  }

  .plan-meta-row {
    flex-wrap: wrap !important;
    gap: 0.5rem 0.875rem !important;
  }

  .plan-action-group {
    margin-left: 0 !important;
    margin-top: 0.75rem !important;
    width: 100%;
    flex-wrap: wrap;
  }

  .plan-action-group button {
    width: 100%;
    min-height: 44px;
    font-size: 0.875rem !important;
  }

  .task-panel-title {
    width: 100%;
  }

  .task-item-row {
    gap: 0.625rem !important;
  }

  .task-item-row > span:last-child,
  .task-item-row > span:nth-last-child(2) {
    align-self: flex-start;
  }
}

@media (max-width: 480px) {
  .main-content {
    padding-left: 0.5rem;
    padding-right: 0.5rem;
  }

  .plans-shell {
    padding: 0.875rem !important;
  }

  .task-panel-toggle {
    padding: 0.625rem 0.75rem !important;
  }

  .px-4.pb-4.space-y-2 {
    padding: 0.5rem 0.75rem 0.75rem !important;
  }

  .task-item-row {
    padding: 0.75rem !important;
  }
}
</style>

