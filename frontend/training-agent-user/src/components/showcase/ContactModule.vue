<template>
  <!-- 联系方式模块 - 与管理端样式一致 -->
  <div class="contact-block" :style="contactStyle">
    <div class="contact-content">
      <div class="contact-info">
        <h3 v-if="module.titleCn">{{ module.titleCn }}</h3>
        <!-- 新格式 items 数组 -->
        <p v-for="(item, idx) in contactItems" :key="idx">
          <span class="icon">{{ item.icon }}</span> {{ item.value }}
        </p>
        <!-- 兼容旧格式 -->
        <template v-if="!contactItems.length">
          <p v-if="typeConfig.phone"><span class="icon">📞</span> {{ typeConfig.phone }}</p>
          <p v-if="typeConfig.email"><span class="icon">✉️</span> {{ typeConfig.email }}</p>
          <p v-if="typeConfig.address"><span class="icon">📍</span> {{ typeConfig.address }}</p>
        </template>
      </div>
      <div class="contact-qr" v-if="typeConfig.qrCodeUrl">
        <img :src="getImageUrl(typeConfig.qrCodeUrl)" />
        <span>{{ typeConfig.qrCodeText || '扫码关注' }}</span>
      </div>
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

const styles = computed(() => props.module.styles || {})
const typeConfig = computed(() => props.module.typeConfig || {})

const contactItems = computed(() => {
  const items = typeConfig.value.items || []
  return items.filter(item => item.value)
})

const contactStyle = computed(() => {
  const bgColor = styles.value.backgroundColor || '#1a1a1a'
  // 判断背景是否为浅色
  const isLightBg = bgColor === '#fff' || bgColor === '#ffffff' || bgColor === 'white' || bgColor === 'transparent' || bgColor === ''
  return {
    backgroundColor: bgColor,
    color: isLightBg ? '#1a1a1a' : (styles.value.contentColor || '#fff')
  }
})
</script>

<style scoped>
.contact-block {
  padding: 50px 40px;
  width: 100%;
}

.contact-content {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.contact-info h3 {
  font-size: 24px;
  font-weight: 300;
  margin: 0 0 24px;
  letter-spacing: 2px;
}

.contact-info p {
  margin: 0 0 14px;
  font-size: 14px;
  opacity: 0.9;
  display: flex;
  align-items: center;
  gap: 8px;
}

.contact-info .icon {
  font-size: 16px;
}

.contact-qr {
  text-align: center;
}

.contact-qr img {
  width: 100px;
  height: 100px;
  border-radius: 8px;
}

.contact-qr span {
  display: block;
  margin-top: 8px;
  font-size: 12px;
  opacity: 0.7;
}

@media (max-width: 768px) {
  .contact-block {
    padding: 30px 20px;
  }
  
  .contact-content {
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 30px;
  }
  
  .contact-info p {
    justify-content: center;
  }
}
</style>

