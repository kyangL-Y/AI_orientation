<template>
  <HeaderBar />
  <div class="py-4 md:py-8 bg-gradient-to-b from-neutral-50 to-neutral-100 min-h-screen">
    <!-- 导航栏占位符 -->
    <div class="w-full h-[60px] md:h-[80px]"></div>
    
    <div class="container mx-auto px-3 md:px-4 mt-1 md:mt-4 max-w-5xl">
      <!-- 统计卡片 - 移动端横向紧凑 -->
      <div class="flex md:grid md:grid-cols-3 gap-2 md:gap-4 mb-4 md:mb-6" data-guide="answer-record-summary">
        <div class="flex-1 bg-white rounded-lg md:rounded-xl shadow-sm p-3 md:p-5 text-center hover:shadow-md transition-all border border-slate-100">
          <div class="text-xl md:text-3xl font-bold text-slate-800">{{ totalQuestions }}</div>
          <div class="text-xs text-slate-400 mt-0.5 md:mt-1">总答题数</div>
        </div>
        
        <div class="flex-1 bg-white rounded-lg md:rounded-xl shadow-sm p-3 md:p-5 text-center hover:shadow-md transition-all border border-slate-100">
          <div class="text-xl md:text-3xl font-bold text-emerald-600">{{ correctAnswers }}</div>
          <div class="text-xs text-slate-400 mt-0.5 md:mt-1">正确答题</div>
        </div>
        
        <div class="flex-1 bg-white rounded-lg md:rounded-xl shadow-sm p-3 md:p-5 text-center hover:shadow-md transition-all border border-slate-100">
          <div class="text-xl md:text-3xl font-bold text-blue-600">{{ accuracyRate }}%</div>
          <div class="text-xs text-slate-400 mt-0.5 md:mt-1">正确率</div>
        </div>
      </div>

      <!-- 筛选条件 - 移动端更紧凑 -->
      <div class="bg-white rounded-xl md:rounded-2xl shadow-sm p-3 md:p-6 mb-4 md:mb-6 border border-slate-100" data-guide="answer-record-filter">
        <div class="flex flex-col md:flex-row gap-2 md:gap-4 items-end">
          <div class="flex-1 w-full">
            <label class="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-1 md:mb-2">题目类型</label>
            <select v-model="filters.questionType" class="w-full px-3 md:px-4 py-2 md:py-2.5 bg-slate-50 border border-slate-200 rounded-lg md:rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none text-xs md:text-sm">
              <option value="">全部类型</option>
              <option value="single">单选题</option>
              <option value="multiple">多选题</option>
              <option value="judgment">判断题</option>
              <option value="text">简答题</option>
              <option value="fill">填空题</option>
            </select>
          </div>
          
          <div class="flex-1 w-full">
            <label class="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-1 md:mb-2">答题结果</label>
            <select v-model="filters.result" class="w-full px-3 md:px-4 py-2 md:py-2.5 bg-slate-50 border border-slate-200 rounded-lg md:rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none text-xs md:text-sm">
              <option value="">全部结果</option>
              <option value="correct">正确</option>
              <option value="wrong">错误</option>
            </select>
          </div>
          
          <div class="flex-1 w-full">
            <label class="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-1 md:mb-2">章节分类</label>
            <select v-model="filters.category" class="w-full px-3 md:px-4 py-2 md:py-2.5 bg-slate-50 border border-slate-200 rounded-lg md:rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none text-xs md:text-sm">
              <option value="">全部章节</option>
              <option v-for="cat in categoryList" :key="cat" :value="cat">{{ cat }}</option>
            </select>
          </div>
          
          <div class="flex-1 w-full">
            <label class="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-1 md:mb-2">时间范围</label>
            <select v-model="filters.timeRange" class="w-full px-3 md:px-4 py-2 md:py-2.5 bg-slate-50 border border-slate-200 rounded-lg md:rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all outline-none text-xs md:text-sm">
              <option value="">全部时间</option>
              <option value="today">今天</option>
              <option value="week">本周</option>
              <option value="month">本月</option>
            </select>
          </div>
          
          <div class="w-full md:w-auto">
            <button @click="applyFilters" class="w-full md:w-auto px-4 md:px-6 py-2 md:py-2.5 bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-lg md:rounded-xl font-semibold hover:shadow-lg hover:shadow-blue-200 transition-all flex items-center justify-center gap-2 text-sm">
              <i class="fa fa-filter"></i>
              筛选
            </button>
          </div>
        </div>
      </div>

      <!-- 答题记录列表 -->
      <div class="bg-white rounded-xl md:rounded-2xl shadow-sm overflow-hidden border border-slate-100">
        <div class="p-3 md:p-5 border-b border-slate-100 bg-gradient-to-r from-slate-50 to-transparent">
          <h3 class="text-sm md:text-base font-bold text-slate-700 flex items-center gap-2">
            <i class="fa fa-list-alt text-blue-500"></i>
            答题记录列表
          </h3>
        </div>
        
        <!-- 未登录提示 -->
        <div v-if="!isLoggedIn" class="p-16 text-center" data-guide="answer-record-guest-empty">
          <div class="w-20 h-20 bg-slate-50 rounded-2xl flex items-center justify-center mx-auto mb-6">
            <i class="fa fa-lock text-4xl text-slate-300"></i>
          </div>
          <h4 class="text-xl font-bold text-slate-800 mb-2">请先登录</h4>
          <p class="text-slate-400 mb-6">登录后即可查看您的详细答题历史</p>
          <button class="px-8 py-3 bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-xl font-semibold hover:shadow-lg transition-all" @click="openLoginModal">
            <i class="fa fa-sign-in mr-2"></i>立即登录
          </button>
        </div>
        
        <!-- 加载中 -->
        <div v-else-if="loading" class="p-16 text-center">
          <div class="inline-flex items-center justify-center w-12 h-12 bg-blue-50 rounded-full mb-4">
            <i class="fa fa-circle-o-notch fa-spin text-xl text-blue-500"></i>
          </div>
          <p class="text-slate-400">正在加载记录...</p>
        </div>
        
        <!-- 空状态 -->
        <div v-else-if="answerRecords.length === 0" class="p-16 text-center" data-guide="answer-record-list">
          <div class="w-20 h-20 bg-slate-50 rounded-2xl flex items-center justify-center mx-auto mb-6">
            <i class="fa fa-file-text-o text-4xl text-slate-300"></i>
          </div>
          <h4 class="text-lg font-bold text-slate-800 mb-2">暂无答题记录</h4>
          <p class="text-slate-400 mb-6">快去答题，开启学习之旅吧！</p>
          <button @click="goToPractice" class="px-8 py-3 bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-xl font-semibold hover:shadow-lg transition-all">
            <i class="fa fa-pencil mr-2"></i>开始练习
          </button>
        </div>
        
        <!-- 答题记录列表 -->
        <div v-else class="divide-y divide-slate-50" data-guide="answer-record-list">
          <div 
            v-for="record in answerRecords" 
            :key="record.id"
            class="transition-all duration-300"
          >
            <!-- 记录主体 - 可点击展开 -->
            <div 
              @click="toggleExpand(record.id)"
              class="p-5 hover:bg-blue-50/30 transition-colors cursor-pointer group"
            >
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1 min-w-0">
                  <!-- 标签行 -->
                  <div class="flex items-center gap-2 mb-2 flex-wrap">
                    <span class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-bold"
                          :class="getQuestionTypeClass(record.questionType)">
                      {{ getQuestionTypeName(record.questionType) }}
                    </span>
                    <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-bold"
                          :class="record.isCorrect ? 'bg-emerald-100 text-emerald-700' : 'bg-rose-100 text-rose-700'">
                      <i :class="record.isCorrect ? 'fa fa-check' : 'fa fa-times'"></i>
                      {{ record.isCorrect ? '正确' : '错误' }}
                    </span>
                    <span v-if="record.moduleName" class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-bold bg-indigo-100 text-indigo-700">
                      <i class="fa fa-book"></i>
                      {{ record.moduleName }}
                    </span>
                    <span class="text-xs text-slate-400 flex items-center gap-1">
                      <i class="fa fa-clock-o"></i> {{ formatDate(record.attemptTime) }}
                    </span>
                  </div>
                  
                  <!-- 题目内容 -->
                  <h4 class="text-base font-medium text-slate-800 leading-relaxed group-hover:text-blue-600 transition-colors line-clamp-2">
                    {{ record.questionText }}
                  </h4>
                  
                  <!-- 简要答案信息 -->
                  <div class="flex items-center gap-4 mt-3 text-sm">
                    <span class="text-slate-400">
                      您的答案: 
                      <span :class="record.isCorrect ? 'text-emerald-600 font-medium' : 'text-rose-600 font-medium'">
                        {{ record.userAnswer }}
                      </span>
                    </span>
                    <span v-if="!record.isCorrect" class="text-slate-400">
                      正确答案: 
                      <span class="text-emerald-600 font-medium">{{ record.correctAnswer }}</span>
                    </span>
                  </div>
                </div>
                
                <!-- 展开/收起图标 -->
                <div class="flex-shrink-0 self-center">
                  <div 
                    class="w-8 h-8 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center transition-all group-hover:bg-blue-100 group-hover:text-blue-600"
                  >
                    <i class="fa fa-chevron-down transition-transform duration-300" :class="{'rotate-180': expandedId === record.id}"></i>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- 展开的详情区域 -->
            <transition
              enter-active-class="transition-all duration-300 ease-out"
              enter-from-class="opacity-0 max-h-0"
              enter-to-class="opacity-100 max-h-[500px]"
              leave-active-class="transition-all duration-200 ease-in"
              leave-from-class="opacity-100 max-h-[500px]"
              leave-to-class="opacity-0 max-h-0"
            >
              <div v-if="expandedId === record.id" class="overflow-hidden">
                <div class="px-5 pb-5 pt-0">
                  <div class="bg-slate-50 rounded-xl p-5 border border-slate-100">
                    <!-- 选项列表（仅单选题和多选题显示，且选项数据有效时） -->
                    <div v-if="shouldShowOptions(record)" class="mb-4">
                      <div class="text-xs font-bold text-slate-400 uppercase tracking-wide mb-3">选项</div>
                      <div class="space-y-2">
                        <div 
                          v-for="(option, idx) in record.options" 
                          :key="idx"
                          class="flex items-start gap-3 p-3 rounded-lg transition-colors"
                          :class="getOptionBgClass(record, idx)"
                        >
                          <span 
                            class="w-6 h-6 rounded-md flex items-center justify-center text-xs font-bold flex-shrink-0"
                            :class="getOptionLabelClass(record, idx)"
                          >
                            {{ String.fromCharCode(65 + idx) }}
                          </span>
                          <span class="text-sm text-slate-700 flex-1">{{ option }}</span>
                          <!-- 标记 -->
                          <span v-if="isUserAnswer(record, idx) && isCorrectAnswer(record, idx)" class="text-xs text-emerald-600 font-medium">
                            <i class="fa fa-check-circle mr-1"></i>你的选择
                          </span>
                          <span v-else-if="isUserAnswer(record, idx) && !isCorrectAnswer(record, idx)" class="text-xs text-rose-600 font-medium">
                            <i class="fa fa-times-circle mr-1"></i>选择错误
                          </span>
                          <span v-else-if="isCorrectAnswer(record, idx)" class="text-xs text-emerald-600 font-medium">
                            <i class="fa fa-check mr-1"></i>正确答案
                          </span>
                        </div>
                      </div>
                    </div>
                    
                    <!-- 答案对比 -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                      <div class="bg-white rounded-lg p-4 border border-slate-100">
                        <div class="text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">您的答案</div>
                        <div class="text-base font-semibold" :class="record.isCorrect ? 'text-emerald-600' : 'text-rose-600'">
                          {{ record.userAnswer || '未作答' }}
                        </div>
                      </div>
                      <div class="bg-white rounded-lg p-4 border border-slate-100">
                        <div class="text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">正确答案</div>
                        <div class="text-base font-semibold text-emerald-600">
                          {{ record.correctAnswer }}
                        </div>
                      </div>
                    </div>
                    
                    <!-- 解析 -->
                    <div class="bg-gradient-to-r from-amber-50 to-orange-50 rounded-lg p-4 border border-amber-100">
                      <div class="flex items-center gap-2 mb-2">
                        <i class="fa fa-lightbulb-o text-amber-500"></i>
                        <span class="text-xs font-bold text-amber-600 uppercase tracking-wide">题目解析</span>
                      </div>
                      <div class="text-sm text-slate-600 leading-relaxed">
                        {{ record.explanation || '暂无解析' }}
                      </div>
                    </div>
                    
                    <!-- 操作按钮 -->
                    <div class="flex justify-end gap-3 mt-4">
                      <button 
                        @click.stop="reviewQuestion(record)"
                        class="px-4 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
                      >
                        <i class="fa fa-refresh mr-1"></i>重新练习
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </transition>
          </div>
        </div>
        
        <!-- 分页 -->
        <div v-if="answerRecords.length > 0" class="p-5 border-t border-slate-100 bg-slate-50/30">
          <div class="flex items-center justify-between">
            <div class="text-sm text-slate-400">
              显示 {{ (currentPage - 1) * pageSize + 1 }}-{{ Math.min(currentPage * pageSize, total) }} 条，共 {{ total }} 条
            </div>
            <div class="flex items-center gap-2">
              <button 
                @click="prevPage"
                :disabled="currentPage <= 1"
                class="px-3 py-1.5 text-sm border border-slate-200 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <i class="fa fa-chevron-left mr-1"></i>上一页
              </button>
              <span class="px-3 py-1.5 text-sm text-slate-500">{{ currentPage }} / {{ totalPages }}</span>
              <button 
                @click="nextPage"
                :disabled="currentPage >= totalPages"
                class="px-3 py-1.5 text-sm border border-slate-200 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                下一页<i class="fa fa-chevron-right ml-1"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import HeaderBar from '@/components/HeaderBar.vue';
