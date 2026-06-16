<template>
  <div class="min-h-screen bg-gradient-to-b from-blue-50/50 to-indigo-50/30 font-sans">
    <HeaderBar />
    <div class="pt-[58px] md:pt-[72px] pb-10 md:pb-12">
      <!-- 顶部 Banner -->
      <div class="relative bg-gradient-to-br from-blue-600 via-blue-700 to-indigo-700 text-white overflow-hidden">
        <div class="absolute inset-0">
          <div class="absolute top-0 right-0 w-[400px] h-[400px] bg-gradient-to-br from-white/5 to-transparent rounded-full blur-3xl transform translate-x-1/3 -translate-y-1/2"></div>
          <div class="absolute bottom-0 left-0 w-[300px] h-[300px] bg-gradient-to-tr from-blue-500/20 to-transparent rounded-full blur-3xl transform -translate-x-1/4 translate-y-1/4"></div>
        </div>

        <div class="container mx-auto px-3 md:px-4 py-4 md:py-14 relative z-10">
          <div class="max-w-3xl">
            <div class="inline-flex items-center gap-1.5 px-2.5 py-1 bg-white/10 backdrop-blur-sm rounded-full text-[11px] md:text-xs mb-1.5 md:mb-4 border border-white/10">
              <i class="fas fa-graduation-cap text-blue-200 text-xs"></i>
              <span class="text-blue-100">专业技能培训平台</span>
            </div>
            <h1 class="text-[1.15rem] md:text-4xl font-bold mb-1 md:mb-4 tracking-tight leading-tight">
              技能工坊<span class="text-blue-200/90">·岗位进阶</span>
            </h1>
            <p class="text-blue-100/90 text-[11px] md:text-lg leading-snug md:leading-relaxed max-w-2xl">
              构建全方位的岗位能力模型，为各部门提供定制化的知识图谱与实战演练。
            </p>
          </div>
        </div>
        <div class="absolute bottom-0 left-0 right-0 h-3 md:h-8 bg-gradient-to-t from-blue-50/50 to-transparent"></div>
      </div>

      <div class="container mx-auto px-2.5 md:px-4 -mt-1 md:-mt-6 relative z-20">
        <!-- 移动端部门选择器 -->
        <div class="lg:hidden mb-2.5">
          <div class="bg-white rounded-xl shadow-sm border border-blue-100 p-2">
            <div class="flex items-center gap-2 mb-1.5">
              <div class="w-[22px] h-[22px] rounded-md bg-blue-600 flex items-center justify-center">
                <i class="fas fa-compass text-white text-xs"></i>
              </div>
              <span class="font-semibold text-gray-700 text-xs">选择部门</span>
            </div>
            <div class="flex gap-1.5 overflow-x-auto pb-0.5 -mx-0.5 px-0.5 mobile-dept-scroll">
              <div v-if="loadingDepts" class="flex-1 text-center py-2">
                <i class="fas fa-spinner fa-spin text-blue-600 text-xs"></i>
              </div>
              <button
                v-else
                v-for="dept in departments"
                :key="dept.id"
                @click="currentDept = dept.id"
                class="flex-shrink-0 px-2 py-1.5 rounded-lg text-[11px] font-medium transition-all whitespace-nowrap"
                :class="currentDept === dept.id
                  ? 'bg-blue-600 text-white shadow-sm'
                  : 'bg-gray-100 text-gray-600'"
              >
                <i :class="dept.icon" class="mr-1"></i>
                {{ dept.name }}
              </button>
            </div>
          </div>
        </div>

        <div class="flex flex-col lg:flex-row gap-4 md:gap-6">
          <!-- 左侧部门导航 (桌面端) -->
          <div class="w-full lg:w-64 flex-shrink-0 hidden lg:block">
            <div class="bg-white/80 backdrop-blur-sm rounded-2xl shadow-lg shadow-blue-900/5 border border-white sticky top-24 overflow-hidden">
              <div class="p-4 border-b border-gray-100/80 bg-gradient-to-r from-blue-50/50 to-transparent">
                <h3 class="font-semibold text-gray-700 flex items-center gap-2.5 text-base">
                  <div class="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
                    <i class="fas fa-compass text-white text-sm"></i>
                  </div>
                  部门导航
                </h3>
              </div>
              <div class="p-2 space-y-0.5">
                <div v-if="loadingDepts" class="py-6 text-center">
                  <i class="fas fa-spinner fa-spin text-blue-600"></i>
                  <span class="ml-2 text-sm text-gray-400">加载中...</span>
                </div>
                <div v-else-if="departments.length === 0" class="py-6 text-center text-gray-400 text-sm">
                  <i class="fas fa-folder-open text-2xl mb-2 block"></i>
                  暂无部门数据
                </div>
                <button
                  v-else
                  v-for="dept in departments"
                  :key="dept.id"
                  @click="currentDept = dept.id"
                  class="w-full text-left px-3 py-3 rounded-xl transition-all duration-300 flex items-center justify-between group relative"
                  :class="currentDept === dept.id
                    ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-md shadow-blue-500/25'
                    : 'text-gray-600 hover:bg-gray-50'"
                >
                  <div class="flex items-center gap-3">
                    <div
                      class="w-8 h-8 rounded-lg flex items-center justify-center transition-all duration-300 text-sm"
                      :class="currentDept === dept.id
                        ? 'bg-white/20 text-white'
                        : 'bg-gray-100 text-gray-400 group-hover:bg-blue-50 group-hover:text-blue-600'"
                    >
                      <i :class="dept.icon"></i>
                    </div>
                    <span class="font-medium text-sm">{{ dept.name }}</span>
                  </div>
                  <i class="fas fa-chevron-right text-xs transition-all duration-300"
                     :class="currentDept === dept.id
                       ? 'text-white/70'
                       : 'text-gray-300 opacity-0 group-hover:opacity-100'"></i>
                </button>
              </div>
            </div>
          </div>

          <!-- 右侧内容区域 -->
          <div class="flex-1 min-w-0 space-y-3 md:space-y-6">
            <!-- 岗位成长路线图 + 学习进度 -->
            <div class="flex md:grid md:grid-cols-3 gap-1.5 md:gap-4">
              <div class="flex-1 md:col-span-2 bg-white rounded-xl md:rounded-2xl p-2.5 md:p-6 shadow-sm border border-gray-100">
                <h3 class="font-semibold text-gray-700 mb-2 md:mb-5 flex items-center gap-1.5 md:gap-2 text-xs md:text-base">
                  <div class="w-[18px] h-[18px] md:w-8 md:h-8 rounded-md md:rounded-lg bg-orange-50 flex items-center justify-center">
                    <i class="fas fa-route text-orange-600 text-xs"></i>
                  </div>
                  岗位成长路线图
                </h3>
                <div class="relative h-14 md:h-24 flex items-center justify-between px-0.5 md:px-4">
                  <div class="absolute left-3 right-3 md:left-8 md:right-8 top-1/2 h-0.5 bg-gray-100 -translate-y-1/2"></div>
                  <div v-for="level in levels" :key="level.id"
                       class="relative z-10 flex flex-col items-center gap-1 md:gap-2 cursor-pointer transition-transform hover:scale-105"
                       @click="handleLevelClick(level.id)">
                    <div class="w-[22px] h-[22px] md:w-10 md:h-10 rounded-full flex items-center justify-center text-[11px] md:text-xs font-bold shadow-sm transition-colors duration-300"
                         :class="currentLevel === level.id ? 'bg-blue-600 text-white' : 'bg-white border-2 border-gray-200 text-gray-400 hover:border-blue-300 hover:text-blue-600'">
                      {{ level.id }}
                    </div>
                    <span class="text-[11px] md:text-xs transition-colors duration-300" :class="currentLevel === level.id ? 'font-bold text-blue-700' : 'text-gray-500'">{{ level.name }}</span>
                  </div>
                </div>
              </div>
              <div class="w-24 md:w-auto flex-shrink-0 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-xl md:rounded-2xl p-2.5 md:p-5 text-white shadow-lg relative overflow-hidden">
                <div class="absolute -bottom-6 -right-6 w-24 h-24 bg-white/10 rounded-full blur-2xl"></div>
                <div class="relative z-10">
                  <div class="flex items-center gap-1 md:gap-2 mb-1">
                    <i class="fas fa-chart-line text-blue-200 text-xs"></i>
                    <span class="text-white/80 text-xs font-medium hidden md:inline">当前学习进度</span>
                    <span class="text-white/80 text-xs font-medium md:hidden">进度</span>
                  </div>
                  <div class="text-xl md:text-4xl font-bold mb-0.5">0%</div>
                  <div class="text-blue-200/80 text-[11px] mb-1.5 md:mb-4 hidden md:block">开始你的学习之旅吧</div>
                  <button @click="goToOnlineTest" class="w-full py-1.5 md:py-2.5 bg-white text-blue-700 hover:bg-blue-50 rounded-lg md:rounded-xl text-[11px] md:text-xs font-semibold transition-all duration-300 shadow-sm hover:shadow-md">
                    <i class="fas fa-play mr-1"></i>
                    <span class="hidden md:inline">开始学习</span>
                    <span class="md:hidden">开始</span>
                  </button>
                </div>
              </div>
            </div>

            <!-- 快捷入口 - 移动端 -->
            <div class="md:hidden">
              <div class="flex gap-1.5 overflow-x-auto pb-0.5 -mx-1 px-1 mobile-quick-scroll">
                <button @click="goToOTACourses" class="flex-shrink-0 bg-white rounded-lg p-2 shadow-sm border border-gray-100 flex items-center gap-1.5 min-w-[108px]">
                  <div class="w-7 h-7 rounded-md bg-orange-50 flex items-center justify-center">
                    <i class="fas fa-graduation-cap text-sm text-orange-600"></i>
                  </div>
                  <div class="text-left">
                    <h4 class="font-semibold text-gray-700 text-xs">OTA课程</h4>
                    <p class="text-[11px] text-gray-400">平台运营</p>
                  </div>
                </button>
                <button @click="goToOnlineTest" class="flex-shrink-0 bg-white rounded-lg p-2 shadow-sm border border-gray-100 flex items-center gap-1.5 min-w-[108px]">
                  <div class="w-7 h-7 rounded-md bg-blue-50 flex items-center justify-center">
                    <i class="fas fa-edit text-sm text-blue-600"></i>
                  </div>
                  <div class="text-left">
                    <h4 class="font-semibold text-gray-700 text-xs">在线刷题</h4>
                    <p class="text-[11px] text-gray-400">专属题库</p>
                  </div>
                </button>
                <button @click="$router.push('/ranking')" class="flex-shrink-0 bg-white rounded-lg p-2 shadow-sm border border-gray-100 flex items-center gap-1.5 min-w-[108px]">
                  <div class="w-7 h-7 rounded-md bg-emerald-50 flex items-center justify-center">
                    <i class="fas fa-trophy text-sm text-emerald-500"></i>
                  </div>
                  <div class="text-left">
                    <h4 class="font-semibold text-gray-700 text-xs">学习排名</h4>
                    <p class="text-[11px] text-gray-400">排行榜</p>
                  </div>
                </button>
                <button @click="$router.push('/personal')" class="flex-shrink-0 bg-white rounded-lg p-2 shadow-sm border border-gray-100 flex items-center gap-1.5 min-w-[108px]">
                  <div class="w-7 h-7 rounded-md bg-gray-100 flex items-center justify-center">
                    <i class="fas fa-user text-sm text-gray-500"></i>
                  </div>
                  <div class="text-left">
                    <h4 class="font-semibold text-gray-700 text-xs">个人中心</h4>
                    <p class="text-[11px] text-gray-400">学习记录</p>
                  </div>
                </button>
              </div>
            </div>

            <!-- 快捷入口 - 桌面端 -->
            <div class="hidden md:flex gap-3">
              <button @click="goToOTACourses" class="flex-1 bg-white rounded-xl px-4 py-3 shadow-sm border border-gray-100 hover:shadow-md hover:border-orange-200 transition-all group flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-orange-50 flex items-center justify-center group-hover:bg-orange-100 transition-colors shrink-0">
                  <i class="fas fa-graduation-cap text-lg text-orange-600"></i>
                </div>
                <div class="text-left">
                  <h4 class="font-semibold text-gray-700 text-sm">OTA课程</h4>
                  <p class="text-xs text-gray-400">平台运营培训</p>
                </div>
              </button>
              <button @click="goToOnlineTest" class="flex-1 bg-white rounded-xl px-4 py-3 shadow-sm border border-gray-100 hover:shadow-md hover:border-blue-200 transition-all group flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center group-hover:bg-blue-100 transition-colors shrink-0">
                  <i class="fas fa-edit text-lg text-blue-600"></i>
                </div>
                <div class="text-left">
                  <h4 class="font-semibold text-gray-700 text-sm">在线刷题</h4>
                  <p class="text-xs text-gray-400">部门专属题库</p>
                </div>
              </button>
              <button @click="$router.push('/ranking')" class="flex-1 bg-white rounded-xl px-4 py-3 shadow-sm border border-gray-100 hover:shadow-md hover:border-emerald-200 transition-all group flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-emerald-50 flex items-center justify-center group-hover:bg-emerald-100 transition-colors shrink-0">
                  <i class="fas fa-trophy text-lg text-emerald-500"></i>
                </div>
                <div class="text-left">
                  <h4 class="font-semibold text-gray-700 text-sm">学习排名</h4>
                  <p class="text-xs text-gray-400">查看排行榜</p>
                </div>
              </button>
              <button @click="$router.push('/personal')" class="flex-1 bg-white rounded-xl px-4 py-3 shadow-sm border border-gray-100 hover:shadow-md hover:border-gray-200 transition-all group flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center group-hover:bg-gray-200 transition-colors shrink-0">
                  <i class="fas fa-user text-lg text-gray-500"></i>
                </div>
                <div class="text-left">
                  <h4 class="font-semibold text-gray-700 text-sm">个人中心</h4>
                  <p class="text-xs text-gray-400">学习记录</p>
                </div>
              </button>
            </div>

            <!-- 课程列表区域 -->
            <div class="space-y-2 md:space-y-4">
              <div class="flex items-center justify-between">
                <h3 class="font-semibold text-gray-700 text-sm md:text-lg flex items-center gap-1.5 md:gap-2">
                  <div class="w-6 h-6 md:w-8 md:h-8 rounded-md md:rounded-lg bg-blue-50 flex items-center justify-center">
                    <i class="fas fa-book text-blue-600 text-xs"></i>
                  </div>
                  推荐课程
                  <span v-if="filteredCourses.length" class="text-xs text-gray-400 font-normal">({{ filteredCourses.length }}门)</span>
                </h3>
                <div class="hidden md:flex gap-2">
                  <span class="px-3 py-1.5 bg-white border border-gray-200 rounded-full text-xs text-gray-400">最新发布</span>
                  <span class="px-3 py-1.5 bg-white border border-gray-200 rounded-full text-xs text-gray-400">最多学习</span>
                </div>
              </div>

              <div v-if="loading" class="bg-white rounded-xl md:rounded-2xl p-8 md:p-10 flex items-center justify-center">
                <i class="fas fa-spinner fa-spin text-xl md:text-2xl text-blue-600"></i>
                <span class="ml-3 text-gray-500 text-sm md:text-base">加载中...</span>
              </div>

              <div v-else-if="filteredCourses.length > 0" class="space-y-3 md:grid md:grid-cols-2 md:gap-4 md:space-y-0">
                <div v-for="course in filteredCourses" :key="course.courseId"
                     @click="goToCourseDetail(course)"
                     class="bg-white rounded-xl md:rounded-2xl p-3 md:p-4 shadow-sm border border-gray-100 hover:shadow-md transition-all cursor-pointer group">
                  <div class="flex gap-3 md:gap-4">
                    <div class="w-20 h-20 md:w-24 md:h-24 rounded-lg md:rounded-xl bg-gradient-to-br from-blue-100 to-indigo-100 flex-shrink-0 overflow-hidden">
                      <img v-if="course.coverImage" :src="course.coverImage" class="w-full h-full object-cover" />
                      <div v-else class="w-full h-full flex items-center justify-center">
                        <i class="fas fa-play-circle text-2xl md:text-3xl text-blue-400"></i>
                      </div>
                    </div>
                    <div class="flex-1 min-w-0 flex flex-col justify-center">
                      <div class="flex items-center gap-2 mb-1.5 md:mb-2">
                        <span class="px-1.5 py-0.5 md:px-2 bg-blue-50 text-blue-700 text-xs rounded-full font-medium">{{ course.level || 'L1' }}</span>
                        <span v-if="course.duration" class="text-xs text-gray-400">
                          <i class="fas fa-clock mr-1"></i>{{ course.duration }}分钟
                        </span>
                      </div>
                      <h4 class="font-semibold text-gray-700 text-sm md:text-base mb-1 truncate group-hover:text-blue-700 transition-colors">{{ course.courseName }}</h4>
                      <p class="text-xs text-gray-400 line-clamp-2 hidden md:block">{{ course.courseDescription }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <div v-else class="bg-white rounded-xl md:rounded-2xl border border-gray-100 p-8 md:p-12 flex flex-col items-center justify-center text-center">
                <div class="w-20 h-20 md:w-28 md:h-28 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-2xl md:rounded-3xl flex items-center justify-center mb-4 md:mb-6 relative shadow-sm border border-blue-100/50">
                  <i class="fas fa-folder-open text-3xl md:text-4xl text-blue-400"></i>
                  <div class="absolute -right-1.5 -bottom-1.5 md:-right-2 md:-bottom-2 w-8 h-8 md:w-10 md:h-10 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-lg md:rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/30">
                    <i class="fas fa-plus text-white text-xs md:text-sm"></i>
                  </div>
                </div>
                <h3 class="text-base md:text-lg font-bold text-gray-800 mb-2">知识库建设中</h3>
                <p class="text-gray-500 text-xs md:text-sm max-w-md">
                  {{ currentDeptInfo?.name || '该部门' }} 的专属培训课程正在编制中，敬请期待。
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>


<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import HeaderBar from '@/components/HeaderBar.vue'
import { api } from '@/utils/api'
import { startCourse } from '@/api/study'

const router = useRouter()

const goToOnlineTest = () => {
  router.push('/online')
}

const goToOTACourses = () => {
  router.push('/study')
}

const goToCourseDetail = async (course) => {
  const contentData = {
    id: course.courseId,
    title: course.courseName,
    content: course.knowledgePoints || course.courseDescription || '',
    category: course.deptType,
    deptType: course.deptType,
    duration: course.duration ? `${course.duration}分钟` : '标准时长',
    level: course.level || 'L1',
    videoApi: 'train/dept-course/video/play',
    courseType: 'dept'
  }
  try {
    await startCourse(course.courseId, course.courseName, {
      courseType: 'dept',
      courseMeta: contentData
    }).catch(() => {})
  } catch {
  }
  sessionStorage.setItem('currentKnowledgeContent', JSON.stringify(contentData))
  window.open('/knowledge-detail.html', '_blank')
}

const levels = [
  { id: 'L1', name: '入门' },
  { id: 'L2', name: '进阶' },
  { id: 'L3', name: '高级' },
  { id: 'L4', name: '专家' }
]

const deptIconMap = {
  '前台': 'fas fa-desktop',
  '前厅': 'fas fa-desktop',
  '接待': 'fas fa-id-card',
  '客房': 'fas fa-bed',
  '房务': 'fas fa-bed',
  '保卫': 'fas fa-shield-alt',
  '安保': 'fas fa-shield-alt',
  '保安': 'fas fa-shield-alt',
  '餐饮': 'fas fa-utensils',
  '餐厅': 'fas fa-utensils',
  '厨房': 'fas fa-utensils',
  '工程': 'fas fa-wrench',
  '维修': 'fas fa-tools',
  '人力': 'fas fa-users',
  '人事': 'fas fa-users',
  '行政': 'fas fa-briefcase',
  '财务': 'fas fa-calculator',
  '会计': 'fas fa-calculator',
  '销售': 'fas fa-chart-line',
  '市场': 'fas fa-bullhorn',
  '康乐': 'fas fa-futbol',
  '健身': 'fas fa-heartbeat',
  '宾客': 'fas fa-handshake',
  '客户': 'fas fa-handshake',
  '服务': 'fas fa-star',
  '管理': 'fas fa-sitemap',
  '经理': 'fas fa-user-tie'
}

const getDeptIcon = (deptType) => {
  for (const [key, icon] of Object.entries(deptIconMap)) {
    if (deptType && deptType.includes(key)) {
      return icon
    }
  }
  return 'fas fa-building'
}

const getDeptCode = (deptType) => {
  if (!deptType) return 'DP'
  const codeMap = {
    '前厅': 'FD', '前台': 'FD', '客房': 'HK', '保卫': 'SEC', '安保': 'SEC',
    '餐饮': 'FB', '工程': 'ENG', '人力': 'HR', '财务': 'FIN', '销售': 'SM',
    '康乐': 'REC', '宾客': 'GR', '管理': 'MGT'
  }
  for (const [key, code] of Object.entries(codeMap)) {
    if (deptType.includes(key)) return code
  }
  return deptType.substring(0, 2).toUpperCase()
}

const departments = ref([])
const currentDept = ref(null)
const courses = ref([])
const loading = ref(false)
const loadingDepts = ref(true)

const deptSortOrder = ['房务', '客房', '餐饮', '康乐', '保安', '安保', '保卫', '前厅', '前台', '工程', '人力', '财务', '销售']

const currentDeptInfo = computed(() => {
  return departments.value.find(d => d.id === currentDept.value)
})

const sortDepartments = (deptList) => {
  return deptList.sort((a, b) => {
    const getOrder = (name) => {
      for (let i = 0; i < deptSortOrder.length; i++) {
        if (name && name.includes(deptSortOrder[i])) return i
      }
      return 999
    }
    return getOrder(a.name) - getOrder(b.name)
  })
}

const loadDepartments = async () => {
  loadingDepts.value = true
  try {
    const courseRes = await api.get('/train/dept-course/dept-types').catch(() => ({ data: { data: [] } }))

    const deptList = []

    if (courseRes.data && courseRes.data.code === 200 && courseRes.data.data) {
      courseRes.data.data.forEach(deptType => {
        if (deptType) {
          deptList.push({
            id: `dept_${deptType}`,
            deptType: deptType,
            name: deptType,
            icon: getDeptIcon(deptType),
            code: getDeptCode(deptType),
            desc: `${deptType}相关的专业培训课程，提升岗位技能与服务水平。`,
            tags: ['专业技能', '服务规范', '岗位培训']
          })
        }
      })
    }

    departments.value = sortDepartments(deptList)
    if (departments.value.length > 0) {
      currentDept.value = departments.value[0].id
    }
  } catch (e) {
    logger.error('加载部门列表失败:', e)
  } finally {
    loadingDepts.value = false
  }
}

const currentLevel = ref('')

const handleLevelClick = (levelId) => {
  if (currentLevel.value === levelId) {
    currentLevel.value = ''
  } else {
    currentLevel.value = levelId
  }
}

const filteredCourses = computed(() => {
  if (!currentLevel.value) return courses.value
  return courses.value.filter(course => (course.level || 'L1') === currentLevel.value)
})

const loadCourses = async () => {
  if (!currentDeptInfo.value) return
  loading.value = true
  courses.value = []
  try {
    const res = await api.get('/train/dept-course/list-by-dept', {
      params: { deptType: currentDeptInfo.value.deptType }
    })
    if (res.data && res.data.code === 200) {
      courses.value = res.data.data || []
    }
  } catch (e) {
    logger.error('加载课程失败:', e)
  } finally {
    loading.value = false
  }
}

watch(currentDept, () => {
  loadCourses()
})

onMounted(() => {
  loadDepartments()
})
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.mobile-dept-scroll {
  -webkit-overflow-scrolling: touch;
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 transparent;
  touch-action: pan-x;
  padding-bottom: 6px;
}
.mobile-dept-scroll::-webkit-scrollbar {
  height: 4px;
}
.mobile-dept-scroll::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 2px;
}
.mobile-dept-scroll::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 2px;
}

