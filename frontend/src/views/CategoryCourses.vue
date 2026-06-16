<template>
  <div>
    <HeaderBar />
    <!-- 导航栏占位符 -->
    <div class="h-[64px] md:h-[72px]"></div>
    <div class="py-4 md:py-8 bg-neutral-100 min-h-screen">
      <div class="container mx-auto px-4">
        <div class="flex flex-col lg:flex-row gap-8">
          <!-- 移动端分类导航 -->
          <div v-if="showSidebar" class="w-full lg:hidden">
            <div class="bg-white rounded-xl shadow-sm p-4 mb-4">
              <div class="flex items-center gap-2 mb-3">
                <i class="fa fa-th-large text-primary"></i>
                <span class="font-bold text-gray-800">分类筛选</span>
              </div>
              
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="link in currentThirdLevelLinks"
                  :key="link"
                  class="px-3 py-2 rounded-lg text-sm transition-all border"
                  :class="specificCategory === link ? 'bg-primary text-white border-primary' : 'bg-gray-50 text-gray-600 border-gray-200 hover:bg-gray-100'"
                  @click="switchCategory(subCategory, link)"
                >
                  {{ link }}
                </button>
              </div>
            </div>
          </div>

          <!-- 左侧分类导航 -->
          <div v-if="showSidebar" class="w-full lg:w-64 flex-shrink-0 hidden lg:block">
            <div class="bg-white rounded-xl shadow-sm p-5 sticky top-24">
              <h3 class="font-bold text-gray-800 mb-4 flex items-center text-lg border-b border-gray-100 pb-3">
                <i class="fa fa-th-large mr-2 text-primary"></i>
                分类导航
              </h3>
              
              <div class="space-y-4 custom-scrollbar max-h-[calc(100vh-200px)] overflow-y-auto pr-2">
                <!-- 显示当前选中的二级分类标题 -->
                <div v-if="subCategory" class="mb-4">
                  <div class="font-bold text-gray-800 mb-3 px-2 border-l-4 border-primary pl-2 text-base">
                    {{ subCategory }}
                  </div>
                  
                  <!-- 显示该二级分类下的三级链接 -->
                  <div class="space-y-1 ml-2">
                    <div 
                      v-for="link in currentThirdLevelLinks" 
                      :key="link"
                      class="px-3 py-2 rounded-lg cursor-pointer transition-all text-sm flex items-center justify-between group/link"
                      :class="(specificCategory === link) ? 'bg-primary text-white font-medium shadow-md shadow-primary/20' : 'text-gray-600 hover:bg-gray-50 hover:text-primary hover:pl-4'"
                      @click="switchCategory(subCategory, link)"
                    >
                      <span>{{ link }}</span>
                      <i v-if="specificCategory === link" class="fa fa-check text-xs opacity-80"></i>
                      <i v-else class="fa fa-angle-right text-xs opacity-0 group-hover/link:opacity-100 transition-opacity"></i>
                    </div>
                  </div>
                </div>
                
                <!-- 如果没有选中二级分类，显示提示 -->
                <div v-else class="text-center text-gray-500 text-sm py-8">
                  请从学习中心选择分类
                </div>
              </div>
            </div>
          </div>

          <!-- 右侧主要内容 -->
          <div class="flex-1 min-w-0">
            <!-- 页面标题 -->
            <div class="mb-6">
              <div class="flex items-center mb-2">
                <router-link to="/study" class="text-primary hover:text-primary/80 mr-2 flex items-center text-sm font-medium bg-white px-3 py-1 rounded-full shadow-sm hover:shadow transition-all">
                  <i class="fa fa-arrow-left mr-1"></i>返回学习中心
                </router-link>
              </div>
              <div class="flex items-end gap-3 flex-wrap title-row">
                <h2 class="text-2xl font-bold text-gray-800">
                  {{ categoryTitle }}
                </h2>
                <span class="text-gray-500 text-sm mb-1 bg-white px-2 py-0.5 rounded border border-gray-100">
                  共 {{ filteredCourses.length }} 门课程
                </span>
              </div>
            </div>

            <!-- 筛选和排序 -->
              <div class="bg-white rounded-xl shadow-sm p-4 mb-6 filter-shell">
                <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 filter-row">
                <!-- 搜索框 -->
                <div class="relative flex-1 max-w-md search-box">
                  <input 
                    type="text" 
                    placeholder="搜索课程..." 
                    class="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-200 focus:outline-none focus:ring-2 focus:ring-primary/30 transition-all"
                    v-model="searchQuery"
                  >
                  <i class="fa fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                </div>

                <!-- 层级选择和排序选项 -->
                <div class="flex items-center gap-4 flex-wrap filter-actions">
                  <div class="flex items-center gap-2 level-filter" v-if="!levelLocked">
                    <span class="text-sm text-gray-600">层级：</span>
                    <select 
                      class="text-sm border border-gray-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-primary/30 cursor-pointer hover:border-primary/50 transition-colors bg-white"
                      v-model="studyLevel"
                    >
                      <option value="all">全部</option>
                      <option value="basic">基础</option>
                      <option value="advance">进阶</option>
                      <option value="high">高阶</option>
                    </select>
                  </div>
                  <div v-else class="flex items-center gap-2 text-sm text-gray-600 level-filter">
                    <span>层级：</span>
                    <span class="px-3 py-1.5 rounded-lg bg-primary/5 text-primary font-bold border border-primary/10">
                      {{ getLevelDisplay(studyLevel) }}
                    </span>
                  </div>
                  
                  <div class="flex items-center gap-2 sort-filter">
                    <span class="text-sm text-gray-600">排序：</span>
                    <select 
                      class="text-sm border border-gray-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-primary/30 cursor-pointer hover:border-primary/50 transition-colors bg-white"
                      v-model="sortBy"
                    >
                      <option value="default">默认排序</option>
                      <option value="newest">最新上线</option>
                      <option value="popular">最受欢迎</option>
                      <option value="rating">评分最高</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>

            <!-- 课程列表 -->
            <div v-if="loading || !isParamsMatch" class="text-center py-20 bg-white rounded-xl shadow-sm">
              <i class="fa fa-circle-o-notch fa-spin text-4xl text-primary mb-4"></i>
              <p class="text-gray-500">正在加载精彩课程...</p>
            </div>

            <div v-else-if="filteredCourses.length === 0" class="bg-white rounded-xl shadow-sm p-16 text-center">
              <div class="w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <i class="fa fa-folder-open text-4xl text-gray-300"></i>
              </div>
              <p class="text-lg text-gray-500 mb-2 font-medium">暂无课程</p>
              <p class="text-sm text-gray-400">该分类下暂时没有可用的课程</p>
            </div>

            <div v-else class="grid grid-cols-2 sm:grid-cols-2 xl:grid-cols-3 gap-4 md:gap-6 course-grid">
              <div 
                v-for="course in filteredCourses" 
                :key="course.id"
                class="bg-white rounded-xl shadow-sm overflow-hidden hover:shadow-lg hover:-translate-y-1 transition-all duration-300 cursor-pointer group border border-gray-100 course-card"
                @click="goToCourse(course)"
              >
                <!-- 课程封面 -->
                <div class="h-44 md:h-44 relative overflow-hidden bg-gray-100 course-cover">
                  <div v-if="course.coverImage" class="absolute inset-0">
                    <img 
                      :src="course.coverImage" 
                      :alt="course.title"
                      class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                      @error="(e) => e.target.style.display = 'none'"
                    >
                    <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-60"></div>
                  </div>
                  <div v-else class="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-50 text-primary text-3xl md:text-5xl group-hover:scale-110 transition-transform duration-500">
                    <i :class="course.icon || 'fa fa-book'"></i>
                  </div>
                  
                  <!-- 标签 -->
                  <div class="absolute top-2 left-2 md:top-3 md:left-3 flex gap-1 md:gap-2">
                    <span class="px-1.5 py-0.5 md:px-2 md:py-1 bg-white/90 backdrop-blur-sm text-primary text-[10px] md:text-xs rounded-md font-bold shadow-sm">
                      {{ getLevelDisplay(course.difficulty || course.level) }}
                    </span>
                    <span v-if="course.isRequired" class="px-1.5 py-0.5 md:px-2 md:py-1 bg-red-500/90 backdrop-blur-sm text-white text-[10px] md:text-xs rounded-md font-bold shadow-sm">
                      必修
                    </span>
                  </div>
                </div>

                <!-- 课程信息 -->
                <div class="p-3 md:p-5 course-info">
                  <h3 class="font-bold text-gray-800 mb-1 md:mb-2 line-clamp-2 group-hover:text-primary transition-colors text-sm md:text-base course-title">
                    {{ course.title }}
                  </h3>
                  <p class="text-[10px] md:text-xs text-gray-500 mb-2 md:mb-4 line-clamp-2 leading-relaxed course-desc hidden md:block">
                    {{ course.description || '暂无描述' }}
                  </p>
                  
                  <!-- 课程元信息 - 移动端简化 -->
                  <div class="flex items-center justify-between text-[10px] md:text-xs text-gray-400 border-t border-gray-50 pt-2 md:pt-4 course-meta">
                    <div class="flex items-center gap-2 md:gap-3">
                      <span class="flex items-center">
                        <i class="fa fa-clock-o mr-0.5 md:mr-1 text-gray-300"></i>
                        <span class="hidden md:inline">{{ course.duration || '2小时' }}</span>
                        <span class="md:hidden">{{ (course.duration || '2小时').replace('小时', 'h') }}</span>
                      </span>
                      <span class="flex items-center">
                        <i class="fa fa-user mr-0.5 md:mr-1 text-gray-300"></i>
                        {{ course.enrollCount || 0 }}
                      </span>
                    </div>
                    <div class="flex items-center text-yellow-400 font-bold">
                      <i class="fa fa-star mr-0.5 text-[10px] md:hidden"></i>
                      <span class="mr-1 text-gray-300 font-normal hidden md:inline">评分</span>
                      {{ course.rating || '5.0' }}
                    </div>
                  </div>

                  <!-- 开始学习按钮 - 移动端更紧凑 -->
                  <button 
                    class="w-full mt-2 md:mt-4 py-1.5 md:py-2.5 bg-gray-50 text-gray-600 rounded-lg hover:bg-primary hover:text-white transition-all text-xs md:text-sm font-bold group-hover:bg-primary group-hover:text-white shadow-sm hover:shadow-md course-btn"
                    @click.stop="startLearning(course)"
                  >
                    <span class="md:hidden">学习</span>
                    <span class="hidden md:inline">开始学习</span>
                  </button>
                </div>
              </div>
            </div>

            <!-- 分页 -->
            <div v-if="totalPages > 1" class="mt-10 flex justify-center">
              <div class="flex items-center gap-2 bg-white p-2 rounded-xl shadow-sm border border-gray-100">
                <button 
                  @click="currentPage = Math.max(1, currentPage - 1)"
                  :disabled="currentPage === 1"
                  class="w-9 h-9 flex items-center justify-center rounded-lg border border-gray-200 hover:bg-gray-50 hover:border-primary hover:text-primary disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                >
                  <i class="fa fa-chevron-left text-xs"></i>
                </button>
                
                <span class="px-4 text-sm text-gray-600 font-medium">
                  {{ currentPage }} / {{ totalPages }}
                </span>
                
                <button 
                  @click="currentPage = Math.min(totalPages, currentPage + 1)"
                  :disabled="currentPage === totalPages"
                  class="w-9 h-9 flex items-center justify-center rounded-lg border border-gray-200 hover:bg-gray-50 hover:border-primary hover:text-primary disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                >
                  <i class="fa fa-chevron-right text-xs"></i>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted, watch, onActivated } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import HeaderBar from '@/components/HeaderBar.vue';
