<template>
  <div
    class="mobile-question-list-btn lg:hidden"
    @click="$emit('open')"
  >
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
    </svg>

    <transition name="tip-fade">
      <div v-if="showTip" class="float-btn-tip">
        <div class="tip-content">
          <span>👆 点击这里切换题目</span>
          <button class="tip-close" @click.stop="$emit('dismissTip')">✕</button>
        </div>
        <div class="tip-arrow"></div>
      </div>
    </transition>
  </div>
</template>

<script setup>
defineProps({
  showTip: {
    type: Boolean,
    default: false,
  },
})

defineEmits(['open', 'dismissTip'])
</script>

