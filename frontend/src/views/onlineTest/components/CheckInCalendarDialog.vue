<template>
  <el-dialog
    v-model="open"
    title="打卡日历"
    width="420px"
    class="rounded-2xl"
  >
    <div class="mb-3 flex items-center justify-between text-sm">
      <div class="text-slate-600">连续打卡 <span class="font-bold text-blue-600">{{ practiceDays }}</span> 天</div>
      <div class="text-slate-600">积分余额 <span class="font-bold text-amber-600">{{ myPoints }}</span></div>
    </div>

    <el-calendar v-model="innerCalendarDate">
      <template #dateCell="{ data }">
        <div class="h-full flex flex-col items-center pt-1.5 relative">
          <span
            class="w-6 h-6 rounded-full flex items-center justify-center text-xs"
            :class="{
              'bg-blue-600 text-white': isToday(data.day),
              'bg-emerald-100 text-emerald-700 font-bold': isCheckInDay(data.day) && !isToday(data.day),
              'text-slate-700': !isCheckInDay(data.day) && !isToday(data.day)
            }"
          >
            {{ data.day.split('-')[2] }}
          </span>
          <span
            v-if="isCheckInDay(data.day)"
            class="mt-1 w-1.5 h-1.5 rounded-full bg-emerald-500"
          ></span>
        </div>
      </template>
    </el-calendar>

    <div class="mt-2 text-xs text-slate-500">绿色日期代表当日已完成打卡（有答题记录）。每日首次打卡可获得 +10 积分。</div>
  </el-dialog>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: { type: Boolean, required: true },
  calendarDate: { type: Date, required: true },
  checkInDays: { type: Array, default: () => [] },
  practiceDays: { type: Number, default: 0 },
  myPoints: { type: Number, default: 0 }
})

const emit = defineEmits(['update:modelValue', 'update:calendarDate'])

const open = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v)
})

const innerCalendarDate = computed({
  get: () => props.calendarDate,
  set: (v) => emit('update:calendarDate', v)
})

const checkInDaySet = computed(() => new Set(props.checkInDays || []))

const isCheckInDay = (day) => checkInDaySet.value.has(day)

const isToday = (day) => {
  const now = new Date()
  const y = now.getFullYear()
  const m = String(now.getMonth() + 1).padStart(2, '0')
  const d = String(now.getDate()).padStart(2, '0')
  return day === `${y}-${m}-${d}`
}
</script>
