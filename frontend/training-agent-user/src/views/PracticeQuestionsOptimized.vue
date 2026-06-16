<template>
  <div class="practice-container">
    <!-- 顶部状态栏 -->
    <div class="top-status-bar">
      <div class="status-left">
        <button class="back-btn" @click="handleBack">
          <i class="fa fa-arrow-left"></i>
        </button>
        <span class="practice-title">专项练习 - {{ currentCategoryName }}</span>
      </div>
      <div class="status-right">
        <span class="status-tag">进度 {{ currentIndex + 1 }}/{{ totalQuestions }}</span>
        <span class="status-tag" :class="{ 'time-warning': remainingTime < 300 }">
          剩余时间 {{ formatTime(remainingTime) }}
        </span>
      </div>
    </div>

    <!-- 主内容区 -->
    <div class="main-content">
      <!-- 左侧题干+选项区 -->
      <div class="question-area">
        <!-- 题干容器 -->
        <div class="question-container">
          <div class="question-header">
            <span class="question-type">【{{ currentQuestion.type }}】第 {{ currentIndex + 1 }} 题</span>
          </div>
          <div class="question-content">
            {{ currentQuestion.content }}
          </div>
          <div v-if="currentQuestion.image" class="question-image">
            <img :src="currentQuestion.image" alt="题目配图" />
            <p class="image-caption">图 1：{{ currentQuestion.imageCaption }}</p>
          </div>
        </div>

        <!-- 选项区域 -->
        <div class="options-area">
          <div 
            v-for="(option, index) in currentQuestion.options" 
            :key="index"
            class="option-item"
            :class="{ 'selected': isSelected(index), 'disabled': showExplanation }"
            @click="selectOption(index)"
          >
            <div class="option-checkbox">
              <input 
                type="radio" 
                :name="`question-${currentQuestion.id}`"
                :checked="isSelected(index)"
                :disabled="showExplanation"
              />
            </div>
            <span class="option-label">{{ String.fromCharCode(65 + index) }}.</span>
            <span class="option-text">{{ option }}</span>
          </div>
        </div>

        <!-- 解析展开区 -->
        <transition name="slide-down">
          <div v-if="showExplanation" class="explanation-area">
            <h4 class="explanation-title">答案解析</h4>
            <p class="correct-answer">
              正确答案：<span class="answer-text">{{ currentQuestion.correctAnswer }}</span>
            </p>
            <p class="explanation-text" v-html="highlightKeywords(currentQuestion.explanation)"></p>
          </div>
        </transition>
      </div>

      <!-- 右侧答题卡侧边栏 (PC端) -->
      <div class="answer-card-sidebar" v-if="!isMobile">
        <div class="sidebar-header">
          <span class="sidebar-title">答题卡</span>
          <i class="fa fa-times-circle error-icon"></i>
        </div>
        <div class="question-grid">
          <button
            v-for="(q, index) in questionList"
            :key="index"
            class="question-number"
            :class="getQuestionStatus(index)"
            @click="jumpToQuestion(index)"
          >
            {{ index + 1 }}
            <span v-if="q.marked" class="mark-indicator"></span>
          </button>
        </div>
      </div>
    </div>

    <!-- 底部固定工具栏 -->
    <div class="bottom-toolbar">
      <button 
        class="toolbar-btn prev-btn" 
        :disabled="currentIndex === 0"
        @click="prevQuestion"
      >
        上一题
      </button>
      <button 
        class="toolbar-btn next-btn" 
        @click="nextQuestion"
      >
        {{ currentIndex === totalQuestions - 1 ? '提交练习' : '下一题' }}
      </button>
      <button 
        class="toolbar-btn mark-btn"
        :class="{ 'marked': currentQuestion.marked }"
        @click="toggleMark"
      >
        <i class="fa fa-bookmark"></i>
        标记本题
      </button>
      <button 
        class="toolbar-btn collect-btn"
        :class="{ 'collected': currentQuestion.collected }"
        @click="toggleCollect"
      >
        <i :class="currentQuestion.collected ? 'fa fa-star' : 'far fa-star'"></i>
        收藏本题
      </button>
      <button 
        class="toolbar-btn view-explanation-btn"
        @click="toggleExplanation"
      >
        {{ showExplanation ? '收起解析' : '查看解析' }}
      </button>
    </div>

    <!-- 退出确认弹窗 -->
    <div v-if="showExitDialog" class="modal-overlay" @click="showExitDialog = false">
      <div class="modal-content" @click.stop>
        <h3>是否退出练习？</h3>
        <p>当前进度将会保存</p>
        <div class="modal-actions">
          <button class="modal-btn cancel-btn" @click="showExitDialog = false">取消</button>
          <button class="modal-btn confirm-btn" @click="confirmExit">确认</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { getMembershipUsageLimits, getMyMembership } from '@/api/membership';