import { getAnswerRecords, getAnswerStatistics } from '@/api/answerRecord';
import { getQuestionDetail } from '@/api/question';
import { getDeptQuestionDetail } from '@/api/deptQuestion';
import { getCultureQuestionDetail } from '@/api/cultureQuestion';
import { getGreenHotelQuestionDetail } from '@/api/greenHotelQuestion';

const router = useRouter();

// 状态
const isLoggedIn = ref(false);
const loading = ref(false);
const expandedId = ref(null); // 当前展开的记录ID

// 统计数据
const totalQuestions = ref(0);
const correctAnswers = ref(0);
const accuracyRate = ref(0);

// 筛选条件
const filters = ref({
  questionType: '',
  result: '',
  timeRange: '',
  category: ''
});

// 章节分类列表
const categoryList = ref([]);

// 分页
const currentPage = ref(1);
const pageSize = ref(10);
const total = ref(0);

// 答题记录数据
const answerRecords = ref([]);

const totalPages = computed(() => Math.ceil(total.value / pageSize.value));

// 切换展开/收起
const toggleExpand = async (id) => {
  if (expandedId.value === id) {
    expandedId.value = null;
  } else {
    expandedId.value = id;
    // 如果没有选项和解析数据，尝试加载
    const record = answerRecords.value.find(r => r.id === id);
    if (record && (!record.options || !record.explanation)) {
      await loadQuestionDetail(record);
    }
  }
};

