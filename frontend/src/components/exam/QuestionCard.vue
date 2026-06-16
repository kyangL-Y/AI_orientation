<template>
  <div class="bg-white rounded-2xl md:rounded-3xl shadow-sm border border-slate-100 overflow-hidden min-h-[400px] md:min-h-[500px] flex flex-col relative">
    <div v-if="loading" class="absolute inset-0 bg-white/80 backdrop-blur-sm z-20 flex flex-col items-center justify-center">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mb-4"></div>
      <p class="text-slate-500 text-sm font-medium">正在加载题目...</p>
    </div>

    <div v-else-if="!question" class="absolute inset-0 bg-white z-10 flex flex-col items-center justify-center text-center p-8">
      <div class="w-24 h-24 bg-slate-50 rounded-full flex items-center justify-center mb-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h3 class="text-lg font-bold text-slate-700 mb-2">暂时没有相关题目</h3>
      <p class="text-slate-500 text-sm max-w-xs mx-auto mb-6">该分类下可能暂时没有题目，或者您已经完成了所有练习。</p>
      <button @click="$emit('goDaily')" class="px-6 py-2 bg-blue-600 text-white rounded-lg text-sm font-bold hover:bg-blue-700 transition-colors">
        去做每日一练
      </button>
    </div>

    <template v-else>
      <div class="px-8 py-6 border-b border-slate-50 flex justify-between items-start">
        <div class="flex items-center gap-3">
          <span class="text-xl font-serif font-bold text-slate-300 italic">#{{ currentIndex + 1 }}</span>
          <div class="flex items-center gap-2">
            <span
              class="px-2 py-0.5 rounded text-xs font-medium border"
              :class="question.level === '简单'
                ? 'bg-emerald-50 text-emerald-600 border-emerald-100'
                : (question.level === '困难'
                    ? 'bg-rose-50 text-rose-600 border-rose-100'
                    : 'bg-amber-50 text-amber-600 border-amber-100')"
            >
              {{ question.level || '中等' }}
            </span>

            <span class="px-2 py-0.5 rounded text-xs font-medium bg-indigo-50 text-indigo-600 border border-indigo-100">
              {{ question.type || '单选题' }}
            </span>

            <span class="px-2 py-0.5 rounded text-xs font-medium bg-slate-50 text-slate-500 border border-slate-100">
              {{ question.tag || '通用知识' }}
            </span>
          </div>
        </div>
        <div class="flex gap-2">
          <button
            @click="$emit('toggleFav')"
            class="w-8 h-8 rounded-full hover:bg-amber-50 flex items-center justify-center transition-all"
            :class="isFavorite ? 'text-amber-500' : 'text-slate-300 hover:text-amber-500'"
            title="收藏题目"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" :fill="isFavorite ? 'currentColor' : 'none'" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
            </svg>
          </button>
        </div>
      </div>

      <div class="px-8 py-6 flex-1">
        <h1 class="text-xl md:text-2xl font-bold text-slate-800 leading-relaxed mb-8">
          {{ question.title || '题目加载中...' }}
        </h1>

        <template v-if="isTextQuestion">
          <div class="max-w-3xl">
            <el-input
              v-model="localTextAnswer"
              type="textarea"
              :rows="isFillQuestion ? 4 : 6"
              :placeholder="isFillQuestion ? '请输入填空答案，多个空请用分号分隔' : '请输入简答答案'"
              class="custom-textarea"
            />
            <div class="mt-3 text-sm text-slate-400">
              <span v-if="isFillQuestion">多个空请使用分号分隔，例如：答案1;答案2</span>
              <span v-else>可直接输入简答答案要点</span>
            </div>
          </div>
        </template>

        <div class="space-y-4 max-w-3xl" v-else-if="question.options && question.options.length > 0">
          <div
            v-for="(option, index) in question.options"
            :key="index"
            @click="$emit('selectOption', index)"
            class="group relative flex items-center p-4 rounded-2xl border-2 transition-all duration-200 cursor-pointer"
            :class="getOptionClass(index)"
          >
            <div class="w-10 h-10 rounded-xl flex items-center justify-center text-sm font-bold mr-4 transition-all shrink-0 shadow-sm" :class="getOptionMarkerClass(index)">
              {{ String.fromCharCode(65 + index) }}
            </div>
            <span class="text-base font-medium text-slate-700 group-hover:text-slate-900">{{ option }}</span>

            <div v-if="showAnswer" class="absolute right-4 flex items-center gap-2">
              <div
                v-if="isCorrectOptionPart(index) && !isSelectedOption(index) && !isMultipleChoice"
                class="px-2 py-0.5 bg-emerald-100 text-emerald-600 text-xs font-bold rounded border border-emerald-200"
              >
                正确答案
              </div>
              <div
                v-if="isCorrectOptionPart(index) && !isSelectedOption(index) && isMultipleChoice"
                class="px-2 py-0.5 bg-emerald-100 text-emerald-600 text-xs font-bold rounded border border-emerald-200"
              >
                漏选
              </div>
              <div
                v-if="isCorrectOptionPart(index) && isSelectedOption(index)"
                class="flex items-center text-emerald-600 font-bold text-xs bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                你的选择
              </div>
              <div
                v-if="!isCorrectOptionPart(index) && isSelectedOption(index)"
                class="flex items-center text-rose-600 font-bold text-xs bg-rose-50 px-2 py-0.5 rounded border border-rose-200"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
                选择错误
              </div>
            </div>
          </div>
        </div>

        <transition name="slide-fade">
          <div v-if="showAnswer" class="mt-8 bg-slate-50 rounded-2xl p-6 border border-slate-200/60">
            <div class="flex items-center gap-3 mb-3">
              <div class="bg-emerald-500 text-white px-3 py-1 rounded-lg text-sm font-bold shadow-sm shadow-emerald-200">
                答案 {{ formatAnswer(question.correctAnswer, question.type) }}
              </div>
              <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">题目解析</span>
            </div>
            <p class="text-slate-600 text-sm leading-relaxed">
              {{ question.explanation || '暂无详细解析' }}
            </p>
          </div>
        </transition>
      </div>

      <div class="px-8 py-5 bg-white border-t border-slate-100 flex justify-between items-center sticky bottom-0 z-10">
        <button
          @click="$emit('prev')"
          class="px-5 py-2.5 text-slate-500 font-bold text-sm hover:bg-slate-50 rounded-xl transition-colors flex items-center gap-2 disabled:opacity-30 disabled:cursor-not-allowed"
          :disabled="currentIndex === 0"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          上一题
        </button>

        <div class="flex gap-3">
          <button
            v-if="!showAnswer"
            @click="$emit('submit')"
            class="px-8 py-2.5 bg-blue-600 text-white rounded-xl font-bold text-sm hover:bg-blue-700 shadow-lg shadow-blue-200 hover:shadow-blue-300 transform hover:-translate-y-0.5 transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="!canSubmit"
          >
            <span>提交答案</span>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </button>

          <button
            v-else
            @click="$emit('next')"
            class="px-8 py-2.5 bg-slate-800 text-white rounded-xl font-bold text-sm hover:bg-slate-900 shadow-lg shadow-slate-200 hover:shadow-slate-300 transform hover:-translate-y-0.5 transition-all flex items-center gap-2"
          >
            <span>下一题</span>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
            </svg>
          </button>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'

