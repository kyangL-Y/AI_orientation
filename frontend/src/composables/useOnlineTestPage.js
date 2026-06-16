import logger from '@/utils/logger';
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  favoriteQuestion,
  generateCustomPaper,
  getFavoriteQuestions,
  getQuestionCategories,
  getQuestionDetail,
  getQuestions,
  getWrongQuestions,
  submitAnswer as apiSubmitAnswer,
  unfavoriteQuestion,
} from '@/api/question';
import {
  getDeptCourseCategories,
  getDeptQuestions,
  getDeptQuestionsByCourse,
  getDeptDailyQuestions,
  getDeptQuestionDetail
} from '@/api/deptQuestion';
import { getCultureCategories, getCultureQuestionDetail, getCultureQuestions } from '@/api/cultureQuestion';
import { getGreenHotelCategories, getGreenHotelQuestionDetail, getGreenHotelQuestions } from '@/api/greenHotelQuestion';
import { getAnswerRecords, getAnswerStatistics } from '@/api/answerRecord';
import { getUserInfo } from '@/api/auth';
import { checkContentAccess, getMembershipUsageLimits, getMyMembership } from '@/api/membership';
import { getPracticeProgress, savePracticeProgress, clearPracticeProgress } from '@/api/practiceProgress';
import { addDailyCheckInPoints, getMyPoints } from '@/api/points';
import { getUserId, getUserInfo as getStoredUserInfo, setUserInfo as setStoredUserInfo } from '@/utils/userStorage';
import { ElMessage, ElMessageBox } from 'element-plus';