// 加载题目详情（选项和解析）
const loadQuestionDetail = async (record) => {
  try {
    const questionId = record.questionId || record.id;
    const questionSource = record.questionSource || record.question_source || 'ota';
    logger.debug('加载题目详情, questionId:', questionId);
    const response = questionSource === 'dept'
      ? await getDeptQuestionDetail(questionId)
      : questionSource === 'culture'
        ? await getCultureQuestionDetail(questionId)
        : questionSource === 'green_hotel'
          ? await getGreenHotelQuestionDetail(questionId)
          : await getQuestionDetail(questionId);
    logger.debug('题目详情响应:', response);
    
    if (response.data && response.data.code === 200) {
      const detail = response.data.data || response.data;
      logger.debug('题目详情数据:', detail);
      
      // 处理选项数据 - 优先使用 optionA/B/C/D 字段
      let options = [];
      
      // 方式1: 从 optionA, optionB, optionC, optionD 字段获取
      if (detail.optionA || detail.optionB || detail.optionC || detail.optionD) {
        if (detail.optionA && detail.optionA.trim()) options.push(detail.optionA.trim());
        if (detail.optionB && detail.optionB.trim()) options.push(detail.optionB.trim());
        if (detail.optionC && detail.optionC.trim()) options.push(detail.optionC.trim());
        if (detail.optionD && detail.optionD.trim()) options.push(detail.optionD.trim());
        logger.debug('从optionA/B/C/D获取选项:', options);
      }
      
      // 方式2: 如果没有单独字段，尝试从 options 字段解析
      if (options.length === 0 && detail.options) {
        let rawOptions = detail.options;
        logger.debug('原始options字段:', rawOptions, '类型:', typeof rawOptions);
        
        if (typeof rawOptions === 'string') {
          // 如果是JSON字符串，尝试解析
          if (rawOptions.startsWith('[')) {
            try {
              options = JSON.parse(rawOptions);
            } catch (e) {
              logger.warn('JSON解析选项失败:', e);
            }
          } else if (rawOptions.includes('|')) {
            // 使用 | 分隔符
            options = rawOptions.split('|').map(s => s.trim()).filter(s => s);
          } else if (rawOptions.includes('\n')) {
            // 使用换行符分隔
            options = rawOptions.split('\n').map(s => s.trim()).filter(s => s);
          }
        } else if (Array.isArray(rawOptions)) {
          options = rawOptions;
        }
      }
      
      logger.debug('处理后的选项:', options);
      record.options = options;
      record.explanation = detail.explanation || detail.remark || '暂无解析';
      record.correctAnswer = detail.correctAnswer !== undefined 
        ? formatAnswerDisplay(detail.correctAnswer) 
        : record.correctAnswer;
      record.questionText = detail.questionText || detail.title || detail.content || record.questionText;
    }
  } catch (error) {
    logger.error('加载题目详情失败:', error);
  }
};