import { ElMessageBox, ElMessage } from 'element-plus';
import { escapeHtml } from '@/utils/security';

const router = useRouter();
const membership = ref(null);
const freeDailyPracticeLimit = ref(5); // 默认值，优先以后端下发为准

// 响应式数据
const isMobile = ref(window.innerWidth < 768);
const currentIndex = ref(0);
const totalQuestions = ref(20);
const remainingTime = ref(900); // 15分钟
const showExplanation = ref(false);
const showExitDialog = ref(false);
const currentCategoryName = ref('OTA运营');
const selectedAnswers = ref({});

// 模拟题目数据
const questionList = ref([
  {
    id: 1,
    type: '单选题',
    content: '在OTA平台运营中，以下哪个指标最能反映酒店的市场竞争力？',
    options: [
      '房间数量',
      '价格水平',
      '评分和评论数量',
      '地理位置'
    ],
    correctAnswer: 'C',
    explanation: '评分和评论数量是OTA平台上最重要的竞争力指标。高评分和大量正面评论能够显著提升酒店的曝光率和预订转化率，这是因为消费者在选择酒店时会优先参考其他客人的真实评价。',
    marked: false,
    collected: false,
    answered: false,
    userAnswer: null
  }
  // ... 更多题目
]);

// 计算属性
const currentQuestion = computed(() => questionList.value[currentIndex.value] || {});