import { getCourseCategoryList, getCourseCategoryListByPlatform } from '@/api/study';
import { checkContentAccess } from '@/api/membership';
import { ElMessage, ElMessageBox } from 'element-plus';

const route = useRoute();
const router = useRouter();
const isDev = !import.meta.env.PROD;

// 状态
const loading = ref(false);
const courses = ref([]);
const loadedParams = ref({}); // 记录当前展示数据对应的参数，用于防止页面切换时的闪烁

const searchQuery = ref('');
const sortBy = ref('default');
const studyLevel = ref(route.query.level || 'all'); // 学习层级（默认不过滤）
const currentPage = ref(1);
const pageSize = 9;
const levelLocked = computed(() => route.query.lockLevel === 'true');

// 获取分类信息
const platform = computed(() => route.query.platform || '');
const mainCategory = computed(() => route.query.main || '');
const subCategory = computed(() => route.query.sub || '');
const specificCategory = computed(() => route.query.specific || '');

// 判断当前路由参数是否与已加载的数据匹配
const isParamsMatch = computed(() => {
  const current = {
    main: (route.query.main || '').trim(),
    sub: (route.query.sub || '').trim(),
    specific: (route.query.specific || '').trim()
  };
  const loaded = loadedParams.value;
  
  // 首次加载时 loaded 为空，视为不匹配
  // if (!loaded.main && !current.main && !loaded.sub && !current.sub) return false;
  
  return current.main === loaded.main &&
         current.sub === loaded.sub &&
         current.specific === loaded.specific;
});

