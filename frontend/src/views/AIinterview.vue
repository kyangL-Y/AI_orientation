<template>
  <div class="bg-slate-50 min-h-screen font-sans flex flex-col h-screen overflow-hidden">
    <!-- 导航栏占位符 -->
    <div class="h-[56px] md:h-[72px] shrink-0"></div>

    <div class="flex flex-1 overflow-hidden relative">
      <!-- 移动端侧边栏遮罩 -->
      <div 
        v-if="!isCollapsed && isMobile" 
        class="fixed inset-0 bg-black/50 z-20 backdrop-blur-sm transition-opacity"
        @click="isCollapsed = true"
      ></div>

      <!-- 左侧边栏 -->
      <div 
        :class="[
          'bg-white border-r border-slate-200 flex flex-col transition-all duration-300 z-20 h-full',
          isMobile ? 'fixed left-0 top-0 bottom-0 shadow-2xl' : 'relative',
          isCollapsed ? (isMobile ? '-translate-x-full w-64' : 'w-20') : (isMobile ? 'w-[85%] max-w-[320px]' : 'w-72')
        ]"
      >
        <!-- Logo和新建对话 -->
        <div class="p-4 border-b border-slate-100">
          <!-- 移动端关闭按钮 -->
          <button v-if="isMobile && !isCollapsed" @click="isCollapsed = true" class="absolute right-3 top-3 w-8 h-8 rounded-full bg-slate-100 text-slate-500 flex items-center justify-center">
             <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>

          <div class="flex items-center gap-3 mb-5 overflow-hidden whitespace-nowrap" v-if="!isCollapsed || isMobile">
             <div class="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center shrink-0 text-blue-600">
                <i class="fa fa-robot text-xl"></i>
             </div>
             <span class="text-lg font-bold text-slate-800 tracking-wide">华智AI</span>
          </div>
          <div class="flex items-center justify-center mb-5" v-else>
             <div class="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center shrink-0 text-blue-600">
                <i class="fa fa-robot text-xl"></i>
             </div>
          </div>

          <button 
            @click="createNewChat" 
            :class="[
              'w-full bg-blue-600 hover:bg-blue-700 text-white rounded-xl transition-all flex items-center justify-center shadow-lg shadow-blue-600/20',
              isCollapsed && !isMobile ? 'p-3' : 'px-4 py-3 gap-2'
            ]"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            <span v-if="!isCollapsed || isMobile" class="font-medium text-sm">开启新对话</span>
          </button>
        </div>

        <!-- PC端折叠开关 -->
        <button 
          v-if="!isMobile"
          @click="toggleSidebar" 
          class="absolute -right-3 top-8 w-6 h-6 rounded-full bg-white text-slate-400 shadow-md flex items-center justify-center hover:text-blue-600 border border-slate-100 z-10"
        >
          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path v-if="isCollapsed" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
          </svg>
        </button>

        <!-- 对话历史 -->
        <div class="flex-1 overflow-y-auto px-3 py-4 space-y-1 custom-scrollbar">
          <div v-if="conversations.length === 0" class="text-center py-8 text-slate-400 text-sm">
            <i class="fa fa-comments text-2xl mb-2 block opacity-50"></i>
            <span v-if="!isCollapsed || isMobile">暂无对话记录</span>
          </div>
          <div v-for="conversation in conversations" :key="conversation.id" 
               class="group relative rounded-xl transition-all cursor-pointer overflow-hidden"
               :class="[
                 conversation.active 
                   ? 'bg-blue-50 text-blue-700 shadow-sm ring-1 ring-blue-100' 
                   : 'text-slate-600 hover:bg-slate-50',
                 isCollapsed && !isMobile ? 'p-2 flex justify-center' : 'p-3'
               ]"
               @click="switchConversation(conversation.id)">
            
            <div v-if="!isCollapsed || isMobile" class="flex items-center gap-3">
              <i class="fa fa-comment-dots shrink-0" :class="conversation.active ? 'text-blue-500' : 'text-slate-400'"></i>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium truncate">{{ conversation.title || '新对话' }}</p>
                <p class="text-xs opacity-60 mt-0.5 truncate">{{ formatTime(conversation.timestamp) }}</p>
              </div>
              <button @click.stop="deleteChat(conversation.id)" 
                      class="p-1.5 hover:bg-red-50 hover:text-red-500 rounded-md transition-all"
                      :class="isMobile ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'">
                <i class="fa fa-trash-alt text-xs"></i>
              </button>
            </div>
            
            <!-- 折叠态显示小圆点或图标 -->
            <div v-else class="w-2 h-2 rounded-full" :class="conversation.active ? 'bg-blue-500' : 'bg-slate-300'"></div>
            
            <!-- 提示语 (Tooltip) 可以后续添加 -->
          </div>
        </div>
      </div>

      <!-- 主聊天区域 -->
      <div class="flex-1 flex flex-col bg-slate-50 relative w-full">
        <!-- 移动端顶部栏 -->
        <div v-if="isMobile" class="h-12 bg-white border-b border-slate-200 flex items-center px-3 justify-between shrink-0">
           <button @click="isCollapsed = false" class="w-9 h-9 rounded-lg bg-slate-50 text-slate-600 flex items-center justify-center">
             <i class="fa fa-bars"></i>
           </button>
           <span class="font-semibold text-slate-700 text-sm">华智 AI 学习助手</span>
           <button v-if="isLoggedIn && messages.length > 0" @click="clearCurrentHistory" class="w-9 h-9 rounded-lg bg-slate-50 text-slate-600 hover:bg-red-50 hover:text-red-600 flex items-center justify-center transition-colors">
             <i class="fa fa-eraser text-sm"></i>
           </button>
           <div v-else class="w-9"></div>
        </div>

        <!-- PC端顶部栏（新增） -->
        <div v-if="!isMobile && isLoggedIn && messages.length > 0" class="h-14 bg-white border-b border-slate-200 flex items-center px-6 justify-between shrink-0">
           <span class="font-semibold text-slate-700">当前对话</span>
           <button @click="clearCurrentHistory" class="px-4 py-2 rounded-lg bg-slate-50 text-slate-600 hover:bg-red-50 hover:text-red-600 flex items-center gap-2 transition-colors text-sm">
             <i class="fa fa-eraser"></i>
             <span>清除历史</span>
           </button>
        </div>

        <!-- 聊天内容区域 -->
        <div class="flex-1 overflow-y-auto p-3 md:p-8 scroll-smooth" ref="chatContainer">
          <div class="max-w-4xl mx-auto min-h-full flex flex-col">
            <!-- 未登录时显示登录提示 -->
            <div v-if="!isLoggedIn" class="flex-1 flex items-center justify-center px-4">
              <div class="text-center p-6 md:p-8 bg-white rounded-2xl shadow-xl max-w-md w-full border border-slate-100">
                <div class="w-16 h-16 md:w-20 md:h-20 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-5 md:mb-6 text-blue-600">
                  <i class="fa fa-user-lock text-2xl md:text-3xl"></i>
                </div>
                <h2 class="text-xl md:text-2xl font-bold text-slate-800 mb-2 md:mb-3">开启 AI 之旅</h2>
                <p class="text-slate-500 text-sm mb-6 md:mb-8 leading-relaxed">请登录以解锁华智酒店专属 AI 培训助手，获取专业的酒店服务指导。</p>
                <button @click="openLoginModal" 
                        class="w-full py-3 md:py-3.5 bg-gradient-to-r from-blue-600 to-blue-500 text-white rounded-xl font-semibold shadow-lg shadow-blue-500/30 hover:shadow-blue-500/40 transition-all active:scale-[0.98] text-sm md:text-base">
                  立即登录
                </button>
              </div>
            </div>
            
            <!-- 已登录时显示聊天消息 -->
            <div v-else class="pb-4">
              <!-- 欢迎消息 -->
              <div v-if="messages.length === 0" class="flex flex-col items-center justify-center py-8 md:py-20 px-2">
                <div class="w-20 h-20 md:w-24 md:h-24 bg-white rounded-2xl shadow-md flex items-center justify-center mb-6 md:mb-8 p-3 md:p-4">
                  <img :src="`/favicon1.png?t=${Date.now()}`" alt="Logo" class="w-full h-full object-contain" />
                </div>
                <h2 class="text-xl md:text-3xl font-bold text-slate-800 mb-3 md:mb-4 text-center">你好，我是华智 AI 助手</h2>
                <p class="text-slate-500 text-center max-w-lg mb-6 md:mb-8 text-sm md:text-base px-2">我可以为您提供酒店业务培训、情景模拟对话以及服务标准查询等支持。</p>
                
                <!-- 快捷建议 -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-3 w-full max-w-3xl">
                  <button @click="() => { message = '模拟投诉处理'; sendMessage(); }" class="p-3 md:p-4 bg-white border border-slate-200 rounded-xl hover:border-blue-300 hover:shadow-md transition-all text-left group">
                    <h3 class="font-semibold text-slate-700 group-hover:text-blue-600 mb-0.5 md:mb-1 text-sm">模拟投诉处理</h3>
                    <p class="text-xs text-slate-400">实战演练客诉场景</p>
                  </button>
                  <button @click="() => { message = 'OTA 规则查询'; sendMessage(); }" class="p-3 md:p-4 bg-white border border-slate-200 rounded-xl hover:border-blue-300 hover:shadow-md transition-all text-left group">
                    <h3 class="font-semibold text-slate-700 group-hover:text-blue-600 mb-0.5 md:mb-1 text-sm">OTA 规则查询</h3>
                    <p class="text-xs text-slate-400">携程/美团评分规则</p>
                  </button>
                  <button @click="() => { message = '安全理念速记'; sendMessage(); }" class="p-3 md:p-4 bg-white border border-slate-200 rounded-xl hover:border-blue-300 hover:shadow-md transition-all text-left group">
                    <h3 class="font-semibold text-slate-700 group-hover:text-blue-600 mb-0.5 md:mb-1 text-sm">安全理念速记</h3>
                    <p class="text-xs text-slate-400">消防/急救关键口诀</p>
                  </button>
                </div>
              </div>
              
              <!-- 聊天消息列表 -->
              <div v-else class="space-y-4 md:space-y-8">
                <div v-for="msg in messages" :key="msg.id" 
                     class="flex w-full" 
                     :class="msg.role === 'user' ? 'justify-end' : 'justify-start'">
                  
                  <!-- AI消息 -->
                  <div v-if="msg.role === 'assistant'" class="flex items-start gap-3 max-w-[92%] md:max-w-3xl group">
                    <div class="w-9 h-9 rounded-full bg-white flex items-center justify-center shrink-0 shadow-md p-0.5 ring-2 ring-white border border-slate-200">
                      <img :src="`/favicon1.png?t=${Date.now()}`" alt="AI" class="w-full h-full object-contain rounded-full bg-white" />
                    </div>
                    <div class="flex flex-col gap-1 min-w-0">
                      <span class="text-xs text-slate-400 ml-1 hidden md:block font-medium">华智 AI 助手</span>
                      <div class="bg-white rounded-2xl rounded-tl-none px-4 py-4 md:px-5 shadow-sm border border-slate-100 text-slate-700 leading-relaxed text-[15px] break-words prose prose-sm max-w-none prose-blue prose-p:my-1 prose-headings:my-2 prose-ul:my-1 prose-li:my-0.5" 
                           :class="{'border-red-200 bg-red-50': msg.isError}">
                        <div v-if="msg.searchMeta?.label" class="mb-3 flex flex-wrap items-center gap-2">
                          <span class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-semibold"
                                :class="msg.searchMeta.isWebSearch ? 'bg-blue-50 text-blue-700 ring-1 ring-blue-100' : 'bg-slate-100 text-slate-600 ring-1 ring-slate-200'">
                            <i class="fa" :class="msg.searchMeta.isWebSearch ? 'fa-globe' : 'fa-database'"></i>
                            {{ msg.searchMeta.label }}
                          </span>
                          <span v-if="msg.isLoading && msg.searchMeta.isWebSearch" class="text-[11px] text-slate-400">
                            正在检索并整理可引用来源
                          </span>
                        </div>
                        <div v-if="msg.isLoading" class="flex items-center gap-2 text-slate-500 py-1">
                          <div class="flex space-x-1.5">
                            <div class="w-2 h-2 bg-blue-400 rounded-full animate-bounce" style="animation-delay: 0s"></div>
                            <div class="w-2 h-2 bg-blue-400 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
                            <div class="w-2 h-2 bg-blue-400 rounded-full animate-bounce" style="animation-delay: 0.4s"></div>
                          </div>
                          <span class="text-xs font-medium ml-1">{{ getLoadingDisplayText(msg) }}</span>
                        </div>
                        <div v-else v-html="formatMessageContent(msg.content)"></div>
                      </div>
                      <div v-if="msg.sources?.length" class="rounded-2xl bg-slate-50/90 border border-slate-200 px-3 py-3 md:px-4">
                        <div class="mb-2 flex items-center gap-2 text-slate-600">
                          <i class="fa fa-link text-xs"></i>
                          <span class="text-xs font-semibold tracking-wide">参考来源</span>
                          <span class="text-[11px] text-slate-400">{{ msg.sources.length }} 条</span>
                        </div>
                        <div class="space-y-2">
                          <button
                            v-for="(source, sourceIndex) in msg.sources"
                            :key="`${msg.id}-source-${sourceIndex}`"
                            type="button"
                            class="w-full rounded-xl border border-slate-200 bg-white px-3 py-3 text-left transition-all hover:border-blue-200 hover:bg-blue-50/50"
                            @click="openSourceLink(source.url)"
                          >
                            <div class="flex items-start justify-between gap-3">
                              <div class="min-w-0 flex-1">
                                <p class="text-sm font-semibold text-slate-700 line-clamp-2">{{ source.title || '未命名来源' }}</p>
                                <p v-if="source.content" class="mt-1 text-xs leading-5 text-slate-500 line-clamp-3">{{ source.content }}</p>
                                <p v-if="source.url" class="mt-2 text-[11px] text-blue-600 break-all line-clamp-1">{{ source.url }}</p>
                              </div>
                              <span v-if="source.score !== '' && source.score !== null && source.score !== undefined"
                                    class="shrink-0 rounded-full bg-slate-100 px-2 py-1 text-[11px] font-medium text-slate-500">
                                {{ formatSourceScore(source.score) }}
                              </span>
                            </div>
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <!-- 用户消息 -->
                  <div v-else class="flex items-end justify-end gap-2 max-w-[85%] md:max-w-2xl">
                    <div class="user-message-bubble text-white px-5 py-3.5 rounded-2xl rounded-tr-none shadow-md text-[15px] leading-relaxed break-all overflow-hidden relative">
                      {{ msg.content }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
            
        <!-- 输入区域 -->
        <div class="p-4 md:p-6 z-10 shrink-0 pb-safe bg-white/80 backdrop-blur-md border-t border-white/50">
          <div class="max-w-4xl mx-auto">
            <div v-if="isLoggedIn" class="relative group bg-white rounded-3xl shadow-xl shadow-slate-200/50 border border-slate-200 focus-within:ring-4 focus-within:ring-blue-50 focus-within:border-blue-400 transition-all duration-300">
              <input 
                v-model="message"
                placeholder="输入您的问题，例如：'如何处理客诉？'"
                class="w-full py-4 md:py-5 pl-6 md:pl-7 pr-16 md:pr-20 bg-transparent border-none outline-none text-slate-700 placeholder-slate-400 text-[15px] md:text-base font-medium"
                :disabled="isLoading"
                @keydown.enter.prevent="sendMessage"
              />
              <div class="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1">
                <button 
                  @click="sendMessage"
                  :disabled="isLoading || !message.trim()"
                  class="w-10 h-10 md:w-12 md:h-12 flex items-center justify-center rounded-full transition-all duration-300 transform active:scale-90"
                  :class="message.trim() ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-lg shadow-blue-500/30 hover:shadow-blue-500/50 hover:-translate-y-0.5' : 'bg-slate-100 text-slate-400 cursor-not-allowed'"
                >
                  <svg v-if="!isLoading" class="w-5 h-5 md:w-6 md:h-6 transform rotate-90 translate-x-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 19V5m0 0l-7 7m7-7l7 7"></path>
                  </svg>
                  <div v-else class="w-5 h-5 md:w-6 md:h-6 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                </button>
              </div>
            </div>
            <p class="text-center text-xs text-slate-400 mt-3 font-medium tracking-wide">AI生成内容仅供参考，请结合实际情况使用。</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, reactive, onMounted, onUnmounted, watch, nextTick, computed } from 'vue';