// 方法
const formatTime = (seconds) => {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const isSelected = (index) => {
  return selectedAnswers.value[currentIndex.value] === index;
};

const selectOption = (index) => {
  if (showExplanation.value) return;
  selectedAnswers.value[currentIndex.value] = index;
  questionList.value[currentIndex.value].answered = true;
  questionList.value[currentIndex.value].userAnswer = String.fromCharCode(65 + index);
};

const getQuestionStatus = (index) => {
  const q = questionList.value[index];
  if (q.marked) return 'marked';
  if (q.answered) return 'answered';
  return 'unanswered';
};

const jumpToQuestion = (index) => {
  currentIndex.value = index;
  showExplanation.value = false;
};

const prevQuestion = () => {
  if (currentIndex.value > 0) {
    currentIndex.value--;
    showExplanation.value = false;
  }
};

const nextQuestion = () => {
  // 免费会员限制：最多练习 freeDailyPracticeLimit 题
  if (membership.value && membership.value.levelCode === 'free' && currentIndex.value >= freeDailyPracticeLimit.value - 1) {
    ElMessageBox.confirm(`免费版每日仅可练习 ${freeDailyPracticeLimit.value} 道题目，升级会员解锁无限刷题！`, '升级提示', {
      confirmButtonText: '去升级',
      cancelButtonText: '下次再说',
      type: 'warning'
    }).then(() => {
      router.push('/member-center');
    }).catch(() => {});
    return;
  }

  if (currentIndex.value < totalQuestions.value - 1) {
    currentIndex.value++;
    showExplanation.value = false;
  } else {
    // 提交练习
    submitPractice();
  }
};

const toggleMark = () => {
  questionList.value[currentIndex.value].marked = !questionList.value[currentIndex.value].marked;
};

const toggleCollect = () => {
  questionList.value[currentIndex.value].collected = !questionList.value[currentIndex.value].collected;
};

const toggleExplanation = () => {
  showExplanation.value = !showExplanation.value;
};

const highlightKeywords = (text) => {
  // 高亮关键知识点
  const safeText = escapeHtml(text || '')
  return safeText.replace(/(评分|评论|竞争力|转化率)/g, '<strong class="keyword">$1</strong>');
};

const handleBack = () => {
  showExitDialog.value = true;
};

const confirmExit = () => {
  router.push('/practice');
};

const submitPractice = () => {
  // 提交练习逻辑
  ElMessage.success('练习已提交！');
};

// 倒计时
let timer = null;
onMounted(async () => {
  timer = setInterval(() => {
    if (remainingTime.value > 0) {
      remainingTime.value--;
    }
  }, 1000);

  // 监听窗口大小变化
  window.addEventListener('resize', () => {
    isMobile.value = window.innerWidth < 768;
  });

  // 获取会员限制配置（失败时使用默认值）
  try {
    const limitRes = await getMembershipUsageLimits();
    const limitPayload = limitRes?.data || limitRes;
    if (limitPayload?.code === 200 && limitPayload?.data?.freePracticeDailyLimit) {
      freeDailyPracticeLimit.value = Number(limitPayload.data.freePracticeDailyLimit) || freeDailyPracticeLimit.value;
    }
  } catch (e) {
    logger.warn('获取会员限制配置失败，使用默认值', e);
  }

  // 获取会员信息
  try {
    const res = await getMyMembership();
    // axios 返回的是 response，数据在 response.data 中
    const data = res.data || res;
    if (data.code === 200) {
      membership.value = data.data;
    }
  } catch (e) {
    logger.error('获取会员信息失败', e);
  }
});

onUnmounted(() => {
  if (timer) clearInterval(timer);
});
</script>

<style scoped>
/* 全局容器 */
.practice-container {
  min-height: 100vh;
  background: #f5f7fa;
  padding-bottom: 80px;
}

/* 顶部状态栏 */
.top-status-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 56px;
  background: #2E64B5;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 24px;
  z-index: 1000;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.status-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.back-btn {
  width: 32px;
  height: 32px;
  border: none;
  background: rgba(255,255,255,0.2);
  color: white;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.back-btn:hover {
  background: rgba(255,255,255,0.3);
}

.practice-title {
  color: white;
  font-size: 16px;
  font-weight: 500;
}

.status-right {
  display: flex;
  gap: 16px;
}

.status-tag {
  color: white;
  font-size: 14px;
  padding: 4px 12px;
  background: rgba(255,255,255,0.15);
  border-radius: 12px;
}

.time-warning {
  background: #ef4444;
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

/* 主内容区 */
.main-content {
  max-width: 1200px;
  margin: 72px auto 0;
  padding: 0 16px;
  display: flex;
  gap: 24px;
}

/* 左侧题干+选项区 */
.question-area {
  flex: 1;
  min-width: 0;
}

.question-container {
  background: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 16px;
  border: 1px solid #E5E7EB;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}

.question-header {
  margin-bottom: 16px;
}

.question-type {
  color: #666;
  font-size: 14px;
  font-weight: 600;
}

.question-content {
  color: #333;
  font-size: 16px;
  line-height: 1.5;
  margin-bottom: 16px;
}

.question-image {
  margin-top: 16px;
}

.question-image img {
  width: 100%;
  max-height: 200px;
  object-fit: contain;
  border-radius: 8px;
}

.image-caption {
  text-align: center;
  color: #666;
  font-size: 12px;
  margin-top: 8px;
}

/* 选项区域 */
.options-area {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.option-item {
  display: flex;
  align-items: center;
  background: white;
  border: 1px solid #E5E7EB;
  border-radius: 8px;
  padding: 12px 16px;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 48px;
}

.option-item:hover:not(.disabled) {
  border-color: #FF8A3C;
  background: #FFF5EB;
}

.option-item.selected {
  border-color: #FF8A3C;
  border-left: 5px solid #FF8A3C;
  background: #FFF5EB;
}

.option-item.disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.option-checkbox {
  margin-right: 8px;
}

.option-checkbox input[type="radio"] {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.option-label {
  font-weight: 600;
  color: #333;
  margin-right: 8px;
}

.option-text {
  color: #333;
  font-size: 15px;
  line-height: 1.4;
}

/* 解析展开区 */
.explanation-area {
  background: #F5F7FA;
  border-radius: 8px;
  padding: 16px;
  margin-top: 16px;
}

.explanation-title {
  color: #2E64B5;
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 8px;
}

.correct-answer {
  color: #666;
  font-size: 14px;
  margin-bottom: 12px;
}

.answer-text {
  color: #F44336;
  font-weight: 600;
}

.explanation-text {
  color: #666;
  font-size: 14px;
  line-height: 1.5;
}

.explanation-text :deep(.keyword) {
  color: #2E64B5;
  font-weight: 600;
}

/* 右侧答题卡 */
.answer-card-sidebar {
  width: 300px;
  background: #F5F7FA;
  border-radius: 12px;
  padding: 16px;
  position: sticky;
  top: 72px;
  height: fit-content;
}

.sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.sidebar-title {
  color: #333;
  font-size: 16px;
  font-weight: 600;
}

.error-icon {
  color: #ef4444;
  font-size: 20px;
}

.question-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}

.question-number {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.question-number.unanswered {
  background: #CCCCCC;
  color: white;
}

.question-number.answered {
  background: #2E64B5;
  color: white;
}

.question-number.marked {
  background: #FF8A3C;
  color: white;
}

.mark-indicator {
  position: absolute;
  top: -2px;
  right: -2px;
  width: 0;
  height: 0;
  border-left: 8px solid transparent;
  border-top: 8px solid #FF8A3C;
}

/* 底部工具栏 */
.bottom-toolbar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 60px;
  background: white;
  border-top: 1px solid #E5E7EB;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 12px;
  padding: 0 24px;
  z-index: 999;
}

.toolbar-btn {
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}

.prev-btn {
  background: white;
  color: #333;
  border: 1px solid #E5E7EB;
}

.prev-btn:hover:not(:disabled) {
  background: #f5f7fa;
}

.prev-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.next-btn {
  background: #2E64B5;
  color: white;
}

.next-btn:hover {
  background: #1e4a8a;
}

.mark-btn {
  background: white;
  color: #FF8A3C;
  border: 1px solid #FF8A3C;
}

.mark-btn.marked {
  background: #FF8A3C;
  color: white;
}

.collect-btn {
  background: white;
  color: #666;
  border: 1px solid #E5E7EB;
}

.collect-btn.collected i {
  color: #FFD700;
}

.view-explanation-btn {
  background: transparent;
  color: #666;
  border: none;
}

.view-explanation-btn:hover {
  color: #2E64B5;
}

/* 弹窗 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  padding: 24px;
  min-width: 320px;
  text-align: center;
}

.modal-content h3 {
  font-size: 18px;
  margin-bottom: 12px;
}

.modal-content p {
  color: #666;
  margin-bottom: 24px;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: center;
}

.modal-btn {
  padding: 10px 24px;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  font-size: 14px;
}

.cancel-btn {
  background: #f5f7fa;
  color: #333;
}

.confirm-btn {
  background: #2E64B5;
  color: white;
}

/* 动画 */
.slide-down-enter-active, .slide-down-leave-active {
  transition: all 0.3s ease;
}

.slide-down-enter-from {
  opacity: 0;
  transform: translateY(-10px);
}

.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

/* 移动端适配 */
@media (max-width: 768px) {
  .main-content {
    flex-direction: column;
    padding: 0 12px;
  }

  .question-container {
    padding: 16px;
  }

  .answer-card-sidebar {
    display: none;
  }

  .bottom-toolbar {
    flex-wrap: wrap;
    height: auto;
    padding: 12px;
  }

  .toolbar-btn {
    font-size: 12px;
    padding: 8px 12px;
  }
}
</style>