// 生成标题
const categoryTitle = computed(() => {
  if (specificCategory.value) {
    return specificCategory.value;
  } else if (subCategory.value) {
    return subCategory.value;
  } else if (mainCategory.value) {
    return mainCategory.value;
  }
  return '全部课程';
});

// 获取层级显示名称
const getLevelDisplay = (level) => {
  if (!level || level === 'all') return '全部';
  const levelStr = String(level).toLowerCase().trim();
  if (levelStr === 'basic' || levelStr === '基础' || levelStr === '初级') return '基础';
  if (levelStr === 'advance' || levelStr === 'advanced' || levelStr === '进阶' || levelStr === '中级') return '进阶';
  if (levelStr === 'high' || levelStr === 'expert' || levelStr === '高级' || levelStr === '高阶' || levelStr === '专家') return '高阶';
  return '全部';
};

// 过滤和排序课程
const filteredCourses = computed(() => {
  let result = [...courses.value];
  
  // 层级过滤 (前端处理)
  if (studyLevel.value && studyLevel.value !== 'all') {
    result = result.filter(course => {
      const l = String(course.level || '').toLowerCase().trim();
      let normalizedLevel = 'basic';
      
      if (l === '进阶' || l === 'advance' || l === 'advanced' || l === '中级') normalizedLevel = 'advance';
      else if (l === '高阶' || l === 'high' || l === 'expert' || l === '高级' || l === '专家') normalizedLevel = 'high';
      
      return normalizedLevel === studyLevel.value;
    });
  }

  // 搜索过滤
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(course => 
      course.title.toLowerCase().includes(query) ||
      (course.description && course.description.toLowerCase().includes(query))
    );
  }
  
  // 排序
  switch (sortBy.value) {
    case 'newest':
      result.sort((a, b) => new Date(b.createTime) - new Date(a.createTime));
      break;
    case 'popular':
      result.sort((a, b) => (b.enrollCount || 0) - (a.enrollCount || 0));
      break;
    case 'rating':
      result.sort((a, b) => (b.rating || 0) - (a.rating || 0));
      break;
  }
  
  // 分页
  const start = (currentPage.value - 1) * pageSize;
  const end = start + pageSize;
  return result.slice(start, end);
});

