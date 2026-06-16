<template>
  <!-- 图文模块 - 与管理端样式一致 -->
  <div class="section-block" :style="sectionStyle">
    <div class="section-title" :style="{ textAlign: styles.textAlign || 'center' }">
      <h2 v-if="module.titleCn" :style="titleStyle">{{ module.titleCn }}</h2>
      <span v-if="module.titleEn" :style="subtitleStyle">{{ module.titleEn }}</span>
    </div>
    
    <!-- 多图展示 -->
    <div v-if="hasMultipleImages" class="images-container" style="gap: 12px;">
      <div v-for="(img, idx) in module.images" :key="idx" class="section-image with-overlay" :style="{ ...imageStyle, flex: '1' }">
        <img :src="getImageUrl(img.url)" :style="{ filter: imageFilter }" />
        <div v-if="img.overlayText" class="image-overlay-text">{{ img.overlayText }}</div>
      </div>
    </div>
    
    <!-- 单图展示 -->
    <div v-else-if="hasImage" class="section-image with-overlay" :style="imageStyle">
      <img :src="getImageUrl(module.images[0].url)" :style="{ filter: imageFilter }" />
      <div v-if="module.images[0].overlayText" class="image-overlay-text">{{ module.images[0].overlayText }}</div>
    </div>
    
    <p v-if="module.description" class="section-desc" :style="descStyle">{{ module.description }}</p>
  </div>
</template>

<script setup>
import { computed } from 'vue'

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

const styles = computed(() => props.module.styles || {})
const size = computed(() => props.module.size || {})

const hasImage = computed(() => props.module.images?.length > 0 && props.module.images[0]?.url)
const hasMultipleImages = computed(() => props.module.images?.length > 1)

const sectionStyle = computed(() => ({
  padding: (size.value.padding || 40) + 'px 30px',
  backgroundColor: styles.value.backgroundColor || '#fff'
}))

const titleStyle = computed(() => ({
  fontFamily: styles.value.fontFamily || 'system-ui',
  fontSize: (styles.value.titleFontSize || 28) + 'px',
  color: styles.value.titleColor || '#1a1a1a',
  fontWeight: styles.value.titleFontWeight || '300',
  fontStyle: styles.value.italic ? 'italic' : 'normal',
  textDecoration: styles.value.underline ? 'underline' : 'none',
  textAlign: styles.value.textAlign || 'center'
}))

const subtitleStyle = computed(() => ({
  fontFamily: styles.value.fontFamily || 'system-ui',
  fontSize: (styles.value.subtitleFontSize || 13) + 'px',
  color: styles.value.subtitleColor || '#9ca3af'
}))

const descStyle = computed(() => ({
  fontFamily: styles.value.fontFamily || 'system-ui',
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

.images-container {
  display: flex;
  width: 100%;
}

.section-image {
  width: 100%;
  overflow: hidden;
  position: relative;
}

.section-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s;
}

.section-image:hover img {
  transform: scale(1.03);
}

.section-image.with-overlay .image-overlay-text {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 20px;
  background: linear-gradient(transparent, rgba(0,0,0,0.7));
  color: #fff;
  font-size: 14px;
  line-height: 1.6;
}

.section-desc {
  margin: 20px auto 0;
  max-width: 600px;
  line-height: 1.8;
}

@media (max-width: 768px) {
  .images-container {
    flex-direction: column;
    gap: 12px !important;
  }
  
  .section-image {
    flex: none !important;
  }
}
</style>