import { useRouter } from 'vue-router';
import { getUserInfo } from '@/api/auth';
import { getMembershipUsageLimits, getMyMembership } from '@/api/membership';
import { getCourseCategoryList } from '@/api/study';
import {
  sendMessageToAI,
  sendMessageToAIStream,
  getConversationHistory,
  saveConversationHistory,
  getConversationList,
  saveConversationList,
  createNewConversation,
  deleteConversation,
  updateConversationTitle,
  clearChatHistory,
  syncHistoryFromServer
} from '@/api/ai';
import { ElMessageBox, ElMessage } from 'element-plus';
import { formatAiMessageContent as formatMessageContent } from '@/utils/aiChat';

// 响应式状态
const router = useRouter();
const isMobile = ref(window.innerWidth < 768)
const isCollapsed = ref(window.innerWidth < 768) // 移动端默认收起
const chatContainer = ref(null)

// 聊天相关数据
const message = ref('')
const conversations = ref([])
const currentConversationId = ref(null)
const messages = ref([])
const conversationMessagesCache = reactive({})
const conversationStreamState = reactive({})
const typingTimerMap = new Map()
const thinkingTicker = ref(0)
let thinkingTickerTimer = null
const isLoading = computed(() => Boolean(
  currentConversationId.value && conversationStreamState[currentConversationId.value]?.isLoading
))