// 总页数
const totalPages = computed(() => 
  Math.ceil(courses.value.length / pageSize)
);

// 动态获取的三级分类列表
const dynamicSpecificCategories = ref([]);

// 废弃原有的 categoryStructure，改为动态数据
// const categoryStructure = { ... }; 

// 侧边栏显示逻辑优化
const showSidebar = computed(() => {
  return dynamicSpecificCategories.value.length > 0;
});

// 获取当前二级分类下的三级链接 (改为返回动态获取的 specific_categories)
const currentThirdLevelLinks = computed(() => {
  return dynamicSpecificCategories.value;
});

// 切换分类
const switchCategory = (sub, specific) => {
  // 如果只传入了2个参数，且第一个参数是对象（来自click事件），则修正参数
  if (typeof sub === 'object') {
    return;
  }

  router.push({
    path: '/category-courses',
    query: {
      main: mainCategory.value,
      sub: sub,
      specific: specific || '',
      level: studyLevel.value,
      lockLevel: 'true'
    }
  });
};

// 加载课程数据
const loadCourses = async () => {
  loading.value = true;
  try {
    // 已知的平台列表
    const knownPlatforms = ['美团', '携程', '飞猪', '独家'];
    
    // 优先使用 URL 中的 platform 参数
    let listRes;
    const queryParams = {
      pageNum: 1,
      pageSize: 1000
    };
    // if (studyLevel.value && studyLevel.value !== 'all') {
    //   queryParams.level = studyLevel.value;
    // }
    if (platform.value && knownPlatforms.includes(platform.value)) {
      // 如果有 platform 参数，使用平台 API
      listRes = await getCourseCategoryListByPlatform(platform.value, queryParams);
    } else if (mainCategory.value && knownPlatforms.includes(mainCategory.value)) {
      // 兼容旧逻辑：如果 main 参数是平台名称
      listRes = await getCourseCategoryListByPlatform(mainCategory.value, queryParams);
    } else {
      // 否则获取所有课程，在前端过滤
      listRes = await getCourseCategoryList(queryParams);
    }
    
    const rows = listRes?.data?.rows || listRes?.data?.data || [];
    
    if (isDev) {
      logger.debug('🔍 [CategoryCourses] API返回数据:', rows.length, '条');
      logger.debug('🔍 [CategoryCourses] URL参数 - platform:', platform.value, 'main:', mainCategory.value, 'sub:', subCategory.value, 'level:', studyLevel.value);
      if (rows.length > 0) {
        logger.debug('🔍 [CategoryCourses] 第一条数据样例:', JSON.stringify(rows[0], null, 2));
      }
    }
    
    // 1. 确定当前页面的数据范围 (Scope)
    // 必须匹配 mainCategory (一级) 和 subCategory (二级)
    const scopeCourses = rows.filter(row => {
      const rMain = (row.mainTitle || row.main_title || '').trim();
      const rSub = (row.mainS || row.main_s || '').trim();
      
      // 如果URL中有指定main/sub，必须匹配
      if (mainCategory.value && rMain !== mainCategory.value) {
        // logger.debug('🔍 [CategoryCourses] 过滤掉(main不匹配):', rMain, '!=', mainCategory.value);
        return false;
      }
      if (subCategory.value && rSub !== subCategory.value) {
        // logger.debug('🔍 [CategoryCourses] 过滤掉(sub不匹配):', rSub, '!=', subCategory.value);
        return false;
      }
      
      return true;
    });
    
    if (isDev) {
      logger.debug('🔍 [CategoryCourses] 过滤后数据:', scopeCourses.length, '条');
    }

    // 2. 提取三级分类 (Specific Categories) 用于侧边栏
    const specifics = new Set();
    scopeCourses.forEach(row => {
      const spec = (row.specificCategory || row.specific_category || '').trim();
      if (spec) specifics.add(spec);
    });
    dynamicSpecificCategories.value = Array.from(specifics).sort(); // 排序

    // 3. 最终显示筛选
    const filteredRows = scopeCourses.filter(row => {
      const specificCat = (row.specificCategory || row.specific_category || '').trim();
      
      // 过滤掉占位课程
      const courseTitle = (row.thirdLevelC || row.third_level_c || '').trim();
      if (courseTitle === '全部' || courseTitle === '全部课程' || courseTitle === '') {
        return false;
      }
      
      // 如果选了三级分类，必须匹配
      if (specificCategory.value) {
        if (specificCat !== specificCategory.value) {
          return false;
        }
      } 
      
      return true;
    });
    
    // 映射为前端显示格式
    courses.value = filteredRows.map((row, idx) => {
      const mainTitle = (row.mainTitle || row.main_title || '').trim();
      const subTitle = (row.mainS || row.main_s || '').trim();
      const specificCat = (row.specificCategory || row.specific_category || '').trim();
      const courseTitle = (row.thirdLevelC || row.third_level_c || row.specificCategory || row.specific_category || row.mainTitle || row.main_title || '未命名课程').trim();
      
      // 生成分类描述
      let categoryDescription = mainTitle;
      if (subTitle) {
        categoryDescription = `${mainTitle} / ${subTitle}`;
      }
      if (specificCat) {
        categoryDescription = `${mainTitle} / ${subTitle} / ${specificCat}`;
      }
      
      return {
        id: row.courseCategoryId || row.course_category_id || row.id || `course-${idx}`,
        courseCategoryId: row.courseCategoryId || row.course_category_id || row.id,
        title: courseTitle,
        description: categoryDescription,
        category: mainTitle,
        subCategory: subTitle,
        specificCategory: specificCat,
        knowledgePoints: row.knowledgePoints || row.knowledge_points || '',
        duration: row.duration || '2小时',
        level: row.level || row.levelType || '基础',
        courseType: 'ota',
        difficulty: row.level || row.levelType || '基础',
        icon: 'fa fa-book',
        isRequired: row.is_required || false,
        enrollCount: row.student_count || 0,
        rating: row.rating || '5.0',
        coverImage: row.cover_image || null,
        createTime: row.create_time || new Date()
      };
    });
    
    if (courses.value.length === 0 && isDev) {
      logger.debug('该分类下暂无真实课程数据');
    }
    
    // 更新已加载的参数记录
    loadedParams.value = {
      main: (mainCategory.value || '').trim(),
      sub: (subCategory.value || '').trim(),
      specific: (specificCategory.value || '').trim()
    };
    
  } catch (error) {
    logger.error('加载课程失败:', error);
    ElMessage.error('加载课程失败，请稍后重试');
    courses.value = [];
  } finally {
    loading.value = false;
  }
};

