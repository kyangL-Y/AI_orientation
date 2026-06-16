<template>
  <div class="bg-white rounded border border-slate-200 p-3 hover:border-blue-300 transition-colors">
    <div class="flex items-center justify-between mb-2">
      <h4 class="text-sm font-semibold text-slate-800">{{ plan.title || plan.planName }}</h4>
      <span class="text-[10px] px-1.5 py-0.5 rounded"
        :class="{
          'bg-emerald-50 text-emerald-600': plan.status === 'completed',
          'bg-blue-50 text-blue-600': plan.status === 'active' || plan.status === 'in_progress',
          'bg-slate-100 text-slate-500': !plan.status || plan.status === 'pending'
        }"
      >
        {{ statusLabel }}
      </span>
    </div>

    <p v-if="plan.description" class="text-xs text-slate-500 mb-2 line-clamp-2">{{ plan.description }}</p>

    <!-- 进度条 -->
    <div v-if="progress > 0" class="mb-2">
      <div class="flex items-center justify-between text-[10px] text-slate-400 mb-1">
        <span>进度</span>
        <span>{{ progress }}%</span>
      </div>
      <div class="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
        <div class="h-full rounded-full transition-all duration-300"
          :class="progress === 100 ? 'bg-emerald-500' : 'bg-blue-500'"
          :style="{ width: progress + '%' }"
        ></div>
      </div>
    </div>

    <!-- 任务列表 -->
    <div v-if="plan.planItems && plan.planItems.length > 0" class="space-y-1">
      <div
        v-for="(item, index) in displayedItems"
        :key="item.itemId || index"
        class="flex items-center gap-2 text-xs text-slate-600 hover:text-blue-600 cursor-pointer py-1"
        @click.stop="$emit('item-click', item)"
      >
        <i class="fa w-4 text-center"
          :class="{
            'fa-check-circle text-emerald-500': item.status === 'completed',
            'fa-play-circle text-blue-500': item.status === 'active' || item.status === 'in_progress',
            'fa-circle-o text-slate-300': !item.status || item.status === 'pending'
          }"
        ></i>
        <span class="truncate flex-1" :class="{ 'line-through text-slate-400': item.status === 'completed' }">
          {{ item.title || item.taskName || item.itemName }}
        </span>
        <span class="text-[10px] text-slate-400 border border-slate-100 px-1 rounded">
          {{ typeLabel(item.contentType) }}
        </span>
      </div>
      <div v-if="plan.planItems.length > maxItems" class="text-center">
        <button class="text-[10px] text-blue-500 hover:text-blue-700" @click.stop="expanded = !expanded">
          {{ expanded ? '收起' : `还有 ${plan.planItems.length - maxItems} 项...` }}
        </button>
      </div>
    </div>

    <!-- 底部元数据 -->
    <div v-if="plan.startDate || plan.endDate" class="flex items-center gap-3 text-[10px] text-slate-400 mt-2 pt-2 border-t border-slate-50">
      <span v-if="plan.startDate"><i class="fa fa-calendar mr-1"></i>{{ plan.startDate }}</span>
      <span v-if="plan.endDate">至 {{ plan.endDate }}</span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LearningPlanCard',
  props: {
    plan: { type: Object, required: true },
    maxItems: { type: Number, default: 5 }
  },
  emits: ['item-click'],
  data() {
    return { expanded: false }
  },
  computed: {
    statusLabel() {
      const map = { completed: '已完成', active: '进行中', in_progress: '进行中', pending: '未开始', 'not-started': '未开始' }
      return map[this.plan.status] || '未开始'
    },
    progress() {
      const items = this.plan.planItems
      if (!items || items.length === 0) return 0
      const done = items.filter(i => i.status === 'completed').length
      return Math.round((done / items.length) * 100)
    },
    displayedItems() {
      if (!this.plan.planItems) return []
      return this.expanded ? this.plan.planItems : this.plan.planItems.slice(0, this.maxItems)
    }
  },
  methods: {
    typeLabel(type) {
      const map = { course: '课程', quiz: '测验', exam: '考试', task: '任务', assignment: '作业' }
      return map[type] || type || '任务'
    }
  }
}
</script>
