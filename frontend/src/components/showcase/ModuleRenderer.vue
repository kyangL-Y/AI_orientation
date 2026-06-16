<template>
  <!-- 模块渲染器 - 根据模块类型分发到对应组件 -->
  <!-- Requirements: 1.6, 3.5 -->
  <div v-if="shouldRender" class="module-renderer" :class="moduleClass">
    <!-- 顶部大图模块 -->
    <HeroModule 
      v-if="module.type === ModuleType.HERO" 
      :module="module" 
      :globalStyles="globalStyles"
    />
    
    <!-- 图文混排模块 -->
    <TextImageModule 
      v-else-if="module.type === ModuleType.TEXT_IMAGE" 
      :module="module" 
      :globalStyles="globalStyles"
    />
    
    <!-- 纯文字模块 -->
    <TextOnlyModule 
      v-else-if="module.type === ModuleType.TEXT_ONLY" 
      :module="module" 
      :globalStyles="globalStyles"
    />
    
    <!-- 图片轮播模块 -->
    <CarouselModule 
      v-else-if="module.type === ModuleType.CAROUSEL" 
      :module="module" 
      :globalStyles="globalStyles"
    />
    
    <!-- 多图展示模块 -->
    <GalleryModule 
      v-else-if="module.type === ModuleType.GALLERY" 
      :module="module" 
      :globalStyles="globalStyles"
    />
    
    <!-- 联系卡片模块 -->
    <ContactModule 
      v-else-if="module.type === ModuleType.CONTACT" 
      :module="module" 
      :globalStyles="globalStyles"
    />
    
    <!-- 未知类型的后备显示 -->
    <div v-else class="unknown-module">
      <p>未知模块类型: {{ module.type }}</p>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { ModuleType } from '@/types/showcase'
import HeroModule from './HeroModule.vue'
import TextImageModule from './TextImageModule.vue'
import TextOnlyModule from './TextOnlyModule.vue'
import CarouselModule from './CarouselModule.vue'
import GalleryModule from './GalleryModule.vue'
import ContactModule from './ContactModule.vue'

const props = defineProps({
  // 模块配置
  module: {
    type: Object,
    required: true
  },
  // 全局样式配置
  globalStyles: {
    type: Object,
    default: () => ({})
  },
  // 是否为移动端
  isMobile: {
    type: Boolean,
    default: false
  }
})

/**
 * 计算是否应该渲染此模块
 * - 检查 visible 属性
 * - 移动端时检查 mobileVisible 属性
 */
const shouldRender = computed(() => {
  // 基础可见性检查
  if (props.module.visible === false) {
    return false
  }
  
  // 移动端可见性检查
  if (props.isMobile && props.module.mobileVisible === false) {
    return false
  }
  
  return true
})

/**
 * 模块容器的CSS类
 */
const moduleClass = computed(() => {
  return [
    `module-type-${props.module.type}`,
    {
      'module-hidden': !shouldRender.value
    }
  ]
})
</script>

<style scoped>
.module-renderer {
  width: 100%;
}

.module-hidden {
  display: none;
}

.unknown-module {
  padding: 20px;
  background: #fff3cd;
  border: 1px solid #ffc107;
  border-radius: 8px;
  text-align: center;
  color: #856404;
}
</style>
