<template>
  <div class="wrong-book-page">
    <HeaderBar />

    <div class="container mx-auto px-4 py-8">
      <template v-if="!isLoggedIn">
        <div class="text-center py-20 bg-white rounded-2xl shadow-sm">
          <h2 class="text-2xl font-bold text-gray-800 mb-2">请先登录</h2>
          <p class="text-gray-500">登录后可查看错题本与记忆复习内容</p>
        </div>
      </template>

      <template v-else>
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-2xl font-bold text-gray-800">错题本 & 记忆复习</h1>
            <p class="text-gray-500 mt-2">基于艾宾浩斯遗忘曲线，为您智能规划复习时间</p>
          </div>
          <div class="flex gap-4">
              <div class="bg-blue-50 text-blue-700 px-4 py-2 rounded-lg">
                  <span class="text-sm">今日待复习</span>
                  <div class="text-xl font-bold">{{ reviewList.length }} 题</div>
              </div>
          </div>
        </div>

        <!-- 复习卡片区域 -->
        <div v-if="reviewList.length > 0" class="max-w-2xl mx-auto">
          <div class="bg-white rounded-2xl shadow-xl overflow-hidden relative min-h-[400px] flex flex-col">
              <!-- 进度条 -->
              <div class="h-1 bg-gray-100 w-full">
                  <div class="h-full bg-indigo-500 transition-all duration-300" :style="{ width: ((currentIndex) / reviewList.length * 100) + '%' }"></div>
              </div>

              <div class="p-8 flex-1 flex flex-col">
                  <div class="flex justify-between items-center mb-6">
                      <span class="bg-indigo-100 text-indigo-700 text-xs px-2 py-1 rounded">
                          {{ getQuestionType(currentQuestion.type) }}
                      </span>
                      <span class="text-gray-400 text-sm">
                          {{ currentIndex + 1 }} / {{ reviewList.length }}
                      </span>
                  </div>

                  <div class="text-xl font-medium text-gray-800 mb-8 leading-relaxed">
                      {{ currentQuestion.content }}
                  </div>

                  <!-- 选项区域 (默认不显示答案，点击显示答案后展示) -->
                  <div class="space-y-3 mb-8">
                      <div v-for="(opt, idx) in parseOptions(currentQuestion.options)" :key="idx"
                          class="p-4 rounded-xl border border-gray-200 flex items-center gap-3 transition-all"
                          :class="{
                              'bg-green-50 border-green-200': showAnswer && opt.label === currentQuestion.correctAnswer,
                              'opacity-50': showAnswer && opt.label !== currentQuestion.correctAnswer
                          }"
                      >
                          <div class="w-8 h-8 rounded-full border-2 flex items-center justify-center font-bold text-sm"
                              :class="showAnswer && opt.label === currentQuestion.correctAnswer ? 'border-green-500 text-green-600 bg-green-100' : 'border-gray-300 text-gray-400'"
                          >
                              {{ opt.label }}
                          </div>
                          <span class="text-gray-700">{{ opt.value }}</span>
                      </div>
                  </div>

                  <!-- 底部操作区 -->
                  <div class="mt-auto">
                      <!-- 阶段1：查看答案 -->
                      <button v-if="!showAnswer" @click="revealAnswer"
                          class="w-full py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl transition-all shadow-lg shadow-indigo-200">
                          显示答案
                      </button>

                      <!-- 阶段2：反馈记忆情况 -->
                      <div v-else class="grid grid-cols-2 gap-4 animate-fade-in">
                          <button @click="handleReview(false)"
                              class="py-3 bg-red-50 hover:bg-red-100 text-red-600 font-bold rounded-xl border border-red-200 transition-all">
                              <i class="fa-regular fa-face-frown mr-2"></i> 忘记了
                          </button>
                          <button @click="handleReview(true)"
                              class="py-3 bg-green-50 hover:bg-green-100 text-green-600 font-bold rounded-xl border border-green-200 transition-all">
                              <i class="fa-regular fa-face-smile mr-2"></i> 记得
                          </button>
                      </div>
                  </div>
              </div>

              <!-- 解析 (背面) -->
              <div v-if="showAnswer" class="bg-gray-50 p-6 border-t border-gray-100 text-sm text-gray-600">
                  <div class="font-bold text-gray-800 mb-2">💡 解析：</div>
                  {{ currentQuestion.analysis || '暂无解析' }}
              </div>
          </div>
        </div>

        <!-- 空状态 -->
        <div v-else class="text-center py-20 bg-white rounded-2xl shadow-sm">
          <div class="text-6xl mb-4">🎉</div>
          <h2 class="text-2xl font-bold text-gray-800 mb-2">太棒了！</h2>
          <p class="text-gray-500 mb-6">今日复习任务已全部完成</p>
          <router-link to="/study" class="text-indigo-600 font-bold hover:underline">去学习新课程 -></router-link>
        </div>
      </template>
    </div>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import HeaderBar from '@/components/HeaderBar.vue'
