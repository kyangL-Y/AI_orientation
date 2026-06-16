<template>
  <div class="study-page">
    <!-- 导航栏占位符 -->
    <div class="h-[56px] md:h-[72px]"></div>
    
    <!-- 顶部 Banner -->
    <div class="banner-section">
      <div class="banner-content">
        <div class="banner-left">
          <div class="banner-icon-box">
             <el-icon><Reading /></el-icon>
          </div>
          <div class="banner-text">
            <h2>开启您的酒店职业成长之旅</h2>
            <p>汇集全方位专业课程，助您轻松卓越进阶</p>
          </div>
        </div>
        <div class="banner-right">
          <div class="user-welcome" v-if="userInfo">
            <span class="user-name">{{ userInfo.nickName || userInfo.userName }}</span>
            <span class="welcome-text">欢迎回来</span>
          </div>
          <div class="user-avatar-box">
            <el-icon><UserFilled /></el-icon>
          </div>
        </div>
      </div>
    </div>

    <div class="main-container">
      <!-- 学习仪表盘 -->
      <StudyDashboard data-guide="study-dashboard" class="mb-4" @filter-level="handleLevelFilter" />

      <!-- 难度筛选区域 -->
      <div class="difficulty-filter-section mb-4">
        <div class="difficulty-tabs">
          <div 
            v-for="level in difficultyOptions" 
            :key="level.value"
            class="difficulty-tab"
            :class="{ active: difficultyLevel === level.value }"
            @click="changeDifficulty(level.value)"
          >
            {{ level.label }}
          </div>
        </div>
      </div>

      <!-- 继续学习区域 -->
      <div class="continue-learning-section">
        <h3 class="section-header">继续学习</h3>
        <div v-if="continueLearningItems.length" class="continue-learning-list">
          <div
            v-for="item in continueLearningItems"
            :key="item.id"
            class="continue-learning-card"
            @click="resumeLearning(item)"
          >
            <div class="continue-learning-icon">
              <el-icon><Notebook /></el-icon>
            </div>
            <div class="continue-learning-info">
              <div class="continue-learning-title">{{ item.courseName }}</div>
              <div class="continue-learning-meta">
                <span>{{ item.statusLabel }}</span>
                <span v-if="item.updatedText">{{ item.updatedText }}</span>
              </div>
              <el-progress
                :percentage="item.progress"
                :show-text="false"
                :stroke-width="6"
                class="continue-learning-progress"
              />
            </div>
            <button class="go-course-btn continue-learning-action" @click.stop="resumeLearning(item)">
              {{ item.progress >= 100 ? '复习' : '继续' }}
            </button>
          </div>
        </div>
        <div v-else class="empty-learning-record">
          <div class="empty-learning-icon">
            <div class="book-icon">
              <el-icon><Notebook /></el-icon>
            </div>
          </div>
          <div class="empty-learning-copy">
            <div class="empty-text">暂无学习记录</div>
            <div class="empty-subtext">开始学习课程，系统会自动记录您的学习进度</div>
          </div>
          <button class="go-course-btn empty-learning-action" @click="scrollToCourses">去选课</button>
        </div>
      </div>

      <div class="training-hub-section mb-4">
        <div class="training-hub-header">
          <h3 class="section-header">岗位培训中心</h3>
          <span>专项能力入口</span>
        </div>
        <div class="training-hub-grid">
          <button class="training-hub-card green" @click="goToGreenHotel">
            <div class="hub-icon">
              <el-icon><Notebook /></el-icon>
            </div>
            <div class="hub-content">
              <h4>绿色饭店</h4>
              <p>聚焦低碳运营、节能降耗与环保服务标准。</p>
            </div>
            <el-icon class="hub-arrow"><ArrowRight /></el-icon>
          </button>
          <button class="training-hub-card workshop" @click="goToDepartmentTraining">
            <div class="hub-icon">
              <el-icon><Folder /></el-icon>
            </div>
            <div class="hub-content">
              <h4>技能工坊</h4>
              <p>按岗位拆解专题课程，快速提升实操能力。</p>
            </div>
            <el-icon class="hub-arrow"><ArrowRight /></el-icon>
          </button>
        </div>
      </div>

      <!-- 主要内容区：侧边栏 + 课程列表 -->
      <div class="content-wrapper" id="course-section" data-guide="study-course-section">
        <!-- 左侧平台侧边栏 -->
        <div class="platform-sidebar" data-guide="study-platform-sidebar">
          <div 
            v-for="category in categories" 
            :key="category.id"
            class="platform-item"
            :class="{ active: selectedCategory === category.id }"
            @click="selectCategory(category.id)"
          >
            <div class="platform-icon-wrapper" :class="{ 'active-icon': selectedCategory === category.id }">
               <img v-if="category.img" :src="category.img" class="platform-img" />
               <el-icon v-else :style="{ color: selectedCategory === category.id ? 'white' : category.color }">
                 <component :is="category.icon" />
               </el-icon>
            </div>
            <span class="platform-name">{{ category.name }}</span>
          </div>
        </div>

        <!-- 右侧课程内容 -->
        <div class="course-content-area">
          
          <!-- 分组展示视图 (按 main_title 分组，展示 main_s 卡片) -->
          <div v-if="groupedCourses.length > 0" class="grouped-view">
             <div 
               v-for="(group, groupIndex) in groupedCourses" 
               :key="group.title"
               class="course-group-section"
             >
               <div class="group-title-line mb-4">
                  <span class="blue-bar"></span>
                  <span class="group-title">{{ group.title }}</span>
               </div>
               
               <div class="course-cards-row">
                   <div 
                     v-for="(sub, subIndex) in group.items" 
                     :key="sub.title"
                     class="simple-course-card"
                     :data-guide="groupIndex === 0 && subIndex === 0 ? 'study-first-course' : null"
                     @click="viewCourses(group.title, sub.title)"
                   >
                     <div class="card-main">
                       <div class="card-title-row flex items-center gap-2 mb-2">
                          <span class="card-title font-bold text-lg">{{ sub.title }}</span>
                          <span 
                            class="level-tag text-xs px-2 py-0.5 rounded" 
                            :class="sub.level.includes('进阶') ? 'is-advance' : 'is-basic'"
                            v-if="sub.level"
                          >
                            {{ sub.level }}
                          </span>
                       </div>
                       <div class="card-sub text-gray-500 text-sm line-clamp-2">{{ sub.subtitle }}</div>
                     </div>
                     <el-icon class="text-gray-400"><ArrowRight /></el-icon>
                   </div>
               </div>
             </div>
          </div>
          
          <!-- 空状态 -->
          <div v-else-if="!loading" class="empty-state py-10 text-center text-gray-400">
            暂无课程数据
          </div>

          <!-- 加载中状态 -->
          <div v-else class="loading-state py-20 text-center">
            <el-icon class="is-loading text-4xl text-blue-500"><Loading /></el-icon>
            <p class="mt-4 text-gray-500">正在获取课程信息...</p>
          </div>

        </div>
      </div>
    </div>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import StudyDashboard from '@/components/StudyDashboard.vue'