// 登录状态
const isLoggedIn = ref(false)
const userInfo = ref(null)
const userMembership = ref(null)

// 每日免费额度
const FREE_DAILY_LIMIT = ref(5); // 默认值，优先以后端下发为准

const fetchMembershipLimits = async () => {
  const token = localStorage.getItem('authToken');
  if (!token) {
    return;
  }

  try {
    const res = await getMembershipUsageLimits();
    const data = res.data || res;
    if (data.code === 200 && data.data?.freeAiDailyLimit) {
      FREE_DAILY_LIMIT.value = Number(data.data.freeAiDailyLimit) || FREE_DAILY_LIMIT.value;
    }
  } catch {
    logger.debug('获取会员限制配置失败（使用默认值）');
  }
};

// 检查会员状态
const fetchMembership = async () => {
  // 只在有 token 时才调用 API
  const token = localStorage.getItem('authToken');
  if (!token) {
    logger.debug('未登录，跳过获取会员信息');
    return;
  }
  
  try {
    const res = await getMyMembership();
    // axios 返回的是 response，数据在 response.data 中
    const data = res.data || res;
    if (data.code === 200) {
      userMembership.value = data.data;
      logger.debug('获取会员信息成功:', userMembership.value);
    }
  } catch (error) {
    // 静默处理错误，不显示提示
    logger.debug('获取会员信息失败（可能未登录）');
  }
};