// 判断是否应该显示选项列表
const shouldShowOptions = (record) => {
  // 判断题不显示选项列表（显示正确/错误即可）
  const typeStr = (record.questionType || '').toString().trim();
  if (typeStr === 'judgment' || typeStr === '判断题' || typeStr === '3') {
    return false;
  }
  // 检查选项是否有效（数组且有内容）
  if (!record.options || !Array.isArray(record.options) || record.options.length === 0) {
    return false;
  }
  // 检查选项内容是否有效（至少有2个有效选项）
  const validOptions = record.options.filter(opt => opt && opt.toString().trim().length > 0);
  return validOptions.length >= 2;
};

// 格式化答案显示
const formatAnswerDisplay = (answer) => {
  if (answer === undefined || answer === null) return '';
  if (Array.isArray(answer)) {
    return answer.map(i => String.fromCharCode(65 + i)).join(',');
  }
  if (typeof answer === 'number') {
    return String.fromCharCode(65 + answer);
  }
  return answer;
};

// 判断选项是否是用户答案
const isUserAnswer = (record, idx) => {
  const userAns = record.userAnswer || '';
  const letter = String.fromCharCode(65 + idx);
  return userAns.includes(letter);
};

// 判断选项是否是正确答案
const isCorrectAnswer = (record, idx) => {
  const correctAns = record.correctAnswer || '';
  const letter = String.fromCharCode(65 + idx);
  return correctAns.includes(letter);
};

