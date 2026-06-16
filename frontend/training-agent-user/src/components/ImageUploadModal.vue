<template>
  <div v-if="show" class="fixed inset-0 bg-black/50 flex items-center justify-center z-[100000]" @click="closeModal">
    <div class="bg-white rounded-xl p-6 max-w-md w-full mx-4" @click.stop>
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-bold text-gray-800">{{ title }}</h3>
        <button @click="closeModal" class="text-gray-400 hover:text-gray-600">
          <i class="fa fa-times"></i>
        </button>
      </div>
      
      <div class="mb-4">
        <div 
          class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-500 transition-colors"
          :class="{ 'border-blue-500 bg-blue-50': isDragOver }"
          @click="selectFile"
          @dragover.prevent="handleDragOver"
          @dragleave.prevent="handleDragLeave"
          @drop.prevent="handleDrop"
        >
          <div v-if="!previewUrl" class="text-gray-500">
            <i class="fa fa-cloud-upload text-3xl mb-2"></i>
            <p class="text-sm">点击选择图片或拖拽到此处</p>
            <p class="text-xs text-gray-400 mt-1">支持 JPG、PNG、GIF 格式，最大 5MB</p>
          </div>
          <div v-else class="relative">
            <img :src="previewUrl" alt="预览" class="max-h-48 mx-auto rounded-lg">
            <button @click="removeImage" class="absolute top-2 right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600">
              <i class="fa fa-times"></i>
            </button>
          </div>
        </div>
        
        <input 
          ref="fileInput"
          type="file" 
          accept="image/*" 
          @change="handleFileSelect"
          class="hidden"
        >
      </div>
      
      <div class="flex gap-3">
        <button 
          @click="selectFile"
          class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
        >
          选择图片
        </button>
        <button 
          @click="confirmUpload"
          :disabled="!previewUrl"
          class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
        >
          确认上传
        </button>
      </div>
      
      <div v-if="error" class="mt-3 p-2 bg-red-50 border border-red-200 rounded text-red-600 text-sm">
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, watch } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: '上传图片'
  },
  maxSize: {
    type: Number,
    default: 5 * 1024 * 1024 // 5MB
  }
})

const emit = defineEmits(['close', 'confirm'])

const fileInput = ref(null)
const previewUrl = ref('')
const error = ref('')
const selectedFile = ref(null)
const isDragOver = ref(false)

const selectFile = () => {
  fileInput.value?.click()
}

const handleFileSelect = (event) => {
  const file = event.target.files[0]
  if (!file) return
  
  processFile(file)
}

const processFile = (file) => {
  // 检查文件大小
  if (file.size > props.maxSize) {
    error.value = `文件大小不能超过 ${Math.round(props.maxSize / 1024 / 1024)}MB`
    return
  }
  
  // 检查文件类型
  if (!file.type.startsWith('image/')) {
    error.value = '请选择图片文件'
    return
  }
  
  error.value = ''
  selectedFile.value = file
  
  // 压缩图片
  compressImage(file, (compressedDataUrl) => {
    previewUrl.value = compressedDataUrl
  })
}

// 图片压缩函数
const compressImage = (file, callback) => {
  const canvas = document.createElement('canvas')
  const ctx = canvas.getContext('2d')
  const img = new Image()
  
  img.onload = () => {
    // 设置最大尺寸
    const maxWidth = 400
    const maxHeight = 400
    
    let { width, height } = img
    
    // 计算压缩后的尺寸
    if (width > height) {
      if (width > maxWidth) {
        height = (height * maxWidth) / width
        width = maxWidth
      }
    } else {
      if (height > maxHeight) {
        width = (width * maxHeight) / height
        height = maxHeight
      }
    }
    
    // 设置canvas尺寸
    canvas.width = width
    canvas.height = height
    
    // 绘制压缩后的图片
    ctx.drawImage(img, 0, 0, width, height)
    
    // 转换为base64，质量设置为0.8
    const compressedDataUrl = canvas.toDataURL('image/jpeg', 0.8)
    
    logger.debug(`图片压缩: ${file.size} bytes -> ${compressedDataUrl.length} characters`)
    callback(compressedDataUrl)
  }
  
  img.src = URL.createObjectURL(file)
}

// 拖拽相关方法
const handleDragOver = (event) => {
  event.preventDefault()
  isDragOver.value = true
}

const handleDragLeave = (event) => {
  event.preventDefault()
  isDragOver.value = false
}

const handleDrop = (event) => {
  event.preventDefault()
  isDragOver.value = false
  
  const files = event.dataTransfer.files
  if (files.length > 0) {
    const file = files[0]
    processFile(file)
  }
}

const removeImage = () => {
  previewUrl.value = ''
  selectedFile.value = null
  error.value = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const confirmUpload = () => {
  if (selectedFile.value && previewUrl.value) {
    emit('confirm', {
      file: selectedFile.value,
      previewUrl: previewUrl.value
    })
    closeModal()
  }
}

const closeModal = () => {
  emit('close')
}

// 监听show变化，重置状态
watch(() => props.show, (newVal) => {
  if (!newVal) {
    removeImage()
  }
})
</script>

<style scoped>
/* 拖拽样式 */
.border-dashed {
  cursor: pointer;
  transition: all 0.3s ease;
}

.border-dashed:hover {
  border-color: #3b82f6;
  background-color: #f8fafc;
}

.border-dashed.drag-over {
  border-color: #3b82f6;
  background-color: #eff6ff;
  transform: scale(1.02);
}

/* 拖拽时的动画效果 */
@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
}

.border-dashed.drag-over {
  animation: pulse 0.5s ease-in-out;
}
</style>