// 检查是否超过限额
const checkLimit = () => {
  const code = userMembership.value?.levelCode;
  // 付费会员无限制 (light/standard/flagship/enterprise)
  if (code && code !== 'free') {
    return true;
  }
  
  // 免费用户检查本地计数
  const today = new Date().toLocaleDateString();
  const userId = userInfo.value?.id || 'guest';
  const key = `ai_usage_${userId}_${today}`;
  const count = parseInt(localStorage.getItem(key) || '0');
  
  if (count >= FREE_DAILY_LIMIT.value) {
    ElMessageBox.confirm(
      `免费版每日仅限 ${FREE_DAILY_LIMIT.value} 次 AI 对话。升级轻量版或更高套餐解锁无限畅聊！`,
      '升级提示',
      {
        confirmButtonText: '查看套餐',
        cancelButtonText: '明日再来',
        type: 'warning',
        center: true
      }
    ).then(() => {
      router.push('/member-center');
    }).catch(() => {});
    return false;
  }
  return true;
};

// 更新使用计数
const incrementUsage = () => {
  const code = userMembership.value?.levelCode;
  // 付费会员无限制 (light/standard/flagship/enterprise)
  if (code && code !== 'free') return;
  
  const today = new Date().toLocaleDateString();
  const userId = userInfo.value?.id || 'guest';
  const key = `ai_usage_${userId}_${today}`;
  const count = parseInt(localStorage.getItem(key) || '0');
  localStorage.setItem(key, (count + 1).toString());
};

// 监听窗口大小变化
const handleResize = () => {
  const mobile = window.innerWidth < 768
  if (isMobile.value !== mobile) {
    isMobile.value = mobile
    isCollapsed.value = mobile // 切换到移动端时自动收起，切换到PC端自动展开(或保持)
  }
}

// 滚动到底部
const scrollToBottom = async () => {
  await nextTick()
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight
  }
}

// 监听消息变化自动滚动
watch(() => messages.value.length, scrollToBottom)

// 时间格式化
const formatTime = (timestamp) => {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  return `${date.getMonth() + 1}/${date.getDate()} ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`
}

