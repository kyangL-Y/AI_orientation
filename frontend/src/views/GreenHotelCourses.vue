<template>
  <div class="green-courses-page">
    <PageVisitTracker pageName="绿色饭店课程" />
    <HeaderBar />
    <div class="h-[64px] md:h-[80px]"></div>

    <section class="hero">
      <div class="hero-inner">
        <router-link class="hero-back-link" to="/green-hotel">
          <i class="fas fa-arrow-left"></i>
          返回绿色饭店首页
        </router-link>
        <div class="badge">岗位培训中心 / 绿色饭店课程库</div>
        <h1>绿色饭店课程中心</h1>
        <p>支持大规模课程浏览、筛选与检索，适配百门以上课程管理与学习场景。</p>
      </div>
    </section>

    <section class="toolbar">
      <div class="toolbar-left">
        <div class="search-wrap">
          <i class="fas fa-search search-icon"></i>
          <input
            v-model.trim="keyword"
            type="text"
            placeholder="搜索课程名或分类"
            @keyup.enter="handleSearch"
          />
          <button type="button" @click="handleSearch">搜索</button>
        </div>
        <div class="level-pills">
          <button
            type="button"
            class="pill"
            :class="{ active: !selectedLevel }"
            @click="selectedLevel = ''; handleSearch()"
          >全部</button>
          <button
            v-for="lv in levelOptions"
            :key="lv.value"
            type="button"
            class="pill"
            :class="{ active: selectedLevel === lv.value }"
            @click="selectedLevel = lv.value; handleSearch()"
          >{{ lv.label }}</button>
        </div>
      </div>
      <div class="toolbar-right">
        <span class="course-count">共 <strong>{{ total }}</strong> 门课程</span>
        <button v-if="keyword || selectedLevel" type="button" class="reset-btn" @click="resetFilters">
          <i class="fas fa-times"></i> 重置
        </button>
      </div>
    </section>

    <section class="course-list-wrap">
      <div v-if="loading" class="loading-state">
        <i class="fas fa-spinner fa-spin text-2xl text-emerald-500"></i>
        <span>正在加载课程...</span>
      </div>
      <div v-else-if="errorMessage" class="empty-state">
        <i class="fas fa-exclamation-circle text-2xl text-orange-400"></i>
        <span>{{ errorMessage }}</span>
        <button type="button" class="action-btn" @click="loadCourses">重试</button>
      </div>
      <div v-else-if="courses.length === 0" class="empty-state">
        <i class="fas fa-box-open text-3xl text-gray-300"></i>
        <span>暂无匹配课程</span>
        <p class="text-xs text-gray-400">请调整筛选条件或清除关键词重试</p>
      </div>
      <div v-else class="course-grid">
        <article
          v-for="course in courses"
          :key="course.id"
          class="course-card"
          @click="goStudy(course)"
        >
          <div class="card-left">
            <div class="cover" :class="`cover-${course.levelLabel || 'basic'}`">
              <i class="fas fa-play-circle play-icon"></i>
              <span class="level-tag">{{ getLevelLabel(course.levelLabel) }}</span>
            </div>
          </div>
          <div class="card-right">
            <div class="card-top">
              <h3 :title="course.title">{{ course.title }}</h3>
              <span class="green-tag">绿色饭店课</span>
            </div>
            <div class="card-bottom">
              <span class="meta-item" v-if="course.mainS">
                <i class="fas fa-folder-open"></i> {{ course.mainS }}
              </span>
              <span class="meta-item">
                <i class="fas fa-signal"></i> {{ getLevelLabel(course.levelLabel) }}
              </span>
              <button type="button" class="study-btn" @click.stop="goStudy(course)">
                <i class="fas fa-play mr-1"></i>
                {{ course.videoUrl ? '观看视频' : '开始学习' }}
              </button>
            </div>
          </div>
        </article>
      </div>
    </section>

    <section class="pager" v-if="total > pageSize">
      <button type="button" class="pager-btn" :disabled="pageNum <= 1" @click="changePage(pageNum - 1)">
        <i class="fas fa-chevron-left"></i>
      </button>
      <div class="pager-pages">
        <button
          v-for="p in visiblePages"
          :key="p"
          type="button"
          class="page-num"
          :class="{ active: p === pageNum }"
          @click="changePage(p)"
        >{{ p }}</button>
      </div>
      <button type="button" class="pager-btn" :disabled="pageNum >= totalPages" @click="changePage(pageNum + 1)">
        <i class="fas fa-chevron-right"></i>
      </button>
    </section>

    <div v-if="playerVisible" class="player-mask" @click.self="closeCoursePlayer">
      <div class="player-dialog">
        <div class="player-header">
          <h3>{{ currentCourseTitle || '课程播放' }}</h3>
          <button type="button" class="player-close" @click="closeCoursePlayer">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="player-body">
          <video
            v-if="isDirectVideoUrl(currentCourseVideoUrl)"
            :src="currentCourseVideoUrl"
            controls
            preload="metadata"
            playsinline
          />
          <iframe v-else :src="currentCourseVideoUrl" title="课程视频" allowfullscreen></iframe>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import HeaderBar from '@/components/HeaderBar.vue'