// 获取选项背景样式
const getOptionBgClass = (record, idx) => {
  const isUser = isUserAnswer(record, idx);
  const isCorrect = isCorrectAnswer(record, idx);
  
  if (isUser && isCorrect) return 'bg-emerald-50 border border-emerald-200';
  if (isUser && !isCorrect) return 'bg-rose-50 border border-rose-200';
  if (isCorrect) return 'bg-emerald-50/50 border border-emerald-100';
  return 'bg-white border border-slate-100';
};

// 获取选项标签样式
const getOptionLabelClass = (record, idx) => {
  const isUser = isUserAnswer(record, idx);
  const isCorrect = isCorrectAnswer(record, idx);
  
  if (isUser && isCorrect) return 'bg-emerald-500 text-white';
  if (isUser && !isCorrect) return 'bg-rose-500 text-white';
  if (isCorrect) return 'bg-emerald-100 text-emerald-600 border border-emerald-300';
  return 'bg-slate-100 text-slate-500';
};

// 格式化日期
const formatDate = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// 获取题目类型样式
const getQuestionTypeClass = (type) => {
  if (!type) return 'bg-slate-100 text-slate-600';
  const typeStr = type.toString().trim();
  const classMap = {
    'single': 'bg-blue-100 text-blue-700',
    'multiple': 'bg-amber-100 text-amber-700',
    'judge': 'bg-purple-100 text-purple-700',
    'judgment': 'bg-purple-100 text-purple-700',
    'text': 'bg-sky-100 text-sky-700',
    'fill': 'bg-teal-100 text-teal-700',
    '单选题': 'bg-blue-100 text-blue-700',
    '多选题': 'bg-amber-100 text-amber-700',
    '判断题': 'bg-purple-100 text-purple-700',
    '简答题': 'bg-sky-100 text-sky-700',
    '填空题': 'bg-teal-100 text-teal-700',
    '1': 'bg-blue-100 text-blue-700',
    '2': 'bg-amber-100 text-amber-700',
    '3': 'bg-purple-100 text-purple-700'
  };
  return classMap[typeStr] || 'bg-slate-100 text-slate-600';
};