// 检查登录状态
const checkLoginStatus = async () => {
  try {
    const token = localStorage.getItem('authToken');
    const storedUserInfo = localStorage.getItem('userInfo');
    
    if (token && storedUserInfo) {
      // 先使用本地存储的用户信息
      try {
        userInfo.value = JSON.parse(storedUserInfo);
        isLoggedIn.value = true;
        logger.debug('使用本地存储的用户信息:', userInfo.value);
        return true;
      } catch (e) {
        logger.warn('解析本地用户信息失败:', e);
      }
    }
    
    if (token) {
      // 尝试从API获取最新用户信息，添加超时处理
      try {
        const response = await Promise.race([
          getUserInfo(),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('获取用户信息超时')), 3000)
          )
        ]);
        if (response.data.code === 200) {
          isLoggedIn.value = true;
          const remoteUserInfo = response.data.user || response.data.data;
          userInfo.value = {
            ...remoteUserInfo,
            profileCompletion: response.data.profileCompletion || remoteUserInfo?.profileCompletion || userInfo.value?.profileCompletion || null
          };
          // 更新本地存储
          localStorage.setItem('userInfo', JSON.stringify(userInfo.value));
          logger.debug('从API获取用户信息成功:', userInfo.value);
          return true;
        }
      } catch (error) {
        logger.warn('获取用户信息失败，使用本地存储:', error.message);
        // 如果API调用失败，尝试使用本地存储的用户信息
        if (storedUserInfo) {
          try {
            userInfo.value = JSON.parse(storedUserInfo);
            isLoggedIn.value = true;
            logger.debug('使用本地存储的用户信息:', userInfo.value);
            return true;
          } catch (e) {
            logger.warn('解析本地用户信息失败:', e);
          }
        }
      }
    }
  } catch (error) {
    logger.error('获取用户信息失败:', error);
  }
  
  isLoggedIn.value = false;
  userInfo.value = null;
  return false;
};

// 切换侧边栏
const toggleSidebar = () => {
  isCollapsed.value = !isCollapsed.value
}

// 加载对话列表
const loadConversations = async () => {
  try {
    conversations.value = getConversationList()
    if (conversations.value.length > 0 && !currentConversationId.value) {
      await switchConversation(conversations.value[0].id)
      return
    }
    syncConversationActiveState(currentConversationId.value)
  } catch (error) {
    logger.error('加载对话列表失败:', error)
  }
}

const ensureConversationMessages = (conversationId) => {
  if (!conversationId) {
    return []
  }
  if (!conversationMessagesCache[conversationId]) {
    conversationMessagesCache[conversationId] = getConversationHistory(conversationId)
  }
  return conversationMessagesCache[conversationId]
}

const setConversationMessages = (conversationId, nextMessages) => {
  if (!conversationId) {
    return []
  }
  conversationMessagesCache[conversationId] = nextMessages
  if (currentConversationId.value === conversationId) {
    messages.value = nextMessages
  }
  return nextMessages
}

const updateConversationMessages = (conversationId, updater) => {
  const currentMessages = ensureConversationMessages(conversationId)
  const nextMessages = updater(currentMessages)
  return setConversationMessages(conversationId, nextMessages)
}

const persistConversationMessages = (conversationId) => {
  if (!conversationId) {
    return
  }
  saveConversationHistory(conversationId, ensureConversationMessages(conversationId))
}

const ensureConversationStream = (conversationId) => {
  if (!conversationId) {
    return { isLoading: false, connection: null }
  }
  if (!conversationStreamState[conversationId]) {
    conversationStreamState[conversationId] = {
      isLoading: false,
      connection: null
    }
  }
  return conversationStreamState[conversationId]
}

const clearTypingTimer = (conversationId) => {
  const timer = typingTimerMap.get(conversationId)
  if (timer) {
    clearTimeout(timer)
    typingTimerMap.delete(conversationId)
  }
}

const setConversationLoading = (conversationId, loading, connection = undefined) => {
  if (!conversationId) {
    return
  }
  const streamState = ensureConversationStream(conversationId)
  streamState.isLoading = loading
  if (connection !== undefined) {
    streamState.connection = connection
  }
}

const closeConversationStream = (conversationId) => {
  if (!conversationId) {
    return
  }
  clearTypingTimer(conversationId)
  const streamState = conversationStreamState[conversationId]
  if (streamState?.connection) {
    streamState.connection.close()
  }
  if (streamState) {
    streamState.connection = null
    streamState.isLoading = false
  }
}

const syncConversationActiveState = (activeConversationId = currentConversationId.value) => {
  conversations.value = conversations.value.map((conversation) => ({
    ...conversation,
    active: conversation.id === activeConversationId
  }))
}

const touchConversation = (conversationId, title) => {
  if (!conversationId) {
    return
  }

  const now = new Date().toISOString()
  const conversation = conversations.value.find((item) => item.id === conversationId)
  if (!conversation) {
    return
  }

  if (title) {
    conversation.title = title
    updateConversationTitle(conversationId, title)
  }

  conversation.updateTime = now
  conversations.value = [...conversations.value].sort((a, b) => new Date(b.updateTime) - new Date(a.updateTime))
  syncConversationActiveState(currentConversationId.value)
  saveConversationList(conversations.value.map(({ active, ...rest }) => rest))
}

// 加载消息历史
const loadMessages = async (conversationId) => {
  try {
    messages.value = ensureConversationMessages(conversationId)
    scrollToBottom()
  } catch (error) {
    logger.error('加载消息历史失败:', error)
  }
}

const openLoginModal = () => {
  window.dispatchEvent(new CustomEvent('showLoginModal'));
};

const createSearchMeta = (thinkingText = '') => {
  const normalizedText = String(thinkingText || '')
  if (normalizedText.includes('联网搜索') || normalizedText.includes('公开信息')) {
    return {
      label: '联网搜索中',
      isWebSearch: true
    }
  }
  if (normalizedText.includes('内部知识') || normalizedText.includes('培训资料')) {
    return {
      label: '检索内部知识',
      isWebSearch: false
    }
  }
  if (normalizedText.includes('学习数据')) {
    return {
      label: '查询学习数据',
      isWebSearch: false
    }
  }
  return null
}

