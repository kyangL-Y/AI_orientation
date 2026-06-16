<template>
  <!-- 纯文字模块 - 与管理端样式一致 -->
  <div class="text-block" :style="sectionStyle">
    <h2 v-if="module.titleCn" :style="titleStyle">{{ module.titleCn }}</h2>
    <div class="text-line" :style="{ background: styles.accentColor || '#8b5cf6' }"></div>
    <p v-if="module.description" :style="descStyle">{{ module.description }}</p>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  module: { type: Object, required: true },
  globalStyles: { type: Object, default: () => ({}) }
})

const styles = computed(() => props.module.styles || {})
const size = computed(() => props.module.size || {})

const sectionStyle = computed(() => ({
  padding: (size.value.padding || 40) + 'px 30px',
  backgroundColor: styles.value.backgroundColor || '#fff',
  textAlign: 'center'
}))

const titleStyle = computed(() => ({
  fontFamily: styles.value.fontFamily || 'system-ui',
  fontSize: (styles.value.titleFontSize || 28) + 'px',
  color: styles.value.titleColor || '#1a1a1a',
  fontWeight: styles.value.titleFontWeight || '300',
  fontStyle: styles.value.italic ? 'italic' : 'normal',
  textDecoration: styles.value.underline ? 'underline' : 'none'
}))

const descStyle = computed(() => ({
  fontFamily: styles.value.fontFamily || 'system-ui',
  fontSize: (styles.value.contentFontSize || 15) + 'px',
  color: styles.value.contentColor || '#6b7280',
  textAlign: styles.value.textAlign || 'center'
}))
</script>

<style scoped>
.text-block {
  width: 100%;
  text-align: center;
}

.text-block h2 {
  margin: 0 0 16px;
  letter-spacing: 4px;
}

.text-line {
  width: 60px;
  height: 3px;
  margin: 0 auto 20px;
  border-radius: 2px;
}

.text-block p {
  max-width: 700px;
  margin: 0 auto;
  line-height: 1.8;
}
</style>
