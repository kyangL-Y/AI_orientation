<template>
  <div class="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100">
    <HeaderBar />
    
    <main class="container mx-auto px-4 py-6 max-w-6xl pt-20">
      <!-- 返回按钮和标题 -->
      <div class="mb-6">
        <div class="flex items-center gap-4 mb-4">
          <button 
            class="flex items-center gap-2 text-gray-600 hover:text-primary transition-colors"
            @click="goBack"
          >
            <i class="fa fa-arrow-left"></i>
            返回学习计划列表
          </button>
        </div>
        
        <div class="bg-white rounded-xl shadow-sm p-6">
          <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <h1 class="text-2xl font-bold text-gray-800 mb-2">{{ planData.title }}</h1>
              <p class="text-gray-600">{{ planData.description }}</p>
            </div>
            <div class="flex items-center gap-3">
              <el-tag 
                :type="getStatusType(planData.status)" 
                size="large"
                effect="light"
              >
                {{ getStatusText(planData.status) }}
              </el-tag>
              <el-button type="primary" @click="exportReport">
                <i class="fa fa-download mr-2"></i>
                导出报告
              </el-button>
            </div>
          </div>
        </div>
      </div>

      <!-- 加载状态 -->
      <div v-if="loading" class="flex justify-center items-center py-20">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>

      <!-- 监控内容 -->
      <div v-else class="space-y-6">
        <!-- 总体进度概览 -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="bg-white rounded-xl shadow-sm p-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-gray-600 text-sm">总体进度</span>
              <i class="fa fa-chart-line text-blue-500"></i>
            </div>
            <div class="text-2xl font-bold text-gray-800">{{ planData.progress || 0 }}%</div>
            <div class="text-xs text-gray-500 mt-1">整体完成率</div>
          </div>
          
          <div class="bg-white rounded-xl shadow-sm p-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-gray-600 text-sm">参与人数</span>
              <i class="fa fa-users text-green-500"></i>
            </div>
            <div class="text-2xl font-bold text-gray-800">{{ planData.participantCount || 0 }}</div>
            <div class="text-xs text-gray-500 mt-1">活跃学员</div>
          </div>
          
          <div class="bg-white rounded-xl shadow-sm p-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-gray-600 text-sm">已完成任务</span>
              <i class="fa fa-check-circle text-green-500"></i>
            </div>
            <div class="text-2xl font-bold text-gray-800">{{ completedTasks }}</div>
            <div class="text-xs text-gray-500 mt-1">总计 {{ totalTasks }} 个任务</div>
          </div>
          
          <div class="bg-white rounded-xl shadow-sm p-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-gray-600 text-sm">剩余时间</span>
              <i class="fa fa-clock text-orange-500"></i>
            </div>
            <div class="text-2xl font-bold text-gray-800">{{ remainingDays }}</div>
            <div class="text-xs text-gray-500 mt-1">天</div>
          </div>
        </div>

        <!-- 进度图表 -->
        <div class="bg-white rounded-xl shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">学习进度趋势</h3>
          <div class="h-64 flex items-center justify-center bg-gray-50 rounded-lg">
            <div class="text-center text-gray-500">
              <i class="fa fa-chart-area text-4xl mb-3"></i>
              <p>进度图表组件（可集成 ECharts）</p>
            </div>
          </div>
        </div>

        <!-- 学员学习情况 -->
        <div class="bg-white rounded-xl shadow-sm p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-800">学员学习情况</h3>
            <div class="flex items-center gap-2">
              <el-input
                v-model="searchUser"
                placeholder="搜索学员"
                size="small"
                style="width: 200px"
                clearable
              >
                <template #prefix>
                  <i class="fa fa-search"></i>
                </template>
              </el-input>
              <el-button size="small" @click="refreshUserData">
                <i class="fa fa-refresh"></i>
              </el-button>
            </div>
          </div>
          
          <el-table :data="filteredUsers" stripe>
            <el-table-column prop="userName" label="学员姓名" width="120">
              <template #default="{ row }">
                <div class="flex items-center gap-2">
                  <div class="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
                    <i class="fa fa-user text-blue-600 text-xs"></i>
                  </div>
                  <span>{{ row.userName }}</span>
                </div>
              </template>
            </el-table-column>
            
            <el-table-column prop="departmentName" label="所属部门" width="120" />
            
            <el-table-column prop="completedTasks" label="已完成任务" width="100" align="center">
              <template #default="{ row }">
                <span class="font-medium text-green-600">{{ row.completedTasks }}</span>
              </template>
            </el-table-column>
            
            <el-table-column prop="totalTasks" label="总任务数" width="100" align="center" />
            
            <el-table-column prop="progress" label="完成进度" width="150">
              <template #default="{ row }">
                <div class="flex items-center gap-2">
                  <el-progress 
                    :percentage="row.progress" 
                    :color="getProgressColor(row.progress)"
                    :stroke-width="6"
                    :show-text="false"
                    style="width: 80px"
                  />
                  <span class="text-sm font-medium">{{ row.progress }}%</span>
                </div>
              </template>
            </el-table-column>
            
            <el-table-column prop="lastActiveTime" label="最后活跃时间">
              <template #default="{ row }">
                <span class="text-sm text-gray-600">{{ formatDate(row.lastActiveTime) }}</span>
              </template>
            </el-table-column>
            
            <el-table-column label="操作" width="120" fixed="right">
              <template #default="{ row }">
                <el-button size="small" text @click="viewUserDetail(row)">
                  查看详情
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>

        <!-- 任务完成情况 -->
        <div class="bg-white rounded-xl shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">任务完成情况</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div v-for="task in planData.planItems" :key="task.itemId" class="border border-gray-200 rounded-lg p-4">
              <div class="flex items-start justify-between mb-3">
                <div>
                  <h4 class="font-medium text-gray-800">{{ task.title }}</h4>
                  <p class="text-sm text-gray-600 mt-1">{{ task.description }}</p>
                </div>
                <el-tag 
                  :type="task.completed ? 'success' : 'info'" 
                  size="small"
                  effect="light"
                >
                  {{ task.completed ? '已完成' : '进行中' }}
                </el-tag>
              </div>
              
              <div class="flex items-center justify-between text-sm">
                <span class="text-gray-500">
                  <i class="fa fa-calendar mr-1"></i>
                  截止: {{ formatDate(task.dueDate) }}
                </span>
                <span class="text-gray-500">
                  <i class="fa fa-users mr-1"></i>
                  {{ task.completedCount || 0 }}/{{ planData.participantCount || 0 }} 人完成
                </span>
              </div>
              
              <!-- 任务进度条 -->
              <div class="mt-3">
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    class="bg-green-500 h-2 rounded-full transition-all duration-300" 
                    :style="`width: ${getTaskProgress(task)}%`"
                  ></div>
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
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import HeaderBar from '@/components/HeaderBar.vue'
import { getLearningPlanDetail } from '@/api/learningPlan'