export function useOnlineTestPage() {
  const router = useRouter();
  const route = useRoute();
  const CATEGORY_CACHE_VERSION = 'v3';
  const CATEGORY_CACHE_MAX_AGE = 6 * 60 * 60 * 1000;
  const managerQuestionBankRoles = new Set(['admin', 'platform', 'tenant_admin', 'company_admin', 'dept_admin']);
  const managerQuestionBankRoleNames = ['管理员', '平台', '集团管理员', '公司管理员', '部门管理员'];
  const normalizeQuestionBankScope = (scope) => (scope === 'all' ? 'all' : 'self');
  const getQuestionBankUserKey = (user = userInfo.value) => {
    return user?.userId || user?.id || user?.userName || getUserId() || 'anonymous';
  };
  const getQuestionBankScopeStorageKey = (user = userInfo.value) => {
    return `questionBankScope:${getQuestionBankUserKey(user)}`;
  };
  const getStoredQuestionBankScope = (user = userInfo.value) => {
    try {
      return normalizeQuestionBankScope(localStorage.getItem(getQuestionBankScopeStorageKey(user)));
    } catch (_) {
      return 'self';
    }
  };
  
  // --- 会员状态 ---
  const membership = ref({ levelCode: 'free' });
  const FREE_DAILY_LIMIT = ref(5); // 默认值，优先以后端下发为准
  
  // --- 核心状态 ---
  const isLoggedIn = ref(false);
  const currentMode = ref('daily'); // 'daily', 'category', 'wrong', 'fav'
  const activeCategory = ref(null);
  const activeCategoryName = ref('每日一练');
  const activeDeptCategoryMeta = ref(null);
  const searchQuery = ref('');
  const userInfo = ref({});
  const questionBankScope = ref('self');
  
  // --- UI状态 ---
  const showRecordModal = ref(false);
  const showTargetModal = ref(false);
  const showCheckInCalendar = ref(false);
  const calendarDate = ref(new Date());
  const showCategoryModal = ref(false); // 移动端专项题库选择弹窗
  const showQuestionListModal = ref(false); // 移动端题目列表弹窗
  const deptSectionExpanded = ref(false); // 部门培训分类默认折叠
  const otaSectionExpanded = ref(false); // OTA平台分类默认折叠
  const showFloatBtnTip = ref(false); // 悬浮按钮新手引导提示
  const loadingQuestions = ref(false);
  const showCelebration = ref(false); // 庆祝弹窗控制
  const deptCategoryExpanded = ref(false); // 部门题库折叠状态
  const otaCategoryExpanded = ref(false); // OTA题库折叠状态
  const cultureCategoryExpanded = ref(false); // 企业文化题库折叠状态
  const greenHotelCategoryExpanded = ref(false); // 绿色饭店题库折叠状态
  
  // --- 统计数据 ---
  const practiceDays = ref(0);
  const totalQuestions = ref(0);
  const correctAnswersCount = ref(0);
  const accuracyRate = ref(0);
  const totalTime = ref(0);
  const todayPracticeCount = ref(0);
  const dailyPracticeTarget = ref(50); // 可设置，默认50题
  const checkInDays = ref([]);
  const myPoints = ref(0);
  const dailyRewardRequesting = ref(false);
  const todayPracticeRate = computed(() => Math.min((todayPracticeCount.value / dailyPracticeTarget.value) * 100, 100));

  const currentRoleKeys = computed(() => {
    const roles = Array.isArray(userInfo.value?.roles) ? userInfo.value.roles : [];
    const roleKeys = roles.map((role) => {
      if (typeof role === 'string') return role;
      return role?.roleKey || '';
    }).filter(Boolean);

    const roleGroup = String(userInfo.value?.roleGroup || '').toLowerCase();
    managerQuestionBankRoles.forEach((roleKey) => {
      if (roleGroup.includes(roleKey)) {
        roleKeys.push(roleKey);
      }
    });
    if (managerQuestionBankRoleNames.some((roleName) => String(userInfo.value?.roleGroup || '').includes(roleName))) {
      roleKeys.push('admin');
    }

    return Array.from(new Set(roleKeys));
  });

  const canUseAllQuestionBanks = computed(() => {
    if (userInfo.value?.canAccessAdmin === true) return true;
    const adminLevel = Number(userInfo.value?.adminLevel);
    if (Number.isFinite(adminLevel) && adminLevel < 999) return true;
    return currentRoleKeys.value.some((roleKey) => managerQuestionBankRoles.has(roleKey));
  });

  const recommendedQuestionBankScope = computed(() => canUseAllQuestionBanks.value ? 'all' : 'self');
  
  // 关闭庆祝弹窗
  const closeCelebration = () => {
    showCelebration.value = false;
  };
  
  // --- 题库数据 ---
  const userCategories = ref([]);
  const loadingCategories = ref(false);
  
  // 部门题库分类
  const deptCategories = computed(() => {
    return userCategories.value.filter(c => c.type === 'dept');
  });
  
  // 过滤后的部门题库分类（受搜索影响）
  const filteredDeptCategories = computed(() => {
    if (!searchQuery.value) return deptCategories.value;
    const lower = searchQuery.value.toLowerCase();
    return deptCategories.value.filter(c =>
      c.name.toLowerCase().includes(lower) ||
      String(c.groupName || '').toLowerCase().includes(lower)
    );
  });

  const deptCategoryGroups = computed(() => {
    const groupedCategories = new Map();
    filteredDeptCategories.value.forEach((category) => {
      const groupName = category.groupName || category.deptType || '未分组课程';
      const groupId = category.groupId || `dept_course_group_${groupName}`;
      if (!groupedCategories.has(groupId)) {
        groupedCategories.set(groupId, {
          id: groupId,
          name: groupName,
          count: 0,
          children: []
        });
      }
      const group = groupedCategories.get(groupId);
      group.children.push(category);
      group.count += Number(category.count || 0);
    });
    return Array.from(groupedCategories.values());
  });

  const groupCourseCategories = (categories, fallbackGroupName) => {
    const groupedCategories = new Map();
    categories.forEach((category) => {
      const groupName = category.groupName || fallbackGroupName;
      const groupId = category.groupId || `${category.type}_group_${groupName}`;
      if (!groupedCategories.has(groupId)) {
        groupedCategories.set(groupId, {
          id: groupId,
          name: groupName,
          count: 0,
          children: []
        });
      }
      const group = groupedCategories.get(groupId);
      group.children.push(category);
      group.count += Number(category.count || 0);
    });
    return Array.from(groupedCategories.values());
  };

  const deptAllCategory = computed(() => ({
    id: 'dept_all',
    name: '全部部门题库',
    count: deptCategories.value.reduce((sum, category) => sum + Number(category.count || 0), 0),
    type: 'dept_all'
  }));
  
  // OTA题库分类（不受搜索影响的原始列表）
  const otaCategories = computed(() => {
    return userCategories.value.filter(c => c.type === 'ota');
  });
  
  // 企业文化题库分类
  const cultureCategories = computed(() => {
    return userCategories.value.filter(c => c.type === 'culture');
  });

  const filteredCultureCategories = computed(() => {
    if (!searchQuery.value) return cultureCategories.value;
    const lower = searchQuery.value.toLowerCase();
    return cultureCategories.value.filter(c => c.name.toLowerCase().includes(lower));
  });
  
  // 绿色饭店题库分类
  const greenHotelCategories = computed(() => {
    return userCategories.value.filter(c => c.type === 'green_hotel');
  });
  
  // 过滤后的OTA题库分类（受搜索影响）
  const filteredOtaCategories = computed(() => {
    if (!searchQuery.value) return otaCategories.value;
    const lower = searchQuery.value.toLowerCase();
    return otaCategories.value.filter(c =>
      c.name.toLowerCase().includes(lower) ||
      String(c.groupName || '').toLowerCase().includes(lower) ||
      String(c.mainTitle || '').toLowerCase().includes(lower)
    );
  });

  const otaCategoryGroups = computed(() => groupCourseCategories(filteredOtaCategories.value, 'OTA课程'));

  const filteredGreenHotelCategories = computed(() => {
    if (!searchQuery.value) return greenHotelCategories.value;
    const lower = searchQuery.value.toLowerCase();
    return greenHotelCategories.value.filter(c =>
      c.name.toLowerCase().includes(lower) ||
      String(c.groupName || '').toLowerCase().includes(lower) ||
      String(c.mainTitle || '').toLowerCase().includes(lower)
    );
  });

  const greenHotelCategoryGroups = computed(() => groupCourseCategories(filteredGreenHotelCategories.value, '绿色饭店课程'));
  
  // --- 答题引擎 ---
  const questions = ref([]);
  const currentIndex = ref(0);
  const selectedOption = ref(null);
  const showAnswer = ref(false);
  const isFavorite = ref(false); // 当前题目是否收藏
  const suppressIndexWatch = ref(false);
  const lastAllowedIndex = ref(0);
  const accessCache = new Map();
  const activeCourseCategoryMeta = ref(null);
  let accessSeq = 0;
  
  const promptUpgrade = async () => {
    try {
      await ElMessageBox.confirm(
        '该题为会员专享内容，升级会员即可解锁。',
        '升级提示',
        {
          confirmButtonText: '去升级',
          cancelButtonText: '取消',
          type: 'warning',
          center: true
        }
      );
      router.push('/member-center');
    } catch {}
  };
  
  const parseAccessResponse = (res) => {
    const payload = res?.data;
    if (payload && typeof payload === 'object' && Object.prototype.hasOwnProperty.call(payload, 'data')) {
      return !!payload.data;
    }
    return !!payload;
  };
  
  const checkQuestionAccess = async (questionId) => {
    if (!questionId) return true;
    const cacheKey = `question:${questionId}`;
    if (accessCache.has(cacheKey)) return accessCache.get(cacheKey);
  
    try {
      const res = await checkContentAccess('question', Number(questionId));
      const hasAccess = parseAccessResponse(res);
      accessCache.set(cacheKey, hasAccess);
      return hasAccess;
    } catch (e) {
      logger.error('检查题目权限失败:', e);
      return true;
    }
  };

  const loadMembershipLimits = async () => {
    try {
      const limitRes = await getMembershipUsageLimits();
      const payload = limitRes?.data || limitRes;
      if (payload?.code === 200 && payload?.data?.freePracticeDailyLimit) {
        FREE_DAILY_LIMIT.value = Number(payload.data.freePracticeDailyLimit) || FREE_DAILY_LIMIT.value;
      }
    } catch (e) {
      logger.warn('获取会员限制配置失败，使用默认值', e);
    }
  };

  const loadMembershipSnapshot = async () => {
    await loadMembershipLimits();

    try {
      const memberRes = await getMyMembership();
      const payload = memberRes.data || memberRes;
      if (payload.code === 200) {
        membership.value = payload.data;
        logger.debug('✅ 会员信息:', membership.value?.levelCode || 'free');
      }
    } catch (e) {
      logger.warn('获取会员信息失败，默认为免费用户', e);
      membership.value = { levelCode: 'free' };
    }
  };
  
  const findNearestAccessibleIndex = async (startIndex) => {
    if (!questions.value || questions.value.length === 0) return null;
  
    for (let i = startIndex; i < questions.value.length; i++) {
      const q = questions.value[i];
      const qId = q?.questionId || q?.id;
      if (!qId) return i;
      if (await checkQuestionAccess(qId)) return i;
    }
  
    for (let i = startIndex - 1; i >= 0; i--) {
      const q = questions.value[i];
      const qId = q?.questionId || q?.id;
      if (!qId) return i;
      if (await checkQuestionAccess(qId)) return i;
    }
  
    return null;
  };
  
  const applyQuestionStateByIndex = async (index, oldIndex) => {
    if (!questions.value || !questions.value[index]) return;
    const seq = ++accessSeq;
    const q = questions.value[index];
    const qId = q?.questionId || q?.id;
  
    if (qId) {
      const hasAccess = await checkQuestionAccess(qId);
      if (seq !== accessSeq) return;
  
      if (!hasAccess) {
        await promptUpgrade();
        const fallbackIndex = await findNearestAccessibleIndex(index);
        if (seq !== accessSeq) return;
  
        const targetIndex =
          typeof fallbackIndex === 'number'
            ? fallbackIndex
            : typeof oldIndex === 'number'
              ? oldIndex
              : lastAllowedIndex.value;
  
        if (targetIndex !== index) {
          suppressIndexWatch.value = true;
          currentIndex.value = targetIndex;
          suppressIndexWatch.value = false;
          await applyQuestionStateByIndex(targetIndex, oldIndex);
        }
        return;
      }
    }
  
    selectedOption.value = q.myAnswer !== undefined ? q.myAnswer : null;
    showAnswer.value = !!q.isSubmitted;
  
    const favIds = JSON.parse(localStorage.getItem('favoriteQuestionIds') || '[]');
    isFavorite.value = favIds.includes(qId);
    lastAllowedIndex.value = index;
  };
  
  const sessionDuration = ref(0);
  let activityTimer = null;
  let categoryLoadSeq = 0;
  let lastTickTime = Date.now();
  let isPageVisible = typeof document !== 'undefined' ? document.visibilityState === 'visible' : true;
  
  // --- 通用答案转换函数 ---
  const normalizeQuestionTypeLabel = (questionType) => {
    const raw = questionType === undefined || questionType === null ? '' : String(questionType).trim();
    if (!raw) return '单选题';

    const lower = raw.toLowerCase();
    if (raw === '单选题' || raw === '单选' || raw === '1' || lower === 'single' || lower === 'choice' || raw.includes('单')) {
      return '单选题';
    }
    if (raw === '多选题' || raw === '多选' || raw === '2' || lower === 'multiple' || raw.includes('多')) {
      return '多选题';
    }
    if (raw === '判断题' || raw === '判断' || raw === '3' || lower === 'judge' || lower === 'judgment' || raw.includes('判') || raw.includes('对错')) {
      return '判断题';
    }
    if (raw === '填空题' || raw === '填空' || lower === 'fill' || lower === 'blank' || raw.includes('填')) {
      return '填空题';
    }
    if (raw === '简答题' || raw === '简答' || lower === 'text' || lower === 'short_text' || raw.includes('简') || raw.includes('问答')) {
      return '简答题';
    }
    return raw;
  };

  const isChoiceQuestionType = (questionType) => {
    const normalized = normalizeQuestionTypeLabel(questionType);
    return normalized === '单选题' || normalized === '多选题' || normalized === '判断题';
  };

  const isTextQuestionType = (questionType) => {
    const normalized = normalizeQuestionTypeLabel(questionType);
    return normalized === '简答题' || normalized === '填空题';
  };

  const normalizeTextAnswer = (value) => String(value === undefined || value === null ? '' : value)
    .replace(/[，。；、,.;\s]+/g, '')
    .trim()
    .toLowerCase();

  const splitTextAnswers = (value) => String(value === undefined || value === null ? '' : value)
    .split(/[;；\n]/)
    .map(item => item.trim())
    .filter(Boolean);

  const extractTextKeywords = (value) => String(value === undefined || value === null ? '' : value)
    .split(/[;；，。,、\n]/)
    .map(item => normalizeTextAnswer(item))
    .filter(item => item.length >= 2);

  // 将后端返回的答案格式转换为前端使用的索引或文本格式
  const parseCorrectAnswer = (answer, questionType = '') => {
    const normalizedType = normalizeQuestionTypeLabel(questionType);

    if (isTextQuestionType(normalizedType)) {
      if (Array.isArray(answer)) {
        return answer.map(item => String(item).trim()).filter(Boolean).join(';');
      }
      return answer === undefined || answer === null ? '' : String(answer).trim();
    }

    if (answer === undefined || answer === null) return 0;
    if (typeof answer === 'number') return answer;
    if (Array.isArray(answer)) return answer;
    
    if (typeof answer === 'string') {
      let ans = answer.replace(/\s/g, '').trim();
      if (!ans) return 0;
      
      ans = ans.replace(/[，、|]/g, ',');
      ans = ans.replace(/,+/g, ',');
      ans = ans.replace(/^,|,$/g, '');
      
      if (ans.includes(',')) {
        const parts = ans.split(',').filter(Boolean);
        if (parts.length > 1) {
          return parts.map(p => {
            p = p.trim().toUpperCase();
            if (/^[A-D]$/.test(p)) return p.charCodeAt(0) - 65;
            if (/^\d+$/.test(p)) return parseInt(p);
            return 0;
          });
        }
        const single = parts[0].trim().toUpperCase();
        if (/^[A-D]$/.test(single)) return single.charCodeAt(0) - 65;
        if (/^\d+$/.test(single)) return parseInt(single);
        return 0;
      }
      
      if (ans.length > 1 && /^[A-D]+$/i.test(ans)) {
        return ans.toUpperCase().split('').map(c => c.charCodeAt(0) - 65);
      }
      
      if (/^[A-D]$/i.test(ans)) {
        return ans.toUpperCase().charCodeAt(0) - 65;
      }
      
      if (/^\d+$/.test(ans)) {
        return parseInt(ans);
      }
      
      if (ans === '正确' || ans === 'true' || ans === '对') return 0;
      if (ans === '错误' || ans === 'false' || ans === '错') return 1;
    }
    
    return 0;
  };

  const buildQuestionOptions = (source, questionType) => {
    const normalizedType = normalizeQuestionTypeLabel(questionType);

    if (normalizedType === '判断题') {
      return ['正确', '错误'];
    }

    if (isTextQuestionType(normalizedType)) {
      return [];
    }

    let options = source?.options;
    if (!options || (Array.isArray(options) && options.length === 0)) {
      options = [source?.optionA, source?.optionB, source?.optionC, source?.optionD].filter(Boolean);
    } else if (typeof options === 'string') {
      if (options.startsWith('[')) {
        try {
          options = JSON.parse(options);
        } catch (e) {
          options = options.split('|').filter(s => s && s.trim());
        }
      } else if (options.includes('|')) {
        options = options.split('|').filter(s => s && s.trim());
      } else {
        options = options.split(',').filter(s => s && s.trim());
      }
    }

    return Array.isArray(options) ? options.filter(Boolean) : [];
  };

  const compareFillAnswers = (userAnswer, correctAnswer) => {
    const correctAnswers = splitTextAnswers(correctAnswer);
    const userAnswers = splitTextAnswers(userAnswer);
    if (correctAnswers.length === 0 || userAnswers.length === 0 || correctAnswers.length !== userAnswers.length) return false;
    return correctAnswers.every((correct, index) => normalizeTextAnswer(userAnswers[index]) === normalizeTextAnswer(correct));
  };

  const compareTextAnswers = (userAnswer, correctAnswer) => {
    const userText = normalizeTextAnswer(userAnswer);
    const correctText = normalizeTextAnswer(correctAnswer);
    if (!userText || !correctText) return false;
    if (userText === correctText) return true;
    const keywords = extractTextKeywords(correctAnswer);
    if (keywords.length === 0) return false;
    const matchedCount = keywords.filter(keyword => userText.includes(keyword)).length;
    return matchedCount >= Math.max(1, Math.ceil(keywords.length / 2));
  };

  const formatTextAnswerDisplay = (answer) => {
    const parts = splitTextAnswers(answer);
    if (parts.length > 0) {
      return parts.join('；');
    }
    return answer === undefined || answer === null ? '' : String(answer).trim();
  };
  
  // --- 刷题进度保存与恢复（后端存储） ---
  
  // 保存刷题进度到后端
  const saveProgress = async () => {
    if (!questions.value || questions.value.length === 0) return;
    if (!isLoggedIn.value) return; // 未登录不保存
    
    try {
      const progressData = {
        mode: currentMode.value,
        categoryName: activeCategoryName.value,
        categoryId: activeCategory.value,
        questionBankScope: questionBankScope.value,
        currentIndex: currentIndex.value,
        questions: questions.value.map(q => ({
          id: q.id || q.questionId,
          title: q.title,
          options: q.options,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation || q.desc,
          type: q.type || q.questionType,
          tag: q.tag,
          level: q.level,
          myAnswer: q.myAnswer,
          isSubmitted: q.isSubmitted,
          isCorrect: q.isCorrect
        }))
      };
      
      await savePracticeProgress(progressData);
      logger.debug('💾 刷题进度已保存到服务器，当前第', currentIndex.value + 1, '题');
    } catch (e) {
      logger.error('保存进度失败:', e);
      // 失败时不影响用户体验，静默处理
    }
  };
  
  // 从后端恢复刷题进度
  const restoreProgress = async () => {
    if (!isLoggedIn.value) return null;
    
    try {
      const res = await getPracticeProgress();
      if (res.data.code === 200 && res.data.data) {
        const progress = res.data.data;
        // 解析题目数据
        if (progress.questionsData) {
          progress.questions = JSON.parse(progress.questionsData);
        }
        logger.debug('📂 从服务器获取到进度:', progress.mode, progress.categoryName);
        return progress;
      }
      return null;
    } catch (e) {
      logger.error('恢复进度失败:', e);
      return null;
    }
  };
  
  // 清除刷题进度
  const clearProgress = async () => {
    if (!isLoggedIn.value) return;
    
    try {
      await clearPracticeProgress(currentMode.value, activeCategory.value);
      logger.debug('🗑️ 刷题进度已清除');
    } catch (e) {
      logger.error('清除进度失败:', e);
    }
  };
  
  const currentQuestion = computed(() => {
    if (!questions.value || questions.value.length === 0 || currentIndex.value >= questions.value.length) {
      return null;
    }
    const q = questions.value[currentIndex.value];
    if (!q) return null;
    
    return {
      id: q.id || q.questionId || 0,
      title: q.title || q.questionText || q.content || '题目加载中...',
      type: q.type || q.questionType || '单选题', // 添加题目类型字段
      options: q.options || [],
      correctAnswer: q.correctAnswer !== undefined ? q.correctAnswer : (isTextQuestionType(q.type || q.questionType) ? '' : 0),
      explanation: q.explanation || q.desc || q.remark || '暂无解析',
      level: q.level || q.difficulty || '中等',
      tag: q.tag || q.category || '通用',
      questionSource: q.questionSource || q.question_source,
      myAnswer: q.myAnswer,
      isSubmitted: q.isSubmitted
    };
  });
  
  // 判断当前题目是否为多选题
  const isMultipleChoice = computed(() => {
    if (!currentQuestion.value) return false;
    const type = currentQuestion.value.type;
    return type === '多选题' || type === 'multiple' || type === '2';
  });
  
  // 已答题数量
  const answeredCount = computed(() => {
    return questions.value.filter(q => q.isSubmitted).length;
  });
  
  const resetSessionTimer = () => {
    sessionDuration.value = 0;
    lastTickTime = Date.now();
  };
  
  const startActivityTimer = () => {
    if (activityTimer) return;
    lastTickTime = Date.now();
    activityTimer = setInterval(() => {
      if (!isPageVisible) {
        lastTickTime = Date.now();
        return;
      }
      const now = Date.now();
      const delta = Math.floor((now - lastTickTime) / 1000);
      if (delta > 0) {
        sessionDuration.value += delta;
        lastTickTime = now;
      }
    }, 1000);
  };
  
  const stopActivityTimer = () => {
    if (activityTimer) {
      clearInterval(activityTimer);
      activityTimer = null;
    }
  };
  
  const handleVisibilityChange = () => {
    isPageVisible = typeof document !== 'undefined' ? document.visibilityState === 'visible' : true;
    lastTickTime = Date.now();
  };
  
  const formatPracticeDuration = (totalSeconds) => {
    const s = Number(totalSeconds || 0);
    if (s <= 0) return '0分钟';
  
    const minute = 60;
    const hour = 60 * minute;
    const day = 24 * hour;
    const month = 30 * day;
    const year = 365 * day;
  
    // 小于1小时：显示分钟数，每分钟更新一次
    if (s < hour) {
      const minutes = Math.floor(s / minute);
      return `${minutes}分钟`;
    }
  
    if (s < day) {
      const hours = Math.round((s / hour) * 10) / 10;
      return `${hours}小时`;
    }
  
    if (s < month) {
      const days = Math.floor(s / day);
      return `${days}天`;
    }
  
    if (s < year) {
      const totalDays = Math.floor(s / day);
      const months = Math.floor(totalDays / 30);
      const remainDays = totalDays % 30;
      if (remainDays === 0) return `${months}个月`;
      return `${months}个月${remainDays}天`;
    }
  
    const totalDays = Math.floor(s / day);
    const years = Math.floor(totalDays / 365);
    let remainDays = totalDays % 365;
    const months = Math.floor(remainDays / 30);
    remainDays = remainDays % 30;
  
    const parts = [];
    if (years > 0) parts.push(`${years}年`);
    if (months > 0) parts.push(`${months}个月`);
    if (remainDays > 0) parts.push(`${remainDays}天`);
    return parts.join('');
  };
  
  // 监听索引变化，恢复题目状态
  watch(currentIndex, async (newVal, oldVal) => {
    if (suppressIndexWatch.value) return;
    await applyQuestionStateByIndex(newVal, oldVal);
  });
  
  // --- 答题记录 ---
  const answerRecords = ref([]);
  const loadingRecords = ref(false);
  
  // --- 生命周期 ---
  onMounted(async () => {
    try {
      // 读取本地存储的目标
      const savedTarget = localStorage.getItem('dailyPracticeTarget');
      if (savedTarget) dailyPracticeTarget.value = parseInt(savedTarget);
      
      // 恢复今日答题数
      const today = new Date().toDateString();
      const todayKey = `todayPractice_${today}`;
      const savedTodayCount = localStorage.getItem(todayKey);
      if (savedTodayCount) {
        todayPracticeCount.value = parseInt(savedTodayCount);
      }
      
      // 检查是否需要显示悬浮按钮新手引导（仅移动端首次访问显示）
      const floatBtnTipDismissed = localStorage.getItem('floatBtnTipDismissed');
      if (!floatBtnTipDismissed && window.innerWidth < 1024) {
        // 延迟显示提示，等待页面加载完成
        setTimeout(() => {
          showFloatBtnTip.value = true;
        }, 1500);
      }
  
      if (typeof document !== 'undefined') {
        document.addEventListener('visibilitychange', handleVisibilityChange);
      }
      startActivityTimer();
  
      await checkLoginStatus();
      applyRecommendedQuestionBankScope();
      if (isLoggedIn.value) {
        hydrateCategoriesFromCache(questionBankScope.value);
        loadMembershipSnapshot();
        loadStatistics();
        fetchMyPoints();
        loadUserCategories(questionBankScope.value, { allowCache: false, background: true });
        
        // 检查是否有指定的题目ID（从答题记录页面跳转过来）
        const questionId = route.query.questionId;
        const routeQuestionSource = String(route.query.questionSource || '').trim() || 'ota';
        if (questionId) {
          // 加载指定题目
          await loadSpecificQuestion(questionId, routeQuestionSource);
        } else {
          const handledByRouteIntent = await applyRouteIntentMode();
          if (handledByRouteIntent) {
            return;
          }

          // 检查是否有保存的刷题进度（从后端获取）
          const savedProgress = await restoreProgress();
          if (savedProgress && savedProgress.questions && savedProgress.questions.length > 0) {
            const unfinishedCount = savedProgress.questions.filter(q => !q.isSubmitted).length;
            if (unfinishedCount > 0) {
              // 有未完成的进度，恢复到对应模式
              logger.debug('🔄 检测到保存的进度，模式:', savedProgress.mode, '分类:', savedProgress.categoryName);
              const savedScope = normalizeQuestionBankScope(savedProgress.questionBankScope);
              if (savedScope !== questionBankScope.value) {
                questionBankScope.value = savedScope;
                persistQuestionBankScope(savedScope);
                hydrateCategoriesFromCache(savedScope);
                loadUserCategories(savedScope, { allowCache: false, background: true });
              }
              currentMode.value = savedProgress.mode;
              activeCategory.value = savedProgress.categoryId;
              activeCategoryName.value = savedProgress.categoryName;
              // loadQuestions 会自动恢复进度
              await loadQuestions(savedProgress.mode, savedProgress.categoryName);
              return;
            }
          }
          // 没有保存的进度，默认加载每日一练
          await loadQuestions('daily');
        }
      }
    } catch (error) {
      logger.error('组件初始化失败:', error);
      // 确保基本状态正确
      questions.value = [];
      currentIndex.value = 0;
      selectedOption.value = null;
      showAnswer.value = false;
      loadingQuestions.value = false;
    }
  });
  
  // --- 模式切换 ---
  const switchMode = async (mode) => {
    if (currentMode.value === mode) return;
    currentMode.value = mode;
    activeCategory.value = null;
    if (mode === 'category') {
      if (userCategories.value.length === 0 && !loadingCategories.value) {
        await loadUserCategories(questionBankScope.value);
      }
      await switchToFirstCategory();
    } else {
      await loadQuestions(mode);
    }
  };

  const persistQuestionBankScope = (scope) => {
    try {
      localStorage.setItem(getQuestionBankScopeStorageKey(), scope);
    } catch (_) {}
  };

  const applyRecommendedQuestionBankScope = () => {
    const storedScope = getStoredQuestionBankScope();
    const hasStoredScope = (() => {
      try {
        return localStorage.getItem(getQuestionBankScopeStorageKey()) !== null;
      } catch (_) {
        return false;
      }
    })();
    const nextScope = hasStoredScope ? storedScope : recommendedQuestionBankScope.value;
    questionBankScope.value = normalizeQuestionBankScope(nextScope);
    if (!hasStoredScope) {
      persistQuestionBankScope(questionBankScope.value);
    }
  };

  const getPreferredPracticeCategory = () => {
    if (deptCategories.value.length > 0) return deptCategories.value[0];
    if (otaCategories.value.length > 0) return otaCategories.value[0];
    if (cultureCategories.value.length > 0) return cultureCategories.value[0];
    if (greenHotelCategories.value.length > 0) return greenHotelCategories.value[0];
    return null;
  };
  
  const switchToFirstCategory = async () => {
    if (loadingCategories.value) {
      return;
    }

    if (userCategories.value.length === 0) {
      await loadUserCategories(questionBankScope.value);
    }

    deptCategoryExpanded.value = false;
    otaCategoryExpanded.value = false;
    cultureCategoryExpanded.value = false;
    greenHotelCategoryExpanded.value = false;

    const firstCategory = getPreferredPracticeCategory();
    if (firstCategory) {
      await selectCategory(firstCategory);
      return;
    }

    currentMode.value = 'category';
  };
  
  const selectCategory = async (category, forceReload = false) => {
    // 防止重复调用：如果正在加载或已选择相同分类，则跳过
    if (loadingQuestions.value) {
      logger.debug('【选择分类】正在加载中，跳过重复调用');
      return;
    }
    
    // 如果已选择相同分类，跳过
    if (!forceReload && activeCategory.value === category.id && currentMode.value === 'category') {
      logger.debug('【选择分类】已选择相同分类，跳过重复调用');
      return;
    }
    
    logger.debug('【选择分类】category:', category);
    currentMode.value = 'category';
    activeCategory.value = category.id;
    activeCategoryName.value = category.name;
    activeDeptCategoryMeta.value = category.type === 'dept' ? category : null;
    activeCourseCategoryMeta.value = ['ota', 'green_hotel'].includes(category.type) ? category : null;
    // 根据分类类型选择不同的加载方式
    if (category.type === 'dept_all') {
      logger.debug('【部门题库】准备加载全部部门题库');
      return loadQuestions('dept_all', category.name);
    } else if (category.type === 'dept') {
      logger.debug('【部门题库】准备加载, courseName:', category.courseName, 'deptType:', category.deptType);
      return loadQuestions('dept_category', category.name);
    } else if (category.type === 'culture') {
      return loadQuestions('culture_category', category.name);
    } else if (category.type === 'green_hotel') {
      return loadQuestions('green_hotel_category', category.name);
    } else {
      return loadQuestions('category', category.name);
    }
  };

  const changeQuestionBankScope = async (scope) => {
    const normalizedScope = normalizeQuestionBankScope(scope);
    if (questionBankScope.value === normalizedScope && userCategories.value.length > 0) {
      return;
    }

    questionBankScope.value = normalizedScope;
    persistQuestionBankScope(normalizedScope);
    userCategories.value = [];
    await loadUserCategories(normalizedScope);

    if (currentMode.value === 'daily') {
      await loadQuestions('daily');
      return;
    }

    if (currentMode.value === 'category') {
      const currentCategory = userCategories.value.find(category => category.id === activeCategory.value);
      if (currentCategory) {
        await selectCategory(currentCategory, true);
      } else {
        await switchToFirstCategory();
      }
    }
  };
  
  // 移动端：选择分类并关闭弹窗
  const selectCategoryAndClose = async (category) => {
    await selectCategory(category);
    showCategoryModal.value = false;
  };
  
  // 移动端：跳转题目并关闭弹窗
  const jumpToQuestionAndClose = (index) => {
    jumpToQuestion(index);
    showQuestionListModal.value = false;
  };
  
  // 关闭悬浮按钮新手引导提示（永久关闭）
  const dismissFloatBtnTip = () => {
    showFloatBtnTip.value = false;
    localStorage.setItem('floatBtnTipDismissed', 'true');
  };

  const getCategoryCacheKey = (scope = questionBankScope.value) => {
    return `onlineTestCategories:${CATEGORY_CACHE_VERSION}:${getQuestionBankUserKey()}:${normalizeQuestionBankScope(scope)}`;
  };

  const readCategoryCache = (scope = questionBankScope.value) => {
    try {
      const rawCache = localStorage.getItem(getCategoryCacheKey(scope));
      if (!rawCache) return null;
      const cachedPayload = JSON.parse(rawCache);
      if (!cachedPayload || !Array.isArray(cachedPayload.categories)) return null;
      if (Date.now() - Number(cachedPayload.savedAt || 0) > CATEGORY_CACHE_MAX_AGE) return null;
      return cachedPayload.categories;
    } catch (_) {
      return null;
    }
  };

  const writeCategoryCache = (scope, categories) => {
    try {
      localStorage.setItem(getCategoryCacheKey(scope), JSON.stringify({
        savedAt: Date.now(),
        categories
      }));
    } catch (_) {}
  };

  const hydrateCategoriesFromCache = (scope = questionBankScope.value) => {
    const cachedCategories = readCategoryCache(scope);
    if (!cachedCategories || cachedCategories.length === 0) return false;
    userCategories.value = cachedCategories;
    return true;
  };

  const GREEN_FOCUS_KEYWORDS = ['绿色', '低碳', '节能', '环保', '可持续', '饭店', '酒店', 'green', 'hotel'];

  const pickFocusedCategoryByKeyword = (rawKeyword = '') => {
    const categories = userCategories.value || [];
    if (categories.length === 0) return null;

    const normalizedKeyword = String(rawKeyword || '').toLowerCase().trim();
    const candidates = Array.from(
      new Set(
        [normalizedKeyword, ...GREEN_FOCUS_KEYWORDS.map((k) => String(k).toLowerCase())].filter(Boolean)
      )
    );

    let bestCategory = null;
    let bestScore = 0;

    categories.forEach((category) => {
      const name = String(category?.name || '').toLowerCase();
      if (!name) return;

      let score = 0;
      candidates.forEach((kw) => {
        if (kw && name.includes(kw)) {
          score += kw.length + 2;
        }
      });

      if ((category.type === 'ota' || category.type === 'culture') && score > 0) {
        score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    });

    return bestScore > 0 ? bestCategory : null;
  };

  const applyRouteIntentMode = async () => {
    const mode = String(route.query.mode || '').trim();
    const focus = String(route.query.focus || '').trim();
    const keyword = String(route.query.keyword || '').trim();

    const isGreenFocus =
      focus === 'green-hotel' ||
      keyword.includes('绿色') ||
      keyword.toLowerCase().includes('green');

    if ((isGreenFocus || (mode === 'category' && keyword)) && userCategories.value.length === 0) {
      await loadUserCategories(questionBankScope.value);
    }

    if (isGreenFocus) {
      currentMode.value = 'category';
      const matched = pickFocusedCategoryByKeyword(keyword || '绿色饭店');
      const fallback = greenHotelCategories.value[0] || otaCategories.value[0] || deptCategories.value[0] || cultureCategories.value[0] || null;

      if (matched) {
        await selectCategory(matched);
        ElMessage.success(`已进入${matched.name}专项练习`);
        return true;
      }

      if (fallback) {
        await selectCategory(fallback);
        ElMessage.info('暂未配置绿色饭店专属题库，已为你打开专项练习');
        return true;
      }

      await loadQuestions('daily');
      ElMessage.info('当前暂无专项题库，已切换到每日一练');
      return true;
    }

    if (mode === 'daily' || mode === 'wrong' || mode === 'fav') {
      currentMode.value = mode;
      await loadQuestions(mode);
      return true;
    }

    if (mode === 'category' && keyword) {
      const matched = pickFocusedCategoryByKeyword(keyword);
      if (matched) {
        currentMode.value = 'category';
        await selectCategory(matched);
        return true;
      }
    }

    return false;
  };
  
  // 辅助函数：补全题目详情
  const fillQuestionDetails = async (items) => {
    if (!items || items.length === 0) return [];
    
    const detailedItems = await Promise.all(items.map(async (item) => {
      // 检查是否需要补全：如果没有标题、选项是默认值、或者没有解析
      const needDetail = !item.title || 
                         item.title === '题目内容' || 
                         !item.options || 
                         (Array.isArray(item.options) && item.options[0] === '选项A') ||
                         !item.explanation ||
                         item.explanation === '暂无解析';
      
      // 确保有ID可用
      const qId = item.questionId || item.id;
      const source = item.questionSource || item.question_source || 'ota';
      
      logger.debug(`📋 检查题目 ${qId} 是否需要补全: needDetail=${needDetail}, title=${item.title}, options=${JSON.stringify(item.options)}, explanation=${item.explanation}`);
      
      if (needDetail && qId) {
        try {
          logger.debug(`🔍 尝试补全题目详情: ${qId}, tag: ${item.tag}`);
          
          let detailRes = await fetchQuestionDetailBySource(qId, source);
          let resData = detailRes.data;
          
          // 仅旧数据来源不明时，才尝试部门题库兜底
          if ((source === 'ota' || !source) && (!resData || resData.code !== 200 || !resData.data)) {
            logger.debug(`普通题库未找到，尝试部门题库API: ${qId}`);
            try {
              detailRes = await getDeptQuestionDetail(qId);
              resData = detailRes.data;
            } catch (deptErr) {
              logger.warn(`部门题库API也未找到: ${qId}`, deptErr);
            }
          }
          
          if (resData && resData.code === 200) {
             // 兼容多种返回结构: data.data 或 data 本身
             const detail = resData.data || resData;
             
             if (detail) {
                 // 处理题目类型
                 let typeVal = normalizeQuestionTypeLabel(detail.questionType || detail.type || item.type || '单选题');
                 const optionSource = { ...item, ...detail };
                 const options = buildQuestionOptions(optionSource, typeVal);
                 const rawAnswer = detail.correctAnswer !== undefined ? detail.correctAnswer : item.correctAnswer;
                 let correctAnswer = parseCorrectAnswer(rawAnswer, typeVal);
                 if (Array.isArray(correctAnswer) && !isTextQuestionType(typeVal) && typeVal !== '判断题') {
                     typeVal = '多选题';
                 }
                 
                 // 合并详情数据
                 return {
                   ...item,
                   title: detail.questionText || detail.title || detail.content || item.title,
                   options: options,
                   type: typeVal,
                   questionType: typeVal,
                   explanation: detail.explanation || detail.desc || detail.remark || item.explanation,
                   level: detail.difficulty || detail.level || item.level,
                   tag: detail.deptName || detail.category || detail.tag || item.tag,
                   correctAnswer: correctAnswer
                 };
             }
          }
        } catch (e) {
          logger.warn(`获取题目 ${qId} 详情失败`, e);
        }
      }
      return item;
    }));
    return detailedItems;
  };
  
  // 加载指定题目（从答题记录页面跳转过来时使用）
  const loadSpecificQuestion = async (questionId, questionSource = 'ota') => {
    loadingQuestions.value = true;
    questions.value = [];
    currentIndex.value = 0;
    selectedOption.value = null;
    showAnswer.value = false;
    isFavorite.value = false;
    activeCategoryName.value = '复习题目';
    
    try {
      const hasAccess = await checkQuestionAccess(questionId);
      if (!hasAccess) {
        await promptUpgrade();
        await loadQuestions('daily');
        return;
      }
  
      const normalizedSource = questionSource || 'ota';
      const res = await fetchQuestionDetailBySource(questionId, normalizedSource);
      logger.debug('加载指定题目响应:', res);
      
      if (res.data && res.data.code === 200) {
        const detail = res.data.data || res.data;
        
        // 处理选项数据
        const questionType = normalizeQuestionTypeLabel(detail.questionType || detail.type || '单选题');
        const options = buildQuestionOptions(detail, questionType);
        const correctAnswer = parseCorrectAnswer(detail.correctAnswer, questionType);
        
        // 构造题目对象
        const question = {
          id: detail.id || questionId,
          questionId: detail.id || questionId,
          title: detail.questionText || detail.title || detail.content,
          questionText: detail.questionText || detail.title || detail.content,
          content: detail.content || detail.questionText || detail.title,
          options: options,
          correctAnswer,
          explanation: detail.explanation || detail.remark || '暂无解析',
          type: questionType,
          questionType,
          questionSource: normalizedSource
        };
        questions.value = [question];
        await applyQuestionStateByIndex(0, 0);
        logger.debug('已加载指定题目:', question);
      } else {
        ElMessage.warning('题目加载失败，将显示每日一练');
        await loadQuestions('daily');
      }
    } catch (error) {
      logger.error('加载指定题目失败:', error);
      ElMessage.warning('题目加载失败，将显示每日一练');
      await loadQuestions('daily');
    } finally {
      loadingQuestions.value = false;
    }
  };
  
  // 从答题记录重新测试指定题目
  const retestQuestion = async (record) => {
    const questionId = record.questionId || record.id;
    const questionSource = record.questionSource || record.question_source || 'ota';
    if (!questionId) {
      ElMessage.warning('无法获取题目ID');
      return;
    }
    
    // 关闭答题记录弹窗
    showRecordModal.value = false;
    
    // 切换到复习模式并加载该题目
    currentMode.value = 'review';
    await loadSpecificQuestion(questionId, questionSource);
  };
  
  const loadQuestions = async (mode, categoryName = null) => {
    loadingQuestions.value = true;
    
    // 支持进度保存的模式列表
    const progressModes = ['daily', 'category', 'dept_category'];
    
    // 检查是否有保存的进度（从后端获取）
    if (progressModes.includes(mode) && isLoggedIn.value) {
      try {
        const res = await getPracticeProgress(mode, activeCategory.value);
        if (res.data.code === 200 && res.data.data) {
          const savedProgress = res.data.data;
          // 解析题目数据
          if (savedProgress.questionsData) {
            savedProgress.questions = JSON.parse(savedProgress.questionsData);
          }
          
          // 检查进度是否匹配当前模式
          const modeMatches = savedProgress.mode === mode;
          const scopeMatches = normalizeQuestionBankScope(savedProgress.questionBankScope) === questionBankScope.value;
          // 分类模式需要检查分类是否匹配
          const categoryMatches = mode === 'daily' || 
            (savedProgress.categoryId == activeCategory.value) ||
            (savedProgress.categoryName === categoryName);
          
          if (modeMatches && scopeMatches && categoryMatches && savedProgress.questions && savedProgress.questions.length > 0) {
            // 检查是否还有未完成的题目
            const unfinishedCount = savedProgress.questions.filter(q => !q.isSubmitted).length;
            if (unfinishedCount > 0) {
              // 恢复进度
              questions.value = savedProgress.questions;
              currentIndex.value = savedProgress.currentIndex || 0;
              activeCategoryName.value = savedProgress.categoryName || (mode === 'daily' ? '每日一练' : '专项练习');
  
              loadingQuestions.value = false;
              await applyQuestionStateByIndex(currentIndex.value, currentIndex.value);
              const modeText = mode === 'daily' ? '每日一练' : savedProgress.categoryName;
              logger.debug('📂 已从服务器恢复刷题进度，继续第', currentIndex.value + 1, '题，剩余', unfinishedCount, '题未完成');
              ElMessage.success(`继续${modeText}进度，第 ${currentIndex.value + 1} 题`);
              return;
            } else {
              // 所有题目都已完成，清除进度，加载新题
              await clearProgress();
            }
          }
        }
      } catch (e) {
        logger.error('获取进度失败:', e);
      }
    }
    
    questions.value = [];
    currentIndex.value = 0;
    selectedOption.value = null;
    showAnswer.value = false;
    isFavorite.value = false;
  
    try {
      let res;
      if (mode === 'daily') {
        activeCategoryName.value = '每日一练';
        const allowAllBanks = questionBankScope.value === 'all';

        try {
          const deptRes = await getDeptDailyQuestions({}, null, 10, questionBankScope.value);
          logger.debug('每日一练(部门)题目响应:', deptRes);

          if (deptRes.data && deptRes.data.code === 200 && deptRes.data.data && deptRes.data.data.length > 0) {
            res = {
              data: {
                code: 200,
                data: deptRes.data.data.map(q => {
                  const questionType = normalizeQuestionTypeLabel(q.questionType || q.type || '单选题');
                  const options = buildQuestionOptions(q, questionType);
                  const correctAnswer = parseCorrectAnswer(q.correctAnswer, questionType);
                  
                  return {
                    id: q.id || q.questionId,
                    questionId: q.id || q.questionId,
                    title: q.questionText || q.questionContent || q.title,
                    questionText: q.questionText || q.questionContent || q.title,
                    options: options,
                    correctAnswer: correctAnswer,
                    explanation: q.explanation || '暂无解析',
                    type: questionType,
                    questionType: questionType,
                    tag: q.deptType || '部门培训',
                    level: q.difficulty || '中等',
                    questionSource: 'dept',
                    question_source: 'dept'
                  };
                })
              }
            };
          }
        } catch (e) {
          logger.warn('获取部门题目失败:', e);
        }

        if (!res && allowAllBanks) {
          try {
            const randomRes = await generateCustomPaper({ category: null, limit: 10 });
            logger.debug('每日一练(OTA)随机题目响应:', randomRes);
            if (randomRes.data && randomRes.data.code === 200 && randomRes.data.data && randomRes.data.data.length > 0) {
              res = randomRes;
            } else {
              res = await getQuestions({ pageSize: 10, pageNum: 1 });
            }
          } catch (e) {
            logger.warn('随机获取OTA题目失败，使用普通方式:', e);
            res = await getQuestions({ pageSize: 10, pageNum: 1 });
          }
        }

        if (!res) {
          res = { data: { code: 200, data: [] } };
        }
      } else if (mode === 'dept_all') {
        activeCategoryName.value = activeCategoryName.value || '全部部门题库';
        logger.debug('【全部部门题库】开始加载');
        try {
          const deptRes = await getDeptQuestions({}, questionBankScope.value);
          const questionList = deptRes.data?.code === 200 && Array.isArray(deptRes.data?.data) ? deptRes.data.data : [];
          res = {
            data: {
              code: 200,
              data: questionList.map(q => {
                const questionType = normalizeQuestionTypeLabel(q.questionType || q.type || '单选题');
                const options = buildQuestionOptions(q, questionType);
                const correctAnswer = parseCorrectAnswer(q.correctAnswer, questionType);

                return {
                  id: q.id || q.questionId,
                  questionId: q.id || q.questionId,
                  title: q.questionText || q.questionContent || q.title,
                  questionText: q.questionText || q.questionContent || q.title,
                  options,
                  correctAnswer,
                  explanation: q.explanation || '暂无解析',
                  type: questionType,
                  questionType,
                  tag: q.category || q.deptType || '部门题库',
                  level: q.difficulty || '中等',
                  questionSource: 'dept',
                  question_source: 'dept'
                };
              })
            }
          };
        } catch (e) {
          logger.error('【全部部门题库】加载失败:', e);
          res = { data: { code: 200, data: [] } };
        }
      } else if (mode === 'dept_category') {
        // 部门专项题库
        activeCategoryName.value = activeCategoryName.value || '部门题库';
        logger.debug('【部门专项题库】开始加载, categoryKey:', categoryName);
        try {
          const selectedDeptCategory = activeDeptCategoryMeta.value && activeDeptCategoryMeta.value.id === activeCategory.value
            ? activeDeptCategoryMeta.value
            : deptCategories.value.find(category => category.id === activeCategory.value) || null;
          const deptRes = selectedDeptCategory
            ? await getDeptQuestionsByCourse({
                courseId: selectedDeptCategory.courseId || undefined,
                courseName: selectedDeptCategory.courseName || selectedDeptCategory.name,
                deptType: selectedDeptCategory.deptType
              }, questionBankScope.value)
            : await getDeptQuestions({ deptType: categoryName }, questionBankScope.value)
          logger.debug('【部门专项题库】API响应:', deptRes);
          logger.debug('【部门专项题库】响应数据结构:', {
            hasData: !!deptRes.data,
            code: deptRes.data?.code,
            hasDataField: !!deptRes.data?.data,
            dataType: Array.isArray(deptRes.data?.data) ? 'array' : typeof deptRes.data?.data,
            dataLength: Array.isArray(deptRes.data?.data) ? deptRes.data.data.length : 'N/A',
            fullResponse: JSON.stringify(deptRes.data, null, 2)
          });
          
          // 改进响应检查：支持多种响应结构
          let questionList = [];
          if (deptRes.data) {
            if (deptRes.data.code === 200) {
              // 尝试多种可能的数据结构
              questionList = deptRes.data.data || deptRes.data.rows || [];
              if (!Array.isArray(questionList)) {
                questionList = [];
              }
            } else {
              logger.warn('【部门专项题库】API返回非200状态码:', deptRes.data.code, deptRes.data.msg || deptRes.data.message);
            }
          }
          
          logger.debug('【部门专项题库】解析后的题目列表长度:', questionList.length);
          
          if (questionList.length > 0) {
            logger.debug('【部门专项题库】获取到', questionList.length, '道题目');
            res = {
              data: {
                code: 200,
              data: questionList.map(q => {
                  const questionType = normalizeQuestionTypeLabel(q.questionType || q.type || '单选题');
                  const options = buildQuestionOptions(q, questionType);
                  const correctAnswer = parseCorrectAnswer(q.correctAnswer, questionType);
                  
                  return {
                    id: q.id || q.questionId,
                    questionId: q.id || q.questionId,
                    title: q.questionText || q.questionContent || q.title,
                    questionText: q.questionText || q.questionContent || q.title,
                    options: options,
                    correctAnswer: correctAnswer,
                    explanation: q.explanation || '暂无解析',
                    type: questionType,
                    questionType: questionType,
                    tag: q.deptType || '部门培训',
                    level: q.difficulty || '中等',
                    questionSource: 'dept',
                    question_source: 'dept'
                  };
                })
              }
            };
          } else {
            logger.warn('【部门专项题库】未获取到题目，category:', selectedDeptCategory || categoryName);
            res = { data: { code: 200, data: [] } };
          }
        } catch (e) {
          logger.error('加载部门题库失败:', e);
          logger.error('错误详情:', e.message, e.stack);
          res = { data: { code: 200, data: [] } };
        }
      } else if (mode === 'culture_category') {
        // 企业文化题库
        activeCategoryName.value = categoryName || '企业文化题库';
        try {
          const cultureRes = await getCultureQuestions(categoryName);
          logger.debug('企业文化题库响应:', cultureRes);
          
          if (cultureRes.data && cultureRes.data.code === 200 && cultureRes.data.data) {
            res = {
              data: {
                code: 200,
                data: cultureRes.data.data.map(q => {
                  const questionType = normalizeQuestionTypeLabel(q.questionType || q.type || '单选题');
                  const options = buildQuestionOptions(q, questionType);
                  const correctAnswer = parseCorrectAnswer(q.correctAnswer, questionType);
                  
                  return {
                    id: q.id || q.questionId,
                    questionId: q.id || q.questionId,
                    title: q.questionText || q.questionContent || q.title,
                    questionText: q.questionText || q.questionContent || q.title,
                    options: options,
                    correctAnswer: correctAnswer,
                    explanation: q.explanation || '暂无解析',
                    type: questionType,
                    questionType: questionType,
                    tag: q.category || '企业文化',
                    level: q.difficulty || '中等',
                    questionSource: 'culture',
                    question_source: 'culture'
                  };
                })
              }
            };
          } else {
            res = { data: { code: 200, data: [] } };
          }
        } catch (e) {
          logger.error('加载企业文化题库失败:', e);
          res = { data: { code: 200, data: [] } };
        }
      } else if (mode === 'green_hotel_category') {
        activeCategoryName.value = categoryName || '绿色饭店题库';
        try {
          const selectedCourseCategory = activeCourseCategoryMeta.value && activeCourseCategoryMeta.value.id === activeCategory.value
            ? activeCourseCategoryMeta.value
            : greenHotelCategories.value.find(category => category.id === activeCategory.value) || null;
          const ghRes = await getGreenHotelQuestions(categoryName, selectedCourseCategory?.courseId);
          logger.debug('绿色饭店题库响应:', ghRes);
          
          if (ghRes.data && ghRes.data.code === 200 && ghRes.data.data) {
            res = {
              data: {
                code: 200,
                data: ghRes.data.data.map(q => {
                  const questionType = normalizeQuestionTypeLabel(q.questionType || q.type || '单选题');
                  const options = buildQuestionOptions(q, questionType);
                  const correctAnswer = parseCorrectAnswer(q.correctAnswer, questionType);
                  
                  return {
                    id: q.id || q.questionId,
                    questionId: q.id || q.questionId,
                    title: q.questionText || q.questionContent || q.title,
                    questionText: q.questionText || q.questionContent || q.title,
                    options: options,
                    correctAnswer: correctAnswer,
                    explanation: q.explanation || '暂无解析',
                    type: questionType,
                    questionType: questionType,
                    tag: q.category || '绿色饭店',
                    level: q.difficulty || '中等',
                    question_source: 'green_hotel'
                  };
                })
              }
            };
          } else {
            res = { data: { code: 200, data: [] } };
          }
        } catch (e) {
          logger.error('加载绿色饭店题库失败:', e);
          res = { data: { code: 200, data: [] } };
        }
      } else if (mode === 'wrong') {
        activeCategoryName.value = '我的错题本';
        // 从答题记录中筛选错题
        try {
          // 增大 pageSize 以获取全部错题
          const recordRes = await getAnswerRecords({ pageNum: 1, pageSize: 500 });
          logger.debug('错题本-答题记录响应:', recordRes);
          
          if (recordRes.data.code === 200) {
            const allRecords = recordRes.data.rows || [];
            // 筛选出错题（isCorrect 为 false 或 0）
            const wrongRecords = allRecords.filter(record => {
              const isCorrect = record.isCorrect;
              return isCorrect === false || isCorrect === 0 || isCorrect === '0' || isCorrect === 'false';
            });
            
            logger.debug('筛选出的错题数量:', wrongRecords.length);
            
            // 直接使用答题记录中的数据构造错题列表
            let wrongQuestions = wrongRecords.map(record => {
              logger.debug('错题记录:', record);
              
              // 尝试解析 question 字段
              let questionObj = record.question;
              if (typeof questionObj === 'string') {
                 try { questionObj = JSON.parse(questionObj); } catch(e) {}
              }
  
              // 优先使用解析出的 questionObj 中的数据
              const title = (questionObj && (questionObj.questionText || questionObj.title)) || record.questionText || '题目内容';
              const explanation = (questionObj && questionObj.explanation) || record.explanation || '暂无解析';
              
              // 处理题目类型
              let typeVal = normalizeQuestionTypeLabel(record.questionType || (questionObj && questionObj.questionType) || '1');
              
              // 获取正确答案
              const rawCorrectAnswer = (questionObj && questionObj.correctAnswer) || record.correctAnswer;
              const parsedAnswer = parseCorrectAnswer(rawCorrectAnswer, typeVal);
              
              // 强力修正：如果正确答案解析出来是数组，且不是文本题，强制设为多选题
              if (Array.isArray(parsedAnswer) && !isTextQuestionType(typeVal) && typeVal !== '判断题') {
                logger.debug('🚀 错题集检测到多个答案，强制设为多选题');
                typeVal = '多选题';
              }
              
              const options = buildQuestionOptions({ ...record, ...(questionObj || {}) }, typeVal);
  
              const questionData = {
                id: record.questionId || record.id,
                questionId: record.questionId || record.id,
                title: title,
                questionText: title,
                content: title,
                options: options,
                correctAnswer: parsedAnswer,
                explanation: explanation,
                type: typeVal,
                questionType: typeVal,
                questionSource: record.questionSource || 'ota' // 保存题目来源
              };
              
              logger.debug('构造的错题:', questionData);
              return questionData;
            });
            
            // 补全题目详情
            if (wrongQuestions.length > 0) {
                wrongQuestions = await fillQuestionDetails(wrongQuestions);
            }
  
            res = { data: { code: 200, rows: wrongQuestions, data: wrongQuestions } };
            
            if (wrongQuestions.length === 0) {
              ElMessage.info('恭喜！暂无错题');
            } else {
              ElMessage.success(`已加载 ${wrongQuestions.length} 道错题`);
            }
          } else {
            res = { data: { code: 200, rows: [] } };
            ElMessage.info('暂无答题记录');
          }
        } catch (e) {
          logger.error('加载错题本失败:', e);
          ElMessage.error('加载错题本失败');
          res = { data: { code: 200, rows: [] } };
        }
      } else if (mode === 'fav') {
        activeCategoryName.value = '收藏夹';
        // 从 localStorage 读取收藏的题目
        const favQuestionsMap = JSON.parse(localStorage.getItem('favoriteQuestionsMap') || '{}');
        let favQuestions = Object.values(favQuestionsMap);
        
        logger.debug('收藏夹题目列表:', favQuestions);
        
        if (favQuestions.length === 0) {
          ElMessage.info('暂无收藏题目');
          res = { data: { code: 200, rows: [] } };
        } else {
          // 补全收藏题目详情
          const originalLength = favQuestions.length;
          favQuestions = await fillQuestionDetails(favQuestions);
          
          // 如果有更新，写回 localStorage
          let hasUpdates = false;
          favQuestions.forEach(q => {
             const oldQ = favQuestionsMap[q.id || q.questionId];
             if (oldQ && (oldQ.title !== q.title || JSON.stringify(oldQ.options) !== JSON.stringify(q.options))) {
                 favQuestionsMap[q.id || q.questionId] = q;
                 hasUpdates = true;
             }
          });
          if (hasUpdates) {
              localStorage.setItem('favoriteQuestionsMap', JSON.stringify(favQuestionsMap));
          }
  
          res = { data: { code: 200, rows: favQuestions, data: favQuestions } };
          ElMessage.success(`已加载 ${favQuestions.length} 道收藏题目`);
        }
      } else if (mode === 'category' && categoryName) {
        const selectedCourseCategory = activeCourseCategoryMeta.value && activeCourseCategoryMeta.value.id === activeCategory.value
          ? activeCourseCategoryMeta.value
          : otaCategories.value.find(category => category.id === activeCategory.value) || null;
        res = await getQuestions({
          courseId: selectedCourseCategory?.courseId,
          category: selectedCourseCategory?.category || categoryName,
          pageSize: 20
        });
      }
  
      // 记录调试日志
      logger.debug('LoadQuestions response:', res);
  
      // 适配数据结构
      const rawList = res?.data?.data || res?.data?.rows || [];
  
      if (Array.isArray(rawList)) {
        if (rawList.length > 0) {
          questions.value = rawList.map(q => {
            if (!q) return null;
  
            // 兼容已转换的数据(question.js)和原始数据
            // 确保 type 字段有值
            let typeVal = normalizeQuestionTypeLabel(q.type || q.questionType || '1');
            logger.debug('🔍 初始类型值:', typeVal, '来源:', { type: q.type, questionType: q.questionType });

            logger.debug('👉 原始题目数据:', q);
            const parsedAnswer = parseCorrectAnswer(q.correctAnswer, typeVal);
            
            if (Array.isArray(parsedAnswer) && !isTextQuestionType(typeVal) && typeVal !== '判断题') {
                logger.debug('🚀 检测到多个答案(Array)，强制设为多选题');
                typeVal = '多选题';
            }
            
            logger.debug('🔧 最终处理结果:', { id: q.id, rawAnswer: q.correctAnswer, parsedAnswer, finalType: typeVal });
  
            const options = buildQuestionOptions(q, typeVal);
  
            const questionObj = {
              id: q.id || q.questionId || Math.random(),
              title: q.title || q.questionText || q.content || '题目内容',
              type: typeVal,
              options: options,
              correctAnswer: parsedAnswer,
              explanation: q.desc || q.explanation || q.remark || '暂无解析',
              level: q.level || q.difficulty || '中等',
              tag: q.tag || q.category || '通用',
              questionSource: q.question_source || q.questionSource || undefined,
              myAnswer: null,
              isSubmitted: false
            };
            
            logger.debug('✅ 返回的题目对象:', questionObj);
            return questionObj;
          }).filter(q => q !== null);
          await applyQuestionStateByIndex(currentIndex.value, currentIndex.value);
        } else {
          questions.value = [];
          logger.debug('该列表下暂无题目');
        }
        loadingQuestions.value = false;
      }
    } catch(e) {
       logger.error('加载题目出错', e);
       questions.value = [];
       loadingQuestions.value = false;
    }
  };
  
  const selectOption = (index) => {
    if (showAnswer.value || isTextQuestionType(currentQuestion.value?.type)) return;
    
    const type = currentQuestion.value?.type;
    const correctAnswer = currentQuestion.value?.correctAnswer;
    logger.debug('当前题目类型:', type, '正确答案:', correctAnswer, '题目对象:', currentQuestion.value);
  
    const isMultipleChoice = type === '多选题' || type === '2' || type === 'multiple' || Array.isArray(correctAnswer);
    
    if (isMultipleChoice) {
        logger.debug('进入多选逻辑 (type或answer检测)');
        let currentSelection = Array.isArray(selectedOption.value) ? [...selectedOption.value] : [];
        if (selectedOption.value !== null && !Array.isArray(selectedOption.value)) {
             currentSelection = [selectedOption.value];
        }
        
        const existingIndex = currentSelection.indexOf(index);
        if (existingIndex >= 0) {
            currentSelection.splice(existingIndex, 1);
        } else {
            currentSelection.push(index);
            currentSelection.sort((a, b) => a - b);
        }
        selectedOption.value = currentSelection.length > 0 ? currentSelection : null;
        logger.debug('当前多选结果:', selectedOption.value);
    } else {
        logger.debug('进入单选逻辑');
        selectedOption.value = index;
    }
  
    if (questions.value[currentIndex.value]) {
        questions.value[currentIndex.value].myAnswer = selectedOption.value;
    }
  };

  const handleTextAnswer = (answer) => {
    if (showAnswer.value || !currentQuestion.value) return;
    const nextAnswer = answer === undefined || answer === null ? '' : String(answer);
    selectedOption.value = nextAnswer;
    if (questions.value[currentIndex.value]) {
      questions.value[currentIndex.value].myAnswer = nextAnswer;
    }
  };
  
  const submitAnswer = async () => {
    if (!currentQuestion.value) return;
    const questionSnapshot = currentQuestion.value;
    const questionType = normalizeQuestionTypeLabel(questionSnapshot.type);

    const hasAnswer = Array.isArray(selectedOption.value)
      ? selectedOption.value.length > 0
      : String(selectedOption.value === undefined || selectedOption.value === null ? '' : selectedOption.value).trim().length > 0;
    if (!hasAnswer) return;

    try {
      let answerChar = '';
      let isCorrect = false;
      
      if (isTextQuestionType(questionType)) {
          answerChar = String(selectedOption.value === undefined || selectedOption.value === null ? '' : selectedOption.value).trim();
          isCorrect = questionType === '填空题'
            ? compareFillAnswers(answerChar, questionSnapshot.correctAnswer)
            : compareTextAnswers(answerChar, questionSnapshot.correctAnswer);
      } else if (Array.isArray(selectedOption.value)) {
          answerChar = selectedOption.value.map(i => String.fromCharCode(65 + i)).join(',');
          isCorrect = isCorrectOption(selectedOption.value);
      } else {
          answerChar = String.fromCharCode(65 + selectedOption.value); 
          isCorrect = isCorrectOption(selectedOption.value);
      }
      
      logger.debug('📤 提交答案 Payload:', {
          id: questionSnapshot.id,
          answer: answerChar,
          isCorrect,
          currentMode: currentMode.value
      });
  
      // 优先从题目对象取来源，再根据当前加载模式判断
      let questionSource = questionSnapshot.questionSource || questionSnapshot.question_source || 'ota';
      if (questionSource === 'ota' || !questionSource) {
          // 题目对象上无来源标记时，使用加载模式和分类标签推断
          const tag = questionSnapshot.tag || '';
          if (tag.includes('部门') || tag.includes('客房') || tag.includes('前厅') || tag.includes('餐饮部') || tag.includes('工程部')) {
              questionSource = 'dept';
          } else if (tag.includes('企业文化') || tag.includes('企业愿景') || tag.includes('核心价值')) {
              questionSource = 'culture';
          } else if (tag.includes('绿色饭店') || tag.includes('节能') || tag.includes('绿色采购') || tag.includes('低碳')) {
              questionSource = 'green_hotel';
          }
      }
  
      const submitResult = await apiSubmitAnswer(questionSnapshot.id, answerChar, isCorrect, questionSource);
      logger.debug('✅ 提交答案响应:', submitResult);
      
      showAnswer.value = true;
      // 保存提交状态和正确性
      if (questions.value[currentIndex.value]) {
          questions.value[currentIndex.value].isSubmitted = true;
          questions.value[currentIndex.value].isCorrect = isCorrect;
      }
      
      // 保存刷题进度（所有练习模式）
      if (['daily', 'category', 'dept_category'].includes(currentMode.value)) {
          saveProgress();
      }

      const nextTotalQuestions = totalQuestions.value + 1;
      const nextCorrectAnswers = correctAnswersCount.value + (isCorrect ? 1 : 0);
      totalQuestions.value = nextTotalQuestions;
      correctAnswersCount.value = nextCorrectAnswers;
      accuracyRate.value = nextTotalQuestions > 0
        ? Math.round((nextCorrectAnswers / nextTotalQuestions) * 100)
        : 0;
  
      // 更新今日答题数（不管对错都计入）
      const previousCount = todayPracticeCount.value;
      todayPracticeCount.value++;
      
      // 保存今日答题数到 localStorage
      const today = new Date().toDateString();
      const todayKey = `todayPractice_${today}`;
      localStorage.setItem(todayKey, todayPracticeCount.value.toString());
      
      // 检查是否达成今日目标
      const celebrationKey = `celebration_online_${today}`;
      const hasShownCelebration = localStorage.getItem(celebrationKey) === 'true';
      
      // 刚好达到目标或首次达成时触发庆祝
      const justReachedTarget = previousCount < dailyPracticeTarget.value && todayPracticeCount.value >= dailyPracticeTarget.value;
      const firstTimeReached = todayPracticeCount.value >= dailyPracticeTarget.value && !hasShownCelebration;
      
      if (justReachedTarget || firstTimeReached) {
        logger.debug('🎉 触发庆祝动画！previousCount:', previousCount, 'currentCount:', todayPracticeCount.value, 'target:', dailyPracticeTarget.value);
        setTimeout(() => {
          showCelebration.value = true;
          localStorage.setItem(celebrationKey, 'true');
        }, 500);
      }
      
      resetSessionTimer();
      
      await Promise.all([
        loadAnswerRecords(),
        loadStatistics(),
        tryAwardDailyCheckInPoints()
      ]);
      
    } catch (e) {
      logger.error('提交答案失败', e);
      const responseData = e?.response?.data || {};
      const responseBody = responseData?.data || {};
      const errorMsg = responseBody?.error || responseData?.msg || e?.message || '提交答案失败，请稍后重试';
      const needUpgrade = Boolean(responseBody?.needUpgrade);

      showAnswer.value = false;
      if (questions.value[currentIndex.value]) {
        questions.value[currentIndex.value].isSubmitted = false;
        questions.value[currentIndex.value].isCorrect = undefined;
      }

      if (needUpgrade) {
        ElMessageBox.confirm(
          errorMsg,
          '升级提示',
          {
            confirmButtonText: '去升级',
            cancelButtonText: '知道了',
            type: 'warning'
          }
        ).then(() => {
          router.push('/member-center');
        }).catch(() => {});
        return;
      }

      ElMessage.error(errorMsg);
    }
  };
  
  const nextQuestion = () => {
    if (!questions.value || questions.value.length === 0) return;
    
    // 免费用户限制：每日最多练习 FREE_DAILY_LIMIT 题
    const isFreeUser = membership.value && membership.value.levelCode === 'free';
    if (isFreeUser && currentIndex.value >= FREE_DAILY_LIMIT.value - 1) {
      ElMessageBox.confirm(
        `免费版每日仅可练习 ${FREE_DAILY_LIMIT.value} 道题目，升级会员解锁无限刷题！`, 
        '升级提示', 
        {
          confirmButtonText: '去升级',
          cancelButtonText: '下次再说',
          type: 'warning'
        }
      ).then(() => {
        router.push('/member-center');
      }).catch(() => {});
      return;
    }
    
    if (currentIndex.value < questions.value.length - 1) {
       // 这里的状态重置逻辑已经移到 watch(currentIndex) 中处理
       currentIndex.value++;
       
       // 保存进度（所有练习模式）
       if (['daily', 'category', 'dept_category'].includes(currentMode.value)) {
           saveProgress();
       }
    } else {
       logger.debug('本组练习已完成！');
       ElMessage.success('本组练习已完成！');
       
       // 完成所有题目，清除进度
       if (['daily', 'category', 'dept_category'].includes(currentMode.value)) {
           clearProgress();
       }
    }
  };
  
  const prevQuestion = () => {
    if (currentIndex.value > 0) {
       // 这里的状态重置逻辑已经移到 watch(currentIndex) 中处理
       currentIndex.value--;
    }
  };
  
  // 跳转到指定题目
  const jumpToQuestion = (index) => {
    if (index >= 0 && index < questions.value.length) {
      currentIndex.value = index;
    }
  };
  
  // 获取题目状态样式
  const getQuestionStatusClass = (q, index) => {
    if (currentIndex.value === index) {
      return 'bg-blue-500 text-white';
    }
    if (q.isSubmitted) {
      return q.isCorrect ? 'bg-emerald-100 text-emerald-600' : 'bg-rose-100 text-rose-600';
    }
    return 'bg-slate-100 text-slate-500 group-hover:bg-slate-200';
  };
  
  const toggleFav = async () => {
     if (!currentQuestion.value) return;
     const qId = currentQuestion.value.id || currentQuestion.value.questionId;
     
     try {
        // 读取 localStorage 中的收藏列表
        const favIds = JSON.parse(localStorage.getItem('favoriteQuestionIds') || '[]');
        const favQuestionsMap = JSON.parse(localStorage.getItem('favoriteQuestionsMap') || '{}');
        
        if (isFavorite.value) {
           // 取消收藏
           try {
              await unfavoriteQuestion(qId);
           } catch (e) {
              logger.warn('后端取消收藏失败，仅更新本地:', e);
           }
           
           // 从 localStorage 中移除
           const newFavIds = favIds.filter(id => id !== qId);
           delete favQuestionsMap[qId];
           localStorage.setItem('favoriteQuestionIds', JSON.stringify(newFavIds));
           localStorage.setItem('favoriteQuestionsMap', JSON.stringify(favQuestionsMap));
           
           isFavorite.value = false;
           logger.debug('已取消收藏');
           ElMessage.success('已取消收藏');
        } else {
           // 添加收藏
           try {
              await favoriteQuestion(qId);
           } catch (e) {
              logger.warn('后端收藏失败，仅更新本地:', e);
           }
           
           // 添加到 localStorage
           if (!favIds.includes(qId)) {
              favIds.push(qId);
           }
           // 保存完整的题目信息
           // 根据当前模式确定题目来源
           let favQuestionSource = currentQuestion.value.questionSource || currentQuestion.value.question_source || 'ota';
  
           favQuestionsMap[qId] = {
              id: qId,
              questionId: qId,
              title: currentQuestion.value.title || currentQuestion.value.questionText || currentQuestion.value.content,
              questionText: currentQuestion.value.questionText || currentQuestion.value.title || currentQuestion.value.content,
              content: currentQuestion.value.content || currentQuestion.value.questionText || currentQuestion.value.title,
              options: currentQuestion.value.options,
              correctAnswer: currentQuestion.value.correctAnswer,
              explanation: currentQuestion.value.explanation,
              type: currentQuestion.value.type || currentQuestion.value.questionType,
              questionType: currentQuestion.value.questionType || currentQuestion.value.type,
              questionSource: favQuestionSource
           };
           localStorage.setItem('favoriteQuestionIds', JSON.stringify(favIds));
           localStorage.setItem('favoriteQuestionsMap', JSON.stringify(favQuestionsMap));
           
           isFavorite.value = true;
           logger.debug('已加入收藏夹');
           ElMessage.success('已加入收藏夹');
        }
     } catch (e) {
        logger.error('收藏操作失败:', e);
        ElMessage.error('收藏操作失败');
     }
  };
  
  const updateTarget = () => {
     localStorage.setItem('dailyPracticeTarget', dailyPracticeTarget.value);
     showTargetModal.value = false;
     logger.debug('今日目标已更新');
     ElMessage.success('今日目标已更新');
  };
  
  onBeforeUnmount(() => {
    stopActivityTimer();
    if (typeof document !== 'undefined') {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    }
  });
  
  // --- 样式辅助 ---
  const getHeaderBadgeClass = () => {
     const map = {
        'daily': 'bg-blue-500',
        'category': 'bg-indigo-500',
        'wrong': 'bg-rose-500',
        'fav': 'bg-amber-500'
     };
     return map[currentMode.value] || 'bg-slate-500';
  };
  
  const getModeName = () => {
     const map = {
        'daily': '每日推荐',
        'category': '专项练习',
        'wrong': '错题复习',
        'fav': '收藏练习'
     };
     return map[currentMode.value] || '练习';
  };
  
  const getModeDescription = () => {
     const map = {
        'daily': '根据您的学习进度智能生成的每日任务',
        'category': '针对特定知识点的集中突破训练',
        'wrong': '温故而知新，攻克薄弱环节',
        'fav': '您标记为重要的题目集合'
     };
     return map[currentMode.value] || '';
  };
  
  // 辅助函数：检查选项是否被用户选中
  const isSelectedOption = (index) => {
    if (selectedOption.value === null) return false;
    if (Array.isArray(selectedOption.value)) {
        return selectedOption.value.includes(index);
    }
    return selectedOption.value === index;
  };
  
  // 别名，方便模板使用
  const isCorrectOptionPart = (index) => checkIsPartOfCorrectAnswer(index);
  
  const getOptionClass = (index) => {
    const base = 'border-slate-100 bg-white hover:border-blue-200 hover:bg-blue-50/30';
    
    const isSelected = isSelectedOption(index);
    
    if (!showAnswer.value) {
      return isSelected
        ? 'border-blue-500 bg-blue-50 ring-1 ring-blue-500' 
        : base;
    }
    
    const isPartOfCorrectAnswer = checkIsPartOfCorrectAnswer(index);
  
    // 1. 选对了：绿色实心
    if (isSelected && isPartOfCorrectAnswer) return 'border-emerald-500 bg-emerald-50 ring-1 ring-emerald-500';
    // 2. 漏选（正确但未选）：绿色虚线，无背景
    if (isPartOfCorrectAnswer) return 'border-emerald-400 border-dashed bg-white ring-1 ring-emerald-200 ring-opacity-50';
    // 3. 选错了：红色实心
    if (isSelected && !isPartOfCorrectAnswer) return 'border-rose-500 bg-rose-50 ring-1 ring-rose-500';
    
    // 4. 其他（没选且错误）：置灰
    return 'border-slate-100 opacity-40 grayscale';
  };
  
  const getOptionMarkerClass = (index) => {
     const isSelected = isSelectedOption(index);
  
     if (!showAnswer.value) {
        return isSelected
           ? 'bg-blue-600 text-white shadow-blue-200 rotate-animation' 
           : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:text-blue-600 group-hover:shadow-sm';
     }
     
     const isPartOfCorrectAnswer = checkIsPartOfCorrectAnswer(index);
     
     if (isSelected && isPartOfCorrectAnswer) return 'bg-emerald-500 text-white shadow-emerald-200 rotate-animation';
     if (isPartOfCorrectAnswer) return 'bg-white text-emerald-600 border-2 border-emerald-500 font-bold'; // 空心绿圈
     if (isSelected && !isPartOfCorrectAnswer) return 'bg-rose-500 text-white shadow-rose-200 rotate-animation';
     
     return 'bg-slate-100 text-slate-400';
  };
  
  // --- API & Helpers ---
  // 判断单个选项是否属于正确答案
  const checkIsPartOfCorrectAnswer = (index) => {
      if (!currentQuestion.value) return false;
      const ans = currentQuestion.value.correctAnswer;
      if (Array.isArray(ans)) return ans.includes(index);
      return ans === index;
  };
  
  const isCorrectOption = (userSelection) => {
    if (!currentQuestion.value) return false;
    const correct = currentQuestion.value.correctAnswer;
    
    if (Array.isArray(correct)) {
        // 多选题：必须完全匹配（数组内容一致，忽略顺序？通常题目选项顺序固定，简单比较即可）
        if (!Array.isArray(userSelection)) return false;
        if (userSelection.length !== correct.length) return false;
        // 简单的数组比较（假设都已排序）
        const sortedUser = [...userSelection].sort((a,b)=>a-b);
        const sortedCorrect = [...correct].sort((a,b)=>a-b);
        return sortedUser.every((val, idx) => val === sortedCorrect[idx]);
    }
    return correct === userSelection;
  };
  
  const formatAnswer = (ans, questionType = '') => {
    const normalizedType = normalizeQuestionTypeLabel(questionType);
    if (isTextQuestionType(normalizedType)) {
      return formatTextAnswerDisplay(ans);
    }

    if (normalizedType === '判断题') {
      const value = ans === undefined || ans === null ? '' : String(ans).trim().toLowerCase();
      if (ans === true || value === 'true' || value === '正确' || value === '对' || value === 'a' || value === '0') return '正确';
      if (ans === false || value === 'false' || value === '错误' || value === '错' || value === 'b' || value === '1') return '错误';
    }

    if (ans === undefined || ans === null) return '';
    
    // 如果是数组（已经是索引格式 [0, 1, 3]）
    if (Array.isArray(ans)) {
      return ans.map(i => {
        if (typeof i === 'number') return String.fromCharCode(65 + i);
        if (typeof i === 'string' && /^[A-Za-z]$/.test(i)) return i.toUpperCase();
        return i;
      }).join('、');
    }
    
    // 如果是数字（单选索引）
    if (typeof ans === 'number') {
      return String.fromCharCode(65 + ans);
    }
    
    // 如果是字符串
    if (typeof ans === 'string') {
      // 先统一分隔符：中文逗号、顿号都转为英文逗号
      let normalized = ans.replace(/[，、]/g, ',').replace(/\s/g, '');
      // 移除多余逗号
      normalized = normalized.replace(/,+/g, ',').replace(/^,|,$/g, '');
      
      // 检查是否是逗号分隔的字母（如 "A,B,D"）
      if (/^[A-Za-z](,[A-Za-z])*$/.test(normalized)) {
        return normalized.split(',').map(c => c.toUpperCase()).join('、');
      }
      
      // 检查是否是连续字母（如 "ABD"）
      if (/^[A-Za-z]+$/.test(normalized) && normalized.length > 1) {
        return normalized.toUpperCase().split('').join('、');
      }
      
      // 单个字母
      if (/^[A-Za-z]$/.test(normalized)) {
        return normalized.toUpperCase();
      }
      
      // 数字字符串
      if (/^\d+$/.test(normalized)) {
        return String.fromCharCode(65 + parseInt(normalized));
      }
      
      // 其他情况直接返回
      return ans;
    }
    
    return String(ans);
  };
  
  const formatDate = (d) => new Date(d).toLocaleString();
  const getQuestionTypeName = (t) => {
    const normalized = normalizeQuestionTypeLabel(t);
    return ({
      single: '单选题',
      multiple: '多选题',
      judgment: '判断题',
      judge: '判断题',
      text: '简答题',
      fill: '填空题',
      '单选题': '单选题',
      '多选题': '多选题',
      '判断题': '判断题',
      '简答题': '简答题',
      '填空题': '填空题'
    }[normalized] || normalized);
  };

  const toDayKey = (dateInput) => {
    if (dateInput === null || dateInput === undefined || dateInput === '') return null;

    if (typeof dateInput === 'string') {
      const raw = dateInput.trim();
      if (!raw) return null;

      const dateOnlyMatch = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
      if (dateOnlyMatch) {
        const year = Number(dateOnlyMatch[1]);
        const month = Number(dateOnlyMatch[2]);
        const day = Number(dateOnlyMatch[3]);
        const localDate = new Date(year, month - 1, day);
        if (Number.isNaN(localDate.getTime())) return null;
        const y = localDate.getFullYear();
        const m = String(localDate.getMonth() + 1).padStart(2, '0');
        const d = String(localDate.getDate()).padStart(2, '0');
        return `${y}-${m}-${d}`;
      }

      const parsed = new Date(raw);
      if (Number.isNaN(parsed.getTime())) return null;
      const year = parsed.getFullYear();
      const month = String(parsed.getMonth() + 1).padStart(2, '0');
      const day = String(parsed.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    }

    const d = new Date(dateInput);
    if (Number.isNaN(d.getTime())) return null;
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  const getRecordDayKey = (record = {}) => {
    const candidateFields = ['submitTime', 'createTime', 'answerTime', 'updateTime'];
    for (const field of candidateFields) {
      const dayKey = toDayKey(record?.[field]);
      if (dayKey) {
        return dayKey;
      }
    }
    return null;
  };

  const rebuildCheckInDays = (records = []) => {
    if (!Array.isArray(records)) {
      checkInDays.value = [];
      return;
    }
    const daySet = new Set();
    records.forEach((record) => {
      const dayKey = getRecordDayKey(record);
      if (dayKey) {
        daySet.add(dayKey);
      }
    });
    checkInDays.value = Array.from(daySet).sort();
  };

  const fetchMyPoints = async () => {
    try {
      const res = await getMyPoints();
      if (res?.data?.code === 200) {
        const rawPoints = res?.data?.data;
        if (typeof rawPoints === 'number' || typeof rawPoints === 'string') {
          const parsed = Number(rawPoints);
          myPoints.value = Number.isFinite(parsed) ? parsed : 0;
        } else if (rawPoints && typeof rawPoints === 'object') {
          const parsed = Number(rawPoints.points ?? rawPoints.balance ?? 0);
          myPoints.value = Number.isFinite(parsed) ? parsed : 0;
        } else {
          myPoints.value = 0;
        }
      } else {
        myPoints.value = 0;
        logger.warn('获取积分余额返回非成功状态:', res?.data);
      }
    } catch (e) {
      logger.warn('获取积分余额失败:', e);
    }
  };

  const tryAwardDailyCheckInPoints = async () => {
    if (dailyRewardRequesting.value) return;

    const uid = getUserId() || userInfo.value?.userId || userInfo.value?.id;
    if (!uid) return;

    const todayKey = toDayKey(new Date());
    if (!todayKey) return;

    const rewardKey = `dailyCheckInReward_${todayKey}_${uid}`;
    const getRewardMark = () => {
      try {
        return localStorage.getItem(rewardKey);
      } catch (_) {
        return null;
      }
    };
    const markRewardDone = () => {
      try {
        localStorage.setItem(rewardKey, 'done');
      } catch (_) {}
    };
    const isDuplicateAwardResponse = (code, msg) => {
      const normalizedMsg = String(msg || '').toLowerCase();
      const duplicateHints = ['已领取', '已发放', '重复', 'already', 'duplicate'];
      return Number(code) === 409 || Number(code) === 40901 || duplicateHints.some((hint) => normalizedMsg.includes(hint.toLowerCase()));
    };

    if (getRewardMark() === 'done') return;

    dailyRewardRequesting.value = true;

    try {
      const res = await addDailyCheckInPoints({
        userId: uid,
        pointsChange: 10,
        reason: '每日打卡奖励'
      });

      const code = res?.data?.code;
      const msg = res?.data?.msg || '';
      const isDuplicate = isDuplicateAwardResponse(code, msg);

      if (Number(code) === 200) {
        markRewardDone();
        try {
          await fetchMyPoints();
        } catch (_) {}
        if (!isDuplicate) {
          ElMessage.success('打卡成功，+10积分');
        }
      } else if (isDuplicate) {
        markRewardDone();
      } else {
        logger.warn('发放每日打卡积分失败(非成功状态):', res?.data);
        ElMessage.warning('打卡奖励暂不可用，不影响答题');
      }
    } catch (e) {
      const code = e?.response?.data?.code;
      const msg = e?.response?.data?.msg || e?.message || '';
      if (isDuplicateAwardResponse(code, msg)) {
        markRewardDone();
      } else {
        logger.warn('发放每日打卡积分失败:', e);
        ElMessage.warning('打卡奖励暂不可用，不影响答题');
      }
    } finally {
      dailyRewardRequesting.value = false;
    }
  };

  const calculateConsecutivePracticeDays = (records = []) => {
    if (!Array.isArray(records) || records.length === 0) return 0;

    const daySet = new Set();
    records.forEach((record) => {
      const dayKey = getRecordDayKey(record);
      if (dayKey) {
        daySet.add(dayKey);
      }
    });

    if (daySet.size === 0) return 0;

    const today = new Date();
    let cursor = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    if (!daySet.has(toDayKey(cursor))) {
      cursor.setDate(cursor.getDate() - 1);
      if (!daySet.has(toDayKey(cursor))) {
        return 0;
      }
    }

    let consecutiveDays = 0;
    while (true) {
      const key = toDayKey(cursor);
      if (!key || !daySet.has(key)) break;
      consecutiveDays++;
      cursor.setDate(cursor.getDate() - 1);
    }

    return consecutiveDays;
  };

  const resolvePracticeDaysFromStats = (data = {}) => {
    const candidates = [
      data.consecutiveDays,
      data.practiceDays,
      data.streakDays,
      data.continuousDays,
      data.checkInDays,
      data.signInDays,
      data.punchDays
    ];

    for (const value of candidates) {
      if (value === null || value === undefined) continue;

      if (typeof value === 'string') {
        const trimmed = value.trim();
        if (!trimmed) continue;
        if (!/^-?\d+(\.\d+)?$/.test(trimmed)) continue;
        const num = Number(trimmed);
        if (Number.isFinite(num) && num >= 0) {
          return Math.floor(num);
        }
        continue;
      }

      if (typeof value === 'number' && Number.isFinite(value) && value >= 0) {
        return Math.floor(value);
      }
    }

    return null;
  };

  const refreshLoginProfile = async () => {
    try {
       const res = await getUserInfo();
       if (res.data.code === 200) {
         const remoteUserInfo = res.data.user || res.data.data;
         userInfo.value = {
           ...remoteUserInfo,
           roleGroup: res.data.roleGroup || remoteUserInfo?.roleGroup || '',
           postGroup: res.data.postGroup || remoteUserInfo?.postGroup || '',
           deptName: res.data.deptName || remoteUserInfo?.deptName || '',
           companyName: res.data.companyName || remoteUserInfo?.companyName || '',
           profileCompletion: res.data.profileCompletion || remoteUserInfo?.profileCompletion || userInfo.value?.profileCompletion || null
         };
         setStoredUserInfo(userInfo.value);
       }
    } catch(e) {}
  };

  const checkLoginStatus = async () => {
    const token = localStorage.getItem('authToken');
    if (token) {
      isLoggedIn.value = true;
      const cachedUserInfo = getStoredUserInfo();
      if (cachedUserInfo) {
        userInfo.value = cachedUserInfo;
        refreshLoginProfile();
        return;
      }
      await refreshLoginProfile();
    }
  };
  
  const loadStatistics = async () => {
    try {
      const res = await getAnswerStatistics();
      logger.debug('📊 统计接口响应:', res);
      if (res.data.code === 200) {
        const data = res.data.data;
        logger.debug('📊 统计数据:', data);
        totalQuestions.value = Number(data.totalQuestions || 0);
        correctAnswersCount.value = Number(data.correctAnswers || 0);
        accuracyRate.value = Math.round(Number(data.accuracyRate || 0));
        totalTime.value = Number(data.totalTime || 0);

        const statsPracticeDays = resolvePracticeDaysFromStats(data);
        if (statsPracticeDays !== null) {
          practiceDays.value = statsPracticeDays;
          logger.debug('📊 连续打卡天数(统计字段):', practiceDays.value, '天');
        } else if (answerRecords.value.length === 0) {
          practiceDays.value = 0;
        }

        logger.debug('📊 totalTime 已更新为:', totalTime.value, '秒');
      }
    } catch(e) {
      logger.error('❌ 加载统计失败:', e);
    }
  };
  
  const loadUserCategories = async (scope = questionBankScope.value, options = {}) => {
    const { allowCache = true, background = false } = options;
    const normalizedScope = normalizeQuestionBankScope(scope);
    const seq = ++categoryLoadSeq;

    if (allowCache && hydrateCategoriesFromCache(normalizedScope)) {
      loadUserCategories(normalizedScope, { allowCache: false, background: true });
      return;
    }

    if (!background) {
      loadingCategories.value = true;
    } else if (userCategories.value.length === 0) {
      loadingCategories.value = true;
    }

    try {
      const requestTasks = [
        getDeptCourseCategories(normalizedScope).then((deptRes) => {
          logger.debug('部门题库类型响应:', deptRes);
          if (deptRes.data.code !== 200 || !deptRes.data.data) {
            return [];
          }
          return deptRes.data.data.map(d => ({
            id: d.id || `dept_course_${d.deptType}_${d.courseName}`,
            name: d.courseName,
            count: d.questionCount || 0,
            type: 'dept',
            courseId: d.courseId || null,
            deptType: d.deptType,
            courseName: d.courseName,
            groupId: d.groupId || null,
            groupName: d.groupName || d.deptType || '未分组课程'
          }));
        }).catch((e) => {
          logger.warn('加载部门题库分类失败:', e);
          return [];
        })
      ];

      if (normalizedScope === 'all') {
        requestTasks.push(
          getQuestionCategories().then((res) => {
            if (res.data.code !== 200 || !res.data.data) {
              return [];
            }
            return res.data.data.map(c => ({
              id: `ota_${c.courseId || c.id}`,
              name: c.name,
              category: c.category || c.name,
              count: c.questionCount || 0,
              type: 'ota',
              courseId: c.courseId || null,
              groupId: c.groupId || c.groupName || c.mainTitle || null,
              groupName: c.groupName || c.mainTitle || '未分组课程',
              mainTitle: c.mainTitle || 'OTA题库'
            }));
          }).catch((e) => {
            logger.warn('加载OTA题库分类失败:', e);
            return [];
          }),
          getCultureCategories().then((cultureRes) => {
            logger.debug('企业文化题库分类响应:', cultureRes);
            if (cultureRes.data.code !== 200 || !cultureRes.data.data) {
              return [];
            }
            return cultureRes.data.data.map(c => ({
              id: `culture_${c.id}`,
              name: c.name,
              count: c.count || 0,
              type: 'culture'
            }));
          }).catch((e) => {
            logger.warn('加载企业文化题库分类失败:', e);
            return [];
          }),
          getGreenHotelCategories().then((ghRes) => {
            logger.debug('绿色饭店题库分类响应:', ghRes);
            if (ghRes.data.code !== 200 || !ghRes.data.data) {
              return [];
            }
            return ghRes.data.data.map(c => ({
              id: `green_hotel_${c.courseId || c.id}`,
              name: c.name,
              category: c.category || c.name,
              count: c.count || 0,
              type: 'green_hotel',
              courseId: c.courseId || null,
              groupId: c.groupId || c.groupName || c.mainTitle || null,
              groupName: c.groupName || c.mainTitle || '未分组课程',
              mainTitle: c.mainTitle || '绿色饭店题库'
            }));
          }).catch((e) => {
            logger.warn('加载绿色饭店题库分类失败:', e);
            return [];
          })
        );
      }

      const categories = (await Promise.all(requestTasks)).flat();
      if (seq !== categoryLoadSeq) return;

      userCategories.value = categories.sort((a, b) => {
        // 部门题库优先
        if (a.type === 'dept' && b.type !== 'dept') return -1;
        if (a.type !== 'dept' && b.type === 'dept') return 1;
        return a.name.localeCompare(b.name, 'zh-CN');
      });
      writeCategoryCache(normalizedScope, userCategories.value);

      if (currentMode.value === 'category' && !activeCategory.value && userCategories.value.length > 0) {
        await selectCategory(userCategories.value[0], true);
      }
    } catch(e) {
       if (userCategories.value.length === 0) {
         userCategories.value = [];
       }
       logger.error('加载分类失败', e);
    } finally {
       if (seq === categoryLoadSeq) {
         loadingCategories.value = false;
       }
    }
  };
  
  // 格式化用户答案显示
  const formatUserAnswer = (record) => {
    // 优先使用 userAnswer，如果为空则尝试其他可能的字段
    let val = record.userAnswer || record.answer || record.myAnswer;
    
    if (val === undefined || val === null || val === '') return '未作答';

    const typeVal = normalizeQuestionTypeLabel(record.questionType || record.type);

    if (isTextQuestionType(typeVal)) {
      return formatTextAnswerDisplay(val) || '未作答';
    }
    
    // 处理数字类型答案：将 0,1,2 转为 A,B,C
    if (typeof val === 'number' && val >= 0 && val <= 25) {
        // 排除掉明显的非选项数字（比如 0/1 可能代表判断题，但也可能代表 A/B）
        // 如果是判断题类型
        if (typeVal === '判断题') {
             // 0/1 已经在下面处理了
        } else {
             // 单选/多选，尝试转字母
             val = String.fromCharCode(65 + val);
        }
    }
  
    // 如果是判断题，后端可能返回 0/1 或 true/false
    if (typeVal === '判断题') {
        const sVal = String(val).toLowerCase();
        if (sVal === '0' || sVal === 'a' || sVal === 'true' || sVal === '正确') return '正确';
        if (sVal === '1' || sVal === 'b' || sVal === 'false' || sVal === '错误') return '错误';
    }
    
    return val;
  };
  
  const resolveQuestionText = (record) => {
    if (!record) return '题目内容缺失';
    
    // 先尝试顶层字段
    let text = record.questionText || record.questionContent || record.content || record.title;
    
    // 如果没有，尝试从 question 字段中获取
    if (!text && record.question) {
      let questionObj = record.question;
      // 如果 question 是字符串，尝试解析为 JSON
      if (typeof questionObj === 'string') {
        try {
          questionObj = JSON.parse(questionObj);
        } catch (e) {
          logger.warn('解析 question 字段失败:', e);
        }
      }
      // 从解析后的对象中获取题目内容
      if (typeof questionObj === 'object' && questionObj !== null) {
        text = questionObj.questionText || questionObj.content || questionObj.title;
      }
    }
    
    return text || '题目内容缺失';
  };
  
  const loadAnswerRecords = async ({ pageSize = 50, fillDetails = false } = {}) => {
     loadingRecords.value = true;
     try {
        const res = await getAnswerRecords({pageNum:1, pageSize});
        logger.debug('答题记录API响应:', res);
        if (res.data.code === 200) {
            const rows = res.data.rows || [];
            if (rows.length > 0) {
                logger.debug('第一条答题记录数据:', rows[0]);
            }
            // 构造基础数据
            let records = rows.map(record => {
                // 解析 question 字段（如果是 JSON 字符串）
                let questionObj = record.question;
                if (typeof questionObj === 'string') {
                    try {
                        questionObj = JSON.parse(questionObj);
                    } catch (e) {
                        logger.warn('解析 question 字段失败:', e);
                        questionObj = null;
                    }
                }
                
                // 1. 适配题目内容字段
                let qText = record.questionText || record.questionContent || record.content || record.title;
                if (!qText && questionObj && typeof questionObj === 'object') {
                    qText = questionObj.questionText || questionObj.content || questionObj.title;
                }
                
                // 2. 适配用户答案字段
                // 尝试多种可能的字段名，包括 snake_case
                let uAnswer = record.userAnswer || record.user_answer || record.answer || record.myAnswer || record.result;
                
                // 如果依然为空，尝试从 questionObj 中获取（有时后端会把提交时的状态保存在这里）
                if ((uAnswer === undefined || uAnswer === null || uAnswer === '') && questionObj) {
                    uAnswer = questionObj.userAnswer || questionObj.myAnswer || questionObj.answer;
                }
                
                // 3. 适配正确答案字段
                let cAnswer = record.correctAnswer || record.rightAnswer;
                if (!cAnswer && questionObj) {
                    cAnswer = questionObj.correctAnswer;
                }
  
                // 4. 规范化 isCorrect
                let correct = record.isCorrect;
                if (correct === 1 || correct === '1' || correct === 'true' || correct === true) {
                    correct = true;
                } else {
                    correct = false;
                }
  
                return {
                    ...record,
                    id: record.questionId || record.id, // 确保有ID供补全使用
                    questionId: record.questionId || record.id,
                    questionText: qText,
                    userAnswer: uAnswer,
                    correctAnswer: cAnswer,
                    isCorrect: correct,
                    questionType: normalizeQuestionTypeLabel(record.questionType || (questionObj && (questionObj.questionType || questionObj.type))),
                    questionObj: questionObj
                };
            });
  
            // 补全题目内容
            if (records.length > 0) {
                // 筛选出需要补全的记录（题目内容缺失或为默认值）
                const recordsToFill = records.filter(r => 
                    !r.questionText || r.questionText === '题目内容缺失'
                );
                
                if (fillDetails && recordsToFill.length > 0) {
                    // 并发获取详情
                    await Promise.all(recordsToFill.map(async (record) => {
                        if (record.questionId) {
                            try {
                                const detailRes = await getQuestionDetail(record.questionId);
                                if (detailRes.data && detailRes.data.code === 200) {
                                    const detail = detailRes.data.data || detailRes.data;
                                    if (detail) {
                                        record.questionText = detail.questionText || detail.title || detail.content || record.questionText;
                                        // 如果正确答案缺失，也顺便补全
                                        if (record.correctAnswer === undefined) {
                                            record.correctAnswer = detail.correctAnswer;
                                        }
                                        // 补全题目类型
                                        if (!record.questionType) {
                                            record.questionType = normalizeQuestionTypeLabel(detail.questionType || detail.type);
                                        }
                                    }
                                }
                            } catch (e) {
                                logger.warn(`补全答题记录 ${record.questionId} 失败`, e);
                            }
                        }
                    }));
                }
            }
            
            answerRecords.value = records;
            rebuildCheckInDays(records);
            practiceDays.value = calculateConsecutivePracticeDays(records);
        }
     } catch(e) {
        logger.error('加载答题记录失败', e);
     } finally {
        loadingRecords.value = false;
     }
  };

  watch(showRecordModal, (opened) => {
    if (opened && answerRecords.value.length === 0 && !loadingRecords.value) {
      loadAnswerRecords();
    }
  });

  return {
    accuracyRate,
    activeCategory,
    activeCategoryName,
    activityTimer,
    answeredCount,
    answerRecords,
    applyQuestionStateByIndex,
    checkIsPartOfCorrectAnswer,
    calendarDate,
    canUseAllQuestionBanks,
    changeQuestionBankScope,
    checkInDays,
    checkLoginStatus,
    checkQuestionAccess,
    clearProgress,
    closeCelebration,
    cultureCategories,
    cultureCategoryExpanded,
    currentIndex,
    greenHotelCategories,
    greenHotelCategoryGroups,
    greenHotelCategoryExpanded,
    currentMode,
    currentQuestion,
    dailyPracticeTarget,
    deptAllCategory,
    deptCategories,
    deptCategoryGroups,
    deptCategoryExpanded,
    deptSectionExpanded,
    dismissFloatBtnTip,
    fillQuestionDetails,
    filteredDeptCategories,
    filteredCultureCategories,
    filteredGreenHotelCategories,
    filteredOtaCategories,
    findNearestAccessibleIndex,
    formatAnswer,
    formatDate,
    formatPracticeDuration,
    formatUserAnswer,
    FREE_DAILY_LIMIT,
    getHeaderBadgeClass,
    getModeDescription,
    getModeName,
    getOptionClass,
    getOptionMarkerClass,
    getQuestionStatusClass,
    getQuestionTypeName,
    handleVisibilityChange,
    handleTextAnswer,
    isCorrectOption,
    isCorrectOptionPart,
    isFavorite,
    isLoggedIn,
    isMultipleChoice,
    isPageVisible,
    isSelectedOption,
    jumpToQuestion,
    jumpToQuestionAndClose,
    lastAllowedIndex,
    lastTickTime,
    loadAnswerRecords,
    loadingCategories,
    loadingQuestions,
    loadingRecords,
    loadQuestions,
    loadSpecificQuestion,
    loadStatistics,
    loadUserCategories,
    membership,
    myPoints,
    nextQuestion,
    otaCategories,
    otaCategoryGroups,
    otaCategoryExpanded,
    otaSectionExpanded,
    parseAccessResponse,
    parseCorrectAnswer,
    practiceDays,
    prevQuestion,
    promptUpgrade,
    questionBankScope,
    recommendedQuestionBankScope,
    questions,
    resetSessionTimer,
    resolveQuestionText,
    restoreProgress,
    retestQuestion,
    saveProgress,
    searchQuery,
    selectCategory,
    selectCategoryAndClose,
    selectedOption,
    selectOption,
    sessionDuration,
    showAnswer,
    showCategoryModal,
    showCelebration,
    showCheckInCalendar,
    showFloatBtnTip,
    showQuestionListModal,
    showRecordModal,
    showTargetModal,
    startActivityTimer,
    stopActivityTimer,
    submitAnswer,
    suppressIndexWatch,
    switchMode,
    switchToFirstCategory,
    todayPracticeCount,
    todayPracticeRate,
    toggleFav,
    totalQuestions,
    correctAnswersCount,
    totalTime,
    updateTarget,
    userCategories,
    userInfo,
  }
}
  const fetchQuestionDetailBySource = async (questionId, questionSource = 'ota') => {
    const source = questionSource || 'ota';
    if (source === 'dept') {
      return getDeptQuestionDetail(questionId);
    }
    if (source === 'culture') {
      return getCultureQuestionDetail(questionId);
    }
    if (source === 'green_hotel') {
      return getGreenHotelQuestionDetail(questionId);
    }
    return getQuestionDetail(questionId);
  };
