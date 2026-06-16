<template>
  <!-- 轮播模块 - 与管理端样式一致 -->
  <div class="section-block" :style="sectionStyle">
    <div class="section-title" v-if="module.titleCn" :style="{ textAlign: styles.textAlign || 'center' }">
      <h2 :style="titleStyle">{{ module.titleCn }}</h2>
      <span v-if="module.titleEn" :style="subtitleStyle">{{ module.titleEn }}</span>
    </div>
    
    <div class="carousel-box" :style="imageStyle">
      <img v-if="currentImage" :src="getImageUrl(currentImage.url)" :style="{ filter: imageFilter }" />
      <div v-else class="image-empty">
        <span>暂无图片</span>
      </div>
      <div class="carousel-dots" v-if="images.length > 1">
        <span v-for="(_, i) in images" :key="i" :class="{ active: currentIndex === i }" @click="currentIndex = i"></span>
      </div>
    </div>
    
    <p v-if="module.description" class="section-desc" :style="descStyle">{{ module.description }}</p>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  module: { type: Object, required: true },
  globalStyles: { type: Object, default: () => ({}) }
})

const BACKEND_URL = 'http://127.0.0.1:9090'

const getImageUrl = (url) => {
  if (!url) return ''
  if (url.startsWith('http')) return url
  if (url.startsWith('/profile/')) return BACKEND_URL + url
  return url
}

const currentIndex = ref(0)
let timer = null

const styles = computed(() => props.module.styles || {})
const size = computed(() => props.module.size || {})
const images = computed(() => props.module.images || [])
const currentImage = computed(() => images.value[currentIndex.value])
const config = computed(() => props.module.typeConfig || {})

const sectionStyle = computed(() => ({
  padding: (size.value.padding || 40) + 'px 30px',
  backgroundColor: styles.value.backgroundColor || '#fff'
}))

const titleStyle = computed(() => ({
  fontFamily: styles.value.fontFamily || 'system-ui',
  fontSize: (styles.value.titleFontSize || 28) + 'px',
  color: styles.value.titleColor || '#1a1a1a',
  fontWeight: styles.value.titleFontWeight || '300'
}))

const subtitleStyle = computed(() => ({
  fontSize: (styles.value.subtitleFontSize || 13) + 'px',
  color: styles.value.subtitleColor || '#9ca3af'
}))

const descStyle = computed(() => ({
  fontSize: (styles.value.contentFontSize || 15) + 'px',
  color: styles.value.contentColor || '#6b7280',
  textAlign: styles.value.textAlign || 'center'
}))

const imageStyle = computed(() => ({
  height: (size.value.imageHeight || 280) + 'px',
  borderRadius: (styles.value.borderRadius || 12) + 'px'
}))

const imageFilter = computed(() => {
  const b = styles.value.brightness || 100
  const c = styles.value.contrast || 100
  const s = styles.value.saturate || 100
  return `brightness(${b}%) contrast(${c}%) saturate(${s}%)`
})

onMounted(() => {
  if (config.value.autoplay !== false && images.value.length > 1) {
    timer = setInterval(() => {
      currentIndex.value = (currentIndex.value + 1) % images.value.length
    }, config.value.interval || 3000)
  }
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.section-block {
  width: 100%;
}

.section-title {
  margin-bottom: 24px;
}

.section-title h2 {
  margin: 0 0 8px;
  letter-spacing: 4px;
  line-height: 1.3;
}

.section-title span {
  font-size: 12px;
  letter-spacing: 2px;
  text-transform: uppercase;
}

.carousel-box {
  width: 100%;
  overflow: hidden;
  position: relative;
}

.carousel-box img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s;
}

.carousel-dots {
  position: absolute;
  bottom: 16px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 8px;
}

.carousel-dots span {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(255,255,255,0.5);
  cursor: pointer;
  transition: all 0.2s;
}

.carousel-dots span.active {
  background: #fff;
  transform: scale(1.2);
}

.image-empty {
  width: 100%;
  height: 100%;
  background: #f9fafb;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #9ca3af;
}

.section-desc {
  margin: 20px auto 0;
  max-width: 600px;
  line-height: 1.8;
}
</style>