const route = useRoute()
const router = useRouter()

// 响应式数据
const loading = ref(true)
const planData = ref({})
const searchUser = ref('')
const userData = ref([])

// 计算属性
const planId = computed(() => route.params.planId)

const completedTasks = computed(() => {
  if (!planData.value.planItems) return 0
  return planData.value.planItems.filter(item => item.completed).length
})

const totalTasks = computed(() => {
  return planData.value.planItems?.length || 0
})

const remainingDays = computed(() => {
  if (!planData.value.endDate) return 0
  const today = new Date()
  const endDate = new Date(planData.value.endDate)
  const diffTime = endDate - today
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  return Math.max(0, diffDays)
})

const filteredUsers = computed(() => {
  if (!searchUser.value) return userData.value
  return userData.value.filter(user => 
    user.userName.toLowerCase().includes(searchUser.value.toLowerCase())
  )
})

// 生命周期
onMounted(() => {
  loadPlanData()
  loadUserData()
})

// 方法
const loadPlanData = async () => {
  try {
    loading.value = true
    const response = await getLearningPlanDetail(planId.value)
    if (response.data && response.data.code === 200) {
      planData.value = response.data.data || {}
    }
  } catch (error) {
    logger.error('加载学习计划数据失败:', error)
    ElMessage.error('加载学习计划数据失败')
  } finally {
    loading.value = false
  }
}

const loadUserData = () => {
  // 模拟用户数据，实际应该从API获取
  userData.value = [
    {
      userId: 1,
      userName: '张三',
      departmentName: '前台部',
      completedTasks: 8,
      totalTasks: 10,
      progress: 80,
      lastActiveTime: '2025-10-21T10:30:00'
    },
    {
      userId: 2,
      userName: '李四',
      departmentName: '客房部',
      completedTasks: 6,
      totalTasks: 10,
      progress: 60,
      lastActiveTime: '2025-10-20T15:45:00'
    },
    {
      userId: 3,
      userName: '王五',
      departmentName: '餐饮部',
      completedTasks: 9,
      totalTasks: 10,
      progress: 90,
      lastActiveTime: '2025-10-21T08:15:00'
    }
  ]
}

const refreshUserData = () => {
  ElMessage.success('用户数据已刷新')
  loadUserData()
}

const goBack = () => {
  router.push('/learning-plans')
}

const exportReport = () => {
  ElMessage.success('报告导出功能开发中')
}

const viewUserDetail = (user) => {
  ElMessage.info(`查看 ${user.userName} 的学习详情`)
}

// 工具方法
const getStatusType = (status) => {
  const statusMap = {
    'draft': 'info',
    'active': 'success',
    'completed': 'success',
    'cancelled': 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status) => {
  const statusMap = {
    'draft': '草稿',
    'active': '进行中',
    'completed': '已完成',
    'cancelled': '已取消'
  }
  return statusMap[status] || status
}

const getProgressColor = (progress) => {
  if (progress < 30) return '#f56c6c'
  if (progress < 70) return '#e6a23c'
  return '#67c23a'
}

const getTaskProgress = (task) => {
  if (!task.completedCount || !planData.value.participantCount) return 0
  return Math.round((task.completedCount / planData.value.participantCount) * 100)
}

const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>

<style scoped>
/* 自定义样式 */
.line-through {
  text-decoration: line-through;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .container {
    padding-left: 1rem;
    padding-right: 1rem;
  }
}
</style>
