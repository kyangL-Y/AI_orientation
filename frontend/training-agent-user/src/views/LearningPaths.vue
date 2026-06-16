<template>
  <div class="min-h-screen bg-gradient-to-b from-neutral-50 to-neutral-100">
    <HeaderBar />
    <main class="container mx-auto px-4 pb-6 max-w-6xl main-content">
      <!-- 导航栏占位符 -->
      <div class="w-full h-[72px] md:h-[80px]"></div>

      <!-- 页面标题 -->
      <div class="mb-8 mt-2 md:mt-4">
        <!-- 统计看板 (Dashboard Style) -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-3 md:p-6 mb-4 md:mb-8 flex md:grid md:grid-cols-3 justify-around md:divide-x divide-slate-100">
          <!-- 我的路径 -->
          <div class="flex flex-col items-center md:flex-row md:items-center md:justify-between md:px-6 md:py-2 group cursor-default">
            <div class="text-center md:text-left">
              <div class="text-xs text-slate-500 mb-0.5 md:mb-1 md:text-sm md:font-medium">我的路径</div>
              <div class="flex items-baseline justify-center md:justify-start gap-1 md:gap-2">
                <span class="text-xl md:text-3xl font-bold text-slate-800">{{ myPathsCount }}</span>
                <span class="hidden md:inline text-xs text-slate-400 font-medium bg-slate-100 px-1.5 py-0.5 rounded">进行中</span>
              </div>
            </div>
            <div class="hidden md:flex w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 items-center justify-center group-hover:bg-emerald-600 group-hover:text-white transition-colors">
              <i class="fa fa-play text-sm"></i>
            </div>
          </div>

          <!-- 总计划 -->
          <div class="flex flex-col items-center md:flex-row md:items-center md:justify-between md:px-6 md:py-2 group cursor-default">
            <div class="text-center md:text-left">
              <div class="text-xs text-slate-500 mb-0.5 md:mb-1 md:text-sm md:font-medium">总任务数</div>
              <div class="flex items-baseline justify-center md:justify-start gap-1 md:gap-2">
                <span class="text-xl md:text-3xl font-bold text-slate-800">{{ totalPlansCount }}</span>
                <span class="hidden md:inline text-xs text-slate-400 font-medium">个计划</span>
              </div>
            </div>
            <div class="hidden md:flex w-10 h-10 rounded-full bg-blue-50 text-blue-600 items-center justify-center group-hover:bg-blue-600 group-hover:text-white transition-colors">
              <i class="fa fa-layer-group text-sm"></i>
            </div>
          </div>

          <!-- 平均进度 -->
          <div class="flex flex-col items-center md:flex-row md:items-center md:justify-between md:px-6 md:py-2 group cursor-default">
            <div class="text-center md:text-left">
              <div class="text-xs text-slate-500 mb-0.5 md:mb-1 md:text-sm md:font-medium">完成率</div>
              <div class="flex items-baseline justify-center md:justify-start gap-1 md:gap-2">
                <span class="text-xl md:text-3xl font-bold text-slate-800">{{ avgProgress }}<span class="text-sm md:text-lg">%</span></span>
              </div>
            </div>
            <div class="hidden md:flex w-10 h-10 rounded-full bg-indigo-50 text-indigo-600 items-center justify-center group-hover:bg-indigo-600 group-hover:text-white transition-colors">
              <i class="fa fa-chart-pie text-sm"></i>
            </div>
          </div>
        </div>

        <!-- 工具栏 (Toolbar) -->
        <div class="flex flex-col md:flex-row items-center justify-between gap-4 mb-6">
          <!-- 左侧：筛选 Tabs -->
          <div class="flex p-1 bg-slate-100 rounded-lg border border-slate-200">
            <button 
              v-for="opt in [{l:'', t:'全部'}, {l:'beginner', t:'初级'}, {l:'intermediate', t:'中级'}, {l:'advanced', t:'高级'}]"
              :key="opt.l"
              @click="difficultyFilter = opt.l; loadPaths()"
              class="px-4 py-1.5 text-sm font-medium rounded-md transition-all"
              :class="difficultyFilter === opt.l ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
            >
              {{ opt.t }}
            </button>
          </div>

          <!-- 右侧：搜索 -->
          <div class="flex items-center gap-3 w-full md:w-auto">
            <div class="relative group">
              <input 
                v-model="searchKeyword"
                type="text"
                placeholder="搜索路径..." 
                class="w-64 pl-9 pr-4 py-2 bg-white border border-slate-200 rounded-lg text-sm text-slate-700 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all"
              >
              <i class="fa fa-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-blue-500 text-xs"></i>
            </div>
            
            <button 
              @click="loadPaths" 
              class="px-3 py-2 bg-white border border-slate-200 rounded-lg text-slate-500 hover:text-blue-600 hover:border-blue-200 transition-colors"
            >
              <i class="fa fa-refresh" :class="{ 'fa-spin': loading }"></i>
            </button>
          </div>
        </div>
      </div>

      <!-- 加载状态 -->
      <div v-if="loading" class="text-center py-12">
        <i class="fa fa-spinner fa-spin text-4xl text-blue-500"></i>
        <p class="text-neutral-500 mt-4">加载中...</p>
      </div>

      <!-- 学习路径列表 -->
      <div v-else-if="filteredPaths.length > 0" class="grid grid-cols-1 gap-4">
        <div
          v-for="path in filteredPaths"
          :key="path.pathId"
          class="bg-white rounded-lg shadow-sm border border-slate-200 hover:shadow-md transition-all duration-200 overflow-hidden group"
          @click="viewPathDetail(path)"
        >
          <div class="flex flex-col md:flex-row">
            <!-- 左侧难度指示条 -->
            <div class="w-1.5 md:h-auto self-stretch"
              :class="{
                'bg-emerald-500': path.difficultyLevel === 'beginner',
                'bg-blue-500': path.difficultyLevel === 'intermediate' || !path.difficultyLevel,
                'bg-amber-500': path.difficultyLevel === 'advanced'
              }"
            ></div>

            <!-- 主内容区 -->
            <div class="flex-1 p-5">
              <div class="flex items-start justify-between mb-2">
                <div>
                  <div class="flex items-center gap-3 mb-1">
                    <h3 class="text-lg font-bold text-slate-800 group-hover:text-blue-600 transition-colors">
                      {{ path.pathName }}
                    </h3>
                    <span class="text-xs font-semibold px-2 py-0.5 rounded border"
                      :class="{
                        'bg-emerald-50 text-emerald-700 border-emerald-100': path.difficultyLevel === 'beginner',
                        'bg-blue-50 text-blue-700 border-blue-100': path.difficultyLevel === 'intermediate' || !path.difficultyLevel,
                        'bg-amber-50 text-amber-700 border-amber-100': path.difficultyLevel === 'advanced'
                      }"
                    >
                      {{ getDifficultyLabel(path.difficultyLevel) }}
                    </span>
                  </div>
                  <p class="text-sm text-slate-500 line-clamp-1">
                    {{ path.pathDescription || '暂无描述' }}
                  </p>
                </div>
                
                <!-- 进度环或百分比 -->
                <div v-if="path.userProgress !== undefined && path.userProgress > 0" class="flex items-center gap-2">
                  <span class="text-sm font-bold text-blue-600">{{ path.userProgress }}%</span>
                  <div class="w-16 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                    <div class="h-full bg-blue-600 rounded-full" :style="{ width: path.userProgress + '%' }"></div>
                  </div>
                </div>
              </div>

              <!-- 元数据行 -->
              <div class="flex items-center gap-4 text-xs text-slate-500 mt-4 pt-4 border-t border-slate-50">
                <div class="flex items-center gap-1.5">
                  <i class="fa fa-briefcase text-slate-400"></i>
                  <span>{{ path.targetRole || '通用角色' }}</span>
                </div>
                <div class="w-px h-3 bg-slate-200"></div>
                <div class="flex items-center gap-1.5">
                  <i class="fa fa-clock text-slate-400"></i>
                  <span>{{ path.estimatedDuration || 0 }} 天</span>
                </div>
                <div class="w-px h-3 bg-slate-200"></div>
                <div class="flex items-center gap-1.5">
                  <i class="fa fa-layer-group text-slate-400"></i>
                  <span>{{ path.planCount || 0 }} 个计划</span>
                </div>

                <div class="ml-auto flex items-center gap-2">
                  <button 
                    class="px-3 py-1.5 text-xs font-medium rounded border border-slate-200 hover:bg-slate-50 hover:text-blue-600 transition-colors"
                    @click.stop="togglePathPlans(path.pathId)"
                  >
                    {{ isPathExpanded(path.pathId) ? '收起详情' : '查看详情' }}
                    <i :class="isPathExpanded(path.pathId) ? 'fa fa-angle-up ml-1' : 'fa fa-angle-down ml-1'"></i>
                  </button>
                  <button 
                    class="px-3 py-1.5 text-xs font-medium rounded bg-slate-900 text-white hover:bg-slate-800 transition-colors"
                    @click.stop="startOrContinuePath(path)"
                  >
                    {{ path.userProgress > 0 ? '继续学习' : '开始学习' }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- 展开区域 -->
          <transition 
            enter-active-class="transition duration-200 ease-out"
            enter-from-class="transform opacity-0 -translate-y-2"
            enter-to-class="transform opacity-100 translate-y-0"
            leave-active-class="transition duration-150 ease-in"
            leave-from-class="transform opacity-100 translate-y-0"
            leave-to-class="transform opacity-0 -translate-y-2"
          >
            <div v-if="isPathExpanded(path.pathId)" class="bg-slate-50/50 border-t border-slate-100 p-4 md:pl-8 md:pr-4">
              <div v-if="path.plans && path.plans.length > 0" class="space-y-3">
                <div 
                  v-for="(plan, planIndex) in path.plans" 
                  :key="plan.planId || planIndex"
                  class="relative pl-6 pb-2 last:pb-0"
                >
                  <!-- Timeline 线 -->
                  <div class="absolute left-0 top-3 bottom-0 w-px bg-slate-200 last:bottom-auto last:h-full"></div>
                  <div class="absolute left-[-4px] top-3 w-2 h-2 rounded-full border-2 border-white"
                    :class="{
                      'bg-emerald-500': plan.status === 'completed',
                      'bg-blue-500': plan.status === 'active',
                      'bg-slate-300': !plan.status || plan.status === 'pending'
                    }"
                  ></div>

                  <!-- 计划卡片 -->
                  <div class="bg-white rounded border border-slate-200 p-3 hover:border-blue-300 transition-colors">
                    <div class="flex items-center justify-between mb-2">
                      <h4 class="text-sm font-semibold text-slate-800">{{ plan.title || plan.planName }}</h4>
                      <span class="text-[10px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-500">
                        {{ plan.status === 'completed' ? '已完成' : plan.status === 'active' ? '进行中' : '未开始' }}
                      </span>
                    </div>

                    <!-- 任务列表简略版 -->
                    <div class="space-y-1">
                      <div 
                        v-for="(item, itemIndex) in getDisplayedPlanItems(path.pathId, plan)" 
                        :key="itemIndex"
                        class="flex items-center gap-2 text-xs text-slate-600 hover:text-blue-600 cursor-pointer py-1"
                        @click.stop="handlePlanItemClick(item, plan)"
                      >
                        <i 
                          class="fa w-4 text-center"
                          :class="{
                            'fa-check-circle text-emerald-500': item.status === 'completed',
                            'fa-circle-o text-slate-300': !item.status || item.status === 'pending',
                            'fa-play-circle text-blue-500': item.status === 'active' || item.status === 'in_progress'
                          }"
                        ></i>
                        <span class="truncate flex-1" :class="{'line-through text-slate-400': item.status === 'completed'}">
                          {{ item.title || item.taskName }}
                        </span>
                        <span class="text-[10px] text-slate-400 border border-slate-100 px-1 rounded">
                          {{ getTaskTypeLabel(item.contentType) }}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div v-else class="text-center py-4 text-sm text-slate-400">
                暂无计划内容
              </div>
            </div>
          </transition>
        </div>
      </div>

      <!-- 空状态 -->
      <div v-else class="text-center py-12">
        <i class="fa fa-inbox text-6xl text-neutral-300 mb-4"></i>
        <p class="text-neutral-500 text-lg">暂无学习路径</p>
        <p class="text-neutral-400 text-sm mt-2">请联系管理员添加学习路径</p>
      </div>
    </main>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import HeaderBar from '@/components/HeaderBar.vue'
