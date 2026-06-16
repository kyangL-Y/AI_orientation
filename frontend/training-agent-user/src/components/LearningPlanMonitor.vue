<template>
  <div class="min-h-screen bg-gray-50">
    <!-- 监控头部 -->
    <div class="bg-white shadow-sm border-b border-gray-200">
      <div class="container mx-auto px-4 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <el-button 
              size="small" 
              @click="goBack"
              class="flex items-center gap-2"
            >
              <i class="fa fa-arrow-left"></i>
              返回
            </el-button>
            <div>
              <h2 class="text-xl font-bold text-gray-800">{{ planData.title }}</h2>
              <p class="text-sm text-gray-600">{{ planData.description }}</p>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <el-tag :type="getStatusType(planData.status)">
              {{ getStatusText(planData.status) }}
            </el-tag>
            <el-button 
              type="primary" 
              size="small"
              @click="exportReport"
            >
              <i class="fa fa-download mr-2"></i>
              导出报告
            </el-button>
          </div>
        </div>
      </div>
    </div>

    <!-- 监控内容 -->
    <div class="container mx-auto px-4 py-6">
      <!-- 总览统计 -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-white rounded-lg p-4 shadow-sm">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600">总参与人数</p>
              <p class="text-2xl font-bold text-gray-800">{{ planData.participantCount || 0 }}</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <i class="fa fa-users text-blue-600"></i>
            </div>
          </div>
        </div>
        
        <div class="bg-white rounded-lg p-4 shadow-sm">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600">平均进度</p>
              <p class="text-2xl font-bold text-green-600">{{ averageProgress }}%</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
              <i class="fa fa-chart-line text-green-600"></i>
            </div>
          </div>
        </div>
        
        <div class="bg-white rounded-lg p-4 shadow-sm">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600">已完成人数</p>
              <p class="text-2xl font-bold text-purple-600">{{ completedCount }}</p>
            </div>
            <div class="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
              <i class="fa fa-check-circle text-purple-600"></i>
            </div>
          </div>
        </div>
        
        <div class="bg-white rounded-lg p-4 shadow-sm">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-gray-600">剩余天数</p>
              <p class="text-2xl font-bold text-orange-600">{{ remainingDays }}</p>
            </div>
            <div class="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center">
              <i class="fa fa-clock text-orange-600"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- 进度图表 -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <!-- 整体进度 -->
        <div class="bg-white rounded-lg p-6 shadow-sm">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">整体进度分布</h3>
          <div class="space-y-3">
            <div v-for="(item, index) in progressDistribution" :key="index" class="flex items-center">
              <span class="w-20 text-sm text-gray-600">{{ item.range }}</span>
              <div class="flex-1 mx-3">
                <div class="bg-gray-200 rounded-full h-6 relative">
                  <div 
                    class="bg-gradient-to-r from-blue-500 to-blue-600 h-6 rounded-full flex items-center justify-end pr-2"
                    :style="`width: ${item.percentage}%`"
                  >
                    <span class="text-xs text-white font-medium">{{ item.count }}人</span>
                  </div>
                </div>
              </div>
              <span class="w-12 text-sm text-gray-800 font-medium text-right">{{ item.percentage }}%</span>
            </div>
          </div>
        </div>

        <!-- 课程完成情况 -->
        <div class="bg-white rounded-lg p-6 shadow-sm">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">课程完成情况</h3>
          <div class="space-y-3 max-h-64 overflow-y-auto">
            <div v-for="course in courseProgress" :key="course.courseId" class="flex items-center">
              <div class="flex-1">
                <div class="flex items-center justify-between mb-1">
                  <span class="text-sm text-gray-800 font-medium">{{ course.title }}</span>
                  <span class="text-xs text-gray-600">{{ course.completedCount }}/{{ course.totalCount }}</span>
                </div>
                <div class="bg-gray-200 rounded-full h-2">
                  <div 
                    class="bg-green-500 h-2 rounded-full transition-all duration-300"
                    :style="`width: ${(course.completedCount / course.totalCount) * 100}%`"
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 学员详情表格 -->
      <div class="bg-white rounded-lg shadow-sm">
        <div class="p-6 border-b border-gray-200">
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-800">学员学习详情</h3>
            <div class="flex items-center gap-3">
              <el-input
                v-model="searchQuery"
                placeholder="搜索学员姓名或部门"
                size="small"
                style="width: 200px"
                clearable
              >
                <template #prefix>
                  <i class="fa fa-search text-gray-400"></i>
                </template>
              </el-input>
              <el-select v-model="statusFilter" placeholder="筛选状态" size="small" style="width: 120px">
                <el-option label="全部" value="" />
                <el-option label="未开始" value="not_started" />
                <el-option label="进行中" value="in_progress" />
                <el-option label="已完成" value="completed" />
              </el-select>
            </div>
          </div>
        </div>
        
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">学员信息</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">所属部门</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">进度</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">完成课程</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">最后学习</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">状态</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="student in filteredStudents" :key="student.userId" class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center">
                      <i class="fa fa-user text-gray-500 text-sm"></i>
                    </div>
                    <div class="ml-3">
                      <div class="text-sm font-medium text-gray-900">{{ student.name }}</div>
                      <div class="text-xs text-gray-500">{{ student.email }}</div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                  {{ student.department }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="flex-1 max-w-xs">
                      <div class="bg-gray-200 rounded-full h-2">
                        <div 
                          class="bg-blue-500 h-2 rounded-full"
                          :style="`width: ${student.progress}%`"
                        ></div>
                      </div>
                    </div>
                    <span class="ml-2 text-sm font-medium text-gray-900">{{ student.progress }}%</span>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                  {{ student.completedCourses }}/{{ student.totalCourses }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                  {{ formatDate(student.lastStudyTime) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <el-tag :type="getStudentStatusType(student.status)" size="small">
                    {{ getStudentStatusText(student.status) }}
                  </el-tag>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <el-button 
                    type="text" 
                    size="small"
                    @click="viewStudentDetail(student)"
                  >
                    查看详情
                  </el-button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <!-- 分页 -->
        <div class="p-4 border-t border-gray-200">
          <el-pagination
            v-model:current-page="currentPage"
            v-model:page-size="pageSize"
            :page-sizes="[10, 20, 50, 100]"
            :total="totalStudents"
            layout="total, sizes, prev, pager, next, jumper"
            @size-change="handleSizeChange"
            @current-change="handleCurrentChange"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

const router = useRouter()
const props = defineProps({
  planId: {
    type: [String, Number],
    required: true
  }
})

// 响应式数据
const planData = ref({})
const studentList = ref([])
const courseProgress = ref([])
const searchQuery = ref('')
const statusFilter = ref('')
const currentPage = ref(1)
const pageSize = ref(20)
const totalStudents = ref(0)

// 计算属性
const averageProgress = computed(() => {
  if (studentList.value.length === 0) return 0
  const total = studentList.value.reduce((sum, student) => sum + student.progress, 0)
  return Math.round(total / studentList.value.length)
})

const completedCount = computed(() => {
  return studentList.value.filter(student => student.status === 'completed').length
})

const remainingDays = computed(() => {
  if (!planData.value.endDate) return 0
  const today = new Date()
  const endDate = new Date(planData.value.endDate)
  const diffTime = endDate - today
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  return Math.max(0, diffDays)
})

const progressDistribution = computed(() => {
  const ranges = [
    { min: 0, max: 25, range: '0-25%', count: 0 },
    { min: 26, max: 50, range: '26-50%', count: 0 },
    { min: 51, max: 75, range: '51-75%', count: 0 },
    { min: 76, max: 100, range: '76-100%', count: 0 }
  ]
  
  studentList.value.forEach(student => {
    const progress = student.progress
    const range = ranges.find(r => progress >= r.min && progress <= r.max)
    if (range) range.count++
  })
  
  const total = studentList.value.length || 1
  return ranges.map(range => ({
    ...range,
    percentage: Math.round((range.count / total) * 100)
  }))
})

const filteredStudents = computed(() => {
  let filtered = studentList.value
  
  // 搜索过滤
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(student => 
      student.name.toLowerCase().includes(query) ||
      student.department.toLowerCase().includes(query)
    )
  }
  
  // 状态过滤
  if (statusFilter.value) {
    filtered = filtered.filter(student => student.status === statusFilter.value)
  }
  
  totalStudents.value = filtered.length
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filtered.slice(start, end)
})

// 方法
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

const getStudentStatusType = (status) => {
  const statusMap = {
    'not_started': 'info',
    'in_progress': 'warning',
    'completed': 'success'
  }
  return statusMap[status] || 'info'
}

const getStudentStatusText = (status) => {
  const statusMap = {
    'not_started': '未开始',
    'in_progress': '进行中',
    'completed': '已完成'
  }
  return statusMap[status] || status
}

const formatDate = (dateString) => {
  if (!dateString) return '暂无'
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  })
}

const goBack = () => {
  router.go(-1)
}

const exportReport = () => {
  ElMessage.success('报告导出功能开发中...')
}

const viewStudentDetail = (student) => {
  ElMessage.info(`查看学员 ${student.name} 的详细学习情况`)
}

const handleSizeChange = (size) => {
  pageSize.value = size
  currentPage.value = 1
}

const handleCurrentChange = (page) => {
  currentPage.value = page
}

const loadPlanData = async () => {
  try {
    // 模拟数据加载
    planData.value = {
      planId: props.planId,
      title: '新员工入职培训计划',
      description: '为新入职员工提供全面的岗位培训，包括公司文化、业务知识和服务技能',
      status: 'active',
      startDate: '2024-01-01',
      endDate: '2024-03-31',
      participantCount: 45
    }
    
    // 模拟学员数据
    studentList.value = Array.from({ length: 45 }, (_, index) => ({
      userId: index + 1,
      name: `学员${index + 1}`,
      email: `student${index + 1}@example.com`,
      department: ['前厅部', '客房部', '餐饮部', '安保部'][index % 4],
      progress: Math.floor(Math.random() * 101),
      completedCourses: Math.floor(Math.random() * 10),
      totalCourses: 10,
      lastStudyTime: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
      status: ['not_started', 'in_progress', 'completed'][Math.floor(Math.random() * 3)]
    }))
    
    // 模拟课程进度数据
    courseProgress.value = [
      { courseId: 1, title: '公司文化介绍', completedCount: 35, totalCount: 45 },
      { courseId: 2, title: '服务礼仪培训', completedCount: 28, totalCount: 45 },
      { courseId: 3, title: '安全操作规程', completedCount: 40, totalCount: 45 },
      { courseId: 4, title: '客户服务技巧', completedCount: 22, totalCount: 45 },
      { courseId: 5, title: '应急处理流程', completedCount: 18, totalCount: 45 }
    ]
  } catch (error) {
    logger.error('加载计划数据失败:', error)
    ElMessage.error('加载数据失败')
  }
}

// 生命周期
onMounted(() => {
  loadPlanData()
})
</script>

<style scoped>
/* 自定义滚动条样式 */
.overflow-y-auto::-webkit-scrollbar {
  width: 6px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
</style>