import { getCourseCategoryListByPlatform, getCourseCategoryList, getCourseProgressList } from '@/api/study'
import { 
  Reading, 
  UserFilled, 
  ArrowDown, 
  InfoFilled, 
  Notebook, 
  StarFilled, 
  ArrowRight,
  ArrowLeft,
  User,
  Clock,
  Folder,
  Loading
} from '@element-plus/icons-vue'

export default {
  name: 'Study',
  components: {
    StudyDashboard,
    Reading,
    UserFilled,
    ArrowDown,
    InfoFilled,
    Notebook,
    StarFilled,
    ArrowRight,
    ArrowLeft,
    User,
    Clock,
    Folder,
    Loading
  },
  data() {
    return {
      selectedCategory: '美团',
      selectedSubCategory: 'all',
      searchKeyword: '',
      userInfo: null,
      activeGroupTitle: null, // 当前选中的一级分类标题
      difficultyLevel: 'all',
      difficultyOptions: [
        { label: '全部', value: 'all' },
        { label: '基础', value: 'basic' },
        { label: '进阶', value: 'advance' },
        { label: '高阶', value: 'high' }
      ],
      levelMapping: {
        'basic': '基础',
        'advance': '进阶',
        'high': '高阶'
      },
      categories: [
        { id: '美团', name: '美团', img: '/meituan.png', color: '#FFD100' },
        { id: '携程', name: '携程', img: '/ctrip.png', color: '#0086F6' },
        { id: '飞猪', name: '飞猪', img: '/fliggy.png', color: '#FF6A00' },
        { id: '独家', name: '独家', icon: 'StarFilled', color: '#722ED1' }
      ],
      subCategories: [],
      courses: [],
      filteredCourses: [],
      groupedCourses: [],
      continueLearningItems: [],
      loading: false
    }
  },
  computed: {
    currentActiveGroup() {
      return this.groupedCourses.find(g => g.title === this.activeGroupTitle)
    }
  },
  mounted() {
    this.loadUserInfo()
    this.loadCourses()
    this.loadContinueLearning()
  },
  methods: {
    loadUserInfo() {
      try {
        const storedUserInfo = localStorage.getItem('userInfo')
        if (storedUserInfo) {
          this.userInfo = JSON.parse(storedUserInfo)
        }
      } catch (e) {
        logger.error('Failed to load user info', e)
      }
    },
    selectCategory(categoryId) {
      this.selectedCategory = categoryId
      this.loadCourses()
    },
    handleCommand(command) {
      if (command === 'all') {
        // Handle all
      } else {
        this.selectCategory(command)
      }
    },
    scrollToCourses() {
      const element = document.getElementById('course-section');
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    },
    goToGreenHotel() {
      this.$router.push('/green-hotel')
    },
    goToDepartmentTraining() {
      this.$router.push('/department-training')
    },
    async loadContinueLearning() {
      try {
        const response = await getCourseProgressList()
        const progressRows = response?.data?.data || response?.data?.rows || []
        this.continueLearningItems = Array.isArray(progressRows)
          ? progressRows
              .filter(item => item.courseId && item.courseName)
              .map(this.normalizeContinueLearningItem)
              .slice(0, 3)
          : []
      } catch (error) {
        logger.error('加载继续学习记录失败:', error)
        this.continueLearningItems = []
      }
    },
    normalizeContinueLearningItem(item) {
      const progress = Math.max(0, Math.min(100, Number(item.progress || 0)))
      const courseMeta = this.parseCourseMeta(item.courseMeta)
      return {
        id: item.id || item.courseId,
        courseId: item.courseId,
        courseName: item.courseName,
        courseType: item.courseType || courseMeta.courseType || 'ota',
        courseMeta,
        progress,
        status: item.status || (progress >= 100 ? 'completed' : 'in_progress'),
        statusLabel: progress >= 100 || item.status === 'completed' ? '已完成' : `已学 ${progress}%`,
        updatedText: this.formatLearningTime(item.updateTime || item.startedAt)
      }
    },
    parseCourseMeta(rawMeta) {
      if (!rawMeta) return {}
      if (typeof rawMeta === 'object') return rawMeta
      try {
        const parsed = JSON.parse(rawMeta)
        return parsed && typeof parsed === 'object' ? parsed : {}
      } catch (error) {
        logger.warn('课程进度上下文解析失败:', error)
        return {}
      }
    },
    formatLearningTime(value) {
      if (!value) return ''
      const date = new Date(value)
      if (Number.isNaN(date.getTime())) return ''
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      return `${month}-${day} 更新`
    },
    resumeLearning(item) {
      if (item.courseMeta && item.courseMeta.id) {
        sessionStorage.setItem('currentKnowledgeContent', JSON.stringify({
          ...item.courseMeta,
          id: item.courseMeta.id || item.courseId,
          title: item.courseMeta.title || item.courseName,
          courseType: item.courseType
        }))
        sessionStorage.setItem('knowledgeDetailReturnPath', window.location.href)
        window.open('/knowledge-detail.html', '_blank')
        return
      }
      const matchedCourse = this.courses.find(course => String(course.id) === String(item.courseId))
      if (matchedCourse) {
        this.viewCourse(matchedCourse)
        return
      }
      this.scrollToCourses()
    },
    async loadCourses() {
      this.loading = true
      this.groupedCourses = []
      this.filteredCourses = [] // 重置过滤后的列表，防止闪烁旧数据
      this.activeGroupTitle = null // 重置选中状态
      try {
        logger.debug('🔍 [Study] 正在加载平台课程:', this.selectedCategory)
        const platformResponse = await getCourseCategoryListByPlatform(this.selectedCategory, {
          keyword: this.searchKeyword
        })
        const platformCourseRows = this.extractCourseRows(platformResponse)

        let courseData = platformCourseRows
        if (!courseData.length) {
          logger.debug('🔍 [Study] 当前平台无数据，尝试加载全量课程列表')
          const allResponse = await getCourseCategoryList({
            keyword: this.searchKeyword
          })
          const allCourseRows = this.extractCourseRows(allResponse)
          const availableRows = allCourseRows.filter(item => this.getCoursePlatformName(item))
          const preferredPlatform = this.resolvePreferredPlatform(availableRows)

          if (preferredPlatform) {
            const preferredRows = allCourseRows.filter(item => this.getCoursePlatformName(item) === preferredPlatform)
            if (preferredRows.length) {
              this.selectedCategory = preferredPlatform
              courseData = preferredRows
              logger.debug('🔍 [Study] 已切换到有数据的平台:', preferredPlatform, preferredRows.length, '条')
            } else if (allCourseRows.length) {
              courseData = allCourseRows
            }
          } else if (allCourseRows.length) {
            courseData = allCourseRows
          }
        }

        logger.debug('🔍 [Study] 获取到课程数据:', courseData.length, '条')
        if (courseData.length > 0) {
          logger.debug('🔍 [Study] 第一条数据样例:', JSON.stringify(courseData[0], null, 2))
        }

        this.applyCourseRows(courseData)
        logger.debug(`✅ 加载${this.selectedCategory}课程成功:`, this.courses.length, '门课程', '分组:', this.groupedCourses.length)
      } catch (error) {
        logger.error('加载课程失败:', error)
        this.courses = []
        this.groupedCourses = []
        this.filteredCourses = []
        this.subCategories = []
      } finally {
        this.loading = false
      }
    },
    extractCourseRows(response) {
      const payload = response?.data || {}
      return Array.isArray(payload.data) ? payload.data : Array.isArray(payload.rows) ? payload.rows : []
    },
    getCoursePlatformName(courseRow) {
      return String(courseRow?.platform || courseRow?.platformName || courseRow?.main_title || courseRow?.mainTitle || '').trim()
    },
    resolvePreferredPlatform(courseRows) {
      if (!Array.isArray(courseRows) || !courseRows.length) {
        return ''
      }
      const platformSet = new Set(courseRows.map(row => this.getCoursePlatformName(row)).filter(Boolean))
      if (platformSet.has(this.selectedCategory)) {
        return this.selectedCategory
      }
      for (const category of this.categories) {
        if (platformSet.has(category.id)) {
          return category.id
        }
      }
      return Array.from(platformSet)[0] || ''
    },
    applyCourseRows(courseRows) {
      const normalizedRows = Array.isArray(courseRows) ? courseRows : []
      this.courses = normalizedRows.map(item => {
        let level = String(item.level || '').toLowerCase()
        if (level === '进阶' || level === 'advance') level = 'advance'
        else if (level === '高阶' || level === 'high' || level === 'expert') level = 'high'
        else level = 'basic'

        return {
          id: item.course_category_id || item.courseCategoryId || item.id,
          title: item.third_level_c || item.thirdLevelC || item.main_title || item.mainTitle || item.name,
          description: item.knowledge_points || item.knowledgePoints || `${item.main_title || item.mainTitle || ''}课程内容`,
          category: item.main_title || item.mainTitle || this.getCoursePlatformName(item) || this.selectedCategory,
          main_title: item.main_title || item.mainTitle,
          main_s: item.main_s || item.mainS,
          specific_category: item.specific_category || item.specificCategory,
          duration: item.duration || '2小时',
          level,
          students: item.student_count || item.studentCount || 0,
          cover: item.cover_image || item.coverImage || ''
        }
      })

      const subCategorySet = new Set()
      normalizedRows.forEach(item => {
        const mainS = item.main_s || item.mainS
        if (mainS) {
          subCategorySet.add(mainS)
        }
      })
      this.subCategories = Array.from(subCategorySet).map(name => ({
        label: name,
        value: name
      }))

      this.processGroupedCourses()
    },
    changeDifficulty(level) {
      this.difficultyLevel = level;
      this.processGroupedCourses();
    },
    processGroupedCourses() {
      // 1. 根据难度筛选
      this.filteredCourses = this.difficultyLevel === 'all' 
         ? this.courses 
         : this.courses.filter(c => c.level === this.difficultyLevel);

      // 2. 处理分组逻辑 (main_title -> main_s)
      const groups = {}
      this.filteredCourses.forEach(course => {
        if (!course.main_title) return
        
        if (!groups[course.main_title]) {
          groups[course.main_title] = {
            title: course.main_title,
            subGroups: {} // main_s -> { title, subtitles: Set, levels: Set }
          }
        }
        
        const mainS = course.main_s || '其他'
        if (!groups[course.main_title].subGroups[mainS]) {
          groups[course.main_title].subGroups[mainS] = {
            title: mainS,
            subtitles: new Set(),
            levels: new Set()
          }
        }
        
        if (course.specific_category) {
          groups[course.main_title].subGroups[mainS].subtitles.add(course.specific_category)
        }
        if (course.level) {
          groups[course.main_title].subGroups[mainS].levels.add(course.level)
        }
      })

      // 3. 转换为数组格式
      this.groupedCourses = Object.values(groups).map(group => {
        const items = Object.values(group.subGroups).map(sub => {
          // 将英文难度映射为中文显示
          const levelLabels = Array.from(sub.levels).map(l => this.levelMapping[l] || l);
          
          return {
            title: sub.title,
            subtitle: Array.from(sub.subtitles).join(' / ') || '查看详情',
            level: levelLabels.join('/') // 显示难度等级中文
          }
        })
        return {
          title: group.title,
          items: items
        }
      })
    },
    viewCourses(mainTitle, mainS) {
      const query = { 
        platform: this.selectedCategory,
        main: mainTitle,
        sub: mainS,
        level: this.difficultyLevel // 始终传递当前选中的难度，包括 'all'
      }
      
      this.$router.push({
        path: '/category-courses',
        query: query
      })
    },
    viewCourse(course) {
      this.$router.push({
        path: '/category-courses',
        query: { 
          platform: this.selectedCategory,
          courseId: course.id 
        }
      })
    },
    handleLevelFilter(difficulty) {
      logger.debug('Received level filter:', difficulty);
      this.difficultyLevel = difficulty;
      this.processGroupedCourses();
      this.scrollToCourses();
    }
  }
}
</script>

