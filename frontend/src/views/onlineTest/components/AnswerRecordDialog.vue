<template>
  <el-dialog
    v-model="open"
    title="答题记录"
    width="800px"
    class="rounded-2xl"
  >
    <div class="h-[500px] overflow-y-auto custom-scrollbar pr-2">
      <div v-if="loadingRecords" class="text-center py-10">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 mx-auto animate-spin text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
      </div>

      <div v-else-if="answerRecords.length === 0" class="text-center py-10 text-slate-400 flex flex-col items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mb-2 text-slate-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        暂无记录
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="record in answerRecords"
          :key="record.id"
          class="bg-slate-50 p-4 rounded-xl border border-slate-100 hover:border-blue-200 hover:bg-blue-50/30 transition-colors cursor-pointer"
          @click="$emit('retest', record)"
        >
          <div class="flex justify-between items-center">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <span class="text-xs px-2 py-0.5 rounded font-bold" :class="record.isCorrect ? 'bg-emerald-100 text-emerald-700' : 'bg-rose-100 text-rose-700'">
                  {{ record.isCorrect ? '正确' : '错误' }}
                </span>
                <h4 class="text-sm font-bold text-slate-700 line-clamp-1">{{ resolveQuestionText(record) }}</h4>
              </div>
              <p class="text-xs text-slate-500">{{ formatDate(record.attemptTime) }} · {{ getQuestionTypeName(record.questionType) }}</p>
            </div>
            <div class="text-right text-xs ml-4 flex items-center gap-3">
              <div>
                <div>你的答案: <span :class="record.isCorrect ? 'text-emerald-600 font-bold' : 'text-rose-600 font-bold'">{{ formatUserAnswer(record) }}</span></div>
                <div v-if="!record.isCorrect" class="text-slate-400 mt-1">正确: <span class="text-emerald-600 font-bold">{{ record.correctAnswer }}</span></div>
              </div>
              <div class="w-8 h-8 rounded-full bg-slate-100 hover:bg-blue-500 text-slate-400 hover:text-white flex items-center justify-center transition-colors flex-shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </el-dialog>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true,
  },
  answerRecords: {
    type: Array,
    default: () => [],
  },
  loadingRecords: {
    type: Boolean,
    default: false,
  },
  resolveQuestionText: {
    type: Function,
    required: true,
  },
  formatDate: {
    type: Function,
    required: true,
  },
  getQuestionTypeName: {
    type: Function,
    required: true,
  },
  formatUserAnswer: {
    type: Function,
    required: true,
  },
})

const emit = defineEmits(['update:modelValue', 'retest'])

const open = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})
</script>