const THINKING_COPY = {
  web: {
    intros: ['我先去网上替你找找最新说法', '先帮你把公开信息这条线拉起来', '网上资料我这边正在过一遍', '这题我先看看网上最近怎么变了', '我先把公开渠道里能用的信息扫一遍', '先替你看看最近有没有新变化'],
    actions: ['比对最新网页和内部口径', '筛选更可靠的公开来源', '抓取和这个问题最相关的变化', '整理能直接引用的外部信息', '把不同平台的公开说法对一遍', '挑更值得参考的来源先留下来'],
    endings: ['尽量给你留一版更稳的口径...', '先把噪音压下去再说...', '马上拼成能直接用的结论...', '我再替你多核一遍来源...', '先帮你把容易混淆的地方剔掉...', '尽量整理得清楚一点给你...']
  },
  internal: {
    intros: ['我先去内部资料里替你翻一翻', '这类题我先对一下集团自己的口径', '先帮你从题库和 SOP 里捞重点', '我先看看内部资料有没有更贴场景的说法', '先替你把内部标准翻出来对一遍', '我先从企业文化和培训资料里找抓手'],
    actions: ['匹配企业文化、SOP 和题库内容', '筛选更贴近门店场景的资料', '抽取能落地执行的关键动作', '核对内部话术和服务标准', '把重复的空话先压掉', '找更适合直接落地的内部表达'],
    endings: ['尽量整理得更像人说的话...', '我会尽量少空话多留动作...', '马上给你拎成一版能直接说的内容...', '我再把口径和动作顺一顺...', '先替你把重点压实一点...', '尽量让这版更贴门店现场...']
  },
  learning: {
    intros: ['我先把你的学习记录翻出来看看', '先帮你回看一下这段时间的表现', '你的训练痕迹我这边正在对', '我先从答题表现里帮你找重点', '先看看你这段时间主要卡在哪', '我先把可用的学习数据串起来'],
    actions: ['比对学习记录和答题表现', '提取更值得关注的薄弱点', '整理更贴合你的学习建议', '汇总当前可用的学习分析结果', '把零散表现先归成几个重点', '看看哪些问题最值得你优先补'],
    endings: ['尽量给你一些真能执行的建议...', '我先把重点挑出来给你...', '再帮你压缩成更容易上手的方向...', '马上整理成一版更清楚的结论...', '先不说虚的，尽量留能做的...', '我尽量帮你说得更直白一点...']
  },
  general: {
    intros: ['我先把你的问题拆开看看', '先替你理一理这里面的重点', '这个问题我先顺一遍思路', '我先看看怎么说会更贴你的场景', '先把你真正关心的部分拎出来', '我先把这题的骨架搭一下'],
    actions: ['梳理你真正想问的重点', '把零散信息重新排一下顺序', '组织更顺一点的表达方式', '补全更适合当前场景的说法', '把太硬的表达先磨顺一点', '先把回答结构排得更清楚些'],
    endings: ['尽量让这版回答别那么硬...', '我再把语气收顺一点...', '马上整理成更顺嘴的版本...', '给你一版没那么像机器的回复...', '尽量别让它看起来像套话...', '我再替你把话捋顺一点...']
  }
}

const inferThinkingCategory = (msg = {}) => {
  const content = String(msg.content || '')
  const label = String(msg.searchMeta?.label || '')

  if (msg.searchMeta?.isWebSearch || content.includes('联网搜索') || content.includes('公开信息') || label.includes('联网搜索')) {
    return 'web'
  }
  if (content.includes('内部知识') || content.includes('培训资料') || label.includes('内部知识')) {
    return 'internal'
  }
  if (content.includes('学习数据') || label.includes('学习数据')) {
    return 'learning'
  }
  return 'general'
}

const buildThinkingVariants = (category) => {
  const config = THINKING_COPY[category] || THINKING_COPY.general
  const variants = []

  config.intros.forEach((intro, introIndex) => {
    config.actions.forEach((action, actionIndex) => {
      const ending = config.endings[(introIndex + actionIndex) % config.endings.length]
      variants.push(`${intro}，正在${action}，${ending}`)
    })
  })

  config.endings.forEach((ending, endingIndex) => {
    const intro = config.intros[endingIndex % config.intros.length]
    const action = config.actions[(endingIndex + 2) % config.actions.length]
    variants.push(`${intro}，先${action}，${ending}`)
  })

  return [...new Set(variants)]
}

const getLoadingDisplayText = (msg = {}) => {
  const category = inferThinkingCategory(msg)
  const variants = buildThinkingVariants(category)
  const customText = String(msg.content || '').trim()

  if (customText && !variants.includes(customText)) {
    variants.unshift(customText)
  }

  if (variants.length === 0) {
    return '正在整理回复...'
  }

  const baseSeed = Math.abs(Number(msg.id) || 0) % variants.length
  const index = (baseSeed + thinkingTicker.value) % variants.length
  return variants[index]
}

const normalizeSourceItem = (source) => ({
  title: source?.title || '',
  url: source?.url || '',
  content: source?.content || '',
  score: source?.score ?? ''
})

const mergeSources = (existingSources = [], nextSources = []) => {
  const merged = [...existingSources]
  const seenKeys = new Set(existingSources.map((item) => `${item.url}|${item.title}`))

  nextSources.forEach((item) => {
    const normalizedItem = normalizeSourceItem(item)
    const key = `${normalizedItem.url}|${normalizedItem.title}`
    if (!seenKeys.has(key)) {
      seenKeys.add(key)
      merged.push(normalizedItem)
    }
  })

  return merged
}