import { getTrainingPaths, getMyPaths, getTrainingPathDetail, getUserPathProgress, startTrainingPath } from '@/api/trainingPath'
import { api } from '@/utils/api'

export default {
  name: 'LearningPaths',
  components: {
    HeaderBar
  },
  data() {
    return {
      loading: false,
      pathList: [],
      searchKeyword: '',
      difficultyFilter: '',
      myPathsCount: 0,
      totalPlansCount: 0,
      avgProgress: 0,
      expandedPaths: {}, // 记录哪些路径展开了计划列表
      planTaskExpanded: {} // 记录计划任务是否展开
    }
  },
  computed: {
    filteredPaths() {
      let filtered = this.pathList

      // 搜索过滤
      if (this.searchKeyword) {
        const keyword = this.searchKeyword.toLowerCase()
        filtered = filtered.filter(path =>
          path.pathName.toLowerCase().includes(keyword) ||
          (path.pathDescription && path.pathDescription.toLowerCase().includes(keyword)) ||
          (path.targetRole && path.targetRole.toLowerCase().includes(keyword))
        )
      }

      // 难度过滤
      if (this.difficultyFilter) {
        filtered = filtered.filter(path => path.difficultyLevel === this.difficultyFilter)
      }

      return filtered
    }
  },
  created() {
    this.loadPaths()
  },
  methods: {
    /** 加载学习路径列表 */
    async loadPaths() {
      this.loading = true
      try {
        // 获取当前用户的学习路径（已分配的路径）
        const user = JSON.parse(localStorage.getItem('userInfo') || '{}')
        const userId = user.userId || user.id
        
        if (userId) {
          try {
            const myPathsResponse = await getMyPaths(userId)
            logger.debug('我的学习路径响应:', myPathsResponse)
            
            if (myPathsResponse.data && myPathsResponse.data.code === 200) {
              let paths = myPathsResponse.data.data || myPathsResponse.data.rows || []
              if (!Array.isArray(paths)) {
                paths = []
              }
              
              // 只显示分配给用户的学习路径，没有分配则不显示任何路径
              this.pathList = paths
              
              // 如果用户有分配的路径，加载详细信息和用户进度
              if (paths.length > 0) {
                // 为每个路径加载详细信息（包含计划）
                await this.loadPathDetails(paths)
                await this.loadUserProgress(userId)
              }
            } else {
              // API调用失败，清空列表
              this.pathList = []
            }
          } catch (myPathsError) {
            logger.error('获取我的学习路径失败:', myPathsError)
            // 获取失败，不显示任何路径
            this.pathList = []
          }
        } else {
          // 未登录用户，不显示任何路径
          this.pathList = []
        }

        // 计算统计数据
        this.calculateStats()
      } catch (error) {
        logger.error('加载学习路径失败:', error)
        this.$message.error('加载学习路径失败')
        // 确保pathList始终是数组
        this.pathList = []
      } finally {
        this.loading = false
      }
    },

    /** 加载路径详细信息（包含计划） */
    async loadPathDetails(paths) {
      // 并行加载所有路径的详细信息
      const detailPromises = paths.map(async (path) => {
        try {
          const response = await getTrainingPathDetail(path.pathId)
          logger.debug(`路径 ${path.pathId} 详情响应:`, response)
          if (response.data && response.data.code === 200) {
            const pathData = response.data.data || response.data
            // 合并详细信息到路径对象
            if (pathData.plans && Array.isArray(pathData.plans)) {
              path.plans = pathData.plans.map(plan => {
                const planObj = {
                  ...plan,
                  planItems: plan.planItems || []
                }
                const key = this.getPlanKey(path.pathId, planObj)
                if (this.planTaskExpanded[key] === undefined) {
                  this.planTaskExpanded[key] = false
                }
                return planObj
              })
              // 更新计划数量
              path.planCount = path.plans.length
              logger.debug(`路径 ${path.pathId} 加载了 ${path.plans.length} 个学习计划`)
            } else {
              path.plans = []
              path.planCount = 0
            }
          }
        } catch (error) {
          logger.warn(`加载路径 ${path.pathId} 详细信息失败:`, error)
          path.plans = []
        }
      })
      
      await Promise.all(detailPromises)
      
      // 加载完成后，默认保持收起状态
      this.expandedPaths = {}
    },

    /** 判断路径是否展开 */
    isPathExpanded(pathId) {
      // 默认收起，只有显式设置为 true 才展开
      return this.expandedPaths[pathId] === true
    },

    /** 切换路径计划列表展开/收起 */
    togglePathPlans(pathId) {
      // Vue 3 中直接赋值即可，无需 $set
      this.expandedPaths = {
        ...this.expandedPaths,
        [pathId]: !this.isPathExpanded(pathId)
      }
    },

    /** 处理计划任务点击 */
    async handlePlanItemClick(item, plan) {
      if (!item || !item.contentType) return

      if (item.contentType === 'course') {
        if (!item.contentId) {
          this.$message.warning('该课程缺少内容ID')
          return
        }
        try {
          const response = await api.get(`/train/course-category/${item.contentId}`)
          const course = response?.data?.data || response?.data
          if (!course) {
            this.$message.error('未找到课程详情')
            return
          }
          const courseData = {
            id: course.courseCategoryId || item.contentId,
            title: course.thirdLevelC || course.mainTitle || item.title || '课程详情',
            content: course.knowledgePoints || '暂无课程内容',
            category: course.mainTitle || '培训课程',
            subCategory: course.mainS || '',
            specificCategory: course.specificCategory || '',
            duration: '2小时',
            level: '中级',
            categoryPath: `${course.mainTitle || '培训中心'} / ${course.mainS || '课程学习'}`,
            videoApi: 'train/video/play',
            courseType: 'ota'
          }
          sessionStorage.setItem('currentKnowledgeContent', JSON.stringify(courseData))
          sessionStorage.setItem('knowledgeDetailReturnPath', window.location.href)
          window.open('/knowledge-detail.html', '_blank')
        } catch (error) {
          logger.error('加载课程详情失败:', error)
          this.$message.error('加载课程详情失败，请稍后重试')
        }
      } else if (item.contentType === 'quiz' || item.contentType === 'exam') {
        const planId = plan.planId || plan.id
        const itemId = item.itemId || item.id
        const examId = item.contentId
        if (!examId) {
          this.$message.warning('该考试缺少试卷ID')
          return
        }
        const params = new URLSearchParams()
        params.append('id', examId)
        if (planId) params.append('planId', planId)
        if (itemId) params.append('itemId', itemId)
        const targetUrl = `/online-exam/start?${params.toString()}`
        window.open(targetUrl, '_blank')
      } else {
        this.$message.info('暂不支持该任务类型的快捷预览')
      }
    },

    /** 获取计划任务显示列表 */
    getDisplayedPlanItems(pathId, plan) {
      if (!plan.planItems || plan.planItems.length === 0) return []
      return this.isPlanItemsExpanded(pathId, plan) ? plan.planItems : plan.planItems.slice(0, 3)
    },

    /** 生成计划任务唯一 key */
    getPlanKey(pathId, plan) {
      return `${pathId}-${plan.planId || plan.id || plan.title || 'temp'}`
    },

    /** 判断计划任务是否展开 */
    isPlanItemsExpanded(pathId, plan) {
      const key = this.getPlanKey(pathId, plan)
      return this.planTaskExpanded[key] === true
    },

    /** 切换计划任务列表展开状态 */
    togglePlanItems(pathId, plan) {
      const key = this.getPlanKey(pathId, plan)
      this.planTaskExpanded = {
        ...this.planTaskExpanded,
        [key]: !this.isPlanItemsExpanded(pathId, plan)
      }
    },
    
    /** 获取任务类型标签 */
    getTaskTypeLabel(type) {
      const typeMap = {
        'course': '课程',
        'quiz': '考试',
        'exam': '考试',
        'task': '任务',
        'assignment': '作业'
      }
      return typeMap[type] || '其他'
    },

    /** 格式化日期 */
    formatDate(date) {
      if (!date) return ''
      if (typeof date === 'string') {
        // 如果是字符串，直接返回或格式化
        if (date.includes('T')) {
          return date.split('T')[0]
        }
        return date
      }
      // 如果是Date对象或其他格式
      try {
        const d = new Date(date)
        return d.toISOString().split('T')[0]
      } catch (e) {
        return String(date)
      }
    },

    /** 加载用户学习进度 */
    async loadUserProgress(userId) {
      try {
        const response = await getUserPathProgress(userId)
        const userProgressMap = {}
        if (response.data && Array.isArray(response.data)) {
          response.data.forEach(item => {
            userProgressMap[item.pathId] = item.progress || 0
          })
        }

        // 将用户进度映射到路径列表
        this.pathList.forEach(path => {
          if (userProgressMap[path.pathId] !== undefined) {
            path.userProgress = userProgressMap[path.pathId]
          }
        })

        // 计算我的路径数量
        this.myPathsCount = Object.keys(userProgressMap).length
      } catch (error) {
        logger.error('加载用户进度失败:', error)
      }
    },

    /** 计算统计数据 */
    calculateStats() {
      // 计算总计划数
      this.totalPlansCount = this.pathList.reduce((sum, path) => sum + (path.planCount || 0), 0)

      // 计算平均进度
      const pathsWithProgress = this.pathList.filter(p => p.userProgress !== undefined)
      if (pathsWithProgress.length > 0) {
        const totalProgress = pathsWithProgress.reduce((sum, p) => sum + p.userProgress, 0)
        this.avgProgress = Math.round(totalProgress / pathsWithProgress.length)
      } else {
        this.avgProgress = 0
      }
    },

    /** 查看路径详情 */
    viewPathDetail(path) {
      this.$router.push({
        name: 'LearningPathDetail',
        params: { pathId: path.pathId }
      })
    },

    /** 开始学习路径 */
    async startPath(path) {
      try {
        const user = JSON.parse(localStorage.getItem('userInfo') || '{}')
        if (!user.userId) {
          this.$message.warning('请先登录')
          return
        }

        await startTrainingPath(path.pathId, user.userId)
        this.$message.success('已加入学习路径')
        this.loadPaths()
      } catch (error) {
        logger.error('加入路径失败:', error)
        this.$message.error('加入路径失败')
      }
    },

    /** 开始或继续学习路径 */
    async startOrContinuePath(path) {
      try {
        const user = JSON.parse(localStorage.getItem('userInfo') || '{}')
        const userId = user.userId || user.id
        
        if (!userId) {
          this.$message.warning('请先登录')
          return
        }

        // 从学习路径列表页，直接跳转到学习路径详情页
        this.$router.push({
          name: 'LearningPathDetail',
          params: { pathId: path.pathId }
        })
      } catch (error) {
        logger.error('操作失败:', error)
        this.$message.error('操作失败，请稍后重试')
      }
    },

    /** 获取难度类型 */
    getDifficultyType(level) {
      const typeMap = {
        'beginner': 'success',
        'intermediate': 'warning',
        'advanced': 'danger'
      }
      return typeMap[level] || 'info'
    },

    /** 获取难度标签 */
    getDifficultyLabel(level) {
      const labelMap = {
        'beginner': '初级',
        'intermediate': '中级',
        'advanced': '高级'
      }
      return labelMap[level] || '未知'
    }
  }
}
</script>

