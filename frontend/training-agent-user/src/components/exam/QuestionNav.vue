<template>
  <div :class="compact ? 'question-nav-shell question-nav-shell-compact' : 'question-nav-shell'">
    <div v-if="!compact" class="p-4 border-b border-slate-50 bg-white z-10">
      <div class="flex justify-between items-center">
        <h3 class="font-bold text-slate-700 text-sm">{{ title }}</h3>
        <span class="text-xs text-slate-400 bg-slate-100 px-2 py-0.5 rounded-full">共 {{ questions.length }} 题</span>
      </div>
    </div>

    <div :class="compact ? 'question-nav-list question-nav-list-compact custom-scrollbar space-y-2' : 'question-nav-list custom-scrollbar p-2 space-y-1'">
      <div
        v-for="(q, index) in questions"
        :key="q.id || index"
        @click="$emit('jump', index)"
        class="group flex items-center gap-2 cursor-pointer transition-all"
        :class="compact
          ? (currentIndex === index ? 'p-3 rounded-lg bg-blue-50 border-2 border-blue-500' : 'p-3 rounded-lg bg-slate-50 border border-slate-200 hover:bg-slate-100')
          : (currentIndex === index ? 'px-3 py-2 rounded-xl bg-blue-50 text-blue-700 ring-1 ring-blue-100' : 'px-3 py-2 rounded-xl text-slate-600 hover:bg-slate-50')"
      >
        <span
          :class="[
            compact ? 'w-7 h-7' : 'w-6 h-6',
            'rounded-lg flex items-center justify-center text-xs font-bold shrink-0',
            getQuestionStatusClass ? getQuestionStatusClass(q, index) : '',
          ]"
        >
          {{ index + 1 }}
        </span>
        <span :class="[compact ? 'text-sm' : 'text-xs', 'truncate flex-1']">{{ q.title }}</span>
        <span
          v-if="q.isSubmitted"
          :class="[
            compact ? 'text-xs px-2 py-0.5 rounded shrink-0' : 'text-[10px] px-1 py-0.5 rounded shrink-0',
            q.isCorrect ? 'bg-emerald-100 text-emerald-600' : 'bg-rose-100 text-rose-600',
          ]"
        >
          {{ q.isCorrect ? '✓' : '✗' }}
        </span>
      </div>
    </div>

    <div v-if="showProgress" :class="compact ? 'mt-4 p-3 bg-slate-50 rounded-lg' : 'p-3 border-t border-slate-100 bg-slate-50'">
      <div class="flex justify-between text-xs text-slate-500 mb-2">
        <span>答题进度</span>
        <span v-if="compact" class="font-bold">{{ answeredCount }}/{{ questions.length }}</span>
        <span v-else>{{ answeredCount }}/{{ questions.length }}</span>
      </div>
      <div class="w-full h-2 bg-slate-200 rounded-full overflow-hidden">
        <div
          class="h-full bg-blue-500 rounded-full transition-all duration-300"
          :style="{ width: questions.length > 0 ? (answeredCount / questions.length * 100) + '%' : '0%' }"
        ></div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  questions: {
    type: Array,
    default: () => [],
  },
  currentIndex: {
    type: Number,
    required: true,
  },
  answeredCount: {
    type: Number,
    required: true,
  },
  getQuestionStatusClass: {
    type: Function,
    default: null,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  showProgress: {
    type: Boolean,
    default: true,
  },
  title: {
    type: String,
    default: '题目列表',
  },
})

defineEmits(['jump'])
</script>

<style scoped>
.question-nav-shell {
  display: flex;
  flex-direction: column;
  min-height: 0;
  max-height: min(600px, calc(100vh - 7rem));
}

.question-nav-shell-compact {
  max-height: 70vh;
}

.question-nav-list {
  flex: 1 1 auto;
  min-height: 0;
  overflow-y: auto;
  overscroll-behavior: contain;
}

.question-nav-list-compact {
  max-height: 60vh;
  flex: 0 1 auto;
}
</style>
