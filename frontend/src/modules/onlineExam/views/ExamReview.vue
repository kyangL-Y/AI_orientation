<template>
  <div class="min-h-screen bg-gray-50">
    <HeaderBar />
    <div class="h-16 md:h-[72px]"></div>
    
    <div class="py-4 md:py-8 px-3 md:px-6 max-w-7xl mx-auto">
      <!-- 返回按钮 -->
      <button @click="goBack" class="mb-4 flex items-center gap-2 text-gray-600 hover:text-blue-600 transition-colors">
        <i class="fa fa-arrow-left"></i>
        <span>返回列表</span>
      </button>

      <!-- 加载中 -->
      <div v-if="loading" class="flex items-center justify-center py-20">
        <div class="text-center">
          <div class="w-16 h-16 border-4 border-blue-200 border-t-blue-500 rounded-full animate-spin mx-auto mb-4"></div>
          <p class="text-gray-500">加载中...</p>
        </div>
      </div>

      <!-- 考试详情 -->
      <div v-else-if="examDetail" class="space-y-6">
        <!-- 成绩概览卡片 -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-bold text-gray-800">{{ examDetail.examName || '考试回看' }}</h2>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="text-center p-4 bg-blue-50 rounded-lg">
              <div class="text-sm text-gray-600 mb-1">{{ reviewResultTitle }}</div>
              <div class="text-2xl font-bold" :class="reviewResultValueClass">{{ reviewResultValue }}</div>
            </div>
            <div class="text-center p-4 bg-green-50 rounded-lg">
              <div class="text-sm text-gray-600 mb-1">正确率</div>
              <div class="text-2xl font-bold text-green-600">
                {{ examDetail.questionCount > 0 ? Math.round((examDetail.correctCount / examDetail.questionCount) * 100) : 0 }}%
              </div>
            </div>
            <div class="text-center p-4 bg-purple-50 rounded-lg">
              <div class="text-sm text-gray-600 mb-1">用时</div>
              <div class="text-2xl font-bold text-purple-600">{{ formatDuration(examDetail.durationSeconds) }}</div>
            </div>
            <div class="text-center p-4 bg-amber-50 rounded-lg">
              <div class="text-sm text-gray-600 mb-1">题目数</div>
              <div class="text-2xl font-bold text-amber-600">{{ examDetail.questionCount || 0 }}</div>
            </div>
          </div>

          <div class="mt-4 text-sm text-gray-500">
            <i class="fa fa-calendar mr-2"></i>
            提交时间：{{ formatDateTime(examDetail.submittedAt) }}
          </div>
        </div>

        <!-- 题目列表 -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h3 class="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
            <div class="w-1 h-5 bg-blue-600 rounded-full"></div>
            题目详情
          </h3>

          <div v-if="questionDetails && questionDetails.length > 0" class="space-y-6">
            <div 
              v-for="(question, index) in questionDetails" 
              :key="question.id"
              class="pb-6 border-b border-gray-100 last:border-0"
            >
              <!-- 题目标题 -->
              <div class="flex items-start gap-3 mb-3">
                <span 
                  class="shrink-0 w-8 h-8 rounded-lg text-sm font-bold flex items-center justify-center text-white shadow-sm"
                  :class="question.isCorrect === 1 ? 'bg-green-500' : 'bg-red-500'"
                >
                  {{ index + 1 }}
                </span>
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="text-xs font-bold px-2 py-1 rounded bg-gray-100 text-gray-600">
                      {{ getQuestionTypeName(question.questionType) }}
                    </span>
                    <span 
                      class="text-xs font-bold px-2 py-1 rounded"
                      :class="question.isCorrect === 1 ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-600'"
                    >
                      {{ question.isCorrect === 1 ? '正确' : '错误' }}
                    </span>
                  </div>
                  <p class="text-gray-800 font-medium leading-relaxed">{{ question.questionText }}</p>
                </div>
              </div>

              <!-- 选项 -->
              <div v-if="hasOptions(question)" class="pl-11 mb-4 space-y-2">
                <div v-if="question.optionA" class="flex gap-2 p-2 rounded hover:bg-gray-50">
                  <span class="font-mono font-bold text-gray-400">A.</span>
                  <span class="text-gray-600">{{ question.optionA }}</span>
                </div>
                <div v-if="question.optionB" class="flex gap-2 p-2 rounded hover:bg-gray-50">
                  <span class="font-mono font-bold text-gray-400">B.</span>
                  <span class="text-gray-600">{{ question.optionB }}</span>
                </div>
                <div v-if="question.optionC" class="flex gap-2 p-2 rounded hover:bg-gray-50">
                  <span class="font-mono font-bold text-gray-400">C.</span>
                  <span class="text-gray-600">{{ question.optionC }}</span>
                </div>
                <div v-if="question.optionD" class="flex gap-2 p-2 rounded hover:bg-gray-50">
                  <span class="font-mono font-bold text-gray-400">D.</span>
                  <span class="text-gray-600">{{ question.optionD }}</span>
                </div>
              </div>

              <!-- 答案对比 -->
              <div class="grid grid-cols-2 gap-4 pl-11 mb-4">
                <div 
                  class="p-3 rounded-lg border"
                  :class="question.isCorrect === 1 ? 'bg-green-50 border-green-100' : 'bg-red-50 border-red-100'"
                >
                  <span 
                    class="text-xs font-bold block mb-1"
                    :class="question.isCorrect === 1 ? 'text-green-600' : 'text-red-600'"
                  >
                    你的答案
                  </span>
                  <span 
                    class="font-bold text-lg"
                    :class="question.isCorrect === 1 ? 'text-green-700' : 'text-red-700'"
                  >
                    {{ question.userAnswer || '未作答' }}
                  </span>
                </div>
                <div class="bg-blue-50 p-3 rounded-lg border border-blue-100">
                  <span class="text-xs font-bold text-blue-600 block mb-1">正确答案</span>
                  <span class="font-bold text-lg text-blue-700">{{ question.correctAnswer }}</span>
                </div>
              </div>

              <!-- 解析 -->
              <div v-if="question.explanation" class="bg-gray-50 p-4 rounded-lg border border-gray-200 ml-11">
                <div class="flex items-start gap-2">
                  <i class="fa fa-lightbulb-o text-blue-500 mt-1"></i>
                  <div>
                    <span class="font-bold text-gray-800 text-sm block mb-1">解析</span>
                    <span class="text-gray-600 text-sm leading-relaxed">{{ question.explanation }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-12 text-gray-400">
            <i class="fa fa-inbox text-5xl mb-3"></i>
            <p>暂无题目详情</p>
          </div>
        </div>
      </div>

      <!-- 错误提示 -->
      <div v-else class="text-center py-20">
        <i class="fa fa-exclamation-circle text-5xl text-gray-300 mb-4"></i>
        <p class="text-gray-500 mb-4">无法加载考试详情</p>
        <button @click="goBack" class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
          返回列表
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import HeaderBar from '@/components/HeaderBar.vue'
import { getExamDetail } from '@/api/examRecord'
import logger from '@/utils/logger'
import { getResultDisplayTextClass, getResultDisplayTitle, getResultDisplayValue, normalizeLevelThresholds, normalizeResultDisplayMode } from '../utils/resultDisplay'
const route = useRoute()
const router = useRouter()

const loading = ref(true)
const examDetail = ref(null)
const questionDetails = computed(() => examDetail.value?.questionDetails || [])
const reviewResultDisplayMode = computed(() => normalizeResultDisplayMode(examDetail.value?.resultDisplayMode))
const reviewResultDisplayConfig = computed(() => normalizeLevelThresholds(examDetail.value || {}))
const reviewResultTitle = computed(() => getResultDisplayTitle(reviewResultDisplayMode.value))
const reviewResultValue = computed(() => getResultDisplayValue(examDetail.value?.score, reviewResultDisplayMode.value, reviewResultDisplayConfig.value))
const reviewResultValueClass = computed(() => getResultDisplayTextClass(examDetail.value?.score, reviewResultDisplayMode.value, reviewResultDisplayConfig.value))

const getCurrentUserId = () => {
  const raw = localStorage.getItem('userInfo')
  if (!raw) return null
  try {
    const parsed = JSON.parse(raw)
    return parsed?.userId || parsed?.id || null
  } catch {
    return null
  }
}

const normalizeAttemptId = (value) => {
  if (value === null || value === undefined) return ''
  return String(value).trim()
}

const isSafeAttemptId = (attemptId) => /^[A-Za-z0-9_-]{1,64}$/.test(attemptId)

const isSameAttempt = (detail, attemptId) => {
  if (!detail || typeof detail !== 'object') return false
  const detailAttemptId = detail.attemptId || detail.id || detail.recordId
  if (detailAttemptId === null || detailAttemptId === undefined || detailAttemptId === '') {
    return true
  }
  return String(detailAttemptId) === String(attemptId)
}

const belongsToCurrentUser = (detail) => {
  if (!detail || typeof detail !== 'object') return false
  const ownerId = detail.userId || detail.uid || detail.createdBy || detail.createBy || detail.submitterId
  if (!ownerId) return true
  const currentUserId = getCurrentUserId()
  if (!currentUserId) return true
  return String(ownerId) === String(currentUserId)
}

// 格式化时长
const formatDuration = (seconds) => {
  if (!seconds) return '0分钟'
  const minutes = Math.floor(seconds / 60)
  const secs = seconds % 60
  if (minutes > 0) {
    return secs > 0 ? `${minutes}分${secs}秒` : `${minutes}分钟`
  }
  return `${secs}秒`
}

// 格式化日期时间
const formatDateTime = (dateStr) => {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 获取题目类型名称
const getQuestionTypeName = (type) => {
  const typeMap = {
    'single': '单选题',
    'multiple': '多选题',
    'judge': '判断题',
    'text': '简答题',
    'fill': '填空题'
  }
  return typeMap[type] || type
}

// 判断是否有选项
const hasOptions = (question) => {
  return question.optionA || question.optionB || question.optionC || question.optionD
}

// 返回列表
const goBack = () => {
  router.back()
}

// 加载考试详情
const loadExamDetail = async () => {
  try {
    loading.value = true
    const attemptId = normalizeAttemptId(route.params.attemptId)

    if (!isSafeAttemptId(attemptId)) {
      logger.warn('⚠️ 非法 attemptId，拒绝加载:', route.params.attemptId)
      examDetail.value = null
      return
    }
    
    logger.debug('🔍 加载考试详情, attemptId:', attemptId)
    
    // 先尝试从路由state获取数据
    if (history.state && history.state.examDetail &&
      isSameAttempt(history.state.examDetail, attemptId) &&
      belongsToCurrentUser(history.state.examDetail)
    ) {
      examDetail.value = history.state.examDetail
      logger.debug('✅ 从路由state获取考试详情成功')
    } else {
      // 否则从API获取
      const res = await getExamDetail(attemptId)
      if (res?.data?.code === 200 && res.data.data &&
        isSameAttempt(res.data.data, attemptId) &&
        belongsToCurrentUser(res.data.data)
      ) {
        examDetail.value = res.data.data
        logger.debug('✅ 从API获取考试详情成功')
      } else {
        logger.error('❌ 获取考试详情失败:', res)
      }
    }
  } catch (error) {
    logger.error('❌ 加载考试详情失败:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadExamDetail()
})
</script>

<style scoped>
/* 自定义样式 */
</style>