const updateAssistantMessage = (conversationId, messageId, updater) => {
  updateConversationMessages(conversationId, (currentMessages) => {
    const idx = currentMessages.findIndex((item) => item.id === messageId)
    if (idx === -1) {
      return currentMessages
    }

    const nextMessages = [...currentMessages]
    const currentMessage = nextMessages[idx]
    nextMessages[idx] = {
      ...currentMessage,
      ...updater(currentMessage)
    }
    return nextMessages
  })
}

const openSourceLink = (url) => {
  if (!url) {
    return
  }
  window.open(url, '_blank', 'noopener,noreferrer')
}

const formatSourceScore = (score) => {
  const numericScore = Number(score)
  if (Number.isNaN(numericScore)) {
    return '来源'
  }
  return `相关度 ${numericScore.toFixed(2)}`
}

// 发送消息
const sendMessage = async () => {
  if (!message.value.trim() || isLoading.value || !isLoggedIn.value) return

  // 检查每日限额
  if (!checkLimit()) return;

  // 移动端发送消息后收起键盘（通过失去焦点）
  if (isMobile.value) {
    document.activeElement?.blur()
  }

  const userMessage = message.value.trim()
  message.value = ''

  // 增加使用计数
  incrementUsage();

  let conversationId = currentConversationId.value

  // 如果没有当前对话，创建新对话
  if (!conversationId) {
    try {
      const conversation = createNewConversation(userMessage.substring(0, 20))
      conversationId = conversation.id
      currentConversationId.value = conversationId
      conversations.value = [conversation, ...conversations.value]
      setConversationMessages(conversationId, [])
      syncConversationActiveState(conversationId)
    } catch (error) {
      logger.error('创建对话失败:', error)
      return
    }
  }

  // 添加用户消息到界面
  const userMsg = {
    id: Date.now(),
    role: 'user',
    content: userMessage,
    timestamp: new Date().toISOString()
  }
  updateConversationMessages(conversationId, (currentMessages) => [...currentMessages, userMsg])
  touchConversation(conversationId)

  // 显示加载状态
  setConversationLoading(conversationId, true, null)
  const aiMsgId = Date.now() + 1
  const aiMsg = {
    id: aiMsgId,
    role: 'assistant',
    content: '',
    timestamp: new Date().toISOString(),
    isLoading: true,
    hasResponseChunk: false,
    searchMeta: null,
    sources: []
  }
  updateConversationMessages(conversationId, (currentMessages) => [...currentMessages, aiMsg])
  scrollToBottom()

  // 尝试 SSE 流式调用
  try {
    const streamConnection = sendMessageToAIStream(
      userMessage,
      conversationId,
      {
        onThinking: (text) => {
          updateAssistantMessage(conversationId, aiMsgId, () => ({
            isLoading: true,
            content: text,
            searchMeta: createSearchMeta(text)
          }))
          scrollToBottom()
        },
        onSources: (payload) => {
          const results = Array.isArray(payload?.results) ? payload.results : []
          updateAssistantMessage(conversationId, aiMsgId, (currentMessage) => ({
            searchMeta: {
              label: results.length > 0 ? '已引用外部来源' : '联网搜索完成',
              isWebSearch: true
            },
            sources: mergeSources(currentMessage.sources, results)
          }))
          scrollToBottom()
        },
        onMessage: (token) => {
          updateAssistantMessage(conversationId, aiMsgId, (currentMessage) => ({
            isLoading: false,
            hasResponseChunk: true,
            content: (currentMessage.hasResponseChunk ? currentMessage.content : '') + token
          }))
          scrollToBottom()
        },
        onDone: () => {
          setConversationLoading(conversationId, false, null)
          updateAssistantMessage(conversationId, aiMsgId, (currentMessage) => (
            currentMessage.hasResponseChunk
              ? {
                  isLoading: false
                }
              : {
                  isLoading: false,
                  isError: true,
                  content: '抱歉，本次请求已结束，但未收到有效回复，请重试。'
                }
          ))
          persistConversationMessages(conversationId)
          updateTitleIfFirst(conversationId, userMessage)
        },
        onError: (err) => {
          logger.warn('SSE流式调用失败，回退到同步接口:', err.message)
          setConversationLoading(conversationId, true, null)
          fallbackSendMessage(userMessage, aiMsgId, conversationId)
        }
      }
    )
    setConversationLoading(conversationId, true, streamConnection)
  } catch (err) {
    logger.warn('SSE连接失败，回退到同步接口:', err.message)
    fallbackSendMessage(userMessage, aiMsgId, conversationId)
  }
}

// 回退到原有同步接口
const fallbackSendMessage = async (userMessage, aiMsgId, conversationId) => {
  try {
    const response = await sendMessageToAI(userMessage, conversationId)

    if (response.data.code === 200) {
      const fullContent = response.data.data || response.data.msg || 'AI回复内容为空'
      updateAssistantMessage(conversationId, aiMsgId, () => ({
        isLoading: false,
        hasResponseChunk: false,
        content: ''
      }))

      // 逐字显示效果
      let currentIndex = 0
      const typingSpeed = 30
      const typeWriter = () => {
        if (currentIndex < fullContent.length) {
          updateAssistantMessage(conversationId, aiMsgId, () => ({
            hasResponseChunk: true,
            content: fullContent.substring(0, currentIndex + 1)
          }))
          currentIndex++
          clearTypingTimer(conversationId)
          const timer = setTimeout(typeWriter, typingSpeed)
          typingTimerMap.set(conversationId, timer)
        } else {
          clearTypingTimer(conversationId)
          persistConversationMessages(conversationId)
          updateTitleIfFirst(conversationId, userMessage)
        }
        scrollToBottom()
      }
      typeWriter()
    } else {
      showErrorMessage(conversationId, aiMsgId, response.data.msg || '未知错误')
    }
  } catch (apiError) {
    logger.error('AI API调用失败:', apiError)
    showErrorMessage(conversationId, aiMsgId, '华智AI服务暂时不可用，请稍后重试。')
  }

  setConversationLoading(conversationId, false, null)
  persistConversationMessages(conversationId)
  touchConversation(conversationId)
}

