<template>
  <el-dialog
    v-model="open"
    title="设置今日目标"
    width="400px"
    class="rounded-2xl"
  >
    <div class="py-4">
      <div class="mb-4">
        <span class="text-sm text-slate-600 block mb-2">请设置您今天的刷题目标数量：</span>
        <div class="flex items-center justify-center gap-4">
          <el-input-number v-model="targetValue" :min="5" :max="100" :step="5" />
          <span class="text-sm text-slate-500">题</span>
        </div>
      </div>
      <div class="bg-blue-50 p-3 rounded-lg text-xs text-blue-600">
        <i class="fa fa-info-circle mr-1"></i>
        坚持完成每日目标，是提高通过率的关键哦！
      </div>
    </div>
    <template #footer>
      <div class="flex justify-end gap-2">
        <el-button @click="open = false">取消</el-button>
        <el-button type="primary" @click="$emit('confirm')">确定</el-button>
      </div>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true,
  },
  target: {
    type: Number,
    required: true,
  },
})

const emit = defineEmits(['update:modelValue', 'update:target', 'confirm'])

const open = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

const targetValue = computed({
  get: () => props.target,
  set: (v) => emit('update:target', v),
})
</script>