// 获取题目类型名称
const getQuestionTypeName = (type) => {
  if (!type) return '未知';
  const typeStr = type.toString().trim();
  const nameMap = {
    'single': '单选题',
    'multiple': '多选题',
    'judge': '判断题',
    'judgment': '判断题',
    'text': '简答题',
    'fill': '填空题',
    '单选题': '单选题',
    '多选题': '多选题',
    '判断题': '判断题',
    '简答题': '简答题',
    '填空题': '填空题',
    '1': '单选题',
    '2': '多选题',
    '3': '判断题'
  };
  return nameMap[typeStr] || '未知';
};

// 检查登录状态
const checkLoginStatus = async () => {
  const token = localStorage.getItem('authToken');
  const storedUserInfo = localStorage.getItem('userInfo');
  isLoggedIn.value = !!(token && storedUserInfo);
  return isLoggedIn.value;
};

// 加载统计数据
const loadStatistics = async () => {
  if (!isLoggedIn.value) return;
  try {
    const response = await getAnswerStatistics();
    if (response.data && response.data.code === 200) {
      const stats = response.data.data;
      totalQuestions.value = stats.totalQuestions || 0;
      correctAnswers.value = stats.correctAnswers || 0;
      accuracyRate.value = Math.round(stats.accuracyRate || 0);
    }
  } catch (error) {
    logger.error('加载统计数据失败:', error);
  }
};