<style scoped>
.study-page {
  min-height: 100vh;
  background-color: #f5f7fa;
}

/* 顶部横幅 */
.banner-section {
  background: linear-gradient(120deg, #2563eb 0%, #1d4ed8 100%);
  padding: 1.75rem 2rem;
  margin: 1rem auto 1.25rem;
  max-width: 1200px;
  border-radius: 24px;
  color: white;
  box-shadow: 0 20px 40px -12px rgba(37, 99, 235, 0.3);
  position: relative;
  overflow: hidden;
}

.banner-section::before {
  content: "";
  position: absolute;
  top: -50%;
  right: -10%;
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0) 70%);
  border-radius: 50%;
  pointer-events: none;
}

.banner-section::after {
  content: "";
  position: absolute;
  bottom: -20%;
  left: 10%;
  width: 200px;
  height: 200px;
  background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, rgba(255,255,255,0) 60%);
  border-radius: 50%;
  pointer-events: none;
}

.banner-content {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.banner-left {
  display: flex;
  align-items: center;
  gap: 1rem;
  min-width: 0;
}

.banner-icon-box {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  width: 72px;
  height: 72px;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
}

.banner-icon-box i {
  font-size: 2.5rem;
  color: white;
}

.banner-text h2 {
  font-size: 1.75rem;
  font-weight: 800;
  margin: 0 0 0.5rem 0;
  letter-spacing: -0.02em;
  text-shadow: 0 2px 4px rgba(0,0,0,0.1);
  line-height: 1.35;
}

.banner-text p {
  font-size: 1rem;
  opacity: 0.9;
  margin: 0;
  font-weight: 500;
  line-height: 1.6;
}

.banner-text {
  min-width: 0;
}

.banner-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.user-welcome {
  text-align: right;
}

.user-name {
  display: block;
  font-weight: 600;
  font-size: 1rem;
}

.welcome-text {
  font-size: 0.8rem;
  opacity: 0.8;
}

.user-avatar-box {
  width: 48px;
  height: 48px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
}

/* 主容器 */
.main-container {
  max-width: 1200px;
  margin: 0 auto; /* 取消负边距，避免重叠导致布局差异 */
  padding: 1rem 1rem 1.5rem;
  position: relative;
  z-index: 10;
}

/* 筛选栏 */
.filter-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  padding: 0 0.5rem;
}