import PageVisitTracker from '@/components/PageVisitTracker.vue'
import { getGreenHotelCourseList, getGreenHotelCoursePage } from '@/api/study'
import { startCourse } from '@/api/study'
import logger from '@/utils/logger'

const route = useRoute()

const keyword = ref('')
const selectedLevel = ref('')
const pageNum = ref(1)
const pageSize = ref(12)
const total = ref(0)
const courses = ref([])
const loading = ref(false)
const errorMessage = ref('')
const useLocalPagingFallback = ref(false)
const localSource = ref([])
const playerVisible = ref(false)
const currentCourseTitle = ref('')
const currentCourseVideoUrl = ref('')

const levelOptions = [
  { value: 'basic', label: '基础' },
  { value: 'advance', label: '进阶' },
  { value: 'expert', label: '高阶' },
]

const totalPages = computed(() => {
  const value = Math.ceil((total.value || 0) / pageSize.value)
  return value > 0 ? value : 1
})

const visiblePages = computed(() => {
  const pages = []
  const maxVisible = 5
  let start = Math.max(1, pageNum.value - Math.floor(maxVisible / 2))
  let end = Math.min(totalPages.value, start + maxVisible - 1)
  if (end - start < maxVisible - 1) {
    start = Math.max(1, end - maxVisible + 1)
  }
  for (let i = start; i <= end; i++) pages.push(i)
  return pages
})

const getLevelLabel = (level) => {
  if (level === 'basic') return '基础'
  if (level === 'advance') return '进阶'
  if (level === 'expert') return '高阶'
  return '基础'
}

const stripHtml = (html) => {
  if (!html) return '绿色饭店专业培训课程'
  return String(html).replace(/<[^>]*>/g, ' ').replace(/&nbsp;/gi, ' ').replace(/\s+/g, ' ').trim() || '绿色饭店专业培训课程'
}

const normalizeCourse = (row) => {
  const title = row.third_level_c || row.thirdLevelC || ''
  const description = row.knowledge_points || row.knowledgePoints || row.main_s || row.mainS || '绿色饭店知识学习'
  return {
    id: row.green_course_id || row.greenCourseId || row.id || title,
    title,
    description,
    mainTitle: row.main_title || row.mainTitle || '',
    mainS: row.main_s || row.mainS || '',
    specificCategory: row.specific_category || row.specificCategory || '',
    levelLabel: row.level || '',
    videoUrl: row.video_url || row.videoUrl || '',
    coverImage: row.cover_image || row.coverImage || '',
  }
}

const applyLocalFilter = (list) => {
  const keywordText = String(keyword.value || '').toLowerCase().trim()
  const level = selectedLevel.value
  return list.filter((item) => {
    const text = `${item.title} ${item.mainS} ${item.specificCategory}`.toLowerCase()
    const keywordMatch = !keywordText || text.includes(keywordText)
    const levelMatch = !level || item.levelLabel === level
    return keywordMatch && levelMatch
  })
}

const buildBackendQuery = () => {
  const params = {
    pageNum: pageNum.value,
    pageSize: pageSize.value,
    status: 1,
  }
  if (selectedLevel.value) {
    params.level = selectedLevel.value
  }
  if (keyword.value) {
    params.thirdLevelC = keyword.value
  }
  return params
}

const loadByBackendPaging = async () => {
  const query = buildBackendQuery()
  const response = await getGreenHotelCoursePage(query)
  const rows = response?.data?.rows || response?.data?.data || []
  const normalizedRows = rows.map(normalizeCourse)

  if (keyword.value && normalizedRows.length === 0) {
    const queryByCategory = { ...query, thirdLevelC: undefined, mainS: keyword.value }
    const categoryResponse = await getGreenHotelCoursePage(queryByCategory)
    const categoryRows = categoryResponse?.data?.rows || categoryResponse?.data?.data || []
    const categoryNormalized = categoryRows.map(normalizeCourse)
    courses.value = categoryNormalized
    total.value = Number(categoryResponse?.data?.total || categoryNormalized.length || 0)
    return
  }

  courses.value = normalizedRows
  total.value = Number(response?.data?.total || normalizedRows.length || 0)
}

