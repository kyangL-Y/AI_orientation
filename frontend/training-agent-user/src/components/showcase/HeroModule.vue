<template>
  <!-- 顶部大图模块 - 与管理端样式一致 -->
  <div class="hero-section" :style="heroStyle">
    <img v-if="backgroundImage" :src="backgroundImage" class="hero-bg" :style="imageStyle" />
    <div class="hero-overlay" :style="overlayStyle"></div>
    <div class="hero-text" :style="textPositionStyle">
      <h1 v-if="module.titleCn" :style="titleStyle">{{ module.titleCn }}</h1>
      <p v-if="module.titleEn" :style="subtitleStyle">{{ module.titleEn }}</p>
    </div>
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

const backgroundImage = computed(() => {
  if (props.module.images?.length > 0) {
    return getImageUrl(props.module.images[0].url)
  }
  return ''
})

const heroStyle = computed(() => {
  const size = props.module.size || {}
  return {
    height: (size.imageHeight || 400) + 'px'
  }
})

const imageStyle = computed(() => {
  const styles = props.module.styles || {}
  const config = props.module.typeConfig || {}
  const b = styles.brightness || 100
  const c = styles.contrast || 100
  const s = styles.saturate || 100
  return {
    filter: `brightness(${b}%) contrast(${c}%) saturate(${s}%)`,
    objectPosition: config.objectPosition || 'center'
  }
})

const overlayStyle = computed(() => {
  const config = props.module.typeConfig || {}
  return {
    background: `rgba(0,0,0,${(config.overlayOpacity ?? 40) / 100})`
  }
})

const textPositionStyle = computed(() => {
  const config = props.module.typeConfig || {}
  const pos = config.textPosition || 'left'
  return {
    left: pos === 'left' ? '60px' : pos === 'center' ? '50%' : 'auto',
    right: pos === 'right' ? '60px' : 'auto',
    transform: pos === 'center' ? 'translateX(-50%)' : 'none',
    textAlign: pos
  }
})

const titleStyle = computed(() => {
  const styles = props.module.styles || {}
  return {
    fontFamily: styles.fontFamily || 'system-ui',
    fontSize: (styles.titleFontSize || 42) + 'px',
    color: styles.titleColor || '#fff',
    fontWeight: styles.titleFontWeight || '700',
    fontStyle: styles.italic ? 'italic' : 'normal',
    textDecoration: styles.underline ? 'underline' : 'none'
  }
})

const subtitleStyle = computed(() => {
  const styles = props.module.styles || {}
  return {
    fontFamily: styles.fontFamily || 'system-ui',
    fontSize: (styles.subtitleFontSize || 16) + 'px',
    color: styles.subtitleColor || 'rgba(255,255,255,0.85)'
  }
})
</script>

<style scoped>
.hero-section {
  position: relative;
  background: #1a1a1a;
  overflow: hidden;
}

.hero-bg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.hero-overlay {
  position: absolute;
  inset: 0;
}

.hero-text {
  position: absolute;
  bottom: 50px;
  max-width: 600px;
  z-index: 1;
}

.hero-text h1 {
  margin: 0 0 12px;
  text-shadow: 0 2px 12px rgba(0,0,0,0.4);
  line-height: 1.2;
}

.hero-text p {
  margin: 0;
}

@media (max-width: 768px) {
  .hero-section {
    height: 300px !important;
  }
  
  .hero-text {
    left: 20px !important;
    right: 20px !important;
    bottom: 30px !important;
    transform: none !important;
    text-align: left !important;
  }
  
  .hero-text h1 {
    font-size: 24px !important;
    margin-bottom: 8px;
  }
  
  .hero-text p {
    font-size: 14px !important;
  }
}
</style>