.el-dropdown-link {
  cursor: pointer;
  color: #303133;
  font-weight: 600;
  font-size: 1rem;
}

.filter-tip {
  font-size: 0.85rem;
  color: #909399;
  margin-left: 0.5rem;
}

/* 继续学习区域 */
.continue-learning-section {
  background: white;
  border-radius: 12px;
  padding: 0.7rem 0.9rem;
  margin-bottom: 0.85rem;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
}

.section-header {
  font-size: 1rem;
  font-weight: 600;
  color: #303133;
  margin-bottom: 0.5rem;
}

.continue-learning-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 0.75rem;
}

.continue-learning-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  border: 1px solid #eef2f7;
  border-radius: 12px;
  background: linear-gradient(135deg, #f8fbff, #ffffff);
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
}

.continue-learning-card:hover {
  border-color: #bfdbfe;
  box-shadow: 0 8px 18px rgba(59, 130, 246, 0.08);
  transform: translateY(-1px);
}

.continue-learning-icon {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #2563eb;
  background: #eff6ff;
}

.continue-learning-info {
  flex: 1;
  min-width: 0;
}

.continue-learning-title {
  font-size: 0.86rem;
  font-weight: 700;
  color: #1f2937;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.continue-learning-meta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.15rem;
  font-size: 0.68rem;
  color: #6b7280;
}