// 加载答题记录
const loadAnswerRecords = async () => {
  if (!isLoggedIn.value) return;
  loading.value = true;
  try {
    const params = {
      pageNum: currentPage.value,
      pageSize: pageSize.value
    };
    
    if (filters.value.result === 'correct') {
      params.isCorrect = 1;
    } else if (filters.value.result === 'wrong') {
      params.isCorrect = 0;
    }
    
    if (filters.value.questionType) {
      const mapType = { single: '单选题', multiple: '多选题', judgment: '判断题', text: '简答题', fill: '填空题' };
      params.questionType = mapType[filters.value.questionType] || filters.value.questionType;
    }
    
    if (filters.value.category) {
      params.moduleName = filters.value.category;
    }
    
    if (filters.value.timeRange) {
      const now = new Date();
      let beginDate;
      if (filters.value.timeRange === 'today') {
        beginDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      } else if (filters.value.timeRange === 'week') {
        beginDate = new Date(now);
        beginDate.setDate(now.getDate() - now.getDay() + 1);
        beginDate.setHours(0, 0, 0, 0);
      } else if (filters.value.timeRange === 'month') {
        beginDate = new Date(now.getFullYear(), now.getMonth(), 1);
      }
      if (beginDate) {
        params.params = {
          beginTime: beginDate.toISOString().split('T')[0] + ' 00:00:00',
          endTime: now.toISOString().split('T')[0] + ' 23:59:59'
        };
      }
    }
    
    const response = await getAnswerRecords(params);
    
    if (response.data.code === 200) {
      answerRecords.value = (response.data.rows || []).map(record => ({
        ...record,
        options: record.options || [],
        explanation: record.explanation || ''
      }));
      total.value = response.data.total || 0;
      
      // 从答题记录中提取章节分类列表（去重）
      if (categoryList.value.length === 0) {
        const categories = new Set();
        answerRecords.value.forEach(record => {
          if (record.moduleName) {
            categories.add(record.moduleName);
          }
        });
        categoryList.value = Array.from(categories).sort();
      }
    }
  } catch (error) {
    logger.error('加载答题记录失败:', error);
  } finally {
    loading.value = false;
  }
};

const applyFilters = () => {
  currentPage.value = 1;
  expandedId.value = null;
  loadAnswerRecords();
};

const prevPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--;
    expandedId.value = null;
    loadAnswerRecords();
  }
};

const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++;
    expandedId.value = null;
    loadAnswerRecords();
  }
};

const reviewQuestion = (record) => {
  const questionId = record.questionId || record.id;
  const questionSource = record.questionSource || record.question_source || 'ota';
  router.push(`/online?questionId=${questionId}&questionSource=${encodeURIComponent(questionSource)}`);
};

const goToPractice = () => {
  router.push('/online');
};

const openLoginModal = () => {
  window.dispatchEvent(new CustomEvent('showLoginModal'));
};

const handleUserLogin = () => {
  isLoggedIn.value = true;
  loadStatistics();
  loadAnswerRecords();
};

onMounted(async () => {
  await checkLoginStatus();
  if (isLoggedIn.value) {
    await loadStatistics();
    await loadAnswerRecords();
  }
  window.addEventListener('userLogin', handleUserLogin);
});
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.rotate-180 {
  transform: rotate(180deg);
}

