<template>
    <HeaderBar />
    <PageVisitTracker pageName="OnlineTest" />
    <div class="bg-slate-50 min-h-screen flex flex-col font-sans">
      <!-- 导航栏占位符 -->
      <div class="w-full h-[64px] md:h-[80px] shrink-0"></div>
  
      <main class="flex-1 container mx-auto px-2.5 sm:px-6 lg:px-8 py-2.5 md:py-6 max-w-7xl">
        
        <!-- 移动端模式切换标签页 (仅移动端显示) -->
        <div class="mobile-mode-tabs lg:hidden" data-guide="online-mobile-mode-tabs">
          <button 
            @click="switchMode('daily')"
            class="mobile-mode-tab"
            :class="{ active: currentMode === 'daily' }"
          >
            <i class="fas fa-calendar-day"></i>
            <span>每日一练</span>
          </button>
          <button 
            @click="switchMode('wrong')"
            class="mobile-mode-tab"
            :class="{ active: currentMode === 'wrong' }"
          >
            <i class="fas fa-circle-exclamation"></i>
            <span>我的错题</span>
          </button>
          <button 
            @click="switchMode('fav')"
            class="mobile-mode-tab"
            :class="{ active: currentMode === 'fav' }"
          >
            <i class="fas fa-star"></i>
            <span>收藏夹</span>
          </button>
          <button 
            @click="showCategoryModal = true"
            class="mobile-mode-tab"
            :class="{ active: currentMode === 'category' }"
          >
            <i class="fas fa-book-open"></i>
            <span>专项练习</span>
          </button>
          <button 
            @click="$router.push('/green-hotel')"
            class="mobile-mode-tab"
          >
            <i class="fas fa-leaf"></i>
            <span>绿色饭店</span>
          </button>
        </div>
        
        <!-- 顶部统计条 - 移动端更紧凑 -->
        <div class="practice-summary-bar mb-2.5 md:mb-6 bg-white rounded-xl md:rounded-2xl shadow-sm border border-slate-100 p-1.5 md:p-4 flex flex-wrap items-center justify-between gap-1.5 md:gap-4" data-guide="online-practice-summary">
           <div class="flex items-center justify-around md:justify-start md:gap-6 flex-1 min-w-0">
              <!-- 打卡 -->
              <div
                @click="showCheckInCalendar = true"
                class="flex flex-col items-center md:flex-row md:items-center md:gap-3 cursor-pointer rounded-lg px-1.5 py-0.5 md:px-2 md:py-1 hover:bg-slate-50 transition-colors"
                title="查看打卡日历"
              >
                 <div class="hidden md:flex w-10 h-10 rounded-full bg-blue-50 text-blue-600 items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                 </div>
                 <div class="flex flex-col items-center md:items-start gap-0.5">
                    <span class="text-slate-800 font-bold text-sm md:text-base leading-none">{{ practiceDays }}<span class="text-[10px] md:text-xs font-normal text-slate-500 ml-0.5">天</span></span>
                    <span class="text-[10px] md:text-xs text-slate-400 leading-none">打卡</span>
                 </div>
              </div>
              <div class="hidden md:block w-px h-8 bg-slate-100"></div>
              <!-- 刷题 -->
               <div class="flex flex-col items-center md:items-start gap-0.5">
                  <span class="text-slate-800 font-bold text-sm md:text-lg">{{ totalQuestions }}</span>
                  <span class="text-[10px] md:text-xs text-slate-400 leading-none">刷题</span>
               </div>
              <div class="hidden md:block w-px h-8 bg-slate-100"></div>
              <!-- 正确率 -->
               <div class="flex flex-col items-center md:items-start gap-0.5">
                  <span class="text-emerald-600 font-bold text-sm md:text-lg">{{ accuracyRate }}%</span>
                  <span class="text-[10px] md:text-xs text-slate-400 leading-none">正确率</span>
               </div>
              <div class="hidden md:block w-px h-8 bg-slate-100"></div>
              <!-- 时长 -->
               <div class="flex flex-col items-center md:items-start gap-0.5">
                  <span class="text-indigo-600 font-bold text-sm md:text-lg whitespace-nowrap">
                    <ExamTimer :duration="sessionDuration" :formatter="formatPracticeDuration" />
                  </span>
                  <span class="text-[10px] md:text-xs text-slate-400 leading-none">时长</span>
               </div>
           </div>
           
           <!-- 右侧：今日目标 -->
           <div 
             @click="showTargetModal = true"
             class="hidden md:flex items-center gap-3 bg-slate-50 px-4 py-2 rounded-xl cursor-pointer hover:bg-slate-100 transition-colors"
             title="点击设置今日目标"
           >
              <span class="text-xs text-slate-500 font-medium">今日目标</span>
              <div class="w-24 h-2 bg-slate-200 rounded-full overflow-hidden">
                 <div class="h-full bg-blue-500 rounded-full transition-all duration-500" :style="{ width: todayPracticeRate + '%' }"></div>
              </div>
              <span class="text-xs font-bold text-blue-600">{{ todayPracticeCount }}/{{ dailyPracticeTarget }}</span>
              <i class="fa fa-pencil text-xs text-slate-400 ml-1"></i>
           </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-3 md:gap-6 items-start">
          
          <DesktopSidebar
            data-guide="online-desktop-sidebar"
            :currentMode="currentMode"
            :activeCategory="activeCategory"
            :deptAllCategory="deptAllCategory"
            :deptCategories="deptCategories"
            :deptCategoryGroups="deptCategoryGroups"
            :otaCategories="otaCategories"
            :otaCategoryGroups="otaCategoryGroups"
            :cultureCategories="cultureCategories"
            :greenHotelCategories="greenHotelCategories"
            :greenHotelCategoryGroups="greenHotelCategoryGroups"
            :filteredOtaCategories="filteredOtaCategories"
            :loadingCategories="loadingCategories"
            :questionBankScope="questionBankScope"
            v-model:deptCategoryExpanded="deptCategoryExpanded"
            v-model:otaCategoryExpanded="otaCategoryExpanded"
            v-model:cultureCategoryExpanded="cultureCategoryExpanded"
            v-model:greenHotelCategoryExpanded="greenHotelCategoryExpanded"
            v-model:searchQuery="searchQuery"
            @switchMode="switchMode"
            @switchToFirstCategory="switchToFirstCategory"
            @selectCategory="selectCategory"
          />
  
          <!-- 中间：沉浸式答题区 -->
          <div class="lg:col-span-6 flex flex-col gap-3 md:gap-6" data-guide="online-question-workspace">
             
             <!-- 模式标题栏 - 移动端更紧凑 -->
             <div class="practice-mode-panel bg-white rounded-xl md:rounded-2xl shadow-sm border border-slate-100 p-2.5 md:p-5 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-1.5 md:gap-4">
                <div>
                   <h2 class="text-base md:text-lg font-bold text-slate-800 mb-0.5 md:mb-1">
                     {{ 
                        currentMode === 'daily' ? '每日一练' : 
                        currentMode === 'wrong' ? '我的错题' : 
                        currentMode === 'fav' ? '收藏夹' : '专项练习' 
                     }}
                   </h2>
                   <p class="text-[11px] md:text-xs text-slate-500 leading-snug">
                      {{ getModeDescription() }}
                    </p>
                   <div
                     v-if="currentMode === 'category' && activeCategory === deptAllCategory.id"
                     class="mt-2 flex flex-wrap items-center gap-1.5"
                   >
                     <span class="rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] md:text-[11px] font-bold text-emerald-600">
                       共 {{ deptAllCategory.count }} 题
                     </span>
                     <span class="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] md:text-[11px] font-medium text-slate-500">
                       {{ deptCategoryGroups.length }} 类部门课程
                     </span>
                     <span class="text-[10px] md:text-[11px] text-slate-400">
                       也可在左侧按分类继续筛选
                     </span>
                   </div>
                </div>
                 
                 <div class="practice-mode-actions flex flex-col items-start sm:items-end gap-1.5 md:gap-2 w-full sm:w-auto">
                    <div class="practice-mode-toolbar flex items-center gap-2 md:gap-3 w-full sm:w-auto">
                      <div class="inline-flex items-center rounded-xl border border-slate-200 bg-slate-50 p-0.5 md:p-1">
                         <button
                           @click="changeQuestionBankScope('self')"
                           class="px-2.5 md:px-3 py-1.25 md:py-1.5 rounded-lg text-[11px] md:text-xs font-bold transition-all"
                           :class="questionBankScope === 'self' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                         >
                           部门推荐
                         </button>
                         <button
                           @click="changeQuestionBankScope('all')"
                           class="px-2.5 md:px-3 py-1.25 md:py-1.5 rounded-lg text-[11px] md:text-xs font-bold transition-all"
                           :class="questionBankScope === 'all' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                        >
                           全部题库
                         </button>
                      </div>
                      <span
                        class="hidden lg:inline-flex items-center rounded-full px-2.5 py-1 text-[11px] font-bold"
                        :class="recommendedQuestionBankScope === 'all' ? 'bg-blue-50 text-blue-600' : 'bg-emerald-50 text-emerald-600'"
                      >
                        {{ recommendedQuestionBankScope === 'all' ? '全部题库' : '部门推荐' }}
                      </span>
                      <button 
                        @click="showRecordModal = true"
                        class="practice-record-btn flex items-center gap-1.5 md:gap-2 px-2.5 md:px-4 py-1.25 md:py-2 bg-slate-50 text-slate-600 rounded-lg md:rounded-xl hover:bg-white hover:ring-1 hover:ring-blue-200 hover:text-blue-600 hover:shadow-sm transition-all text-[11px] md:text-sm font-bold"
                      >
                         <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 md:h-4 md:w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                           <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                         </svg>
                        答题记录
                      </button>
                    </div>
                 </div>
             </div>

             <!-- 题目卡片区域 - 移动端优化 -->
             <QuestionCard
               :loading="loadingQuestions"
               :question="currentQuestion"
               :currentIndex="currentIndex"
               :selectedOption="selectedOption"
               :showAnswer="showAnswer"
               :isFavorite="isFavorite"
               :isMultipleChoice="isMultipleChoice"
               :getOptionClass="getOptionClass"
               :getOptionMarkerClass="getOptionMarkerClass"
               :isCorrectOptionPart="isCorrectOptionPart"
               :isSelectedOption="isSelectedOption"
               :formatAnswer="formatAnswer"
               @updateAnswer="handleTextAnswer"
               @goDaily="switchMode('daily')"
               @toggleFav="toggleFav"
               @selectOption="selectOption"
               @prev="prevQuestion"
               @submit="submitAnswer"
               @next="nextQuestion"
             />
          </div>

          <!-- 右侧：题目列表 -->
          <aside v-if="questions.length > 0" class="lg:col-span-3 sticky top-24" data-guide="online-question-nav">
            <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden flex flex-col max-h-[600px]">
              <QuestionNav
                :questions="questions"
                :currentIndex="currentIndex"
                :answeredCount="answeredCount"
                :getQuestionStatusClass="getQuestionStatusClass"
                title="题目列表"
                @jump="jumpToQuestion"
              />
            </div>
          </aside>
        </div>
      </main>
      
      <MobileQuestionListButton
        v-if="questions.length > 0"
        data-guide="online-question-nav-trigger"
        :showTip="showFloatBtnTip"
        @open="showQuestionListModal = true; showFloatBtnTip = false"
        @dismissTip="dismissFloatBtnTip"
      />
      
      <CategorySelectDialog
        v-model="showCategoryModal"
        v-model:searchQuery="searchQuery"
        v-model:deptSectionExpanded="deptSectionExpanded"
        v-model:otaSectionExpanded="otaSectionExpanded"
        :filteredDeptCategories="filteredDeptCategories"
        :deptAllCategory="deptAllCategory"
        :deptCategoryGroups="deptCategoryGroups"
        :otaCategoryGroups="otaCategoryGroups"
        :cultureCategories="filteredCultureCategories"
        :filteredOtaCategories="filteredOtaCategories"
        :greenHotelCategories="filteredGreenHotelCategories"
        :greenHotelCategoryGroups="greenHotelCategoryGroups"
        :activeCategory="activeCategory"
        @selectCategory="selectCategoryAndClose"
      />
      
      <!-- 移动端题目列表弹窗 -->
      <el-dialog
        v-model="showQuestionListModal"
        title="题目列表"
        width="90%"
        class="rounded-2xl"
      >
        <QuestionNav
          :questions="questions"
          :currentIndex="currentIndex"
          :answeredCount="answeredCount"
          :getQuestionStatusClass="getQuestionStatusClass"
          :compact="true"
          title="题目列表"
          @jump="jumpToQuestionAndClose"
        />
      </el-dialog>
      
      <AnswerRecordDialog
        v-model="showRecordModal"
        :answerRecords="answerRecords"
        :loadingRecords="loadingRecords"
        :resolveQuestionText="resolveQuestionText"
        :formatDate="formatDate"
        :getQuestionTypeName="getQuestionTypeName"
        :formatUserAnswer="formatUserAnswer"
        @retest="retestQuestion"
      />

      <TargetDialog
        v-model="showTargetModal"
        v-model:target="dailyPracticeTarget"
        @confirm="updateTarget"
      />

      <CheckInCalendarDialog
        v-model="showCheckInCalendar"
        v-model:calendarDate="calendarDate"
        :checkInDays="checkInDays"
        :practiceDays="practiceDays"
        :myPoints="myPoints"
      />

      <CelebrationModal
        v-model="showCelebration"
        :dailyPracticeTarget="dailyPracticeTarget"
      />
    </div>
  </template>
  
  <script>
  import { defineComponent } from "vue";

  import HeaderBar from "@/components/HeaderBar.vue";
  import PageVisitTracker from "@/components/PageVisitTracker.vue";
  import ExamTimer from "@/components/exam/ExamTimer.vue";
  import QuestionNav from "@/components/exam/QuestionNav.vue";
  import QuestionCard from "@/components/exam/QuestionCard.vue";
  import MobileQuestionListButton from "./components/MobileQuestionListButton.vue";
  import CategorySelectDialog from "./components/CategorySelectDialog.vue";
  import AnswerRecordDialog from "./components/AnswerRecordDialog.vue";
  import TargetDialog from "./components/TargetDialog.vue";
  import CheckInCalendarDialog from "./components/CheckInCalendarDialog.vue";
  import CelebrationModal from "./components/CelebrationModal.vue";
  import DesktopSidebar from "./components/DesktopSidebar.vue";

  import { useOnlineTestPage } from "@/composables/useOnlineTestPage";

  export default defineComponent({
    name: "OnlineTestPage",
    components: {
      HeaderBar,
      PageVisitTracker,
      ExamTimer,
      QuestionNav,
      QuestionCard,
      MobileQuestionListButton,
      CategorySelectDialog,
      AnswerRecordDialog,
      TargetDialog,
      CheckInCalendarDialog,
      CelebrationModal,
      DesktopSidebar,
    },
    setup() {
      return useOnlineTestPage();
    },
  });
  </script>
  
  <style src="./OnlineTestPage.css"></style>