.continue-learning-progress {
  margin-top: 0.45rem;
}

.continue-learning-action {
  flex-shrink: 0;
  padding: 0.28rem 0.8rem;
  box-shadow: none;
}

.empty-learning-record {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0.25rem 0 0.5rem;
}

.empty-learning-icon {
  display: flex;
  align-items: center;
  justify-content: center;
}

.empty-learning-copy {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.book-icon {
  font-size: 1.5rem;
  color: #409eff;
  margin-bottom: 0.25rem;
}

.empty-text {
  font-size: 0.9rem;
  font-weight: 600;
  color: #303133;
  margin-bottom: 0.15rem;
}

.empty-subtext {
  color: #909399;
  font-size: 0.75rem;
  margin-bottom: 0.75rem;
}

.go-course-btn {
  background: #409eff;
  color: white;
  border: none;
  padding: 0.3rem 1.5rem;
  border-radius: 20px;
  font-size: 0.8rem;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 4px 10px rgba(64, 158, 255, 0.3);
}

.go-course-btn:hover {
  background: #66b1ff;
  transform: translateY(-2px);
}

.training-hub-section {
  background: #fffdf8;
  border-radius: 12px;
  padding: 0.85rem 0.9rem;
  margin-bottom: 0.85rem;
  box-shadow: 0 2px 12px rgba(57, 75, 63, 0.08);
  border: 1px solid #e7ece1;
}

.training-hub-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 0.75rem;
}

.training-hub-header span {
  font-size: 0.8rem;
  color: #6f7f74;
}

.training-hub-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.75rem;
}

.training-hub-card {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  width: 100%;
  border: 1px solid transparent;
  border-radius: 12px;
  padding: 0.9rem;
  cursor: pointer;
  text-align: left;
  background: #f4f8ef;
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
}