const showErrorMessage = (conversationId, aiMsgId, errorText) => {
  updateAssistantMessage(conversationId, aiMsgId, () => ({
    isLoading: false,
    hasResponseChunk: false,
    content: '抱歉，' + errorText,
    isError: true
  }))
  persistConversationMessages(conversationId)
}

const updateTitleIfFirst = (conversationId, userMessage) => {
  const currentMessages = ensureConversationMessages(conversationId)
  if (currentMessages.length <= 3) {
    try {
      touchConversation(conversationId, userMessage.substring(0, 20))
    } catch (error) {
      logger.error('更新对话标题失败:', error)
    }
  }
}

// 创建新对话
const createNewChat = async () => {
  try {
    const conversation = createNewConversation('新对话')
    conversations.value = [conversation, ...conversations.value]
    currentConversationId.value = conversation.id
    setConversationMessages(conversation.id, [])
    syncConversationActiveState(conversation.id)
    messages.value = ensureConversationMessages(conversation.id)
    if (isMobile.value) {
      isCollapsed.value = true // 移动端创建后自动关闭侧边栏
    }
  } catch (error) {
    logger.error('创建新对话失败:', error)
  }
}

// 切换对话
const switchConversation = async (conversationId) => {
  currentConversationId.value = conversationId
  await loadMessages(conversationId)
  syncConversationActiveState(conversationId)
  
  if (isMobile.value) {
    isCollapsed.value = true // 移动端切换后自动关闭侧边栏
  }
}

// 删除对话
const deleteChat = async (conversationId) => {
  try {
    closeConversationStream(conversationId)
    const success = deleteConversation(conversationId)
    if (success) {
      conversations.value = conversations.value.filter(conv => conv.id !== conversationId)
      delete conversationMessagesCache[conversationId]
      delete conversationStreamState[conversationId]
      if (currentConversationId.value === conversationId) {
        if (conversations.value.length > 0) {
          await switchConversation(conversations.value[0].id)
        } else {
          currentConversationId.value = null
          messages.value = []
        }
      }
    }
  } catch (error) {
    logger.error('删除对话失败:', error)
  }
}

// 清除当前对话的历史记录
const clearCurrentHistory = async () => {
  if (!currentConversationId.value) {
    ElMessage.warning('请先选择一个对话')
    return
  }
  
  try {
    await ElMessageBox.confirm(
      '清除后，AI将不再记住本次对话的上下文，但对话记录仍会保留在左侧列表中。是否继续？',
      '清除对话历史',
      {
        confirmButtonText: '确定清除',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
    
    // 调用后端API清除数据库中的历史记录
    const response = await clearChatHistory(currentConversationId.value)
    
    if (response.data.code === 200) {
      closeConversationStream(currentConversationId.value)
      setConversationMessages(currentConversationId.value, [])
      persistConversationMessages(currentConversationId.value)
      messages.value = ensureConversationMessages(currentConversationId.value)
      scrollToBottom()
      ElMessage.success('对话历史已清除，AI将重新开始对话')
    } else {
      ElMessage.error(response.data.msg || '清除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      logger.error('清除对话历史失败:', error)
      ElMessage.error('清除对话历史失败')
    }
  }
}

// 监听登录事件
const handleUserLogin = (event) => {
  isLoggedIn.value = true;
  userInfo.value = event.detail;
  fetchMembershipLimits();
  fetchMembership();
};

onMounted(async () => {
  thinkingTickerTimer = window.setInterval(() => {
    thinkingTicker.value += 1
  }, 2200)
  await checkLoginStatus();
  if (isLoggedIn.value) {
    await fetchMembershipLimits();
    await fetchMembership();
    // 从服务器同步聊天历史（用户登录后恢复历史记录）
    try {
      const syncResult = await syncHistoryFromServer();
      if (syncResult.synced > 0) {
        logger.debug(`✅ 已从服务器同步 ${syncResult.synced} 个历史会话`);
      }
    } catch (e) {
      logger.warn('同步历史记录失败:', e);
    }
  }
  window.addEventListener('resize', handleResize);
  window.addEventListener('userLogin', handleUserLogin);
  await loadConversations();
});

onUnmounted(() => {
  if (thinkingTickerTimer) {
    clearInterval(thinkingTickerTimer)
    thinkingTickerTimer = null
  }
  Object.keys(conversationStreamState).forEach((conversationId) => closeConversationStream(conversationId))
  window.removeEventListener('resize', handleResize);
  window.removeEventListener('userLogin', handleUserLogin);
});
</script>

<style scoped>
/* 自定义滚动条 */
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 2px;
}
.custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background: #cbd5e1;
}

/* 用户消息气泡 - 华智科技风 */
.user-message-bubble {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  border: 1px solid rgba(255,255,255,0.1);
  word-break: break-all;
  overflow-wrap: break-word;
  max-width: 100%;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
}

/* 动画 */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>

