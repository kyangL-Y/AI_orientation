<template>
  <!-- 图片墙模块 - 与管理端样式一致 -->
  <div class="section-block" :style="sectionStyle">
    <div class="section-title" v-if="module.titleCn" :style="{ textAlign: styles.textAlign || 'center' }">
      <h2 :style="titleStyle">{{ module.titleCn }}</h2>
      <span v-if="module.titleEn" :style="subtitleStyle">{{ module.titleEn }}</span>
    </div>
    
    <div class="gallery-box" :style="gridStyle">
      <div v-for="(img, i) in displayImages" :key="i" class="gallery-cell" :style="cellStyle">
        <img v-if="img.url" :src="getImageUrl(img.url)" :style="{ filter: imageFilter }" />
        <div v-else class="image-empty small"></div>
      </div>
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
const config = computed(() => props.module.typeConfig || {})

const displayImages = computed(() => {
  const images = props.module.images || []
  return images.length > 0 ? images : [{}, {}, {}]
})

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

const gridStyle = computed(() => ({
  gridTemplateColumns: `repeat(${config.value.columns || 3}, 1fr)`,
  gap: (config.value.gap || 12) + 'px'
}))

const cellStyle = computed(() => ({
  borderRadius: (styles.value.borderRadius || 8) + 'px'
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

.gallery-box {
  display: grid;
}

.gallery-cell {
  aspect-ratio: 1;
  overflow: hidden;
}

.gallery-cell img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s;
}

.gallery-cell:hover img {
  transform: scale(1.05);
}

.image-empty {
  width: 100%;
  height: 100%;
  background: #f9fafb;
}

.section-desc {
  margin: 20px auto 0;
  max-width: 600px;
  line-height: 1.8;
}

@media (max-width: 768px) {
  .gallery-box {
    grid-template-columns: repeat(2, 1fr) !important;
  }
}
</style>