.training-hub-card.green {
  background: linear-gradient(135deg, #edf7ee, #e3f1e2);
  border-color: #c9dfc9;
}

.training-hub-card.workshop {
  background: linear-gradient(135deg, #faf6f1, #f5efe8);
  border-color: #e8dfd4;
}

.training-hub-card.workshop .hub-icon {
  background: #8b7355;
}

.training-hub-card.workshop .hub-content h4 {
  color: #5c4a3a;
}

.training-hub-card.workshop .hub-content p {
  color: #7a6b5c;
}

.training-hub-card.workshop .hub-arrow {
  color: #7a6b5c;
}

.training-hub-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(54, 79, 64, 0.12);
}

.hub-icon {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  background: #3f7d5f;
}

.hub-content {
  flex: 1;
}

.hub-content h4 {
  margin: 0;
  font-size: 0.95rem;
  color: #2e4537;
}

.hub-content p {
  margin: 0.2rem 0 0;
  font-size: 0.78rem;
  line-height: 1.4;
  color: #5f7366;
}

.hub-arrow {
  color: #5f7366;
}

/* 主要内容区布局 */
.content-wrapper {
  display: flex;
  gap: 1rem;
  background: white;
  border-radius: 12px;
  padding: 1rem;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
}

/* 左侧边栏美化 */
.platform-sidebar {
  width: 100px;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
  border-right: 1px solid #f3f4f6;
  padding-right: 1rem;
  padding-top: 0.75rem;
}

.platform-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 12px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
}

.platform-item:hover .platform-icon-wrapper {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.platform-item.active .platform-icon-wrapper {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
  color: white;
  transform: scale(1.05);
}

.platform-item.active .platform-name {
  color: #2563eb;
  font-weight: 700;
}

.platform-icon-wrapper {
  width: 52px;
  height: 52px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.5rem;
  background: #f8fafc;
  transition: all 0.3s ease;
  overflow: hidden;
  border: 1px solid #f1f5f9;
}



.platform-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.platform-item i {
  font-size: 1.5rem;
}

.platform-name {
  font-size: 0.85rem;
  color: #606266;
}

/* 右侧内容区 */
.course-content-area {
  flex: 1;
}

.course-group-section {
  margin-bottom: 1rem;
}

.group-title-line {
  display: flex;
  align-items: center;
  margin-bottom: 0.75rem;
}

.blue-bar {
  width: 4px;
  height: 18px;
  background: #409eff;
  border-radius: 2px;
  margin-right: 0.75rem;
}

.group-title {
  font-size: 1.1rem;
  font-weight: 600;
  color: #303133;
}

.course-cards-row {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}

/* 课程卡片美化 */
.simple-course-card {
  background: #fff;
  border: 1px solid #f1f5f9;
  border-radius: 16px;
  padding: 1.1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.simple-course-card:hover {
  border-color: #bfdbfe;
  box-shadow: 0 10px 25px -5px rgba(59, 130, 246, 0.1), 0 4px 6px -2px rgba(59, 130, 246, 0.05);
  transform: translateY(-4px);
}

.simple-course-card::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 4px;
  height: 100%;
  background: #3b82f6;
  opacity: 0;
  transition: opacity 0.3s;
}

.simple-course-card:hover::after {
  opacity: 1;
}

.simple-course-card i {
  color: #c0c4cc;
}

.simple-course-card:hover i {
  color: #409eff;
}

.card-header-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.25rem;
}

.card-title {
  font-size: 1rem;
  font-weight: 600;
  color: #303133;
  margin-bottom: 0;
}

.level-tag {
  font-size: 0.75rem;
  padding: 1px 6px;
  border-radius: 4px;
  border: 1px solid transparent;
}

.level-tag.is-basic {
  background-color: #ecf5ff;
  color: #409eff;
  border-color: #d9ecff;
}

.level-tag.is-advance {
  background-color: #fdf6ec;
  color: #e6a23c;
  border-color: #faecd8;
}

.card-sub {
  font-size: 0.85rem;
  color: #909399;
}

/* 动态课程列表（备用） */
.course-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1rem;
}

.course-card {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  cursor: pointer;
  transition: all 0.3s;
}

.course-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0,0,0,0.1);
}

.course-cover {
  height: 120px;
  background: #f5f7fa;
}

.course-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.course-info {
  padding: 0.75rem;
}

.course-title {
  font-size: 0.95rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.course-meta {
  font-size: 0.8rem;
  color: #909399;
  display: flex;
  justify-content: space-between;
}

/* Level 1 View Styles */
.difficulty-filter-section {
  padding: 0 0.5rem;
}

.difficulty-tabs {
  display: flex;
  gap: 1rem;
  background: white;
  padding: 0.5rem;
  border-radius: 8px;
  width: fit-content;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}

@media (max-width: 768px) {
  .difficulty-tabs {
    width: 100%;
    gap: 0.25rem;
    padding: 0.25rem;
    justify-content: space-between;
  }
}

.difficulty-tab {
  padding: 0.5rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.95rem;
  color: #606266;
  transition: all 0.3s;
  font-weight: 500;
}

@media (max-width: 768px) {
  .difficulty-tab {
    padding: 0.4rem 0;
    font-size: 0.85rem;
    flex: 1;
    text-align: center;
  }
}

.difficulty-tab:hover {
  color: #409eff;
  background-color: #ecf5ff;
}

.difficulty-tab.active {
  background-color: #409eff;
  color: white;
  box-shadow: 0 2px 6px rgba(64, 158, 255, 0.3);
}

.level-one-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  padding-bottom: 2rem;
}