const parseAccessResponse = (res) => {
  const payload = res?.data;
  if (payload && typeof payload === 'object' && Object.prototype.hasOwnProperty.call(payload, 'data')) {
    return !!payload.data;
  }
  return !!payload;
};

const ensureCourseAccess = async (course) => {
  const contentId = Number(course.id || course.courseCategoryId || course.course_category_id);
  if (!contentId || Number.isNaN(contentId)) {
    return true;
  }

  try {
    const res = await checkContentAccess('course', contentId);
    const hasAccess = parseAccessResponse(res);
    if (hasAccess) {
      return true;
    }

    try {
      await ElMessageBox.confirm(
        '该课程为会员专享内容，升级会员即可解锁。',
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

    return false;
  } catch (error) {
    logger.error('检查课程访问权限失败:', error);
    return true;
  }
};

// 跳转到课程详情
const goToCourse = async (course) => {
  if (!(await ensureCourseAccess(course))) {
    return;
  }

  // 获取真实的知识点内容
  const knowledgeContent = course.knowledgePoints || course.knowledge_points || '';
  
  if (knowledgeContent) {
    // 构建知识点数据（使用真实数据）
    const knowledgeData = {
      id: course.id || course.courseCategoryId || course.course_category_id,
      title: course.title,
      category: course.category || categoryTitle.value || '订单处理',
      subCategory: course.subCategory || subCategory.value || '',
      specificCategory: course.specificCategory || course.title,
      content: knowledgeContent, // 使用真实的知识点内容
      duration: course.duration || '2小时',
      level: course.level || course.difficulty || '基础',
      courseType: course.courseType || 'ota',
      videoApi: 'train/video/play'
    };
    
    // 将数据存储到 sessionStorage
    sessionStorage.setItem('currentKnowledgeContent', JSON.stringify(knowledgeData));
    const returnPath = window.location.href;
    sessionStorage.setItem('knowledgeDetailReturnPath', returnPath);
    
    // 直接在新窗口打开课程详情页，权限验证由后端处理
    window.open('/knowledge-detail.html', '_blank');
  } else {
    // 如果没有知识点内容，显示提示
    ElMessage.info('该课程暂无详细内容');
  }
};

// 生成课程内容
const generateCourseContent = (course) => {
  // 根据课程标题生成相应的内容
  const content = `
    <h2>1. 课程简介</h2>
    <p>${course.description || '这是一门关于' + course.title + '的精彩课程，包含丰富的实战内容和案例分析。'}</p>
    
    <h2>2. 学习目标</h2>
    <ul>
      <li>掌握${course.title}的核心知识点</li>
      <li>了解相关的实际操作流程</li>
      <li>能够独立处理常见问题</li>
      <li>提升工作效率和服务质量</li>
    </ul>
    
    <h2>3. 课程大纲</h2>
    <h3>3.1 基础知识</h3>
    <p>本章节将介绍${course.title}的基本概念和重要术语，帮助学员建立完整的知识体系。</p>
    
    <h3>3.2 操作流程</h3>
    <p>详细讲解各项操作的步骤和注意事项，配合实际案例进行演示。</p>
    
    <h3>3.3 常见问题</h3>
    <p>总结日常工作中遇到的典型问题，提供解决方案和最佳实践。</p>
    
    <h3>3.4 进阶技巧</h3>
    <p>分享高效的工作技巧和优化方法，帮助学员提升专业能力。</p>
    
    <h2>4. 学习建议</h2>
    <p>建议学员按照课程大纲的顺序学习，并结合实际工作进行练习。如有疑问，可以通过在线讨论或联系讲师进行咨询。</p>
  `;
  
  return content;
};

// 开始学习
const startLearning = (course) => {
  // 直接跳转到知识点详情页面，无需弹窗
  goToCourse(course);
};

onMounted(() => {
  loadCourses();
});

onActivated(() => {
  // 当组件被 keep-alive 缓存并重新激活时，检查参数是否匹配
  if (!isParamsMatch.value) {
    // 如果不匹配，强制清空数据并重新加载，防止闪烁旧数据
    courses.value = [];
    loading.value = true;
    loadCourses();
  }
});

watch(() => route.query.level, (newLevel) => {
  if (newLevel && studyLevel.value !== newLevel) {
    studyLevel.value = newLevel;
    loadCourses();
  }
});

watch(
  () => [route.query.main, route.query.sub, route.query.specific],
  () => {
    currentPage.value = 1;
    loadCourses();
  }
);
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  /* 标准属性用于兼容性 */
  line-clamp: 2;
  display: -moz-box;
  -moz-box-orient: vertical;
}

.title-row,
.filter-shell,
.filter-row,
.search-box,
.filter-actions,
.level-filter,
.sort-filter,
.course-grid,
.course-card,
.course-info,
.course-title,
.course-meta,
.course-btn {
  min-width: 0;
}
</style>


<style scoped>
/* 移动端课程卡片深度优化 */
@media (max-width: 768px) {
  .course-grid {
    grid-template-columns: 1fr !important;
    gap: 0.875rem !important;
  }
  
  .course-card {
    border-radius: 0.875rem !important;
  }
  
  .course-cover {
    height: 9rem !important;
  }
  
  .course-info {
    padding: 0.875rem !important;
  }
  
  .course-title {
    font-size: 0.95rem !important;
    line-height: 1.45 !important;
    height: auto !important;
    margin-bottom: 0.375rem !important;
  }
  
  .course-desc {
    display: block !important;
    font-size: 0.8125rem !important;
    margin-bottom: 0.625rem !important;
  }
  
  .course-meta {
    padding-top: 0.625rem !important;
    font-size: 0.8125rem !important;
    flex-wrap: wrap;
    gap: 0.5rem;
    align-items: flex-start !important;
  }
  
  .course-btn {
    margin-top: 0.75rem !important;
    padding: 0.75rem 0.875rem !important;
    font-size: 0.875rem !important;
    border-radius: 0.625rem !important;
    min-height: 44px;
  }
  
  .container {
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
  }
  
  .text-2xl {
    font-size: 1.125rem !important;
  }
  
  .filter-shell {
    padding: 0.75rem !important;
    margin-bottom: 0.75rem !important;
  }

  .filter-row,
  .filter-actions,
  .level-filter,
  .sort-filter {
    align-items: stretch !important;
    width: 100%;
  }

  .filter-actions {
    gap: 0.75rem !important;
  }

  .search-box,
  .level-filter,
  .sort-filter {
    max-width: none !important;
    width: 100%;
  }

  .level-filter select,
  .sort-filter select {
    flex: 1;
    min-height: 44px;
  }
  
  .search-box input {
    padding: 0.5rem 0.75rem 0.5rem 2rem !important;
    font-size: 0.8125rem !important;
    min-height: 44px;
  }
  
  select {
    padding: 0.5rem 0.75rem !important;
    font-size: 0.8125rem !important;
  }
  
  .flex.flex-wrap.gap-2 button {
    padding: 0.375rem 0.625rem !important;
    font-size: 0.75rem !important;
  }
}

/* 超小屏幕优化 (< 375px) */
@media (max-width: 375px) {
  .course-grid {
    gap: 0.75rem !important;
  }

  .course-cover {
    height: 7.5rem !important;
  }
  
  .course-title {
    font-size: 0.875rem !important;
  }
  
  .course-meta {
    font-size: 0.75rem !important;
  }
  
  .course-btn {
    font-size: 0.8125rem !important;
    padding: 0.625rem 0.75rem !important;
  }
}
</style>