const loadByLocalFallback = async () => {
  if (localSource.value.length === 0) {
    const allRes = await getGreenHotelCourseList({ status: 1, pageNum: 1, pageSize: 2000 })
    const rows = allRes?.data?.rows || allRes?.data?.data || []
    localSource.value = rows.map(normalizeCourse)
  }

  const filtered = applyLocalFilter(localSource.value)
  total.value = filtered.length
  const start = (pageNum.value - 1) * pageSize.value
  const end = start + pageSize.value
  courses.value = filtered.slice(start, end)
}

const loadCourses = async () => {
  loading.value = true
  errorMessage.value = ''
  try {
    if (useLocalPagingFallback.value) {
      await loadByLocalFallback()
    } else {
      await loadByBackendPaging()
    }
  } catch (error) {
    logger.error('绿色饭店课程中心加载失败，降级本地分页:', error)
    useLocalPagingFallback.value = true
    try {
      await loadByLocalFallback()
    } catch (innerError) {
      logger.error('绿色饭店课程中心本地分页兜底失败:', innerError)
      courses.value = []
      total.value = 0
      errorMessage.value = '课程加载失败，请稍后重试。'
    }
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pageNum.value = 1
  loadCourses()
}

const resetFilters = () => {
  keyword.value = ''
  selectedLevel.value = ''
  pageNum.value = 1
  loadCourses()
}

const changePage = (targetPage) => {
  if (targetPage < 1 || targetPage > totalPages.value) return
  pageNum.value = targetPage
  loadCourses()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const goStudy = async (course) => {
  if (!course) return

  const normalizedId = Number(course.id)
  const contentData = {
    id: Number.isFinite(normalizedId) && normalizedId > 0 ? normalizedId : undefined,
    title: course.title || '绿色饭店课程',
    content: course.description || '课程内容整理中',
    category: course.mainTitle || '绿色饭店培训',
    subCategory: course.mainS || '',
    specificCategory: course.specificCategory || course.title || '',
    duration: '标准时长',
    level: getLevelLabel(course.levelLabel),
    videoApi: 'train/green-hotel-course/video/play',
    directVideoUrl: course.videoUrl || '',
    courseType: 'green_hotel',
  }

  try {
    await startCourse(course.id, course.title, {
      courseType: 'green_hotel',
      courseMeta: contentData
    }).catch(() => {})
  } catch {}

  sessionStorage.setItem('currentKnowledgeContent', JSON.stringify(contentData))
  sessionStorage.setItem('knowledgeDetailReturnPath', window.location.href)
  window.open('/knowledge-detail.html', '_blank')
}

const closeCoursePlayer = () => {
  playerVisible.value = false
  currentCourseTitle.value = ''
  currentCourseVideoUrl.value = ''
}

const isDirectVideoUrl = (url) => {
  return /\.(mp4|webm|ogg)(\?.*)?$/i.test(String(url || '').trim())
}

onMounted(() => {
  const initialKeyword = String(route.query.keyword || '').trim()
  if (initialKeyword) {
    keyword.value = initialKeyword
  }
  loadCourses()
})
</script>

<style scoped>
.green-courses-page {
  --gc-bg: #f2f4ec;
  --gc-surface: #fffdf8;
  --gc-forest: #2c6a4c;
  --gc-leaf: #4e8f67;
  --gc-earth: #7b5b40;
  --gc-text: #223328;
  --gc-muted: #627467;
  --gc-line: #d4dfd1;

  min-height: 100vh;
  background: radial-gradient(circle at 0 0, #edf5ea 0%, var(--gc-bg) 58%);
  color: var(--gc-text);
  font-family: 'Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  padding-bottom: 40px;
}

.hero {
  max-width: 1200px;
  margin: 20px auto 0;
  padding: 0 16px;
}

.hero-inner {
  position: relative;
  border-radius: 20px;
  background: linear-gradient(135deg, #3d7b5a, #2d5d45);
  color: #f5fbf8;
  padding: 24px 28px;
  box-shadow: 0 12px 30px rgba(36, 72, 52, 0.25);
}

.hero-back-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-height: 30px;
  padding: 0 12px;
  border-radius: 999px;
  border: 1px solid rgba(229, 244, 232, 0.35);
  background: rgba(240, 250, 243, 0.14);
  color: #eef9f1;
  text-decoration: none;
  font-size: 12px;
  margin-bottom: 12px;
  transition: background 0.2s;
}

.hero-back-link:hover {
  background: rgba(240, 250, 243, 0.25);
}

.badge {
  font-size: 11px;
  letter-spacing: 0.06em;
  opacity: 0.85;
}

.hero h1 {
  margin: 6px 0 0;
  font-size: 26px;
  font-weight: 700;
}

.hero p {
  margin: 8px 0 0;
  max-width: 60ch;
  line-height: 1.7;
  opacity: 0.9;
  font-size: 14px;
}

.toolbar {
  max-width: 1200px;
  margin: 16px auto 0;
  padding: 0 16px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  min-width: 0;
  flex-wrap: wrap;
}

.search-wrap {
  display: flex;
  align-items: center;
  background: var(--gc-surface);
  border: 1px solid var(--gc-line);
  border-radius: 12px;
  overflow: hidden;
  min-width: 260px;
  max-width: 380px;
  flex: 1;
  box-shadow: 0 2px 8px rgba(50, 70, 55, 0.06);
  transition: border-color 0.2s, box-shadow 0.2s;
}

.search-wrap:focus-within {
  border-color: #6da67e;
  box-shadow: 0 0 0 3px rgba(109, 166, 126, 0.15);
}

.search-icon {
  color: #9bb5a3;
  padding-left: 12px;
  font-size: 13px;
}

.search-wrap input {
  flex: 1;
  min-height: 38px;
  border: none;
  padding: 0 10px;
  font-size: 13px;
  color: var(--gc-text);
  background: transparent;
  outline: none;
}

.search-wrap button {
  min-height: 38px;
  min-width: 64px;
  border: none;
  background: var(--gc-leaf);
  color: #fff;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  transition: background 0.2s;
}

.search-wrap button:hover {
  background: var(--gc-forest);
}

.level-pills {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.pill {
  min-height: 32px;
  padding: 0 14px;
  border-radius: 999px;
  border: 1px solid var(--gc-line);
  background: var(--gc-surface);
  color: var(--gc-muted);
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.pill:hover {
  border-color: #a0c5aa;
  color: var(--gc-forest);
}

.pill.active {
  background: var(--gc-forest);
  color: #fff;
  border-color: var(--gc-forest);
  box-shadow: 0 2px 8px rgba(44, 106, 76, 0.2);
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.course-count {
  font-size: 13px;
  color: var(--gc-muted);
}

.course-count strong {
  color: var(--gc-forest);
  font-size: 15px;
}

.reset-btn {
  min-height: 32px;
  padding: 0 12px;
  border-radius: 8px;
  border: 1px solid #dbe5dc;
  background: #f5faf4;
  color: var(--gc-forest);
  font-size: 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  transition: all 0.2s;
}

.reset-btn:hover {
  background: #e8f2e8;
}

.course-list-wrap {
  max-width: 1200px;
  margin: 16px auto 0;
  padding: 0 16px;
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 60px 20px;
  color: var(--gc-muted);
  font-size: 14px;
}

.action-btn {
  margin-top: 6px;
  min-height: 36px;
  border: none;
  border-radius: 8px;
  padding: 0 16px;
  background: var(--gc-leaf);
  color: #fff;
  cursor: pointer;
  font-size: 13px;
}

.course-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
}

.course-card {
  display: flex;
  gap: 16px;
  background: var(--gc-surface);
  border: 1px solid #deeadf;
  border-radius: 16px;
  padding: 16px;
  box-shadow: 0 4px 14px rgba(52, 74, 59, 0.06);
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s;
}

.course-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 28px rgba(52, 74, 59, 0.12);
  border-color: #95ba9d;
}

.card-left {
  flex-shrink: 0;
}

.cover {
  width: 120px;
  height: 90px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}

.cover-basic {
  background: linear-gradient(135deg, #d7e9da, #bdd6c2);
}

.cover-advance {
  background: linear-gradient(135deg, #c8dfe8, #a8c8d8);
}

.cover-expert {
  background: linear-gradient(135deg, #d6d0e3, #beb4d0);
}

.play-icon {
  font-size: 28px;
  color: rgba(255, 255, 255, 0.85);
  z-index: 2;
  transition: transform 0.3s;
}

.course-card:hover .play-icon {
  transform: scale(1.15);
}

.level-tag {
  position: absolute;
  top: 6px;
  right: 6px;
  padding: 1px 8px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.85);
  color: var(--gc-forest);
  font-size: 10px;
  font-weight: 600;
}

.card-right {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.card-top {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  margin-bottom: 6px;
}

.card-top h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #2a4e37;
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.course-card:hover .card-top h3 {
  color: var(--gc-forest);
}

.green-tag {
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  min-height: 20px;
  border-radius: 999px;
  border: 1px solid #b7d3bc;
  background: #ecf6ee;
  color: #2b6a40;
  font-size: 10px;
  font-weight: 600;
  padding: 0 7px;
}

.desc {
  margin: 0;
  color: #5e7a68;
  font-size: 13px;
  line-height: 1.6;
  flex: 1;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-bottom {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 8px;
}

.meta-item {
  color: var(--gc-muted);
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 4px;
}

.meta-item i {
  font-size: 10px;
  opacity: 0.7;
}

.study-btn {
  margin-left: auto;
  min-height: 30px;
  padding: 0 14px;
  border: 1px solid #b8d6be;
  border-radius: 8px;
  background: #f0f8f2;
  color: var(--gc-forest);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s;
}

.study-btn:hover {
  background: var(--gc-forest);
  color: #fff;
  border-color: var(--gc-forest);
}

.pager {
  max-width: 1200px;
  margin: 24px auto 0;
  padding: 0 16px;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 6px;
}

.pager-btn {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid var(--gc-line);
  border-radius: 8px;
  background: var(--gc-surface);
  color: var(--gc-muted);
  cursor: pointer;
  transition: all 0.2s;
}

.pager-btn:hover:not(:disabled) {
  border-color: #a0c5aa;
  color: var(--gc-forest);
}

.pager-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.pager-pages {
  display: flex;
  gap: 4px;
}

.page-num {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
  border-radius: 8px;
  background: transparent;
  color: var(--gc-muted);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.page-num:hover {
  background: #f0f5ef;
}

.page-num.active {
  background: var(--gc-forest);
  color: #fff;
  border-color: var(--gc-forest);
  font-weight: 600;
}

.player-mask {
  position: fixed;
  inset: 0;
  z-index: 1100;
  background: rgba(20, 35, 27, 0.65);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
}

.player-dialog {
  width: min(960px, 100%);
  border-radius: 16px;
  border: 1px solid #cfe0d0;
  background: #f7fbf6;
  box-shadow: 0 20px 50px rgba(12, 32, 22, 0.4);
  overflow: hidden;
}

.player-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 14px 18px;
  border-bottom: 1px solid #d6e2d6;
  background: #f0f5ef;
}

.player-header h3 {
  margin: 0;
  font-size: 15px;
  color: #24533a;
  font-weight: 600;
}

.player-close {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #c4d6c6;
  border-radius: 8px;
  background: #edf5ed;
  color: #2d5f44;
  cursor: pointer;
  transition: all 0.2s;
}

.player-close:hover {
  background: #d8ead8;
}

.player-body {
  padding: 16px;
}

.player-body video,
.player-body iframe {
  width: 100%;
  height: min(56vw, 520px);
  border: none;
  border-radius: 12px;
  background: #111;
}

@media (min-width: 768px) {
  .course-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 767px) {
  .hero h1 {
    font-size: 22px;
  }

  .hero-inner {
    padding: 18px 16px;
  }

  .toolbar {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }

  .toolbar-left {
    flex-direction: column;
    gap: 12px;
  }

  .search-wrap {
    max-width: none;
    min-width: 0;
  }

  .search-wrap input,
  .search-wrap button,
  .reset-btn {
    min-height: 44px;
  }

  .toolbar-right {
    width: 100%;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 10px;
  }

  .level-pills {
    flex-wrap: wrap;
    gap: 8px;
  }

  .pill {
    min-height: 40px;
  }

  .course-card {
    flex-direction: column;
    gap: 12px;
  }

  .cover {
    width: 100%;
    height: 100px;
  }

  .card-bottom {
    flex-wrap: wrap;
    align-items: stretch;
    gap: 8px;
  }

  .card-top {
    flex-direction: column;
    align-items: flex-start;
  }

  .card-top h3 {
    white-space: normal;
    overflow: visible;
    text-overflow: unset;
    line-height: 1.45;
  }

  .meta-item {
    flex-wrap: wrap;
  }

  .study-btn {
    width: 100%;
    margin-left: 0;
    margin-top: 6px;
    text-align: center;
    min-height: 44px;
  }
}
</style>