.level-one-card {
  background: white;
  border-radius: 16px;
  padding: 2rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid #e4e7ed;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  position: relative;
  overflow: hidden;
}

.level-one-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 24px rgba(0, 134, 246, 0.15);
  border-color: #409eff;
}

.level-one-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 6px;
  height: 100%;
  background: #409eff;
  opacity: 0;
  transition: opacity 0.3s;
}

.level-one-card:hover::before {
  opacity: 1;
}

.card-icon-bg {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  background: linear-gradient(135deg, #e6f7ff 0%, #bae7ff 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.8rem;
  color: #0086F6;
  margin-right: 1.5rem;
}

.level-one-card .card-info {
  flex: 1;
}

.level-one-card .card-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #303133;
  margin: 0 0 0.5rem 0;
}

.level-one-card .card-subtitle {
  font-size: 0.9rem;
  color: #909399;
  margin: 0;
}

.card-arrow {
  color: #c0c4cc;
  font-size: 1.2rem;
  transition: transform 0.3s;
}

.level-one-card:hover .card-arrow {
  color: #409eff;
  transform: translateX(4px);
}

/* Level 2 View Header */
.view-header {
  display: flex;
  align-items: center;
  margin-bottom: 2rem;
}

.back-btn-wrapper {
  display: flex;
  align-items: center;
  cursor: pointer;
  color: #606266;
  font-size: 1rem;
  transition: color 0.3s;
}

.back-btn-wrapper:hover {
  color: #409eff;
}

.divider {
  margin: 0 1rem;
  color: #dcdfe6;
}

.view-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: #303133;
  margin: 0;
}

