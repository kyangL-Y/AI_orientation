<template>
  <div
    v-if="modelValue"
    class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50 backdrop-blur-sm"
    @click="$emit('update:modelValue', false)"
  >
    <div
      class="bg-white rounded-3xl p-8 text-center max-w-sm w-full mx-4 relative overflow-hidden shadow-2xl transform animate-bounce-in"
      @click.stop
    >
      <div class="absolute inset-0 bg-gradient-to-b from-amber-50 via-white to-blue-50 -z-10"></div>

      <div class="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
        <div
          v-for="n in 20"
          :key="n"
          class="absolute w-2 h-2 rounded-full animate-confetti"
          :style="{
            left: Math.random() * 100 + '%',
            top: -10 + '%',
            backgroundColor: ['#FFD700', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FF9F43'][Math.floor(Math.random() * 6)],
            animationDelay: Math.random() * 2 + 's',
            animationDuration: (Math.random() * 2 + 2) + 's'
          }"
        ></div>
      </div>

      <div class="relative z-10">
        <div class="mb-5 relative inline-block">
          <div class="absolute inset-0 bg-amber-200 rounded-full blur-2xl opacity-60 animate-pulse scale-150"></div>
          <div class="relative w-24 h-24 bg-gradient-to-br from-amber-300 to-amber-500 rounded-full flex items-center justify-center shadow-lg">
            <i class="fa fa-trophy text-5xl text-white drop-shadow-md"></i>
          </div>
          <div class="absolute -top-1 -right-1 text-2xl animate-bounce">✨</div>
          <div class="absolute -bottom-1 -left-1 text-2xl animate-bounce" style="animation-delay: 0.3s">🎉</div>
        </div>

        <h3 class="text-2xl font-bold text-slate-800 mb-2">🎊 太棒了！目标达成！</h3>
        <p class="text-slate-500 mb-6 leading-relaxed">
          恭喜您完成了今日 <span class="text-blue-600 font-bold text-xl">{{ dailyPracticeTarget }}</span> 道题的目标！<br>
          <span class="text-sm">坚持就是胜利，继续保持哦~</span>
        </p>

        <button
          @click="$emit('update:modelValue', false)"
          class="px-8 py-3 bg-gradient-to-r from-amber-400 to-orange-500 text-white rounded-full font-bold shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 active:scale-95"
        >
          <i class="fa fa-thumbs-up mr-2"></i>我知道了
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  modelValue: {
    type: Boolean,
    required: true,
  },
  dailyPracticeTarget: {
    type: Number,
    required: true,
  },
})

defineEmits(['update:modelValue'])
</script>