<style scoped>
.main-content {
  min-height: calc(100vh - 64px);
}

/* Shimmer 动画 */
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

/* autoprefixer-disable */
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  line-clamp: 1;
  -webkit-box-orient: vertical;
  box-orient: vertical;
  overflow: hidden;
}

/* autoprefixer-disable */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  box-orient: vertical;
  overflow: hidden;
}
/* autoprefixer-enable */

/* ========== 移动端优化样式 ========== */
@media (max-width: 768px) {
  /* 页面容器 */
  .main-content {
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
  }
  
  /* 导航栏占位符 */
  .w-full.h-\[56px\] {
    height: 56px !important;
  }
  
  /* 统计看板 - 移动端横向紧凑布局 */
  .grid.grid-cols-3 {
    padding: 0.75rem !important;
    gap: 0 !important;
  }
  
  .grid.grid-cols-3 > div {
    padding: 0.5rem 0.25rem !important;
  }
  
  .grid.grid-cols-3 .text-2xl {
    font-size: 1.25rem !important;
  }
  
  .grid.grid-cols-3 .text-xs {
    font-size: 0.65rem !important;
  }
  
  /* 筛选标签 - 横向滚动 */
  .flex.p-1.bg-slate-100 {
    overflow-x: auto !important;
    -webkit-overflow-scrolling: touch !important;
    touch-action: pan-x !important;
    scrollbar-width: none !important;
    flex-wrap: nowrap !important;
    padding: 0.25rem !important;
  }
  
  .flex.p-1.bg-slate-100::-webkit-scrollbar {
    display: none !important;
  }
  
  .flex.p-1.bg-slate-100 button {
    flex-shrink: 0 !important;
    padding: 0.375rem 0.75rem !important;
    font-size: 0.75rem !important;
    white-space: nowrap !important;
  }
  
  /* 搜索框 */
  .w-64 {
    width: 100% !important;
  }
  
  .flex.items-center.gap-3.w-full {
    width: 100% !important;
  }
  
  /* 路径卡片 */
  .bg-white.rounded-lg.shadow-sm.border {
    border-radius: 0.75rem !important;
  }
  
  .bg-white.rounded-lg.shadow-sm.border .p-5 {
    padding: 0.875rem !important;
  }
  
  /* 路径标题 */
  .text-lg.font-bold {
    font-size: 0.9375rem !important;
  }
  
  /* 路径描述 */
  .text-sm.text-slate-500 {
    font-size: 0.75rem !important;
  }
  
  /* 元数据行 - 移动端简化 */
  .flex.items-center.gap-4.text-xs {
    flex-wrap: wrap !important;
    gap: 0.5rem !important;
    font-size: 0.625rem !important;
  }
  
  .flex.items-center.gap-4.text-xs .w-px {
    display: none !important;
  }
  
  /* 操作按钮 - 移动端堆叠 */
  .ml-auto.flex.items-center.gap-2 {
    width: 100% !important;
    margin-left: 0 !important;
    margin-top: 0.75rem !important;
    justify-content: flex-end !important;
  }
  
  .ml-auto.flex.items-center.gap-2 button {
    padding: 0.375rem 0.625rem !important;
    font-size: 0.6875rem !important;
  }
  
  /* 展开区域 */
  .bg-slate-50\/50.border-t {
    padding: 0.75rem !important;
  }
  
  /* 计划卡片 */
  .bg-white.rounded.border.border-slate-200.p-3 {
    padding: 0.625rem !important;
  }
  
  .bg-white.rounded.border.border-slate-200.p-3 h4 {
    font-size: 0.8125rem !important;
  }
  
  /* 任务列表项 */
  .flex.items-center.gap-2.text-xs {
    font-size: 0.6875rem !important;
    padding: 0.375rem 0 !important;
  }
  
  /* 进度条 */
  .w-16.h-1\.5 {
    width: 3rem !important;
  }
  
  /* 难度标签 */
  .text-xs.font-semibold.px-2.py-0\.5 {
    font-size: 0.625rem !important;
    padding: 0.125rem 0.375rem !important;
  }
  
  /* 空状态 */
  .text-center.py-12 {
    padding: 2rem 1rem !important;
  }
  
  .text-center.py-12 .text-6xl {
    font-size: 3rem !important;
  }
  
  .text-center.py-12 .text-lg {
    font-size: 0.9375rem !important;
  }
}

/* 超小屏幕优化 (< 375px) */
@media (max-width: 375px) {
  .grid.grid-cols-3 .text-2xl {
    font-size: 1rem !important;
  }
  
  .text-lg.font-bold {
    font-size: 0.875rem !important;
  }
  
  .ml-auto.flex.items-center.gap-2 button {
    padding: 0.25rem 0.5rem !important;
    font-size: 0.625rem !important;
  }
}
</style>