const props = defineProps({
  loading: {
    type: Boolean,
    default: false,
  },
  question: {
    type: Object,
    default: null,
  },
  currentIndex: {
    type: Number,
    required: true,
  },
  selectedOption: {
    type: [Number, Array, String, Object],
    default: null,
  },
  showAnswer: {
    type: Boolean,
    required: true,
  },
  isFavorite: {
    type: Boolean,
    default: false,
  },
  isMultipleChoice: {
    type: Boolean,
    default: false,
  },
  getOptionClass: {
    type: Function,
    required: true,
  },
  getOptionMarkerClass: {
    type: Function,
    required: true,
  },
  isCorrectOptionPart: {
    type: Function,
    required: true,
  },
  isSelectedOption: {
    type: Function,
    required: true,
  },
  formatAnswer: {
    type: Function,
    required: true,
  },
})

const emit = defineEmits(['goDaily', 'toggleFav', 'selectOption', 'updateAnswer', 'prev', 'submit', 'next'])

const isTextQuestion = computed(() => ['text', 'fill', '简答', '填空', '简答题', '填空题'].includes(props.question?.type))
const isFillQuestion = computed(() => ['fill', '填空', '填空题'].includes(props.question?.type))
const localTextAnswer = ref('')

const normalizeTextValue = (value) => {
  if (value === undefined || value === null) return ''
  return String(value)
}

watch(
  () => props.selectedOption,
  (value) => {
    if (isTextQuestion.value) {
      localTextAnswer.value = normalizeTextValue(value)
    }
  },
  { immediate: true }
)

watch(localTextAnswer, (value) => {
  if (isTextQuestion.value) {
    emit('updateAnswer', value)
  }
})

const canSubmit = computed(() => {
  if (isTextQuestion.value) {
    return normalizeTextValue(localTextAnswer.value).trim().length > 0
  }

  if (Array.isArray(props.selectedOption)) {
    return props.selectedOption.length > 0
  }

  return props.selectedOption !== null && props.selectedOption !== ''
})
</script>