import { getReviewList, updateReviewStatus } from '@/api/question'
import { ElMessage } from 'element-plus'

export default {
  name: 'WrongBook',
  components: { HeaderBar },
  data() {
    return {
      reviewList: [],
      currentIndex: 0,
      showAnswer: false,
      loading: false,
      isLoggedIn: false
    }
  },
  computed: {
    currentQuestion() {
      return this.reviewList[this.currentIndex] || {}
    }
  },
  created() {
    this.syncLoginStatus()
    if (this.isLoggedIn) {
      this.fetchReviewList()
    }
  },
  mounted() {
    window.addEventListener('userLogin', this.handleUserLogin)
    window.addEventListener('userLogout', this.handleUserLogout)
    window.addEventListener('storage', this.handleStorageChange)
  },
  beforeUnmount() {
    window.removeEventListener('userLogin', this.handleUserLogin)
    window.removeEventListener('userLogout', this.handleUserLogout)
    window.removeEventListener('storage', this.handleStorageChange)
  },
  methods: {
    syncLoginStatus() {
      this.isLoggedIn = !!localStorage.getItem('authToken')
    },
    handleUserLogin() {
      const wasLoggedIn = this.isLoggedIn
      this.syncLoginStatus()
      if (!wasLoggedIn && this.isLoggedIn) {
        this.currentIndex = 0
        this.showAnswer = false
        this.fetchReviewList()
      }
    },
    handleUserLogout() {
      this.syncLoginStatus()
      this.reviewList = []
      this.currentIndex = 0
      this.showAnswer = false
    },
    handleStorageChange(event) {
      if (event.key === 'authToken') {
        if (event.newValue) {
          this.handleUserLogin()
        } else {
          this.handleUserLogout()
        }
      }
    },
    async fetchReviewList() {
      this.loading = true
      try {
        const res = await getReviewList()
        if (res.code === 200) {
          this.reviewList = res.data
        }
      } catch (e) {
        logger.error(e)
      } finally {
        this.loading = false
      }
    },
    parseOptions(optionsStr) {
        try {
            let rawOptions = optionsStr
            if (typeof rawOptions === 'string') {
                rawOptions = JSON.parse(rawOptions)
            }
            if (!Array.isArray(rawOptions)) {
                return []
            }

            return rawOptions.map((opt, idx) => {
                const fallbackLabel = String.fromCharCode(65 + idx)

                if (typeof opt === 'string') {
                    return {
                        label: fallbackLabel,
                        value: opt
                    }
                }

                if (opt && typeof opt === 'object') {
                    return {
                        label: opt.label || fallbackLabel,
                        value: opt.value || opt.content || opt.text || ''
                    }
                }

                return {
                    label: fallbackLabel,
                    value: ''
                }
            })
        } catch(e) {
            return []
        }
    },
    getQuestionType(type) {
        const map = {
            'CHOICE': '单选题',
            'JUDGE': '判断题',
            'MULTI': '多选题'
        }
        return map[type] || '题目'
    },
    revealAnswer() {
        this.showAnswer = true
    },
    async handleReview(remembered) {
        try {
            const questionId = this.currentQuestion.id
            await updateReviewStatus({
                questionId,
                remembered
            })
            
            if (remembered) {
                ElMessage.success('已标记为掌握，下次复习间隔将延长')
            } else {
                ElMessage.warning('已重置复习进度，明天继续努力')
            }

            // 下一题
            if (this.currentIndex < this.reviewList.length - 1) {
                this.currentIndex++
                this.showAnswer = false
            } else {
                // 完成所有
                this.reviewList = []
                ElMessage.success('今日复习已完成！')
            }
        } catch (e) {
            logger.error(e)
            ElMessage.error('操作失败')
        }
    }
  }
}
</script>

<style scoped>
.animate-fade-in {
    animation: fadeIn 0.3s ease-in-out;
}
@keyframes fadeIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
}
</style>