.mobile-quick-scroll {
  -webkit-overflow-scrolling: touch;
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 transparent;
  touch-action: pan-x;
  padding-bottom: 6px;
}
.mobile-quick-scroll::-webkit-scrollbar {
  height: 4px;
}
.mobile-quick-scroll::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 2px;
}
.mobile-quick-scroll::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 2px;
}

@media (max-width: 767px) {
  .mobile-dept-scroll button,
  .mobile-quick-scroll button {
    min-height: 44px;
  }

  .mobile-quick-scroll {
    gap: 0.625rem;
  }

  .mobile-quick-scroll > button {
    min-width: 132px;
    align-items: flex-start;
  }

  .flex.md\:grid.md\:grid-cols-3.gap-1\.5.md\:gap-4 {
    flex-direction: column;
  }

  .space-y-3.md\:grid.md\:grid-cols-2.md\:gap-4.md\:space-y-0 > div {
    min-width: 0;
  }

  .space-y-3.md\:grid.md\:grid-cols-2.md\:gap-4.md\:space-y-0 .truncate {
    white-space: normal;
    overflow: visible;
    text-overflow: unset;
  }
}

@media (max-width: 420px) {
  .mobile-dept-scroll button {
    font-size: 12px !important;
  }

  .mobile-quick-scroll > button {
    min-width: 140px;
  }

  .space-y-3.md\:grid.md\:grid-cols-2.md\:gap-4.md\:space-y-0 .hidden.md\:block {
    display: block !important;
  }
}
</style>
