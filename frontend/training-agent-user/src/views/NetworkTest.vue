<template>
  <div class="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100">
    <HeaderBar />
    <main class="container mx-auto px-4 py-6 max-w-4xl pt-20">
      <div class="bg-white rounded-2xl shadow-md p-6">
        <h2 class="text-2xl font-bold text-gray-800 mb-6">网络连接测试</h2>
        
        <!-- 网络环境信息 -->
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-gray-700 mb-3">当前网络环境</h3>
          <div class="bg-gray-50 rounded-lg p-4">
            <div class="grid grid-cols-2 gap-4 text-sm">
              <div><strong>Origin:</strong> {{ networkInfo.origin }}</div>
              <div><strong>Hostname:</strong> {{ networkInfo.hostname }}</div>
              <div><strong>Protocol:</strong> {{ networkInfo.protocol }}</div>
              <div><strong>Port:</strong> {{ networkInfo.port || '默认' }}</div>
              <div><strong>Backend URL:</strong> {{ networkInfo.backendUrl }}</div>
              <div><strong>Is Localhost:</strong> {{ networkInfo.isLocalhost ? '是' : '否' }}</div>
            </div>
          </div>
        </div>

        <!-- 连接测试 -->
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-gray-700 mb-3">后端连接测试</h3>
          <div class="flex gap-4 mb-4">
            <button 
              @click="testConnection" 
              :disabled="testing"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              {{ testing ? '测试中...' : '测试连接' }}
            </button>
            <button 
              @click="testCaptcha" 
              :disabled="testingCaptcha"
              class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
            >
              {{ testingCaptcha ? '测试中...' : '测试验证码' }}
            </button>
          </div>
          
          <div v-if="testResult" class="bg-gray-50 rounded-lg p-4">
            <h4 class="font-semibold mb-2">测试结果:</h4>
            <pre class="text-sm text-gray-700 whitespace-pre-wrap">{{ testResult }}</pre>
          </div>
        </div>

        <!-- 验证码显示 -->
        <div v-if="captchaImage" class="mb-6">
          <h3 class="text-lg font-semibold text-gray-700 mb-3">验证码图片</h3>
          <div class="bg-gray-50 rounded-lg p-4 text-center">
            <img :src="captchaImage" alt="验证码" class="mx-auto mb-2" />
            <p class="text-sm text-gray-600">UUID: {{ captchaUuid }}</p>
          </div>
        </div>

        <!-- 错误信息 -->
        <div v-if="errorMessage" class="bg-red-50 border border-red-200 rounded-lg p-4">
          <h4 class="font-semibold text-red-800 mb-2">错误信息:</h4>
          <p class="text-red-700">{{ errorMessage }}</p>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, onMounted } from 'vue'
import HeaderBar from '@/components/HeaderBar.vue'
import { getNetworkInfo, testBackendConnection, getCaptchaUrl } from '@/utils/backend'

const networkInfo = ref({})
const testResult = ref('')
const errorMessage = ref('')
const testing = ref(false)
const testingCaptcha = ref(false)
const captchaImage = ref('')
const captchaUuid = ref('')

onMounted(() => {
  networkInfo.value = getNetworkInfo()
})

const testConnection = async () => {
  testing.value = true
  testResult.value = ''
  errorMessage.value = ''
  
  try {
    const isConnected = await testBackendConnection()
    testResult.value = `连接测试结果: ${isConnected ? '成功' : '失败'}`
  } catch (error) {
    errorMessage.value = `连接测试失败: ${error.message}`
  } finally {
    testing.value = false
  }
}

const testCaptcha = async () => {
  testingCaptcha.value = true
  testResult.value = ''
  errorMessage.value = ''
  captchaImage.value = ''
  captchaUuid.value = ''
  
  try {
    const captchaUrl = getCaptchaUrl()
    logger.debug('测试验证码URL:', captchaUrl)
    
    const response = await fetch(captchaUrl, {
      method: 'GET',
      cache: 'no-store',
      mode: 'cors',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    })
    
    logger.debug('验证码响应状态:', response.status)
    
    if (response.ok) {
      const data = await response.json()
      logger.debug('验证码响应数据:', data)
      
      if (data.code === 200) {
        if (data.captchaEnabled === false) {
          testResult.value = '验证码已被禁用'
        } else if (data.img && data.uuid) {
          captchaImage.value = `data:image/jpeg;base64,${data.img}`
          captchaUuid.value = data.uuid
          testResult.value = '验证码获取成功'
        } else {
          testResult.value = '验证码数据不完整'
        }
      } else {
        testResult.value = `验证码获取失败: ${data.msg || '未知错误'}`
      }
    } else {
      testResult.value = `HTTP错误: ${response.status} ${response.statusText}`
    }
  } catch (error) {
    errorMessage.value = `验证码测试失败: ${error.message}`
    logger.error('验证码测试错误:', error)
  } finally {
    testingCaptcha.value = false
  }
}
</script>

<style scoped>
pre {
  font-family: 'Courier New', monospace;
}
</style>

