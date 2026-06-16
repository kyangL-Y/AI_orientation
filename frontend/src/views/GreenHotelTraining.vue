<template>
  <div class="green-hotel-page min-h-screen">
    <PageVisitTracker pageName="绿色饭店培训" />
    <HeaderBar />
    <div class="pt-[60px] md:pt-[72px] pb-8 md:pb-12">
      <section class="relative overflow-hidden gh-hero">
        <div class="absolute inset-0">
          <div class="absolute top-0 right-0 w-[360px] h-[360px] bg-white/10 rounded-full blur-3xl translate-x-1/3 -translate-y-1/2"></div>
          <div class="absolute bottom-0 left-0 w-[280px] h-[280px] bg-emerald-300/20 rounded-full blur-3xl -translate-x-1/4 translate-y-1/4"></div>
        </div>
        <div class="container mx-auto px-4 py-5 md:py-14 relative z-10 gh-hero-inner">
          <div class="max-w-4xl">
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs bg-white/12 border border-white/20 mb-3 md:mb-4 gh-hero-badge">
              <i class="fas fa-leaf text-emerald-100"></i>
              <span class="text-emerald-50">岗位培训中心 / 绿色饭店</span>
            </div>
            <h1 class="text-xl md:text-4xl font-bold text-white leading-tight tracking-tight mb-2 md:mb-4 gh-hero-title">
              绿色饭店培训模块
            </h1>
            <p class="text-emerald-50/90 text-sm md:text-lg max-w-3xl leading-relaxed gh-hero-desc">
              聚焦节能降耗、绿色采购、低碳运营与环保服务，帮助团队建立可持续服务能力。
            </p>
            <div class="mt-4 md:mt-6 flex flex-wrap gap-2 gh-hero-tags">
              <span v-for="tag in highlightTags" :key="tag" class="px-3 py-1 rounded-full text-xs bg-white/12 border border-white/20 text-emerald-50">
                {{ tag }}
              </span>
            </div>
          </div>
        </div>
        <div class="absolute bottom-0 left-0 right-0 h-5 md:h-8 bg-gradient-to-t from-[#f1f5ef] to-transparent"></div>
      </section>

      <div class="container mx-auto px-3 md:px-4 -mt-2 md:-mt-6 relative z-20">
        <div class="lg:hidden mb-2.5 gh-mobile-topic-wrap">
          <div class="bg-white rounded-xl shadow-sm border border-emerald-100 p-2.5 gh-mobile-topic-panel">
            <div class="flex items-center gap-2 mb-2 gh-mobile-topic-head">
              <div class="w-6 h-6 rounded-md bg-emerald-700 flex items-center justify-center gh-mobile-topic-icon">
                <i class="fas fa-compass text-white text-xs"></i>
              </div>
              <span class="font-semibold text-gray-700 text-xs">选择训练主题</span>
            </div>
            <div class="flex gap-1.5 overflow-x-auto pb-1 -mx-0.5 px-0.5 mobile-topic-scroll">
              <button
                v-for="topic in topicOptions"
                :key="topic"
                @click="selectTopic(topic)"
                class="flex-shrink-0 px-2.5 py-1.5 rounded-lg text-xs font-medium transition-all whitespace-nowrap gh-mobile-topic-pill"
                :class="activeTopic === topic && !customKeyword
                  ? 'bg-emerald-700 text-white shadow-sm'
                  : 'bg-emerald-50 text-emerald-800'"
              >
                {{ topic }}
              </button>
            </div>
          </div>
        </div>

        <div class="flex flex-col lg:flex-row gap-4 md:gap-6">
          <aside class="w-full lg:w-72 flex-shrink-0 hidden lg:block">
            <div class="bg-white/85 backdrop-blur-sm rounded-2xl shadow-lg shadow-emerald-900/5 border border-white sticky top-24 overflow-hidden flex flex-col max-h-[calc(100vh-120px)]">
              <div class="flex-shrink-0">
                <div class="p-4 border-b border-emerald-100 bg-gradient-to-r from-emerald-50/70 to-transparent">
                  <h3 class="font-semibold text-gray-700 flex items-center gap-2.5 text-base">
                    <div class="w-8 h-8 rounded-lg bg-emerald-700 flex items-center justify-center">
                      <i class="fas fa-seedling text-white text-sm"></i>
                    </div>
                    训练主题
                  </h3>
                </div>
                <div class="p-2 space-y-1">
                  <button
                    v-for="topic in topicOptions"
                    :key="topic"
                    @click="selectTopic(topic)"
                    class="w-full text-left px-3 py-3 rounded-xl transition-all duration-300 flex items-center justify-between group"
                    :class="activeTopic === topic && !customKeyword
                      ? 'bg-gradient-to-r from-emerald-700 to-green-700 text-white shadow-md shadow-emerald-500/25'
                      : 'text-gray-600 hover:bg-emerald-50'"
                  >
                    <span class="font-medium text-sm">{{ topic }}</span>
                    <i class="fas fa-chevron-right text-xs transition-all duration-300"
                       :class="activeTopic === topic && !customKeyword
                         ? 'text-white/70'
                         : 'text-emerald-300 opacity-0 group-hover:opacity-100'"></i>
                  </button>
                </div>
                <div class="topic-side-entry">
                  <div class="topic-side-title">智囊阁</div>
                  <router-link to="/knowledge" class="topic-side-link">
                    去看绿色饭店知识文章
                    <i class="fas fa-arrow-right text-xs"></i>
                  </router-link>
                </div>
              </div>

              <!-- 新增：培训知识内容 -->
              <div class="flex-1 overflow-y-auto mt-2 border-t border-emerald-100 bg-white/50 relative">
                <div class="p-4 border-b border-emerald-50 sticky top-0 bg-white/95 backdrop-blur z-10 flex justify-between items-center shadow-sm">
                  <h3 class="font-semibold text-gray-700 flex items-center gap-2 text-sm">
                    <i class="fas fa-file-alt text-emerald-600"></i>
                    培训知识内容
                  </h3>
                  <span class="text-xs text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">{{ articles.length }} 篇</span>
                </div>
                <div class="p-3">
                  <div v-if="loadingArticles" class="text-center py-4 text-xs text-gray-400">
                    <i class="fas fa-spinner fa-spin mr-1"></i>正在加载...
                  </div>
                  <div v-else-if="articleErrorMessage" class="text-center py-4 text-xs text-gray-400">
                    {{ articleErrorMessage }}
                    <button class="text-emerald-600 ml-2 hover:underline" @click="retryLoadArticles">重试</button>
                  </div>
                  <div v-else-if="articles.length === 0" class="text-center py-8 text-xs text-gray-400">
                    <div class="w-12 h-12 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-2 text-gray-300 text-lg">
                      <i class="fas fa-box-open"></i>
                    </div>
                    暂无相关知识
                  </div>
                  <div v-else class="space-y-2.5">
                    <article
                      v-for="(item, index) in articles"
                      :key="item.articleId || `article-${index}`"
                      class="bg-white border border-emerald-50 rounded-xl p-3 cursor-pointer hover:border-emerald-300 hover:shadow-md transition-all group"
                      @click="goToArticle(item.articleId)"
                    >
                      <h4 class="font-medium text-gray-800 text-sm mb-1.5 line-clamp-2 group-hover:text-emerald-700">{{ item.title }}</h4>
                      <p class="text-xs text-gray-500 line-clamp-2 leading-relaxed">{{ item.summary }}</p>
                    </article>
                  </div>
                </div>
              </div>
            </div>
          </aside>

          <main class="flex-1 min-w-0 space-y-2.5 md:space-y-6">
            <section class="flex md:grid md:grid-cols-3 gap-2 md:gap-4 items-stretch gh-mobile-overview">
              <div class="flex-1 md:col-span-2 bg-white rounded-xl md:rounded-2xl p-3 md:p-6 shadow-sm border border-emerald-100 hover:shadow-md transition-shadow gh-route-card">
                <h3 class="font-semibold text-gray-700 mb-3 md:mb-4 flex items-center gap-2 text-xs md:text-base gh-route-title">
                  <div class="w-5 h-5 md:w-8 md:h-8 rounded-md md:rounded-lg bg-emerald-50 flex items-center justify-center gh-route-icon">
                    <i class="fas fa-route text-emerald-600 text-xs"></i>
                  </div>
                  绿色饭店课程难度路线
                </h3>
                <p class="text-xs md:text-sm text-gray-500 mb-2 gh-route-desc">点击难度即可筛选课程。</p>
                <div class="difficulty-route">
                  <button
                    v-for="item in difficultyLevels"
                    :key="item.value"
                    type="button"
                    class="difficulty-node hover:border-emerald-300"
                    :class="{ active: selectedDifficulty === item.value }"
                    @click="selectDifficulty(item.value)"
                  >
                    <span class="difficulty-level">{{ item.label }}</span>
                    <span class="difficulty-count">{{ item.count }} 门课程</span>
                  </button>
                </div>
              </div>

              <div class="w-28 md:w-auto flex-shrink-0 bg-gradient-to-br from-emerald-600 to-green-700 rounded-xl md:rounded-2xl p-3 md:p-5 text-white shadow-lg relative overflow-hidden group gh-summary-card">
                <div class="absolute -bottom-6 -right-6 w-24 h-24 bg-white/10 rounded-full blur-2xl group-hover:bg-white/20 transition-all"></div>
                <div class="relative z-10 h-full flex flex-col gh-summary-content">
                  <div class="flex items-center gap-1 md:gap-2 mb-1 gh-summary-head">
                    <i class="fas fa-chart-line text-emerald-100 text-xs"></i>
                    <span class="text-emerald-100/90 text-xs font-medium hidden md:inline">当前资源概览</span>
                    <span class="text-emerald-100/90 text-xs font-medium md:hidden">概览</span>
                  </div>
                  <div class="text-2xl md:text-4xl font-bold mb-1 flex-1 gh-summary-value">{{ allCourseEntries.length }}</div>
                  <div class="text-emerald-100/80 text-[10px] md:text-xs mb-2 md:mb-4 hidden md:block">门课程可直接进入训练</div>
                  <button type="button" @click="goToPractice" class="w-full py-1.5 md:py-2.5 bg-white/95 text-emerald-800 hover:bg-white rounded-lg md:rounded-xl text-xs font-semibold transition-all duration-300 shadow-sm hover:shadow-md flex items-center justify-center mt-auto gh-summary-action">
                    <i class="fas fa-play mr-1 text-[10px] gh-summary-action-icon"></i>
                    <span class="hidden md:inline">立即刷题</span>
                    <span class="md:hidden gh-summary-action-label">练习</span>
                  </button>
                </div>
              </div>
            </section>

            <!-- 快捷入口 - 桌面端与移动端一致但横向排列，合并了搜索和统计数据 -->
            <section class="hidden md:flex gap-3">
              <button @click="scrollToSection('courses')" class="flex-1 bg-white rounded-xl px-4 py-3 shadow-sm border border-emerald-100 hover:shadow-md hover:border-lime-200 transition-all group flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-lime-50 flex items-center justify-center group-hover:bg-lime-100 transition-colors shrink-0">
                  <i class="fas fa-video text-lg text-lime-600"></i>
                </div>
                <div class="text-left">
                  <h4 class="font-semibold text-gray-700 text-sm group-hover:text-lime-700">推荐看课</h4>
                  <p class="text-xs text-gray-400">按主题快速学习</p>
                </div>
              </button>
              
              <button @click="goToPractice" class="flex-1 bg-white rounded-xl px-4 py-3 shadow-sm border border-emerald-100 hover:shadow-md hover:border-green-200 transition-all group flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg bg-green-50 flex items-center justify-center group-hover:bg-green-100 transition-colors shrink-0">
                  <i class="fas fa-clipboard-check text-lg text-green-600"></i>
                </div>
                <div class="text-left">
                  <h4 class="font-semibold text-gray-700 text-sm group-hover:text-green-700">测评巩固</h4>
                  <p class="text-xs text-gray-400">完成在线刷题闭环</p>
                </div>
              </button>

              <div class="flex-[1.2] bg-white rounded-xl px-4 py-3 shadow-sm border border-emerald-100 flex flex-col justify-center gap-1.5 transition-all hover:shadow-md hover:border-emerald-200">
                <div class="flex items-center gap-2 text-[11px] text-gray-500 mb-0.5">
                  <i class="fas fa-filter text-emerald-500"></i>
                  <span>当前主题：<strong class="text-emerald-700 font-medium">{{ currentKeyword }}</strong></span>
                </div>
                <div class="relative">
                  <input
                    v-model.trim="keywordInput"
                    type="text"
                    placeholder="搜索知识/课程"
                    @keyup.enter="applySearch"
                    class="w-full bg-emerald-50/50 border border-transparent hover:border-emerald-100 rounded-lg pl-8 pr-3 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-emerald-400 focus:bg-white transition-colors"
                  />
                  <i class="fas fa-search absolute left-2.5 top-1/2 -translate-y-1/2 text-emerald-400/80 text-xs"></i>
                </div>
              </div>
            </section>

            <!-- 快捷入口 - 移动端 -->
            <div class="md:hidden space-y-3 gh-mobile-quick">
              <div class="flex gap-2 gh-mobile-quick-row">
                <button type="button" @click="scrollToSection('courses')" class="flex-1 bg-white rounded-xl p-3 shadow-sm border border-emerald-100 flex items-center gap-2 gh-mobile-quick-card">
                  <div class="w-8 h-8 rounded-md bg-lime-50 flex items-center justify-center shrink-0 gh-mobile-quick-icon">
                    <i class="fas fa-video text-lime-600 text-sm"></i>
                  </div>
                  <div class="text-left min-w-0">
                    <h4 class="font-semibold text-gray-700 text-xs truncate">推荐看课</h4>
                    <p class="text-[10px] text-gray-400 truncate">按主题快速学习</p>
                  </div>
                </button>
                <button type="button" @click="goToPractice" class="flex-1 bg-white rounded-xl p-3 shadow-sm border border-emerald-100 flex items-center gap-2 gh-mobile-quick-card">
                  <div class="w-8 h-8 rounded-md bg-green-50 flex items-center justify-center shrink-0 gh-mobile-quick-icon">
                    <i class="fas fa-clipboard-check text-green-600 text-sm"></i>
                  </div>
                  <div class="text-left min-w-0">
                    <h4 class="font-semibold text-gray-700 text-xs truncate">测评巩固</h4>
                    <p class="text-[10px] text-gray-400 truncate">完成在线刷题</p>
                  </div>
                </button>
              </div>
              <div class="bg-white rounded-xl p-2.5 shadow-sm border border-emerald-100 gh-mobile-search-card">
                <div class="relative flex items-center">
                  <input
                    v-model.trim="keywordInput"
                    type="text"
                    placeholder="搜索知识/课程"
                    @keyup.enter="applySearch"
                    class="w-full bg-gray-50 border-none rounded-lg pl-8 pr-12 py-2 text-xs focus:outline-none gh-mobile-search-input"
                  />
                  <i class="fas fa-search absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400 text-xs"></i>
                  <button @click="applySearch" class="absolute right-1 px-2 py-1 text-[10px] bg-emerald-600 text-white rounded-md gh-mobile-search-button">搜索</button>
                </div>
              </div>
            </div>

            <!-- 课程列表区域，类似于技能工坊直接展示 -->
            <div ref="courseSectionRef" class="space-y-2 md:space-y-4">
              <div class="flex items-center justify-between">
                <h3 class="font-semibold text-gray-700 text-sm md:text-lg flex items-center gap-1.5 md:gap-2">
                  <div class="w-6 h-6 md:w-8 md:h-8 rounded-md md:rounded-lg bg-emerald-50 flex items-center justify-center">
                    <i class="fas fa-book text-emerald-600 text-xs md:text-sm"></i>
                  </div>
                  推荐课程
                  <span class="text-xs text-gray-400 font-normal ml-1">
                    ({{ displayCourseEntries.length }}<span v-if="displayCourseEntries.length !== allCourseEntries.length">/{{ allCourseEntries.length }}</span>门)
                  </span>
                </h3>
                <router-link to="/green-hotel/courses" class="text-emerald-600 text-xs hover:underline hidden md:flex items-center gap-1">
                  查看全部 {{ allCourseEntries.length }} 门课程 <i class="fas fa-chevron-right text-[10px]"></i>
                </router-link>
              </div>

              <div v-if="loadingCourses" class="bg-white rounded-xl md:rounded-2xl p-8 md:p-10 flex items-center justify-center border border-emerald-100 shadow-sm">
                <i class="fas fa-spinner fa-spin text-xl md:text-2xl text-emerald-600"></i>
                <span class="ml-3 text-gray-500 text-sm md:text-base">加载中...</span>
              </div>
              
              <div v-else-if="displayCourseEntries.length === 0" class="bg-white rounded-xl md:rounded-2xl border border-emerald-100 shadow-sm p-8 md:p-12 flex flex-col items-center justify-center text-center">
                <div class="w-16 h-16 bg-emerald-50 rounded-full flex items-center justify-center mb-4 text-emerald-400 text-2xl">
                  <i class="fas fa-folder-open"></i>
                </div>
                <p class="text-gray-500 text-sm">当前难度暂无推荐课程，请切换难度或前往全部课程查看。</p>
                <button type="button" @click="clearDifficulty" class="mt-4 px-4 py-2 bg-emerald-50 text-emerald-700 rounded-lg text-xs font-medium hover:bg-emerald-100 transition-colors">清除难度筛选</button>
              </div>
              
              <div v-else class="space-y-3 md:grid md:grid-cols-2 md:gap-4 md:space-y-0">
                <div
                  v-for="item in displayCourseEntries"
                  :key="item.id"
                  @click="goToCourseCenter(item.title)"
                  class="bg-white rounded-xl md:rounded-2xl p-3 md:p-4 shadow-sm border border-emerald-100 hover:shadow-md hover:border-emerald-300 transition-all cursor-pointer group"
                >
                  <div class="flex gap-3 md:gap-4">
                    <div class="w-20 h-20 md:w-24 md:h-24 rounded-lg md:rounded-xl bg-gradient-to-br from-emerald-50 to-green-50 flex-shrink-0 flex items-center justify-center relative overflow-hidden group-hover:from-emerald-100 group-hover:to-green-100 transition-colors">
                      <i class="fas fa-play-circle text-2xl md:text-3xl text-emerald-300 group-hover:text-emerald-500 transition-colors z-10 transform group-hover:scale-110 duration-300"></i>
                      <div class="absolute bottom-0 left-0 right-0 h-1/2 bg-gradient-to-t from-emerald-200/30 to-transparent"></div>
                    </div>
                    <div class="flex-1 min-w-0 flex flex-col justify-center py-1">
                      <div class="flex items-center gap-2 mb-1.5 md:mb-2">
                        <span class="px-1.5 py-0.5 md:px-2 bg-emerald-50 text-emerald-700 text-[10px] md:text-xs rounded-full font-medium border border-emerald-100">
                          绿色饭店课
                        </span>
                        <span class="text-[10px] md:text-xs text-emerald-600 bg-emerald-50/50 border border-emerald-50 px-1.5 py-0.5 rounded-md font-medium">
                          {{ getLevelLabel(item.level) }}
                        </span>
                      </div>
                      <h4 class="font-semibold text-gray-700 text-sm md:text-base mb-1 truncate group-hover:text-emerald-700 transition-colors" :title="item.title">{{ item.title }}</h4>
                      <p class="text-xs text-gray-400 line-clamp-1 md:line-clamp-2" :title="item.section">{{ item.section || '绿色饭店实战培训' }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- 移动端的全部课程按钮 -->
              <div class="md:hidden mt-4">
                <router-link to="/green-hotel/courses" class="block w-full py-2.5 text-center bg-white border border-emerald-100 text-emerald-600 rounded-xl text-xs font-medium shadow-sm">
                  查看全部 {{ allCourseEntries.length }} 门课程
                </router-link>
              </div>
            </div>
          </main>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger'
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import HeaderBar from '@/components/HeaderBar.vue'
import PageVisitTracker from '@/components/PageVisitTracker.vue'
import { searchArticles } from '@/api/knowledge'
import { getGreenHotelCoursePage } from '@/api/study'

const router = useRouter()

const TOPIC_ALL = '全部'
const topicOptions = [
  TOPIC_ALL,
  '绿色饭店基础',
  '节能降耗',
  '绿色采购',
  '低碳客房',
  '绿色餐饮',
  '垃圾分类与循环利用',
]
const topicKeywordMap = {
  绿色饭店基础: ['绿色饭店', '评定标准', '标准认知', '发展历程', '核心理念', '等级划分'],
  节能降耗: ['节能', '降耗', '能耗', '水电', '减排', '碳'],
  绿色采购: ['绿色采购', '供应商', '准入', '认证', '台账', '供应链'],
  低碳客房: ['低碳客房', '客房', '布草', '洗涤', '清洁', '耗材'],
  绿色餐饮: ['绿色餐饮', '餐饮', '后厨', '食材', '减废', '厨余'],
  垃圾分类与循环利用: ['垃圾分类', '循环利用', '回收', '厨余垃圾', '可回收', '有害垃圾'],
}

const highlightTags = ['节能管理', '低碳运营', '环保采购', '绿色服务']
const trainingCheckpoints = [
  { title: '标准认知', description: '理解绿色饭店评定标准与关键条款。' },
  { title: '岗位实操', description: '按客房/餐饮/采购场景完成课程训练。' },
  { title: '考核巩固', description: '通过在线刷题验证学习效果并查漏补缺。' },
]
const greenConceptKeywords = [
  '绿色饭店',
  '绿色',
  '低碳',
  '节能',
  '环保',
  '可持续',
  '减排',
  '碳中和',
  '垃圾分类',
  '循环利用',
  'green',
  'sustainable',
  'carbon',
]
const hotelSceneKeywords = ['饭店', '酒店', '客房', '餐饮', '前台', '后厨', 'hotel', 'hospitality']

const allCourseEntries = ref([])
const loadingCourses = ref(false)

const getLevelLabel = (level) => {
  if (level === 'basic') return '基础'
  if (level === 'advance') return '进阶'
  if (level === 'expert') return '高阶'
  return '未分级'
}

const loadCourseEntries = async () => {
  loadingCourses.value = true
  try {
    const res = await getGreenHotelCoursePage({ pageNum: 1, pageSize: 200, status: 1 })
    const rows = res?.data?.rows || res?.data?.data || []
    allCourseEntries.value = rows.map((row) => ({
      id: row.green_course_id || row.greenCourseId || row.id,
      title: row.third_level_c || row.thirdLevelC || row.main_title || row.mainTitle || '',
      level: row.level || '',
      section: row.main_s || row.mainS || '',
      category: row.specific_category || row.specificCategory || '',
      knowledgePoints: row.knowledge_points || row.knowledgePoints || '',
    }))
  } catch (e) {
    logger.error('加载推荐课程失败:', e)
    allCourseEntries.value = []
  } finally {
    loadingCourses.value = false
  }
}

const activeTopic = ref(TOPIC_ALL)
const keywordInput = ref('')
const customKeyword = ref('')
const articles = ref([])
const loadingArticles = ref(false)
const articleErrorMessage = ref('')
const articleRequestSeq = ref(0)
const articleSectionRef = ref(null)
const courseSectionRef = ref(null)
const selectedDifficulty = ref('')

const currentKeyword = computed(() => customKeyword.value || (activeTopic.value === TOPIC_ALL ? '绿色饭店' : activeTopic.value))
const currentTopicKeywords = computed(() => {
  if (customKeyword.value) {
    return [String(customKeyword.value).toLowerCase()]
  }
  if (activeTopic.value === TOPIC_ALL) {
    return ['绿色饭店', '绿色', '节能', '低碳', '环保']
  }
  return (topicKeywordMap[activeTopic.value] || [activeTopic.value]).map((item) => String(item).toLowerCase())
})

const toPlainText = (html) => {
  if (!html) return ''
  return String(html).replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
}

const normalizeArticle = (row) => {
  const contentText = toPlainText(row?.content || '')
  const summaryText = toPlainText(row?.summary || '')
  const summarySource = summaryText || contentText
  return {
    articleId: row?.articleId || row?.id,
    title: row?.title || '未命名文章',
    summary: summarySource.length > 90 ? `${summarySource.slice(0, 90)}...` : summarySource,
    authorName: row?.authorName,
    viewCount: row?.viewCount || 0,
    likeCount: row?.likeCount || 0,
    rawText: `${row?.title || ''} ${summaryText} ${contentText}`.trim(),
  }
}

const containsGreenTheme = (text) => {
  const value = String(text || '').toLowerCase()
  const hasExactPhrase = value.includes('绿色饭店') || value.includes('green hotel')
  const hasGreenConcept = greenConceptKeywords.some((k) => value.includes(k))
  const hasHotelScene = hotelSceneKeywords.some((k) => value.includes(k))
  return hasExactPhrase || (hasGreenConcept && hasHotelScene)
}

const matchCurrentTopic = (text) => {
  const value = String(text || '').toLowerCase()
  return currentTopicKeywords.value.some((keyword) => value.includes(keyword))
}

const extractRows = (response) => {
  const data = response?.data
  if (Array.isArray(data?.rows)) return data.rows
  if (Array.isArray(data?.data?.rows)) return data.data.rows
  if (Array.isArray(data?.data)) return data.data
  return []
}

const filterGreenArticles = (items) => {
  return items.filter((item) => {
    const fullText = `${item.title || ''} ${item.summary || ''} ${item.rawText || ''}`
    return containsGreenTheme(fullText) && matchCurrentTopic(fullText)
  })
}

const mergeRowsById = (existingRows, incomingRows) => {
  const rowMap = new Map()
  ;[...existingRows, ...incomingRows].forEach((row, index) => {
    const key = row?.articleId || row?.id || `${row?.title || 'untitled'}-${index}`
    if (!rowMap.has(key)) {
      rowMap.set(key, row)
    }
  })
  return Array.from(rowMap.values())
}

const isShowAll = computed(() => activeTopic.value === TOPIC_ALL && !customKeyword.value)

const filteredCourseEntries = computed(() => {
  if (allCourseEntries.value.length === 0) return []
  if (isShowAll.value) return allCourseEntries.value
  return allCourseEntries.value.filter((item) => {
    const fullText = `${item.title || ''} ${item.section || ''} ${item.category || ''} ${item.knowledgePoints || ''}`
    return matchCurrentTopic(fullText)
  })
})

const difficultyLevels = computed(() => {
  const list = filteredCourseEntries.value
  return [
    { value: 'basic', label: '基础', count: list.filter((item) => item.level === 'basic').length },
    { value: 'advance', label: '进阶', count: list.filter((item) => item.level === 'advance').length },
    { value: 'expert', label: '高阶', count: list.filter((item) => item.level === 'expert').length },
  ]
})

const displayCourseEntries = computed(() => {
  if (!selectedDifficulty.value) return filteredCourseEntries.value
  return filteredCourseEntries.value.filter((item) => item.level === selectedDifficulty.value)
})

const loadArticles = async () => {
  const requestId = articleRequestSeq.value + 1
  articleRequestSeq.value = requestId
  loadingArticles.value = true
  articleErrorMessage.value = ''
  try {
    const params = { pageNum: 1, pageSize: 20, status: 'published' }
    const keyword = currentKeyword.value || '绿色饭店'
    const searchKeywords = keyword === '绿色饭店' ? [keyword] : [keyword, '绿色饭店']
    let mergedRows = []

    for (const searchKeyword of searchKeywords) {
      const response = await searchArticles(searchKeyword, params)
      const rows = extractRows(response)
      mergedRows = mergeRowsById(mergedRows, rows)
    }

    const matchedArticles = filterGreenArticles(mergedRows.map(normalizeArticle))

    if (requestId !== articleRequestSeq.value) return
    articles.value = matchedArticles
  } catch (error) {
    if (requestId !== articleRequestSeq.value) return
    logger.error('加载绿色饭店知识内容失败:', error)
    articles.value = []
    articleErrorMessage.value = '知识内容加载失败，请稍后重试。'
  } finally {
    if (requestId === articleRequestSeq.value) {
      loadingArticles.value = false
    }
  }
}

const selectTopic = (topic) => {
  activeTopic.value = topic
  customKeyword.value = ''
  keywordInput.value = ''
  selectedDifficulty.value = ''
  loadArticles()
}

const applySearch = () => {
  customKeyword.value = keywordInput.value
  selectedDifficulty.value = ''
  loadArticles()
}

const retryLoadArticles = () => {
  loadArticles()
}

const scrollToSection = (type) => {
  const target = type === 'courses' ? courseSectionRef.value : articleSectionRef.value
  if (!target || typeof target.scrollIntoView !== 'function') return
  target.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

const goToPractice = () => {
  router.push({
    path: '/online',
    query: {
      mode: 'category',
      focus: 'green-hotel',
      keyword: currentKeyword.value || '绿色饭店',
    },
  })
}

const selectDifficulty = (level) => {
  selectedDifficulty.value = selectedDifficulty.value === level ? '' : level
  scrollToSection('courses')
}

const clearDifficulty = () => {
  selectedDifficulty.value = ''
}

const goToCourseCenter = (keyword) => {
  router.push({ path: '/green-hotel/courses', query: keyword ? { keyword } : {} })
}

const goToArticle = (articleId) => {
  if (!articleId) return
  router.push(`/knowledge/${articleId}`)
}

onMounted(() => {
  loadArticles()
  loadCourseEntries()
})
</script>

<style scoped>
.green-hotel-page {
  --gh-bg: #f1f5ef;
  --gh-surface: #fffdfa;
  --gh-forest: #2d6a4f;
  --gh-leaf: #4c956c;
  --gh-earth: #8a5a44;
  --gh-text: #243228;
  --gh-muted: #607067;
  --gh-line: #d6dfd0;

  background: radial-gradient(circle at 0 0, #eef5ec 0%, var(--gh-bg) 65%);
  color: var(--gh-text);
  font-family: 'Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.gh-hero {
  background: linear-gradient(135deg, #3f7a59, #285741);
}

.mobile-topic-scroll {
  -webkit-overflow-scrolling: touch;
  scrollbar-width: thin;
  scrollbar-color: #a8c8b1 transparent;
  touch-action: pan-x;
  padding-bottom: 6px;
}

.mobile-topic-scroll::-webkit-scrollbar {
  height: 4px;
}

.mobile-topic-scroll::-webkit-scrollbar-track {
  background: #ecf4ed;
  border-radius: 2px;
}

.mobile-topic-scroll::-webkit-scrollbar-thumb {
  background: #a8c8b1;
  border-radius: 2px;
}

.topic-side-entry {
  margin: 10px 10px 12px;
  border-top: 1px solid #e0ece1;
  padding-top: 10px;
}

.topic-side-title {
  font-size: 12px;
  color: #64806f;
  margin-bottom: 8px;
}

.topic-side-link {
  min-height: 34px;
  border: 1px solid #cfe2d2;
  border-radius: 10px;
  background: #f3f9f4;
  color: #2d6548;
  text-decoration: none;
  font-size: 12px;
  padding: 0 10px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.search-box {
  display: flex;
  gap: 8px;
}

.search-box input {
  flex: 1;
  min-height: 40px;
  border: 1px solid var(--gh-line);
  border-radius: 10px;
  padding: 10px 12px;
  font-size: 14px;
  outline: none;
  color: var(--gh-text);
  background: #fff;
}

.search-box button {
  border: none;
  min-width: 88px;
  min-height: 40px;
  background: var(--gh-leaf);
  color: #fff;
  border-radius: 10px;
  padding: 0 16px;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.search-box button:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 14px rgba(76, 149, 108, 0.28);
}

.difficulty-route {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.difficulty-node {
  border: 1px solid #d6e7d9;
  border-radius: 999px;
  padding: 8px 12px;
  background: #f8fcf8;
  text-align: left;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
}

.difficulty-node.active {
  border-color: #72a884;
  background: #edf8f0;
  box-shadow: 0 4px 10px rgba(48, 82, 58, 0.1);
  transform: translateY(-1px);
}

.difficulty-level {
  font-size: 12px;
  font-weight: 700;
  color: #2a4f36;
}

.difficulty-count {
  font-size: 11px;
  color: var(--gh-muted);
}

.difficulty-actions {
  margin-top: 10px;
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.difficulty-action-btn {
  min-height: 32px;
  border: 1px solid #c8dccb;
  border-radius: 999px;
  background: #f1f9f2;
  color: #2f6448;
  font-size: 12px;
  padding: 0 12px;
  cursor: pointer;
}

.difficulty-action-btn.secondary {
  background: #e6f3e9;
}

.quick-entry-card {
  border: 1px solid #dbe9dc;
  background: #fff;
  border-radius: 12px;
  min-height: 72px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  text-align: left;
  transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
}

.quick-entry-card:hover {
  border-color: #9fc5ab;
  box-shadow: 0 8px 18px rgba(48, 82, 58, 0.1);
  transform: translateY(-1px);
}

.quick-entry-course {
  border-color: #84b596;
  background: linear-gradient(135deg, #f5fcf7, #ecf8ef);
}

.course-entry-tag {
  display: inline-flex;
  align-items: center;
  min-height: 22px;
  border-radius: 999px;
  padding: 0 8px;
  font-size: 11px;
  color: #1f5f3e;
  border: 1px solid #abd1b7;
  background: #e4f4e8;
}

.entry-icon {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.entry-main {
  flex: 1;
  min-width: 0;
}

.entry-main h4 {
  margin: 0;
  color: #2a4f36;
  font-size: 13px;
  font-weight: 700;
}

.entry-main p {
  margin: 2px 0 0;
  color: var(--gh-muted);
  font-size: 12px;
}

.stat-card {
  background: var(--gh-surface);
  border-radius: 14px;
  padding: 14px;
  border: 1px solid var(--gh-line);
  box-shadow: 0 8px 20px rgba(50, 66, 54, 0.06);
}

.stat-card .label {
  color: var(--gh-muted);
  font-size: 12px;
}

.stat-card .value {
  margin-top: 4px;
  font-size: 26px;
  font-weight: 700;
  color: var(--gh-forest);
}

.stat-card .value.text {
  font-size: 16px;
  font-weight: 600;
  color: var(--gh-earth);
}

.content-card {
  background: var(--gh-surface);
  border-radius: 14px;
  padding: 16px;
  border: 1px solid var(--gh-line);
  box-shadow: 0 10px 22px rgba(48, 67, 54, 0.06);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.card-header h2 {
  margin: 0;
  font-size: 18px;
  color: var(--gh-text);
}

.link-btn {
  color: var(--gh-forest);
  font-size: 13px;
  text-decoration: none;
  font-weight: 600;
}

.placeholder {
  background: #f7faf5;
  border: 1px dashed #c9d8c4;
  border-radius: 8px;
  padding: 20px;
  color: var(--gh-muted);
  font-size: 14px;
}

.retry-btn {
  margin-top: 10px;
  border: none;
  background: var(--gh-leaf);
  color: #fff;
  border-radius: 8px;
  padding: 6px 12px;
  min-height: 36px;
  cursor: pointer;
}

.article-list,
.course-list {
  display: grid;
  gap: 10px;
}

.course-list {
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.article-item {
  border: 1px solid #deeadf;
  border-radius: 10px;
  padding: 12px;
  cursor: pointer;
  transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
}

.article-item:hover {
  border-color: #95ba9d;
  box-shadow: 0 7px 18px rgba(48, 82, 58, 0.12);
  transform: translateY(-1px);
}

.article-item h3 {
  margin: 0;
  font-size: 16px;
  color: #2a4f36;
}

.article-item p {
  margin: 6px 0;
  color: #4f6356;
  font-size: 13px;
  line-height: 1.6;
}

.meta {
  display: flex;
  gap: 12px;
  color: #75897d;
  font-size: 12px;
}

.course-item {
  border: 1px solid #deeadf;
  border-radius: 12px;
  padding: 14px;
  background: #fcfefb;
  box-shadow: 0 8px 18px rgba(48, 82, 58, 0.06);
  cursor: pointer;
  transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
}

.course-item:hover {
  border-color: #95ba9d;
  box-shadow: 0 7px 18px rgba(48, 82, 58, 0.12);
  transform: translateY(-1px);
}

.course-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.course-title {
  font-size: 17px;
  font-weight: 600;
  color: #2a4f36;
}

.course-title-wrap {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.course-green-badge {
  display: inline-flex;
  align-items: center;
  min-height: 22px;
  padding: 0 8px;
  border-radius: 999px;
  border: 1px solid #b8d6be;
  background: #ecf7ee;
  color: #2a6b3f;
  font-size: 11px;
  font-weight: 600;
}

.course-level {
  background: #eef6ef;
  color: #2f5d42;
  border: 1px solid #d0e1d1;
  border-radius: 999px;
  padding: 2px 8px;
  font-size: 12px;
}

.actions {
  margin-top: 14px;
  display: flex;
  gap: 8px;
}

.action-btn {
  flex: 1;
  text-align: center;
  text-decoration: none;
  background: var(--gh-forest);
  color: #fff;
  border-radius: 8px;
  padding: 9px 10px;
  font-size: 13px;
  transition: transform 0.2s ease, box-shadow 0.2s ease, opacity 0.2s ease;
}

.action-btn.secondary {
  background: var(--gh-earth);
}

.action-btn.tertiary {
  background: #3f7a59;
}

.action-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 14px rgba(45, 106, 79, 0.24);
}

.search-box input:focus,
.search-box button:focus-visible,
.retry-btn:focus-visible,
.course-item:focus-visible,
.action-btn:focus-visible,
.link-btn:focus-visible,
.article-item:focus-visible,
.difficulty-node:focus-visible,
.difficulty-action-btn:focus-visible,
.topic-side-link:focus-visible,
.quick-entry-card:focus-visible {
  outline: 2px solid #6da67e;
  outline-offset: 2px;
}

@media (max-width: 767px) {
  .gh-hero-inner {
    padding-top: 14px;
    padding-bottom: 14px;
  }

  .gh-hero-badge {
    margin-bottom: 8px;
    padding: 3px 8px;
    gap: 5px;
    font-size: 10px;
  }

  .gh-hero-title {
    font-size: 1rem;
    margin-bottom: 4px;
  }

  .gh-hero-desc {
    font-size: 11px;
    line-height: 1.4;
    max-width: 19rem;
  }

  .gh-hero-tags {
    margin-top: 8px;
    gap: 5px;
  }

  .gh-hero-tags span {
    padding: 3px 7px;
    font-size: 10px;
  }

  .gh-mobile-topic-wrap {
    margin-bottom: 8px;
  }

  .gh-mobile-topic-panel {
    padding: 7px;
    border-radius: 12px;
  }

  .gh-mobile-topic-head {
    margin-bottom: 5px;
  }

  .gh-mobile-topic-icon {
    width: 18px;
    height: 18px;
    border-radius: 5px;
  }

  .gh-mobile-topic-pill {
    padding: 4px 9px;
    border-radius: 9px;
    font-size: 10px;
  }

  .mobile-topic-scroll {
    padding-bottom: 3px;
  }

  .gh-mobile-overview {
    gap: 6px;
  }

  .gh-route-card {
    padding: 8px;
    border-radius: 12px;
  }

  .gh-route-title {
    margin-bottom: 5px;
    gap: 5px;
    line-height: 1.25;
  }

  .gh-route-icon {
    width: 16px;
    height: 16px;
    border-radius: 5px;
  }

  .gh-route-desc {
    margin-bottom: 5px;
    font-size: 10px;
    line-height: 1.25;
  }

  .difficulty-route {
    gap: 5px;
  }

  .difficulty-node {
    flex: 1 1 calc(50% - 3px);
    min-width: calc(50% - 3px);
    justify-content: space-between;
    padding: 6px 8px;
    gap: 4px;
  }

  .difficulty-level {
    font-size: 10px;
  }

  .difficulty-count {
    font-size: 9px;
    white-space: nowrap;
  }

  .gh-summary-card {
    width: 4.35rem;
    padding: 6px 5px;
    border-radius: 10px;
  }

  .gh-summary-head {
    margin-bottom: 2px;
    gap: 2px;
  }

  .gh-summary-head span {
    font-size: 8px !important;
  }

  .gh-summary-value {
    font-size: 0.92rem;
    line-height: 1;
    margin-bottom: 2px;
  }

  .gh-summary-action {
    min-height: 20px;
    padding-top: 3px;
    padding-bottom: 3px;
    padding-left: 4px;
    padding-right: 4px;
    border-radius: 6px;
    font-size: 8px;
    line-height: 1;
  }

  .gh-summary-action-icon {
    margin-right: 0 !important;
    font-size: 8px !important;
  }

  .gh-summary-action-label {
    white-space: nowrap;
    letter-spacing: 0.02em;
  }

  .gh-mobile-quick {
    gap: 6px;
  }

  .gh-mobile-quick-row {
    gap: 6px;
  }

  .gh-mobile-quick-card {
    padding: 8px;
    border-radius: 12px;
    gap: 6px;
  }

  .gh-mobile-quick-icon {
    width: 24px;
    height: 24px;
    border-radius: 7px;
  }

  .gh-mobile-search-card {
    padding: 6px 7px;
    border-radius: 12px;
  }

  .gh-mobile-search-input {
    padding-top: 7px;
    padding-bottom: 7px;
    padding-right: 46px;
    padding-left: 28px;
    font-size: 10px;
  }

  .gh-mobile-search-button {
    min-height: 22px;
    padding: 3px 7px;
    border-radius: 7px;
    font-size: 9px;
  }
}

@media (max-width: 420px) {
  .gh-hero-inner {
    padding-top: 12px;
    padding-bottom: 12px;
  }

  .gh-hero-desc {
    font-size: 10px;
    line-height: 1.35;
  }

  .gh-mobile-topic-panel {
    padding: 6px;
  }

  .gh-route-card {
    padding: 7px;
  }

  .difficulty-node {
    padding: 5px 7px;
  }

  .gh-summary-card {
    width: 3.95rem;
    padding: 5px 4px;
  }

  .gh-summary-value {
    font-size: 0.84rem;
  }

  .gh-mobile-quick-card {
    padding: 7px;
  }

  .gh-mobile-quick-card h4 {
    font-size: 11px;
  }

  .gh-mobile-quick-card p {
    font-size: 9px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .article-item,
  .search-box button,
  .action-btn,
  .quick-entry-card,
  .difficulty-node {
    transition: none;
  }
}

@media (max-width: 900px) {
  .course-list {
    grid-template-columns: 1fr;
  }

  .actions {
    flex-direction: column;
  }

  .search-box {
    width: 100%;
  }

  .search-box button {
    min-width: 72px;
  }
}

.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
