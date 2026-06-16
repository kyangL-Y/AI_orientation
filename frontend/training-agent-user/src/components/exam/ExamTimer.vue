<template>
  <span>{{ formatted }}</span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  duration: {
    type: Number,
    required: true,
  },
  formatter: {
    type: Function,
    default: null,
  },
})

const formatted = computed(() => {
  if (typeof props.formatter === 'function') return props.formatter(props.duration)
  return String(props.duration)
})
</script>

