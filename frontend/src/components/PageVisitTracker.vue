<template>
  <!-- 这是一个功能性组件，不渲染UI内容 -->
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { useRoute } from 'vue-router';
import { recordPageVisit } from '@/api/pageVisit';

const props = defineProps({
  pageName: {
    type: String,
    default: null // 如果未指定，将使用路由名称
  }
});

const route = useRoute();
const sessionDuration = ref(0);
let activityTimer = null;
let lastTickTime = Date.now();
let isPageVisible = typeof document !== 'undefined' ? document.visibilityState === 'visible' : true;
let hasVisibilityListener = false;

// 重置会话计时器
const resetSessionTimer = () => {
  sessionDuration.value = 0;
  lastTickTime = Date.now();
};

// 开始计时
const startActivityTimer = () => {
  if (activityTimer) return;
  lastTickTime = Date.now();
  
  activityTimer = setInterval(() => {
    if (!isPageVisible) {
      lastTickTime = Date.now();
      return;
    }
    
    const now = Date.now();
    const delta = Math.floor((now - lastTickTime) / 1000);
    
    if (delta > 0) {
      sessionDuration.value += delta;
      lastTickTime = now;
    }
  }, 1000);
};

// 停止计时
const stopActivityTimer = () => {
  if (activityTimer) {
    clearInterval(activityTimer);
    activityTimer = null;
  }
};

// 处理页面可见性变化
const handleVisibilityChange = () => {
  isPageVisible = document.visibilityState === 'visible';
  
  if (isPageVisible) {
    // 页面恢复可见，重置计时起点
    lastTickTime = Date.now();
  }
};

// 保存页面访问记录
const savePageVisit = async () => {
  try {
    if (sessionDuration.value <= 0) return;
    
    const actualPageName = props.pageName || route.name || 'unknown';
    await recordPageVisit(actualPageName, sessionDuration.value);
    resetSessionTimer();
  } catch (error) {
    logger.error('保存页面访问记录失败:', error);
  }
};

// 初始化
onMounted(() => {
  if (typeof document !== 'undefined' && !hasVisibilityListener) {
    document.addEventListener('visibilitychange', handleVisibilityChange);
    hasVisibilityListener = true;
  }
  startActivityTimer();
  
  // 每5分钟保存一次，避免丢失太多数据
  const saveInterval = setInterval(() => {
    if (sessionDuration.value > 10) { // 只有超过10秒才保存
      savePageVisit();
    }
  }, 300000); // 5分钟 = 300,000毫秒
  
  // 清理函数
  onBeforeUnmount(() => {
    clearInterval(saveInterval);
    stopActivityTimer();
    
    if (typeof document !== 'undefined' && hasVisibilityListener) {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    }
    
    // 组件卸载时保存最后一次记录
    savePageVisit();
  });
});
</script>