/* 移动端深度优化 */
@media (max-width: 768px) {
  /* 统计卡片 - 一排3个紧凑显示 */
  .grid-cols-1.md\:grid-cols-3 {
    grid-template-columns: repeat(3, 1fr) !important;
    gap: 0.5rem !important;
  }
  
  .grid-cols-1.md\:grid-cols-3 > div {
    padding: 0.625rem !important;
  }
  
  .grid-cols-1.md\:grid-cols-3 .text-3xl {
    font-size: 1.25rem !important;
  }
  
  .grid-cols-1.md\:grid-cols-3 .text-sm {
    font-size: 0.625rem !important;
  }
  
  /* 筛选区域 - 2x2网格 */
  .flex-col.md\:flex-row {
    display: grid !important;
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 0.5rem !important;
  }
  
  .flex-col.md\:flex-row .flex-1.w-full {
    width: 100% !important;
  }
  
  .flex-col.md\:flex-row .w-full.md\:w-auto {
    grid-column: span 2 !important;
  }
  
  /* 筛选标签 */
  .text-xs.font-bold.text-slate-400 {
    font-size: 0.625rem !important;
    margin-bottom: 0.25rem !important;
  }
  
  /* 下拉框 */
  select {
    padding: 0.5rem 0.625rem !important;
    font-size: 0.75rem !important;
  }
  
  /* 筛选按钮 */
  .px-6.py-2\.5 {
    padding: 0.5rem 1rem !important;
    font-size: 0.75rem !important;
  }
  
  /* 记录列表 */
  .p-5 {
    padding: 0.625rem !important;
  }
  
  /* 记录项标签 */
  .px-2.py-0\.5 {
    padding: 0.125rem 0.375rem !important;
    font-size: 0.625rem !important;
  }
  
  /* 题目文字 */
  .text-base.font-medium {
    font-size: 0.8125rem !important;
    line-height: 1.4 !important;
  }
  
  /* 答案信息 */
  .flex.items-center.gap-4.mt-3 {
    flex-wrap: wrap !important;
    gap: 0.375rem !important;
    margin-top: 0.5rem !important;
    font-size: 0.6875rem !important;
  }
  
  /* 展开按钮 */
  .w-8.h-8.rounded-full {
    width: 1.75rem !important;
    height: 1.75rem !important;
  }
  
  /* 展开详情区域 */
  .bg-slate-50.rounded-xl.p-5 {
    padding: 0.625rem !important;
  }
  
  /* 选项列表 */
  .space-y-2 > div {
    padding: 0.5rem !important;
  }
  
  .w-6.h-6 {
    width: 1.25rem !important;
    height: 1.25rem !important;
    font-size: 0.625rem !important;
  }
  
  /* 答案对比 */
  .grid-cols-1.md\:grid-cols-2 {
    grid-template-columns: repeat(2, 1fr) !important;
    gap: 0.5rem !important;
  }
  
  .bg-white.rounded-lg.p-4 {
    padding: 0.5rem !important;
  }
  
  /* 解析区域 */
  .bg-gradient-to-r.from-amber-50.to-orange-50 {
    padding: 0.625rem !important;
  }
  
  /* 分页 */
  .p-5.border-t {
    padding: 0.625rem !important;
  }
  
  .px-3.py-1\.5 {
    padding: 0.375rem 0.5rem !important;
    font-size: 0.6875rem !important;
  }
  
  /* 容器内边距 */
  .container.mx-auto.px-4 {
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
  }
  
  /* 圆角优化 */
  .rounded-2xl {
    border-radius: 0.875rem !important;
  }
  
  .rounded-xl {
    border-radius: 0.625rem !important;
  }
  
  /* 间距优化 */
  .mb-6 {
    margin-bottom: 0.75rem !important;
  }
  
  .gap-4 {
    gap: 0.5rem !important;
  }
}

/* 超小屏幕优化 */
@media (max-width: 375px) {
  /* 统计卡片更紧凑 */
  .grid-cols-1.md\:grid-cols-3 .text-3xl {
    font-size: 1rem !important;
  }
  
  /* 筛选区域单列 */
  .flex-col.md\:flex-row {
    grid-template-columns: 1fr !important;
  }
  
  .flex-col.md\:flex-row .w-full.md\:w-auto {
    grid-column: span 1 !important;
  }
  
  /* 答案对比单列 */
  .grid-cols-1.md\:grid-cols-2 {
    grid-template-columns: 1fr !important;
  }
}
</style>