/* 响应式 */
@media (max-width: 768px) {
  .main-container {
    padding: 0.875rem 0.75rem 1.25rem;
  }

  .difficulty-filter-section {
    padding: 0;
    margin-bottom: 0.75rem !important;
  }

  .banner-section {
    padding: 1rem;
    margin: 0.5rem 0.75rem 1rem;
    border-radius: 12px;
    box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
  }

  .banner-section::before,
  .banner-section::after {
    display: none;
  }

  .banner-content {
    flex-direction: column;
    align-items: stretch;
    text-align: left;
    gap: 0.875rem;
    justify-content: initial;
  }
  
  .banner-left {
    flex-direction: row;
    align-items: flex-start;
    gap: 0.75rem;
    flex: initial;
  }

  .banner-icon-box {
    width: 44px;
    height: 44px;
    min-width: 44px;
    border-radius: 10px;
  }

  .banner-icon-box i {
    font-size: 1.25rem;
  }

  .banner-text h2 {
    font-size: clamp(1rem, 4.6vw, 1.2rem);
    margin-bottom: 0.25rem;
    line-height: 1.4;
    word-break: break-word;
  }

  .banner-text p {
    font-size: clamp(0.78rem, 3.4vw, 0.92rem);
    line-height: 1.5;
    max-width: 100%;
    opacity: 0.9;
  }

  .banner-right {
    display: none;
  }

  .difficulty-tabs {
    width: 100%;
    gap: 0.2rem;
    padding: 0.22rem;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.04);
  }

  .difficulty-tab {
    padding: 0.42rem 0;
    font-size: 0.8rem;
    border-radius: 8px;
  }

  .continue-learning-section {
    padding: 0.8rem 0.85rem;
    margin-bottom: 0.75rem;
    border-radius: 10px;
  }

  .continue-learning-section .section-header,
  .training-hub-section .section-header {
    margin-bottom: 0.35rem;
    font-size: 0.95rem;
  }

  .empty-learning-record {
    padding: 0.05rem 0 0.1rem;
  }

  .continue-learning-list {
    grid-template-columns: 1fr;
    gap: 0.55rem;
  }

  .continue-learning-card {
    padding: 0.58rem;
    border-radius: 10px;
  }

  .continue-learning-icon {
    width: 32px;
    height: 32px;
    border-radius: 9px;
  }

  .continue-learning-title {
    font-size: 0.78rem;
  }

  .continue-learning-meta {
    font-size: 0.6rem;
  }

  .book-icon {
    font-size: 1rem;
    margin-bottom: 0;
  }

  .empty-text {
    font-size: 0.82rem;
    margin-bottom: 0.08rem;
  }

  .empty-subtext {
    font-size: 0.64rem;
    line-height: 1.35;
    margin-bottom: 0.45rem;
    max-width: 14rem;
    text-align: center;
  }

  .go-course-btn {
    padding: 0.36rem 1rem;
    font-size: 0.72rem;
    border-radius: 999px;
    box-shadow: 0 3px 8px rgba(64, 158, 255, 0.24);
  }

  .training-hub-section {
    padding: 0.85rem;
    margin-bottom: 0.75rem;
    border-radius: 10px;
  }

  .training-hub-header {
    margin-bottom: 0.55rem;
  }

  .training-hub-header span {
    font-size: 0.72rem;
  }

  .training-hub-grid {
    gap: 0.55rem;
  }

  .training-hub-card {
    padding: 0.62rem 0.7rem;
    gap: 0.55rem;
    border-radius: 10px;
  }

  .hub-icon {
    width: 28px;
    height: 28px;
    border-radius: 8px;
    flex-shrink: 0;
  }

  .hub-content h4 {
    font-size: 0.84rem;
  }

  .hub-content p {
    margin-top: 0.08rem;
    font-size: 0.66rem;
    line-height: 1.28;
  }

  .hub-arrow {
    font-size: 0.8rem;
  }
  
  .content-wrapper {
    flex-direction: column;
    padding: 0;
    background: transparent;
    box-shadow: none;
    gap: 0.75rem;
  }
  
  .platform-sidebar {
    width: 100%;
    flex-direction: row;
    overflow-x: auto;
    border-right: none;
    border-bottom: none;
    padding: 0.35rem 0.2rem;
    background: white;
    border-radius: 10px;
    margin-bottom: 0.35rem;
    gap: 0.35rem;
  }
  
  .platform-item {
    min-width: 62px;
    padding: 0.18rem;
  }

  .platform-icon-wrapper {
    width: 36px;
    height: 36px;
    border-radius: 10px;
    margin-bottom: 0.18rem;
  }

  .platform-icon-wrapper i {
    font-size: 1rem;
  }

  .platform-name {
    font-size: 0.68rem;
  }
  
  .course-group-section {
    margin-bottom: 0.9rem;
  }

  .group-title-line {
    margin-bottom: 0.55rem;
  }

  .blue-bar {
    width: 3px;
    height: 14px;
    margin-right: 0.5rem;
  }

  .group-title {
    font-size: 0.95rem;
  }

  .course-cards-row {
    grid-template-columns: 1fr;
    gap: 0.65rem;
  }

  .simple-course-card {
    padding: 0.85rem 0.9rem;
    border-radius: 11px;
  }

  .card-title {
    font-size: 0.9rem;
  }

  .level-tag {
    font-size: 0.64rem;
    padding: 0 5px;
  }

  .card-sub {
    font-size: 0.72rem;
    line-height: 1.25;
  }

  .training-hub-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 480px) {
  .main-container {
    padding: 0.8rem 0.65rem 1rem;
  }

  .difficulty-filter-section {
    margin-bottom: 0.65rem !important;
  }

  .difficulty-tabs {
    padding: 0.18rem;
    gap: 0.15rem;
  }

  .difficulty-tab {
    padding: 0.38rem 0;
    font-size: 0.76rem;
  }

  .continue-learning-section,
  .training-hub-section {
    padding: 0.68rem;
    border-radius: 9px;
  }

  .continue-learning-section .section-header,
  .training-hub-section .section-header {
    font-size: 0.9rem;
    margin-bottom: 0.32rem;
  }

  .empty-learning-record {
    display: grid;
    grid-template-columns: auto 1fr auto;
    align-items: center;
    gap: 0.45rem;
    padding: 0;
    text-align: left;
  }

  .empty-learning-copy {
    align-items: flex-start;
    min-width: 0;
  }

  .empty-text {
    font-size: 0.78rem;
    margin-bottom: 0.04rem;
  }

  .empty-subtext {
    font-size: 0.6rem;
    margin-bottom: 0;
    max-width: none;
    text-align: left;
    line-height: 1.25;
  }

  .empty-learning-action {
    padding: 0.34rem 0.8rem;
    font-size: 0.68rem;
    white-space: nowrap;
  }

  .training-hub-header {
    align-items: center;
    margin-bottom: 0.45rem;
  }

  .training-hub-header span {
    font-size: 0.64rem;
  }

  .training-hub-card {
    padding: 0.56rem 0.62rem;
    gap: 0.48rem;
  }

  .hub-icon {
    width: 26px;
    height: 26px;
  }

  .hub-content h4 {
    font-size: 0.8rem;
  }

  .hub-content p {
    font-size: 0.62rem;
    line-height: 1.2;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .platform-sidebar {
    padding-bottom: 0.45rem;
  }

  .course-group-section {
    margin-bottom: 0.75rem;
  }

  .group-title-line {
    margin-bottom: 0.45rem;
  }

  .group-title {
    font-size: 0.9rem;
  }

  .course-cards-row {
    gap: 0.55rem;
  }

  .simple-course-card {
    padding: 0.72rem 0.78rem;
  }

  .card-title {
    font-size: 0.84rem;
  }

  .level-tag {
    font-size: 0.6rem;
    padding: 0 4px;
  }

  .card-sub {
    font-size: 0.68rem;
    display: -webkit-box;
    -webkit-line-clamp: 1;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
}
</style>

