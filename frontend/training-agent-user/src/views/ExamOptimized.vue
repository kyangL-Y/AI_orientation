<template>
  <div class="exam-optimized">
    <!-- 顶部状态栏 -->
    <div class="exam-header">
      <div class="header-content">
        <div class="exam-info">
          <span class="exam-name">{{ examInfo.name }}</span>
          <span class="exam-meta">{{ examInfo.type }}</span>
        </div>
        <div class="exam-status">
          <span class="answered-count">已答 {{ answeredCount }}/{{ totalQuestions }}</span>
          <span :class="['time-remaining', { warning: timeWarning }]">
            <i class="el-icon-time"></i> {{ formattedTime }}
          </span>
        </div>
      </div>
    </div>

    <!-- 防作弊提示 -->
    <div v-if="showWarning" class="cheat-warning">
      <i class="el-icon-warning"></i>
      检测到切屏行为（{{ switchCount }}/3），切屏3次将自动交卷
    </div>

    <!-- 主体区域 -->
    <div class="exam-main">
      <!-- 左侧题干区 -->
      <div class="question-area">
        <div class="question-container">
          <!-- 题目编号和类型 -->
          <div class="question-header">
            <span class="question-type">【{{ currentQuestion.type }}】</span>
            <span class="question-number">第 {{ currentIndex + 1 }} 题</span>
          </div>

          <!-- 题干 -->
          <div class="question-content">
            <p class="question-text">{{ currentQuestion.content }}</p>
            <img v-if="currentQuestion.image" :src="currentQuestion.image" class="question-image" />
          </div>

          <!-- 选项 -->
          <div class="options-list">
            <div
              v-for="(option, index) in currentQuestion.options"
              :key="index"
              :class="['option-item', { selected: isSelected(index) }]"
              @click="selectOption(index)"
            >
              <div class="option-checkbox">
                <input
                  :type="currentQuestion.type === '单选题' ? 'radio' : 'checkbox'"
                  :checked="isSelected(index)"
                  @click.stop
                />
              </div>
              <div class="option-content">
                <span class="option-label">{{ getOptionLabel(index) }}.</span>
                <span class="option-text">{{ option }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧答题卡 (PC端) -->
      <div v-if="!isMobile" class="answer-sheet">
        <div class="sheet-header">
          <h3>答题卡</h3>
          <span class="sheet-stats">已答 {{ answeredCount }}/{{ totalQuestions }}</span>
        </div>
        <div class="sheet-grid">
          <div
            v-for="(q, index) in questions"
            :key="index"
            :class="['sheet-item', getQuestionStatus(index), { current: index === currentIndex }]"
            @click="jumpToQuestion(index)"
          >
            {{ index + 1 }}
          </div>
        </div>
        <div class="sheet-legend">
          <div class="legend-item">
            <span class="legend-dot unanswered"></span>
            <span>未答</span>
          </div>
          <div class="legend-item">
            <span class="legend-dot answered"></span>
            <span>已答</span>
          </div>
          <div class="legend-item">
            <span class="legend-dot marked"></span>
            <span>标记</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部工具栏 -->
    <div class="exam-footer">
      <div class="footer-content">
        <div class="footer-left">
          <button
            class="nav-btn prev-btn"
            :disabled="currentIndex === 0"
            @click="prevQuestion"
          >
            上一题
          </button>
          <button
            class="nav-btn next-btn"
            @click="nextQuestion"
          >
            {{ currentIndex === totalQuestions - 1 ? '提交试卷' : '下一题' }}
          </button>
        </div>
        <div class="footer-right">
          <button class="tool-btn mark-btn" @click="toggleMark">
            <i :class="currentQuestion.marked ? 'el-icon-star-on' : 'el-icon-star-off'"></i>
            {{ currentQuestion.marked ? '取消标记' : '标记本题' }}
          </button>
          <button v-if="isMobile" class="tool-btn sheet-btn" @click="showSheetDrawer = true">
            <i class="el-icon-document"></i>
            答题卡
          </button>
        </div>
      </div>
    </div>

    <!-- 移动端答题卡抽屉 -->
    <el-drawer
      v-model="showSheetDrawer"
      title="答题卡"
      direction="btt"
      size="70%"
      v-if="isMobile"
    >
      <div class="sheet-drawer-content">
        <div class="drawer-stats">
          已答 {{ answeredCount }}/{{ totalQuestions }} 题
        </div>
        <div class="sheet-grid">
          <div
            v-for="(q, index) in questions"
            :key="index"
            :class="['sheet-item', getQuestionStatus(index), { current: index === currentIndex }]"
            @click="jumpToQuestion(index); showSheetDrawer = false"
          >
            {{ index + 1 }}
          </div>
        </div>
      </div>
    </el-drawer>

    <!-- 交卷确认弹窗 -->
    <el-dialog
      v-model="showSubmitDialog"
      title="确认交卷"
      width="400px"
      center
    >
      <div class="submit-dialog-content">
        <p class="submit-warning">
          <i class="el-icon-warning"></i>
          交卷后无法修改答案，确定要交卷吗？
        </p>
        <div class="submit-stats">
          <div class="stat-item">
            <span class="stat-label">已答题目：</span>
            <span class="stat-value">{{ answeredCount }}/{{ totalQuestions }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">未答题目：</span>
            <span class="stat-value warning">{{ totalQuestions - answeredCount }}</span>
          </div>
        </div>
      </div>
      <template #footer>
        <button class="dialog-btn cancel-btn" @click="showSubmitDialog = false">再检查一下</button>
        <button class="dialog-btn confirm-btn" @click="submitExam">确定交卷</button>
      </template>
    </el-dialog>

    <!-- 成绩弹窗 -->
    <el-dialog
      v-model="showScoreDialog"
      title="考试完成"
      width="400px"
      center
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      :show-close="false"
    >
      <div class="score-dialog-content">
        <div class="score-display">
          <div class="score-number">{{ examScore }}</div>
          <div class="score-label">分</div>
        </div>
        <div class="score-stats">
          <div class="score-stat">
            <span class="stat-label">正确率：</span>
            <span class="stat-value">{{ correctRate }}%</span>
          </div>
          <div class="score-stat">
            <span class="stat-label">答对题数：</span>
            <span class="stat-value">{{ correctCount }}/{{ totalQuestions }}</span>
          </div>
        </div>
      </div>
      <template #footer>
        <button class="dialog-btn" @click="viewAnalysis">查看错题解析</button>
        <button class="dialog-btn confirm-btn" @click="exitExam">返回首页</button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { getExamDetail, submitExamAnswers } from '@/api/exam';
import { ElMessage } from 'element-plus';

const router = useRouter();
const route = useRoute();
const isMobile = ref(window.innerWidth <= 768);

// 考试信息
const examInfo = ref({
  id: null,
  name: '综合能力测评',
  type: '期末考试',
  duration: 90, // 分钟
  totalScore: 100
});

// 题目数据
const questions = ref([]);
const currentIndex = ref(0);
const answers = ref({}); // { questionIndex: selectedOptions }
const markedQuestions = ref(new Set());

// 时间相关
const remainingTime = ref(5400); // 秒
const timer = ref(null);

// 防作弊
const switchCount = ref(0);
const showWarning = ref(false);

// 弹窗状态
const showSheetDrawer = ref(false);
const showSubmitDialog = ref(false);
const showScoreDialog = ref(false);

// 考试结果
const examScore = ref(0);
const correctCount = ref(0);

// 当前题目
const currentQuestion = computed(() => {
  const q = questions.value[currentIndex.value] || {};
  return {
    ...q,
    marked: markedQuestions.value.has(currentIndex.value)
  };
});

// 总题数
const totalQuestions = computed(() => questions.value.length);

// 已答题数
const answeredCount = computed(() => Object.keys(answers.value).length);

// 格式化时间
const formattedTime = computed(() => {
  const minutes = Math.floor(remainingTime.value / 60);
  const seconds = remainingTime.value % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
});

// 时间警告
const timeWarning = computed(() => remainingTime.value < 600); // 小于10分钟

// 正确率
const correctRate = computed(() => {
  if (totalQuestions.value === 0) return 0;
  return Math.round((correctCount.value / totalQuestions.value) * 100);
});

// 加载考试数据
const loadExam = async () => {
  try {
    const examId = route.params.id;
    const response = await getExamDetail(examId);
    examInfo.value = response.data.exam;
    questions.value = response.data.questions;
    remainingTime.value = examInfo.value.duration * 60;
    startTimer();
  } catch (error) {
    logger.error('加载考试失败:', error);
    // 使用模拟数据
    questions.value = getMockQuestions();
    startTimer();
  }
};

// 开始计时
const startTimer = () => {
  timer.value = setInterval(() => {
    if (remainingTime.value > 0) {
      remainingTime.value--;
      if (remainingTime.value === 600) {
        ElMessage.warning('考试时间不足10分钟，请抓紧时间答题');
      }
      if (remainingTime.value === 0) {
        ElMessage.error('考试时间已到，自动交卷');
        submitExam();
      }
    }
  }, 1000);
};

// 停止计时
const stopTimer = () => {
  if (timer.value) {
    clearInterval(timer.value);
    timer.value = null;
  }
};

// 判断选项是否被选中
const isSelected = (optionIndex) => {
  const answer = answers.value[currentIndex.value];
  if (!answer) return false;
  if (Array.isArray(answer)) {
    return answer.includes(optionIndex);
  }
  return answer === optionIndex;
};

// 选择选项
const selectOption = (optionIndex) => {
  if (currentQuestion.value.type === '单选题') {
    answers.value[currentIndex.value] = optionIndex;
  } else {
    // 多选题
    let answer = answers.value[currentIndex.value] || [];
    if (answer.includes(optionIndex)) {
      answer = answer.filter(i => i !== optionIndex);
    } else {
      answer = [...answer, optionIndex];
    }
    answers.value[currentIndex.value] = answer.length > 0 ? answer : undefined;
    if (answer.length === 0) {
      delete answers.value[currentIndex.value];
    }
  }
};

// 获取选项标签
const getOptionLabel = (index) => {
  return String.fromCharCode(65 + index); // A, B, C, D
};

// 获取题目状态
const getQuestionStatus = (index) => {
  if (markedQuestions.value.has(index)) return 'marked';
  if (answers.value[index] !== undefined) return 'answered';
  return 'unanswered';
};

// 跳转到指定题目
const jumpToQuestion = (index) => {
  currentIndex.value = index;
};

// 上一题
const prevQuestion = () => {
  if (currentIndex.value > 0) {
    currentIndex.value--;
  }
};

// 下一题
const nextQuestion = () => {
  if (currentIndex.value < totalQuestions.value - 1) {
    currentIndex.value++;
  } else {
    showSubmitDialog.value = true;
  }
};

// 标记/取消标记
const toggleMark = () => {
  if (markedQuestions.value.has(currentIndex.value)) {
    markedQuestions.value.delete(currentIndex.value);
  } else {
    markedQuestions.value.add(currentIndex.value);
  }
};

// 提交考试
const submitExam = async () => {
  showSubmitDialog.value = false;
  stopTimer();
  
  try {
    const response = await submitExamAnswers({
      examId: examInfo.value.id,
      answers: answers.value,
      duration: examInfo.value.duration * 60 - remainingTime.value
    });
    
    examScore.value = response.data.score;
    correctCount.value = response.data.correctCount;
    showScoreDialog.value = true;
  } catch (error) {
    logger.error('提交考试失败:', error);
    // 模拟结果
    correctCount.value = Math.floor(Math.random() * totalQuestions.value);
    examScore.value = Math.round((correctCount.value / totalQuestions.value) * 100);
    showScoreDialog.value = true;
  }
};

// 查看解析
const viewAnalysis = () => {
  router.push(`/exam/${examInfo.value.id}/analysis`);
};

// 退出考试
const exitExam = () => {
  router.push('/');
};

// 监听页面可见性变化（防作弊）
const handleVisibilityChange = () => {
  if (document.hidden) {
    switchCount.value++;
    showWarning.value = true;
    
    if (switchCount.value >= 3) {
      ElMessage.error('检测到多次切屏，自动交卷');
      submitExam();
    } else {
      setTimeout(() => {
        showWarning.value = false;
      }, 3000);
    }
  }
};

// 模拟数据
const getMockQuestions = () => {
  return [
    {
      id: 1,
      type: '单选题',
      content: '酒店前台接待客人时，以下哪项不是标准服务流程？',
      options: [
        '微笑问候客人',
        '核对客人身份信息',
        '直接收取现金押金',
        '介绍酒店设施'
      ],
      correctAnswer: 2
    },
    {
      id: 2,
      type: '多选题',
      content: 'OTA平台运营中，以下哪些因素会影响酒店排名？',
      options: [
        '客户评分',
        '回复率',
        '房间价格',
        '照片质量'
      ],
      correctAnswer: [0, 1, 3]
    }
  ];
};

// 监听窗口大小变化
const handleResize = () => {
  isMobile.value = window.innerWidth <= 768;
};

onMounted(() => {
  loadExam();
  document.addEventListener('visibilitychange', handleVisibilityChange);
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  stopTimer();
  document.removeEventListener('visibilitychange', handleVisibilityChange);
  window.removeEventListener('resize', handleResize);
});
</script>

<style scoped>
.exam-optimized {
  min-height: 100vh;
  background: #F5F7FA;
  display: flex;
  flex-direction: column;
}

/* 顶部状态栏 */
.exam-header {
  background: #2E64B5;
  color: white;
  padding: 16px 0;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.exam-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.exam-name {
  font-size: 18px;
  font-weight: 600;
}

.exam-meta {
  font-size: 14px;
  opacity: 0.9;
}

.exam-status {
  display: flex;
  align-items: center;
  gap: 24px;
}

.answered-count {
  font-size: 14px;
}

.time-remaining {
  font-size: 16px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
}

.time-remaining.warning {
  color: #FF4444;
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 50%, 100% { opacity: 1; }
  25%, 75% { opacity: 0.5; }
}

/* 防作弊提示 */
.cheat-warning {
  background: #FFF3CD;
  color: #856404;
  padding: 12px 20px;
  text-align: center;
  font-size: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

/* 主体区域 */
.exam-main {
  flex: 1;
  max-width: 1200px;
  width: 100%;
  margin: 24px auto;
  padding: 0 20px;
  display: flex;
  gap: 24px;
}

/* 题干区 */
.question-area {
  flex: 1;
}

.question-container {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.question-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid #E5E7EB;
}

.question-type {
  color: #2E64B5;
  font-weight: 600;
  font-size: 14px;
}

.question-number {
  color: #666;
  font-size: 14px;
}

.question-content {
  margin-bottom: 24px;
}

.question-text {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  line-height: 1.6;
  margin: 0 0 16px 0;
}

.question-image {
  max-width: 100%;
  border-radius: 8px;
  margin-top: 16px;
}

/* 选项列表 */
.options-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.option-item {
  display: flex;
  align-items: center;
  padding: 16px;
  background: white;
  border: 1px solid #E5E7EB;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.option-item:hover {
  border-color: #2E64B5;
  background: #F8FAFC;
}

.option-item.selected {
  border-color: #FF8A3C;
  border-width: 2px;
  border-left: 5px solid #FF8A3C;
  background: #FFF5EB;
}

.option-checkbox {
  margin-right: 12px;
}

.option-checkbox input {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.option-content {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.option-label {
  font-weight: 600;
  color: #333;
  font-size: 15px;
}

.option-text {
  color: #333;
  font-size: 15px;
  line-height: 1.5;
}

/* 答题卡 */
.answer-sheet {
  width: 300px;
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  height: fit-content;
  position: sticky;
  top: 100px;
}

.sheet-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid #E5E7EB;
}

.sheet-header h3 {
  font-size: 16px;
  color: #333;
  margin: 0;
}

.sheet-stats {
  font-size: 14px;
  color: #666;
}

.sheet-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 8px;
  margin-bottom: 16px;
}

.sheet-item {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
}

.sheet-item.unanswered {
  background: #E5E7EB;
  color: #666;
}

.sheet-item.answered {
  background: #2E64B5;
  color: white;
}

.sheet-item.marked {
  background: #FF8A3C;
  color: white;
}

.sheet-item.current {
  border: 2px solid #10B981;
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.2);
}

.sheet-item:hover {
  transform: scale(1.1);
}

.sheet-legend {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: 12px;
  border-top: 1px solid #E5E7EB;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #666;
}

.legend-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
}

.legend-dot.unanswered {
  background: #E5E7EB;
}

.legend-dot.answered {
  background: #2E64B5;
}

.legend-dot.marked {
  background: #FF8A3C;
}

/* 底部工具栏 */
.exam-footer {
  background: white;
  border-top: 1px solid #E5E7EB;
  padding: 16px 0;
  position: sticky;
  bottom: 0;
  z-index: 100;
}

.footer-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.footer-left,
.footer-right {
  display: flex;
  gap: 12px;
}

.nav-btn,
.tool-btn {
  padding: 10px 24px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  gap: 6px;
}

.prev-btn {
  background: white;
  color: #333;
  border: 1px solid #E5E7EB;
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
  background: #1E4A8F;
}

.tool-btn {
  background: white;
  color: #666;
  border: 1px solid #E5E7EB;
}

.tool-btn:hover {
  border-color: #FF8A3C;
  color: #FF8A3C;
}

/* 弹窗样式 */
.submit-dialog-content,
.score-dialog-content {
  padding: 20px;
  text-align: center;
}

.submit-warning {
  font-size: 16px;
  color: #666;
  margin-bottom: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.submit-stats {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
}

.stat-label {
  color: #666;
}

.stat-value {
  font-weight: 600;
  color: #333;
}

.stat-value.warning {
  color: #FF4444;
}

.score-display {
  display: flex;
  align-items: baseline;
  justify-content: center;
  margin-bottom: 24px;
}

.score-number {
  font-size: 72px;
  font-weight: 700;
  color: #2E64B5;
  line-height: 1;
}

.score-label {
  font-size: 24px;
  color: #666;
  margin-left: 8px;
}

.score-stats {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.score-stat {
  display: flex;
  justify-content: space-between;
  font-size: 16px;
}

.dialog-btn {
  padding: 10px 24px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s;
}

.cancel-btn {
  background: #F5F7FA;
  color: #666;
}

.confirm-btn {
  background: #2E64B5;
  color: white;
}

.confirm-btn:hover {
  background: #1E4A8F;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .exam-main {
    flex-direction: column;
  }
  
  .answer-sheet {
    display: none;
  }
  
  .header-content {
    flex-direction: column;
    gap: 12px;
    align-items: flex-start;
  }
  
  .footer-content {
    flex-direction: column;
    gap: 12px;
  }
  
  .footer-left,
  .footer-right {
    width: 100%;
  }
  
  .nav-btn,
  .tool-btn {
    flex: 1;
  }
}

.sheet-drawer-content {
  padding: 20px;
}

.drawer-stats {
  font-size: 16px;
  color: #666;
  margin-bottom: 20px;
  text-align: center;
}
</style>

