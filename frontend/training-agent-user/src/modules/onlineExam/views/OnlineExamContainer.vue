<template>
  <div>
    <HeaderBar />
    <!-- 导航栏占位 -->
    <div class="h-16 md:h-[72px]"></div>
    <div class="py-3 md:py-8 bg-gray-50 min-h-screen">
      <div class="container mx-auto px-3 md:px-4 max-w-6xl">
        <!-- 顶部统计看板 - 移动端横向滚动 -->
        <div v-if="!showExamStart && isLoggedIn" class="mb-4 md:mb-12" data-guide="exam-overview-stats">
          <div class="flex md:grid md:grid-cols-3 gap-3 md:gap-6 overflow-x-auto pb-2 md:pb-0 scrollbar-thin">
            <div class="bg-white rounded-xl md:rounded-2xl p-3 md:p-6 shadow-sm border border-gray-100 flex items-center relative overflow-hidden group hover:shadow-md transition-all duration-300 min-w-[140px] md:min-w-0 flex-shrink-0">
              <div class="absolute right-0 bottom-0 opacity-10 transform translate-x-2 translate-y-2 group-hover:scale-110 transition-transform duration-500">
                <i class="fa fa-flag text-5xl md:text-8xl text-blue-500"></i>
              </div>
              <div class="w-10 h-10 md:w-14 md:h-14 rounded-full bg-blue-50 flex items-center justify-center mr-2 md:mr-4 group-hover:bg-blue-100 transition-colors flex-shrink-0">
                <i class="fa fa-flag text-lg md:text-2xl text-blue-500"></i>
              </div>
              <div>
                <div class="text-gray-500 text-xs md:text-sm mb-0.5 md:mb-1 whitespace-nowrap">待参加</div>
                <div class="text-xl md:text-3xl font-bold text-gray-800">{{ upcomingExams.length }}<span class="text-xs md:text-sm font-normal text-gray-400 ml-1">场</span></div>
              </div>
            </div>

            <div class="bg-white rounded-xl md:rounded-2xl p-3 md:p-6 shadow-sm border border-gray-100 flex items-center relative overflow-hidden group hover:shadow-md transition-all duration-300 min-w-[140px] md:min-w-0 flex-shrink-0">
              <div class="absolute right-0 bottom-0 opacity-10 transform translate-x-2 translate-y-2 group-hover:scale-110 transition-transform duration-500">
                <i class="fa fa-check-circle text-5xl md:text-8xl text-green-500"></i>
              </div>
              <div class="w-10 h-10 md:w-14 md:h-14 rounded-full bg-green-50 flex items-center justify-center mr-2 md:mr-4 group-hover:bg-green-100 transition-colors flex-shrink-0">
                <i class="fa fa-check-circle text-lg md:text-2xl text-green-500"></i>
              </div>
              <div>
                <div class="text-gray-500 text-xs md:text-sm mb-0.5 md:mb-1 whitespace-nowrap">已完成</div>
                <div class="text-xl md:text-3xl font-bold text-gray-800">{{ allTotalAttempts }}<span class="text-xs md:text-sm font-normal text-gray-400 ml-1">场</span></div>
              </div>
            </div>

            <div class="bg-white rounded-xl md:rounded-2xl p-3 md:p-6 shadow-sm border border-gray-100 flex items-center relative overflow-hidden group hover:shadow-md transition-all duration-300 min-w-[140px] md:min-w-0 flex-shrink-0">
              <div class="absolute right-0 bottom-0 opacity-10 transform translate-x-2 translate-y-2 group-hover:scale-110 transition-transform duration-500">
                <i class="fa fa-trophy text-5xl md:text-8xl text-amber-500"></i>
              </div>
              <div class="w-10 h-10 md:w-14 md:h-14 rounded-full bg-amber-50 flex items-center justify-center mr-2 md:mr-4 group-hover:bg-amber-100 transition-colors flex-shrink-0">
                <i class="fa fa-trophy text-lg md:text-2xl text-amber-500"></i>
              </div>
              <div>
                <div class="text-gray-500 text-xs md:text-sm mb-0.5 md:mb-1 whitespace-nowrap">{{ allAverageScoreTitle }}</div>
                <div class="text-xl md:text-3xl font-bold" :class="allAverageScoreClass">
                  {{ allAverageScoreDisplay }}<span v-if="showAllAverageScoreUnit" class="text-xs md:text-sm font-normal text-gray-400 ml-1">分</span>
                </div>
              </div>
            </div>
          </div>
        </div>

      <!-- 正式考试（内嵌渲染在本页标题下） -->
      <div v-if="showExamStart" class="mb-4 md:mb-10">
        <ExamStart :exam-id="selectedExamId" />
      </div>

      <!-- 综合平时测验 -->
      <div class="mb-4 md:mb-12" v-if="!showExamStart" data-guide="exam-practice-section">
        <div class="flex items-center justify-between mb-3 md:mb-6">
          <div class="flex items-center">
            <div class="w-1 h-5 md:w-1.5 md:h-8 bg-blue-600 rounded-full mr-2 md:mr-4"></div>
            <h3 class="text-base md:text-2xl font-bold text-gray-800">综合平时测验</h3>
          </div>
          <span class="text-xs md:text-sm text-gray-500 bg-gray-100 px-2 py-0.5 md:px-3 md:py-1 rounded-full hidden md:inline">随时练习，提升能力</span>
        </div>
        
        <!-- 未登录状态 -->
        <div v-if="!isLoggedIn" class="text-center py-4 md:py-6">
          <div class="text-neutral-500">
            <i class="fa fa-user-circle text-3xl md:text-4xl mb-2 md:mb-3 text-neutral-300"></i>
            <p class="text-sm md:text-lg mb-1 md:mb-2">请先登录参加测验</p>
            <p class="text-xs md:text-sm">登录后即可参加综合平时测验</p>
          </div>
        </div>
        
        <!-- 已登录状态 -->
        <div v-else class="space-y-3 md:space-y-4">
          <div
            v-for="exam in practiceExams"
            :key="exam.id"
            class="group bg-white rounded-xl md:rounded-2xl p-3 md:p-6 shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100 hover:border-blue-100 relative overflow-hidden"
          >
            <!-- 装饰背景 -->
            <div class="absolute top-0 right-0 w-32 md:w-64 h-32 md:h-64 bg-gradient-to-bl from-blue-50 to-transparent rounded-full -mr-10 md:-mr-20 -mt-10 md:-mt-20 opacity-50 group-hover:scale-110 transition-transform duration-700"></div>
            
            <div class="flex items-center gap-3 md:gap-6 relative z-10">
              <!-- 图标区域 -->
              <div class="w-10 h-10 md:w-16 md:h-16 rounded-xl md:rounded-2xl bg-blue-50 flex items-center justify-center flex-shrink-0 group-hover:bg-blue-500 transition-colors duration-300 shadow-sm">
                <i class="fa fa-cube text-lg md:text-3xl text-blue-500 group-hover:text-white transition-colors duration-300"></i>
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-center mb-1 md:mb-3 flex-wrap gap-1 md:gap-3">
                  <h4 class="text-sm md:text-xl font-bold text-gray-800 group-hover:text-blue-600 transition-colors">{{ exam.title }}</h4>
                  <span class="bg-blue-50 text-blue-600 px-1.5 py-0.5 md:px-3 md:py-1 rounded-full text-[10px] md:text-xs font-medium border border-blue-100">随机抽题</span>
                </div>
                
                <div class="flex flex-wrap gap-2 md:gap-6 text-xs md:text-sm text-gray-500">
                  <div class="flex items-center">
                    <i class="fa fa-clock-o mr-1 text-blue-400"></i>
                    <span>{{ exam.duration }}分钟</span>
                  </div>
                  <div class="flex items-center">
                    <i class="fa fa-file-text-o mr-1 text-purple-400"></i>
                    <span>{{ exam.questions }}题</span>
                  </div>
                </div>
              </div>

              <div class="flex-shrink-0">
                <button
                  class="px-3 py-1.5 md:px-8 md:py-3 bg-gray-900 text-white rounded-lg md:rounded-xl hover:bg-blue-600 transition-all duration-300 font-medium shadow-lg hover:shadow-blue-500/30 flex items-center gap-1 md:gap-2 group/btn text-xs md:text-base"
                  @click="openPracticeTypeModal(exam.id)"
                >
                  <span>开始</span>
                  <i class="fa fa-arrow-right transform group-hover/btn:translate-x-1 transition-transform hidden md:inline"></i>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <teleport to="body">
        <div v-if="showPracticeTypeModal" class="practice-type-sheet-wrap fixed inset-0 z-[99999] flex items-center justify-center px-4" @click="closePracticeTypeModal">
          <div class="absolute inset-0 bg-black/40"></div>
          <div class="practice-type-sheet relative w-full max-w-md bg-white rounded-2xl shadow-2xl border border-gray-100 overflow-hidden" @click.stop>
            <div class="practice-type-handle md:hidden"></div>
            <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
              <div class="font-bold text-gray-800 text-base">选择测验内容</div>
              <button class="w-8 h-8 rounded-full hover:bg-gray-100 flex items-center justify-center text-gray-500" @click="closePracticeTypeModal">
                <i class="fa fa-times"></i>
              </button>
            </div>
            <div class="p-5 space-y-3">
              <button
                class="practice-type-option w-full flex items-center justify-between px-4 py-3 rounded-xl border border-gray-200 hover:border-blue-300 hover:bg-blue-50 transition-all"
                @click="startPracticeExam('dept')"
              >
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600">
                    <i class="fa fa-building"></i>
                  </div>
                  <div class="text-left">
                    <div class="font-semibold text-gray-800">部门知识测验</div>
                    <div class="text-xs text-gray-500">部门题库随机抽题</div>
                  </div>
                </div>
                <i class="fa fa-angle-right text-gray-400"></i>
              </button>

              <button
                class="practice-type-option w-full flex items-center justify-between px-4 py-3 rounded-xl border border-gray-200 hover:border-blue-300 hover:bg-blue-50 transition-all"
                @click="startPracticeExam('ota')"
              >
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center text-indigo-600">
                    <i class="fa fa-globe"></i>
                  </div>
                  <div class="text-left">
                    <div class="font-semibold text-gray-800">OTA测验</div>
                    <div class="text-xs text-gray-500">OTA题库随机抽题</div>
                  </div>
                </div>
                <i class="fa fa-angle-right text-gray-400"></i>
              </button>

              <button
                class="practice-type-option w-full flex items-center justify-between px-4 py-3 rounded-xl border border-gray-200 hover:border-blue-300 hover:bg-blue-50 transition-all"
                @click="startPracticeExam('all')"
              >
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center text-blue-600">
                    <i class="fa fa-cubes"></i>
                  </div>
                  <div class="text-left">
                    <div class="font-semibold text-gray-800">综合测验</div>
                    <div class="text-xs text-gray-500">全题库随机抽题</div>
                  </div>
                </div>
                <i class="fa fa-angle-right text-gray-400"></i>
              </button>
            </div>
            <div class="px-5 pb-5">
              <button class="w-full py-2.5 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium transition-all" @click="closePracticeTypeModal">
                取消
              </button>
            </div>
          </div>
        </div>
      </teleport>

      <!-- 待参加考试 -->
      <div class="mb-4 md:mb-12" v-if="!showExamStart" data-guide="exam-upcoming-section">
        <div class="flex items-center justify-between mb-3 md:mb-6">
          <div class="flex items-center">
            <div class="w-1 h-5 md:w-1.5 md:h-8 bg-orange-500 rounded-full mr-2 md:mr-4"></div>
            <h3 class="text-base md:text-2xl font-bold text-gray-800">待参加考试</h3>
          </div>
          <span class="text-xs md:text-sm text-gray-500 bg-gray-100 px-2 py-0.5 md:px-3 md:py-1 rounded-full" v-if="upcomingExams.length > 0">{{ upcomingExams.length }}场</span>
        </div>
        
        <!-- 未登录状态 -->
        <div v-if="!isLoggedIn" class="text-center py-4 md:py-6">
          <div class="text-neutral-500">
            <i class="fa fa-user-circle text-3xl md:text-4xl mb-2 md:mb-3 text-neutral-300"></i>
            <p class="text-sm md:text-lg mb-1 md:mb-2">请先登录查看考试信息</p>
            <p class="text-xs md:text-sm">登录后即可查看您的考试安排和进度</p>
          </div>
        </div>
        
        <!-- 已登录状态 -->
        <div v-else class="space-y-3 md:space-y-4">
          <div
            v-for="exam in upcomingExams"
            :key="exam.id"
            class="group bg-white rounded-xl md:rounded-2xl p-3 md:p-6 shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100 hover:border-orange-100 relative overflow-hidden"
          >
            <!-- 装饰背景 -->
            <div class="absolute top-0 right-0 w-32 md:w-64 h-32 md:h-64 bg-gradient-to-bl from-orange-50 to-transparent rounded-full -mr-10 md:-mr-20 -mt-10 md:-mt-20 opacity-50 group-hover:scale-110 transition-transform duration-700"></div>

            <div class="flex items-center gap-3 md:gap-6 relative z-10">
              <!-- 图标区域 -->
              <div class="w-10 h-10 md:w-16 md:h-16 rounded-xl md:rounded-2xl bg-orange-50 flex items-center justify-center flex-shrink-0 group-hover:bg-orange-500 transition-colors duration-300 shadow-sm">
                <span class="exam-card-glyph text-sm md:text-2xl font-bold text-orange-500 group-hover:text-white transition-colors duration-300">考</span>
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-center mb-1 md:mb-3 flex-wrap gap-1 md:gap-3">
                  <h4 class="text-sm md:text-xl font-bold text-gray-800 group-hover:text-orange-600 transition-colors truncate max-w-[120px] md:max-w-none">{{ exam.title }}</h4>
                  
                  <span class="bg-purple-50 text-purple-600 px-1.5 py-0.5 md:px-3 md:py-1 rounded-full text-[10px] md:text-xs font-medium border border-purple-100" v-if="exam.planName">
                    {{ exam.planName }}
                  </span>
                  <span class="bg-red-50 text-red-600 px-1.5 py-0.5 md:px-3 md:py-1 rounded-full text-[10px] md:text-xs font-medium border border-red-100" v-else-if="exam.required">必修</span>
                  <span class="bg-gray-100 text-gray-600 px-1.5 py-0.5 md:px-3 md:py-1 rounded-full text-[10px] md:text-xs font-medium border border-gray-200 hidden md:inline" v-else>选修</span>
                </div>

                <div class="flex flex-wrap gap-2 md:gap-6 text-xs md:text-sm text-gray-500">
                  <div class="flex items-center">
                    <i class="fa fa-clock-o mr-1 text-orange-400"></i>
                    <span>{{ exam.duration }}分钟</span>
                  </div>
                  <div class="flex items-center">
                    <i class="fa fa-file-text-o mr-1 text-orange-400"></i>
                    <span>{{ exam.questions }}题</span>
                  </div>
                  <div class="flex items-center hidden md:flex">
                    <i class="fa fa-calendar-times-o mr-1 text-red-400"></i>
                    <span>截止: {{ exam.deadline || '无' }}</span>
                  </div>
                </div>
              </div>

              <div class="flex-shrink-0">
                <button
                  class="px-3 py-1.5 md:px-8 md:py-3 bg-orange-500 text-white rounded-lg md:rounded-xl hover:bg-orange-600 transition-all duration-300 font-medium shadow-lg hover:shadow-orange-500/30 flex items-center gap-1 md:gap-2 group/btn text-xs md:text-base"
                  @click="enterFormalExam(exam)"
                >
                  <span>参加</span>
                  <i class="fa fa-pencil-square-o transform group-hover/btn:scale-110 transition-transform hidden md:inline"></i>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 已参加考试 -->
      <div v-if="!showExamStart" class="mb-4 md:mb-12" data-guide="exam-history-section">
        <div class="flex items-center justify-between mb-3 md:mb-6">
          <div class="flex items-center gap-3">
            <div class="w-1 h-5 md:w-1.5 md:h-8 bg-green-500 rounded-full mr-2 md:mr-4"></div>
            <h3 class="text-base md:text-2xl font-bold text-gray-800">考试历史</h3>
            <div class="flex items-center gap-2 ml-2 flex-wrap">
              <button
                @click="currentHistoryView = 'exam'"
                class="px-3 py-1.5 rounded-lg text-xs md:text-sm font-medium transition-all"
                :class="currentHistoryView === 'exam' ? 'bg-green-500 text-white shadow-sm' : 'bg-white border border-gray-300 text-gray-600 hover:bg-gray-50'"
              >
                考试记录
              </button>
              <button
                @click="currentHistoryView = 'practice'"
                class="px-3 py-1.5 rounded-lg text-xs md:text-sm font-medium transition-all"
                :class="currentHistoryView === 'practice' ? 'bg-blue-500 text-white shadow-sm' : 'bg-white border border-gray-300 text-gray-600 hover:bg-gray-50'"
              >
                普通测验
              </button>
              <button
                @click="currentHistoryView = 'course_quiz'"
                class="px-3 py-1.5 rounded-lg text-xs md:text-sm font-medium transition-all"
                :class="currentHistoryView === 'course_quiz' ? 'bg-slate-900 text-white shadow-sm' : 'bg-white border border-gray-300 text-gray-600 hover:bg-gray-50'"
              >
                结课测验
              </button>
            </div>
          </div>
        </div>
        
        <!-- 未登录状态 -->
        <div v-if="!isLoggedIn" class="text-center py-8 md:py-12">
          <div class="text-neutral-500">
            <i class="fa fa-history text-4xl md:text-5xl mb-3 md:mb-4 text-neutral-300"></i>
            <p class="text-sm md:text-lg mb-1 md:mb-2">请先登录查看考试记录</p>
            <p class="text-xs md:text-sm">登录后即可查看您的考试历史和成绩</p>
          </div>
        </div>
        
        <!-- 已登录状态 -->
        <div v-else>
          <!-- 考试记录视图 -->
          <div v-if="currentHistoryView === 'exam'">
            <div class="flex items-center justify-between mb-3 md:mb-4">
              <h4 class="text-sm md:text-lg font-bold text-gray-800">考试记录</h4>
              <span class="text-xs md:text-sm text-gray-400">共 {{ examTotal }} 条</span>
            </div>

              <div class="history-stats-grid grid grid-cols-2 md:grid-cols-2 gap-3 md:gap-4 mb-6 md:mb-8">
                <div class="history-stat-card bg-white rounded-xl p-4 md:p-5 border border-gray-100 hover:shadow-lg transition-all duration-300 group">
                  <div class="history-stat-icon flex items-center justify-between mb-2">
                    <div class="w-10 h-10 md:w-12 md:h-12 rounded-lg bg-blue-50 flex items-center justify-center group-hover:bg-blue-100 transition-colors">
                      <i class="fa fa-list-alt text-lg md:text-xl text-blue-500"></i>
                    </div>
                  </div>
                  <div class="history-stat-label text-xs md:text-sm text-gray-500 mb-1">考试次数</div>
                  <div class="history-stat-value text-2xl md:text-3xl font-bold text-gray-800">{{ examHistoryStats.totalAttempts || 0 }}</div>
                </div>

                <div class="history-stat-card bg-white rounded-xl p-4 md:p-5 border border-gray-100 hover:shadow-lg transition-all duration-300 group">
                  <div class="history-stat-icon flex items-center justify-between mb-2">
                    <div class="w-10 h-10 md:w-12 md:h-12 rounded-lg bg-green-50 flex items-center justify-center group-hover:bg-green-100 transition-colors">
                      <i class="fa fa-line-chart text-lg md:text-xl text-green-500"></i>
                    </div>
                  </div>
                  <div class="history-stat-label text-xs md:text-sm text-gray-500 mb-1">{{ examAverageScoreTitle }}</div>
                  <div class="history-stat-value text-2xl md:text-3xl font-bold" :class="examAverageScoreClass">{{ examAverageScoreDisplay }}</div>
                </div>

              </div>

              <div class="space-y-3 md:space-y-4">
                <div
                  v-for="record in examRecords"
                  :key="record.attemptId"
                  class="group bg-white rounded-xl p-4 md:p-5 shadow-sm hover:shadow-lg transition-all duration-300 border border-gray-100 hover:border-green-200"
                >
                  <div class="flex items-center gap-3 md:gap-4">
                    <div class="w-12 h-12 md:w-14 md:h-14 rounded-xl bg-gradient-to-br from-green-50 to-green-100 flex items-center justify-center flex-shrink-0 group-hover:from-green-100 group-hover:to-green-200 transition-all">
                      <i class="fa fa-file-text text-xl md:text-2xl text-green-600"></i>
                    </div>

                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 mb-2 flex-wrap">
                        <h4 class="text-sm md:text-lg font-bold text-gray-800 truncate max-w-[150px] md:max-w-none">
                          {{ record.examName || '正式考试' }}
                        </h4>
                        <span class="px-2 py-0.5 md:px-2.5 md:py-1 rounded-md text-xs font-medium bg-blue-100 text-blue-700">考试</span>
                      </div>

                      <div class="flex flex-wrap gap-3 md:gap-4 text-xs md:text-sm text-gray-500">
                        <div class="flex items-center">
                          <i class="fa fa-clock-o mr-1.5 text-gray-400"></i>
                          <span>{{ formatDuration(record.durationSeconds) }}</span>
                        </div>
                        <div class="flex items-center">
                          <i class="fa fa-calendar mr-1.5 text-gray-400"></i>
                          <span>{{ formatDateTime(record.submittedAt) }}</span>
                        </div>
                      </div>
                    </div>

                    <div class="flex items-center gap-3 md:gap-4 flex-shrink-0">
                      <div class="text-right">
                        <div class="text-xs text-gray-400 mb-1 hidden md:block">{{ getRecordResultTitle(record) }}</div>
                        <div class="text-xl md:text-3xl font-bold" :class="getRecordResultClass(record)">
                          {{ getRecordResultValue(record) }}
                        </div>
                      </div>
                      <button
                        @click="viewRecordDetail(record)"
                        class="px-3 py-2 md:px-4 md:py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-all text-xs md:text-sm font-medium flex items-center gap-1.5 shadow-sm hover:shadow-md"
                      >
                        <i class="fa fa-eye"></i>
                        <span class="hidden md:inline">回看</span>
                      </button>
                    </div>
                  </div>
                </div>

                <div v-if="examRecords.length === 0" class="text-center py-12 md:py-16 bg-white rounded-xl border border-gray-100">
                  <i class="fa fa-inbox text-5xl md:text-6xl text-gray-300 mb-4"></i>
                  <p class="text-base md:text-lg text-gray-500 mb-1">暂无考试记录</p>
                  <p class="text-sm text-gray-400">完成考试后，记录将显示在这里</p>
                </div>

                <div v-if="examTotalPages > 1" class="flex items-center justify-center gap-2 md:gap-3 pt-2">
                  <button
                    class="px-3 py-2 rounded-lg text-xs md:text-sm font-medium border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="examPageNum === 1"
                    @click="changeExamPage(examPageNum - 1)"
                  >上一页</button>
                  <span class="text-xs md:text-sm text-gray-500">第 {{ examPageNum }} / {{ examTotalPages }} 页</span>
                  <button
                    class="px-3 py-2 rounded-lg text-xs md:text-sm font-medium border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="examPageNum >= examTotalPages"
                    @click="changeExamPage(examPageNum + 1)"
                  >下一页</button>
                </div>
              </div>
          </div>

          <!-- 普通测验记录视图 -->
          <div v-if="currentHistoryView === 'practice'">
            <div class="flex items-center justify-between mb-3 md:mb-4">
              <h4 class="text-sm md:text-lg font-bold text-gray-800">普通测验记录</h4>
              <span class="text-xs md:text-sm text-gray-400">共 {{ practiceTotal }} 条</span>
            </div>

              <div class="history-stats-grid grid grid-cols-2 md:grid-cols-2 gap-3 md:gap-4 mb-6 md:mb-8">
                <div class="history-stat-card bg-white rounded-xl p-4 md:p-5 border border-gray-100 hover:shadow-lg transition-all duration-300 group">
                  <div class="history-stat-icon flex items-center justify-between mb-2">
                    <div class="w-10 h-10 md:w-12 md:h-12 rounded-lg bg-blue-50 flex items-center justify-center group-hover:bg-blue-100 transition-colors">
                      <i class="fa fa-list-alt text-lg md:text-xl text-blue-500"></i>
                    </div>
                  </div>
                  <div class="history-stat-label text-xs md:text-sm text-gray-500 mb-1">测验次数</div>
                  <div class="history-stat-value text-2xl md:text-3xl font-bold text-gray-800">{{ practiceHistoryStats.totalAttempts || 0 }}</div>
                </div>

                <div class="history-stat-card bg-white rounded-xl p-4 md:p-5 border border-gray-100 hover:shadow-lg transition-all duration-300 group">
                  <div class="history-stat-icon flex items-center justify-between mb-2">
                    <div class="w-10 h-10 md:w-12 md:h-12 rounded-lg bg-green-50 flex items-center justify-center group-hover:bg-green-100 transition-colors">
                      <i class="fa fa-line-chart text-lg md:text-xl text-green-500"></i>
                    </div>
                  </div>
                  <div class="history-stat-label text-xs md:text-sm text-gray-500 mb-1">平均分</div>
                  <div class="history-stat-value text-2xl md:text-3xl font-bold text-green-600">{{ practiceHistoryStats.averageScore || 0 }}</div>
                </div>

              </div>

              <div class="space-y-3 md:space-y-4">
                <div
                  v-for="record in practiceRecords"
                  :key="record.attemptId"
                  class="group bg-white rounded-xl p-4 md:p-5 shadow-sm hover:shadow-lg transition-all duration-300 border border-gray-100 hover:border-green-200"
                >
                  <div class="flex items-center gap-3 md:gap-4">
                    <div class="w-12 h-12 md:w-14 md:h-14 rounded-xl bg-gradient-to-br from-green-50 to-green-100 flex items-center justify-center flex-shrink-0 group-hover:from-green-100 group-hover:to-green-200 transition-all">
                      <i class="fa fa-file-text text-xl md:text-2xl text-green-600"></i>
                    </div>

                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 mb-2 flex-wrap">
                        <h4 class="text-sm md:text-lg font-bold text-gray-800 truncate max-w-[150px] md:max-w-none">
                          {{ record.examName || '平时测验' }}
                        </h4>
                        <span class="px-2 py-0.5 md:px-2.5 md:py-1 rounded-md text-xs font-medium bg-blue-100 text-blue-700">普通测验</span>
                      </div>

                      <div class="flex flex-wrap gap-3 md:gap-4 text-xs md:text-sm text-gray-500">
                        <div class="flex items-center">
                          <i class="fa fa-clock-o mr-1.5 text-gray-400"></i>
                          <span>{{ formatDuration(record.durationSeconds) }}</span>
                        </div>
                        <div class="flex items-center">
                          <i class="fa fa-calendar mr-1.5 text-gray-400"></i>
                          <span>{{ formatDateTime(record.submittedAt) }}</span>
                        </div>
                      </div>
                    </div>

                    <div class="flex items-center gap-3 md:gap-4 flex-shrink-0">
                      <div class="text-right">
                        <div class="text-xs text-gray-400 mb-1 hidden md:block">{{ getRecordResultTitle(record) }}</div>
                        <div class="text-xl md:text-3xl font-bold" :class="getRecordResultClass(record)">
                          {{ getRecordResultValue(record) }}
                        </div>
                      </div>
                      <button
                        @click="viewRecordDetail(record)"
                        class="px-3 py-2 md:px-4 md:py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-all text-xs md:text-sm font-medium flex items-center gap-1.5 shadow-sm hover:shadow-md"
                      >
                        <i class="fa fa-eye"></i>
                        <span class="hidden md:inline">回看</span>
                      </button>
                    </div>
                  </div>
                </div>

                <div v-if="practiceRecords.length === 0" class="text-center py-12 md:py-16 bg-white rounded-xl border border-gray-100">
                  <i class="fa fa-inbox text-5xl md:text-6xl text-gray-300 mb-4"></i>
                  <p class="text-base md:text-lg text-gray-500 mb-1">暂无普通测验记录</p>
                  <p class="text-sm text-gray-400">完成随机测验后，记录将显示在这里</p>
                </div>

                <div v-if="practiceTotalPages > 1" class="flex items-center justify-center gap-2 md:gap-3 pt-2">
                  <button
                    class="px-3 py-2 rounded-lg text-xs md:text-sm font-medium border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="practicePageNum === 1"
                    @click="changePracticePage(practicePageNum - 1)"
                  >上一页</button>
                  <span class="text-xs md:text-sm text-gray-500">第 {{ practicePageNum }} / {{ practiceTotalPages }} 页</span>
                  <button
                    class="px-3 py-2 rounded-lg text-xs md:text-sm font-medium border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="practicePageNum >= practiceTotalPages"
                    @click="changePracticePage(practicePageNum + 1)"
                  >下一页</button>
                </div>
              </div>
            </div>
          </div>

          <!-- 结课测验记录视图 -->
          <div v-if="currentHistoryView === 'course_quiz'">
            <div class="flex items-center justify-between mb-3 md:mb-4">
              <h4 class="text-sm md:text-lg font-bold text-gray-800">结课测验记录</h4>
              <span class="text-xs md:text-sm text-gray-400">共 {{ courseQuizTotal }} 条</span>
            </div>

              <div class="history-stats-grid grid grid-cols-2 md:grid-cols-2 gap-3 md:gap-4 mb-6 md:mb-8">
                <div class="history-stat-card bg-white rounded-xl p-4 md:p-5 border border-gray-100 hover:shadow-lg transition-all duration-300 group">
                  <div class="history-stat-icon flex items-center justify-between mb-2">
                    <div class="w-10 h-10 md:w-12 md:h-12 rounded-lg bg-slate-100 flex items-center justify-center group-hover:bg-slate-200 transition-colors">
                      <i class="fa fa-video-camera text-lg md:text-xl text-slate-700"></i>
                    </div>
                  </div>
                  <div class="history-stat-label text-xs md:text-sm text-gray-500 mb-1">结课次数</div>
                  <div class="history-stat-value text-2xl md:text-3xl font-bold text-gray-800">{{ courseQuizHistoryStats.totalAttempts || 0 }}</div>
                </div>

                <div class="history-stat-card bg-white rounded-xl p-4 md:p-5 border border-gray-100 hover:shadow-lg transition-all duration-300 group">
                  <div class="history-stat-icon flex items-center justify-between mb-2">
                    <div class="w-10 h-10 md:w-12 md:h-12 rounded-lg bg-emerald-50 flex items-center justify-center group-hover:bg-emerald-100 transition-colors">
                      <i class="fa fa-trophy text-lg md:text-xl text-emerald-600"></i>
                    </div>
                  </div>
                  <div class="history-stat-label text-xs md:text-sm text-gray-500 mb-1">平均分</div>
                  <div class="history-stat-value text-2xl md:text-3xl font-bold text-emerald-600">{{ courseQuizHistoryStats.averageScore || 0 }}</div>
                </div>

              </div>

              <div class="space-y-3 md:space-y-4">
                <div
                  v-for="record in courseQuizRecords"
                  :key="record.attemptId"
                  class="group bg-white rounded-xl p-4 md:p-5 shadow-sm hover:shadow-lg transition-all duration-300 border border-gray-100 hover:border-slate-300"
                >
                  <div class="flex items-center gap-3 md:gap-4">
                    <div class="w-12 h-12 md:w-14 md:h-14 rounded-xl bg-gradient-to-br from-slate-100 to-slate-200 flex items-center justify-center flex-shrink-0 group-hover:from-slate-200 group-hover:to-slate-300 transition-all">
                      <i class="fa fa-play-circle text-xl md:text-2xl text-slate-700"></i>
                    </div>

                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 mb-2 flex-wrap">
                        <h4 class="text-sm md:text-lg font-bold text-gray-800 truncate max-w-[150px] md:max-w-none">
                          {{ record.examName || '结课测验' }}
                        </h4>
                        <span class="px-2 py-0.5 md:px-2.5 md:py-1 rounded-md text-xs font-medium bg-slate-900 text-white">结课测验</span>
                      </div>

                      <div class="flex flex-wrap gap-3 md:gap-4 text-xs md:text-sm text-gray-500">
                        <div class="flex items-center">
                          <i class="fa fa-clock-o mr-1.5 text-gray-400"></i>
                          <span>{{ formatDuration(record.durationSeconds) }}</span>
                        </div>
                        <div class="flex items-center">
                          <i class="fa fa-calendar mr-1.5 text-gray-400"></i>
                          <span>{{ formatDateTime(record.submittedAt) }}</span>
                        </div>
                      </div>
                    </div>

                    <div class="flex items-center gap-3 md:gap-4 flex-shrink-0">
                      <div class="text-right">
                        <div class="text-xs text-gray-400 mb-1 hidden md:block">{{ getRecordResultTitle(record) }}</div>
                        <div class="text-xl md:text-3xl font-bold" :class="getRecordResultClass(record)">
                          {{ getRecordResultValue(record) }}
                        </div>
                      </div>
                      <button
                        @click="viewRecordDetail(record)"
                        class="px-3 py-2 md:px-4 md:py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-all text-xs md:text-sm font-medium flex items-center gap-1.5 shadow-sm hover:shadow-md"
                      >
                        <i class="fa fa-eye"></i>
                        <span class="hidden md:inline">回看</span>
                      </button>
                    </div>
                  </div>
                </div>

                <div v-if="courseQuizRecords.length === 0" class="text-center py-12 md:py-16 bg-white rounded-xl border border-gray-100">
                  <i class="fa fa-film text-5xl md:text-6xl text-gray-300 mb-4"></i>
                  <p class="text-base md:text-lg text-gray-500 mb-1">暂无结课测验记录</p>
                  <p class="text-sm text-gray-400">完成视频课程后的自动测验后，记录将显示在这里</p>
                </div>

                <div v-if="courseQuizTotalPages > 1" class="flex items-center justify-center gap-2 md:gap-3 pt-2">
                  <button
                    class="px-3 py-2 rounded-lg text-xs md:text-sm font-medium border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="courseQuizPageNum === 1"
                    @click="changeCourseQuizPage(courseQuizPageNum - 1)"
                  >上一页</button>
                  <span class="text-xs md:text-sm text-gray-500">第 {{ courseQuizPageNum }} / {{ courseQuizTotalPages }} 页</span>
                  <button
                    class="px-3 py-2 rounded-lg text-xs md:text-sm font-medium border border-gray-200 bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="courseQuizPageNum >= courseQuizTotalPages"
                    @click="changeCourseQuizPage(courseQuizPageNum + 1)"
                  >下一页</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

    <!-- 全局提示框 -->
    <div
      id="toast"
      class="fixed bottom-6 right-6 px-6 py-3 rounded-lg shadow-lg transform translate-y-20 opacity-0 transition-all duration-300 flex items-center z-50 hidden"
      :class="toastClass"
    >
      <i :class="toastIcon" class="mr-3 text-xl"></i>
      <span>{{ toastMessage }}</span>
    </div>
  </div>
</template>


<script setup>
import { ref, onMounted, nextTick, computed, onUnmounted } from 'vue';
import { useRouter } from 'vue-router'; // 若需路由跳转，确保项目安装了vue-router
import ExamStart from './ExamStart.vue';
import HeaderBar from '@/components/HeaderBar.vue';
import { getUserInfo } from '@/api/auth';
import { getMyUpcomingExams, getMyCompletedExams } from '@/api/exam';
import { getMyLearningPlans, getMyCompletions } from '@/api/learningPlan';
import { getMyExamRecords, getMyExamStatsByType, getExamDetail } from '@/api/examRecord';
import { getUserId } from '@/utils/userStorage';
import logger from '@/utils/logger'
import { getResultDisplayTextClass, getResultDisplayTitle, getResultDisplayValue, normalizeLevelThresholds, normalizeResultDisplayMode } from '../utils/resultDisplay';
// 综合平时测验数据
const practiceExams = ref([
  {
    id: 'practice-001',
    title: '综合平时测验',
    duration: 60,
    questions: 20,
    isRandom: true,
  },
]);

// 待参加考试数据（从API获取）
const upcomingExams = ref([]);

// 已参加考试数据（从API获取）
const completedExams = ref([]);

// 历史记录相关
const examHistoryStats = ref({});

// 历史记录视图切换 ('exam' | 'practice' | 'course_quiz')
const currentHistoryView = ref('exam');

const HISTORY_PAGE_SIZE = 10;

const examRecords = ref([]);
const allPracticeRecords = ref([]);
const examTotal = ref(0);
const examPageNum = ref(1);
const practicePageNum = ref(1);
const courseQuizPageNum = ref(1);

const examTotalPages = computed(() => Math.ceil(examTotal.value / HISTORY_PAGE_SIZE));
const isCourseQuizRecord = (record) => record?.attemptScene === 'course_quiz' || String(record?.examName || '').includes('结课测验');
const filteredPracticeRecords = computed(() => allPracticeRecords.value.filter(record => !isCourseQuizRecord(record)));
const filteredCourseQuizRecords = computed(() => allPracticeRecords.value.filter(record => isCourseQuizRecord(record)));
const practiceTotal = computed(() => filteredPracticeRecords.value.length);
const courseQuizTotal = computed(() => filteredCourseQuizRecords.value.length);
const practiceTotalPages = computed(() => Math.max(1, Math.ceil(practiceTotal.value / HISTORY_PAGE_SIZE)));
const courseQuizTotalPages = computed(() => Math.max(1, Math.ceil(courseQuizTotal.value / HISTORY_PAGE_SIZE)));
const paginateRecords = (list, pageNum) => {
  const start = (pageNum - 1) * HISTORY_PAGE_SIZE;
  return list.slice(start, start + HISTORY_PAGE_SIZE);
};
const practiceRecords = computed(() => paginateRecords(filteredPracticeRecords.value, practicePageNum.value));
const courseQuizRecords = computed(() => paginateRecords(filteredCourseQuizRecords.value, courseQuizPageNum.value));
const practiceHistoryStats = ref({ totalAttempts: 0, averageScore: 0, hasLevelDisplay: false });
const courseQuizHistoryStats = ref({ totalAttempts: 0, averageScore: 0, hasLevelDisplay: false });
const allPracticeHistoryStats = ref({ totalAttempts: 0, averageScore: 0, hasLevelDisplay: false });
const hasLevelModeExamStats = computed(() => Boolean(examHistoryStats.value?.hasLevelDisplay));
const allTotalAttempts = computed(() => {
  const fromStats = (examHistoryStats.value?.totalAttempts || 0) + (allPracticeHistoryStats.value?.totalAttempts || 0);
  if (fromStats > 0) return fromStats;
  return (examTotal.value || 0) + (allPracticeRecords.value.length || 0);
});

const allAverageScore = computed(() => {
  const examCount = examHistoryStats.value?.totalAttempts || 0;
  const practiceCount = allPracticeHistoryStats.value?.totalAttempts || 0;
  const total = examCount + practiceCount;
  if (total <= 0) return 0;
  const examAvg = Number(examHistoryStats.value?.averageScore || 0);
  const practiceAvg = Number(allPracticeHistoryStats.value?.averageScore || 0);
  const weighted = (examAvg * examCount + practiceAvg * practiceCount) / total;
  return Math.round(weighted);
});
const allAverageScoreTitle = computed(() => (hasLevelModeExamStats.value ? '综合结果' : '总平均分'));
const allAverageScoreDisplay = computed(() => (hasLevelModeExamStats.value ? '按规则展示' : allAverageScore.value));
const allAverageScoreClass = computed(() => (hasLevelModeExamStats.value ? 'text-amber-600' : 'text-gray-800'));
const showAllAverageScoreUnit = computed(() => !hasLevelModeExamStats.value);
const examAverageScoreTitle = computed(() => (hasLevelModeExamStats.value ? '结果统计' : '平均分'));
const examAverageScoreDisplay = computed(() => (hasLevelModeExamStats.value ? '按规则展示' : (examHistoryStats.value?.averageScore || 0)));
const examAverageScoreClass = computed(() => (hasLevelModeExamStats.value ? 'text-amber-600' : 'text-green-600'));

// 格式化时长
const formatDuration = (seconds) => {
  if (!seconds) return '0分钟';
  const minutes = Math.floor(seconds / 60);
  const secs = seconds % 60;
  if (minutes > 0) {
    return secs > 0 ? `${minutes}分${secs}秒` : `${minutes}分钟`;
  }
  return `${secs}秒`;
};

// 格式化日期时间
const formatDateTime = (dateStr) => {
  if (!dateStr) return '-';
  const date = new Date(dateStr);
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// 查看记录详情
const viewRecordDetail = async (record) => {
  try {
    logger.debug('🔍 查看考试详情:', record);
    
    // 调用API获取考试详情
    const res = await getExamDetail(record.attemptId);
    
    if (res?.data?.code === 200 && res.data.data) {
      const detail = res.data.data;
      logger.debug('✅ 获取考试详情成功:', detail);
      
      // 跳转到回看页面，传递考试详情数据
      router.push({
        name: 'ExamReview',
        params: { attemptId: record.attemptId },
        state: { examDetail: detail }
      });
    } else {
      showToast('获取考试详情失败', 'error');
    }
  } catch (error) {
    logger.error('❌ 查看考试详情失败:', error);
    showToast('获取考试详情失败，请稍后重试', 'error');
  }
};

// 加载历史记录
const loadHistoryRecords = async () => {
  if (!isLoggedIn.value) {
    logger.debug('📋 用户未登录，跳过加载历史记录');
    return;
  }
  
  try {
    await Promise.all([loadExamRecords(), loadPracticeRecords(), loadHistoryStats()]);
    
    if (examTotal.value > 0) {
      currentHistoryView.value = 'exam';
      logger.debug('📋 有考试记录，自动切换到考试视图');
    } else if (courseQuizTotal.value > 0) {
      currentHistoryView.value = 'course_quiz';
      logger.debug('📋 无正式考试，自动切换到结课测验视图');
    } else if (practiceTotal.value > 0) {
      currentHistoryView.value = 'practice';
      logger.debug('📋 无正式考试，自动切换到普通测验视图');
    }
  } catch (error) {
    logger.error('📋 加载历史记录失败:', error);
  }
};

const loadHistoryStats = async () => {
  try {
    const statsRes = await getMyExamStatsByType();
    if (statsRes?.data?.code === 200) {
      const data = statsRes.data.data || {};
      examHistoryStats.value = data.exam || {};
      practiceHistoryStats.value = data.practiceGeneral || data.practice || { totalAttempts: 0, averageScore: 0, hasLevelDisplay: false };
      courseQuizHistoryStats.value = data.courseQuiz || { totalAttempts: 0, averageScore: 0, hasLevelDisplay: false };
      allPracticeHistoryStats.value = data.practice || data.practiceGeneral || { totalAttempts: 0, averageScore: 0, hasLevelDisplay: false };
    }
  } catch (e) {
    examHistoryStats.value = {};
    practiceHistoryStats.value = { totalAttempts: 0, averageScore: 0, hasLevelDisplay: false };
    courseQuizHistoryStats.value = { totalAttempts: 0, averageScore: 0, hasLevelDisplay: false };
    allPracticeHistoryStats.value = { totalAttempts: 0, averageScore: 0, hasLevelDisplay: false };
  }
};

const loadExamRecords = async () => {
  try {
    const userId = userInfo.value?.userId || userInfo.value?.id;
    const res = await getMyCompletedExams(userId);
    if (res?.data?.code === 200) {
      const rows = (res.data.data || []).map((row) => ({
        ...row,
        resultDisplayMode: normalizeResultDisplayMode(row.resultDisplayMode),
        ...normalizeLevelThresholds(row)
      }));
      examTotal.value = rows.length;
      const start = (examPageNum.value - 1) * HISTORY_PAGE_SIZE;
      examRecords.value = rows.slice(start, start + HISTORY_PAGE_SIZE);
    } else {
      examRecords.value = [];
      examTotal.value = 0;
    }
  } catch (e) {}
};

const loadPracticeRecords = async () => {
  try {
    const res = await getMyExamRecords({
      pageNum: 1,
      pageSize: 500,
      attemptType: 'practice'
    });
    if (res?.data?.code === 200) {
      const rows = res.data.rows || res.data.data || [];
      allPracticeRecords.value = rows.map((row) => ({
        ...row,
        resultDisplayMode: normalizeResultDisplayMode(row.resultDisplayMode),
        ...normalizeLevelThresholds(row)
      }));
      if (practicePageNum.value > practiceTotalPages.value) {
        practicePageNum.value = practiceTotalPages.value;
      }
      if (courseQuizPageNum.value > courseQuizTotalPages.value) {
        courseQuizPageNum.value = courseQuizTotalPages.value;
      }
    } else {
      allPracticeRecords.value = [];
    }
  } catch (e) {
    allPracticeRecords.value = [];
  }
};

const changeExamPage = async (nextPage) => {
  const target = Math.max(1, nextPage);
  examPageNum.value = target;
  await loadExamRecords();
};

const changePracticePage = async (nextPage) => {
  const target = Math.max(1, nextPage);
  practicePageNum.value = target;
};

const changeCourseQuizPage = async (nextPage) => {
  const target = Math.max(1, nextPage);
  courseQuizPageNum.value = target;
};

// 计算平均分
const averageScore = computed(() => {
  if (completedExams.value.length === 0) return 0;
  const total = completedExams.value.reduce((sum, exam) => sum + (exam.score || 0), 0);
  return Math.round(total / completedExams.value.length);
});

// 加载考试数据
const loadExams = async () => {
  if (!isLoggedIn.value || !userInfo.value) {
    upcomingExams.value = [];
    completedExams.value = [];
    return;
  }
  
  const userId = userInfo.value.userId || userInfo.value.id;
  if (!userId) {
    logger.warn('无法获取用户ID');
    return;
  }
  
  try {
    const officialUpcoming = [];
    const officialCompleted = [];
    
    const upcomingRes = await getMyUpcomingExams(userId);
    if (upcomingRes?.data?.code === 200) {
      const exams = upcomingRes.data.data || [];
      officialUpcoming.push(
        ...exams.map(exam => ({
          id: exam.id,
          title: exam.name,
          required: false,
          duration: exam.duration || exam.timeLimit || 60, // 使用考试设置的时长，默认60分钟
          passScore: exam.passScore || exam.passingScore || exam.qualifiedScore || 80,
          resultDisplayMode: normalizeResultDisplayMode(exam.resultDisplayMode),
          ...normalizeLevelThresholds(exam),
          questions: resolveQuestionCount(exam),
          deadline: formatDate(exam.endTime),
          startTime: exam.startTime,
          endTime: exam.endTime,
          source: 'official'
        }))
      );
    }
    
    const completedRes = await getMyCompletedExams(userId);
    if (completedRes?.data?.code === 200) {
      const exams = completedRes.data.data || [];
      officialCompleted.push(
        ...exams.map(exam => ({
          id: exam.id,
          title: exam.name,
          duration: exam.duration || exam.timeLimit || 60, // 使用考试设置的时长，默认60分钟
          passScore: exam.passScore || exam.passingScore || exam.qualifiedScore || 80,
          resultDisplayMode: normalizeResultDisplayMode(exam.resultDisplayMode),
          ...normalizeLevelThresholds(exam),
          questions: resolveQuestionCount(exam),
          date: formatDate(exam.submittedAt || exam.endTime),
          score: exam.score ?? 0,
          passed: exam.passed ?? false,
          source: 'official'
        }))
      );
    }

    const planResult = await loadPlanExamTasks();
    
    const mergedUpcoming = mergeExamLists(officialUpcoming, planResult.upcoming);
    const mergedCompleted = mergeExamLists(officialCompleted, planResult.completed);

    // 正式考试是否还能继续参加应以后端 upcoming 查询为准。
    // 这里只去掉学习计划里同一个待办项被同时标记为已完成的重复项。
    const completedPlanItemIds = new Set(
      mergedCompleted
        .filter(exam => exam.source === 'plan')
        .map(exam => exam.planItemId)
        .filter(Boolean)
    );

    upcomingExams.value = mergedUpcoming.filter(exam => {
      if (exam.source === 'plan' && exam.planItemId && completedPlanItemIds.has(exam.planItemId)) {
        return false;
      }
      return true;
    });

    completedExams.value = mergedCompleted;

    logger.debug('✅ 考试列表加载成功:', {
      upcoming: upcomingExams.value.length,
      completed: completedExams.value.length
    });
  } catch (error) {
    logger.error('加载考试数据失败:', error);
    showToast('加载考试数据失败', 'error');
  }
};

// 计算考试时长（分钟）
const calculateDuration = (startTime, endTime) => {
  if (!startTime || !endTime) return 60;
  const start = new Date(startTime);
  const end = new Date(endTime);
  const diffMs = end - start;
  return Math.round(diffMs / (1000 * 60)); // 转换为分钟
};

// 解析题目数量（从remark字段中解析题目ID列表）
const parseQuestionCount = (remark) => {
  if (!remark || remark.trim() === '') return 0;
  const ids = remark.split(',').filter(id => id && id.trim() !== '');
  return ids.length;
};

const resolveQuestionCount = (exam = {}) => {
  const directCount = [
    exam.questionCount,
    exam.totalQuestions,
    exam.questions,
    exam.questionTotal,
  ].find((value) => Number.isFinite(Number(value)) && Number(value) > 0);

  if (directCount !== undefined) {
    return Number(directCount);
  }

  return parseQuestionCount(exam.remark || '');
};

// 格式化日期
const formatDate = (dateStr) => {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const getExamKey = (exam) => {
  return `${exam.source || 'official'}-${exam.planItemId || exam.id}`;
};

const mergeExamLists = (primary = [], secondary = []) => {
  const map = new Map();
  const pushExam = (exam) => {
    if (!exam) return;
    map.set(getExamKey(exam), exam);
  };
  primary.forEach(pushExam);
  secondary.forEach(pushExam);
  return Array.from(map.values());
};

const loadPlanExamTasks = async () => {
  const result = { upcoming: [], completed: [] };
  try {
    const [plansResp, completionsResp] = await Promise.all([
      getMyLearningPlans(),
      getMyCompletions()
    ]);
    const plans = Array.isArray(plansResp?.data)
      ? plansResp.data
      : plansResp?.data?.data || [];
    const completions = Array.isArray(completionsResp?.data)
      ? completionsResp.data
      : completionsResp?.data?.data || [];
    const completionMap = new Map();
    completions.forEach(record => {
      const key = record.planItemId || record.itemId;
      if (key) {
        completionMap.set(key, record);
      }
    });

    plans.forEach(plan => {
      if (!Array.isArray(plan.planItems)) return;
      plan.planItems.forEach(item => {
        if (!['exam', 'quiz'].includes(item.contentType)) return;
        const normalized = normalizePlanExam(plan, item, completionMap.get(item.itemId));
        if (normalized.status === 'completed') {
          result.completed.push(normalized);
        } else {
          result.upcoming.push(normalized);
        }
      });
    });
  } catch (error) {
    logger.error('同步学习计划考试失败:', error);
  }
  return result;
};

const normalizePlanExam = (plan, item, completion) => {
  const completed = !!completion || item.completed === true || item.status === 'completed';
  const score = completion?.score ?? completion?.examScore ?? item.score ?? null;
  const examId = item.contentId || item.examId || item.itemId;
  const passScore = completion?.passScore || item.passScore || 60;
  return {
    id: examId,
    examContentId: examId,
    title: item.title || plan.title || '学习计划考试',
    required: item.isRequired !== false,
    duration: item.duration || 60,
    passScore,
    resultDisplayMode: normalizeResultDisplayMode(completion?.resultDisplayMode ?? item.resultDisplayMode),
    ...normalizeLevelThresholds(completion || item || {}),
    questions: item.questionCount || parseQuestionCount(item.remark || ''),
    deadline: item.dueDate ? formatDate(item.dueDate) : formatDate(plan.endDate),
    date: completion?.completedAt ? formatDate(completion.completedAt) : (completed ? formatDate(item.completedAt || plan.endDate) : ''),
    score,
    passed: completion?.isPassed !== undefined
      ? !!completion.isPassed
      : (score != null ? score >= passScore : null),
    status: completed ? 'completed' : 'pending',
    planId: plan.planId || plan.id,
    planItemId: item.itemId,
    planName: plan.title || plan.planName,
    description: plan.description || '',
    source: 'plan'
  };
};

const getScoreColor = (score) => {
  if (score == null) return 'text-neutral-500';
  if (score >= 90) return 'text-green-600';
  if (score >= 60) return 'text-blue-600';
  return 'text-red-500';
};

const getRecordResultTitle = (record) => getResultDisplayTitle(record?.resultDisplayMode);
const getRecordResultValue = (record) => getResultDisplayValue(record?.score, record?.resultDisplayMode, record || {});
const getRecordResultClass = (record) => getResultDisplayTextClass(record?.score, record?.resultDisplayMode, record || {});

// 提示框状态
const toastMessage = ref('');
const toastIcon = ref('');
const toastClass = ref('');

// 路由实例（若项目使用路由）
const router = useRouter();

// 内嵌正式考试显示控制
const showExamStart = ref(false);
const selectedExamId = ref(null);

// 登录状态
const isLoggedIn = ref(false);
const userInfo = ref(null);

const getStorageUserId = () => {
  const currentUserId = userInfo.value?.userId || userInfo.value?.id || getUserId();
  if (currentUserId === null || currentUserId === undefined || currentUserId === '') return 'guest';
  return String(currentUserId);
};

const isValidUserInfo = (value) => {
  return !!(value && typeof value === 'object' && (value.userId || value.id));
};

const unifiedLogout = (reason = '') => {
  if (reason) {
    logger.warn(`登录态失效，已执行统一退出: ${reason}`);
  }
  localStorage.removeItem('authToken');
  localStorage.removeItem('userInfo');
  isLoggedIn.value = false;
  userInfo.value = null;
};

// 检查登录状态
const checkLoginStatus = async () => {
  const token = localStorage.getItem('authToken');
  if (!token) {
    unifiedLogout('缺少 token');
    return false;
  }

  try {
    const storedUserInfo = localStorage.getItem('userInfo');
    
    if (storedUserInfo) {
      try {
        const parsedUserInfo = JSON.parse(storedUserInfo);
        if (isValidUserInfo(parsedUserInfo)) {
          userInfo.value = parsedUserInfo;
          isLoggedIn.value = true;
          return true;
        }
      } catch (e) {
        logger.warn('解析本地用户信息失败:', e);
      }
    }
    
    const response = await getUserInfo();
    const remoteUserInfo = response?.data?.user || response?.data?.data;
    if (response?.data?.code === 200 && isValidUserInfo(remoteUserInfo)) {
      isLoggedIn.value = true;
      userInfo.value = {
        ...remoteUserInfo,
        profileCompletion: response.data.profileCompletion || remoteUserInfo?.profileCompletion || userInfo.value?.profileCompletion || null
      };
      localStorage.setItem('userInfo', JSON.stringify(userInfo.value));
      return true;
    }
    unifiedLogout('用户信息无效');
    return false;
  } catch (error) {
    logger.error('获取用户信息失败:', error);
    unifiedLogout('获取用户信息失败');
    return false;
  }
};

// 显示全局提示
const showToast = (message, type = 'info') => {
  toastMessage.value = message;

  // 根据类型设置样式和图标
  switch (type) {
    case 'success':
      toastClass.value = 'bg-success/90 text-white';
      toastIcon.value = 'fa fa-check-circle';
      break;
    case 'error':
      toastClass.value = 'bg-danger/90 text-white';
      toastIcon.value = 'fa fa-times-circle';
      break;
    case 'warning':
      toastClass.value = 'bg-warning/90 text-white';
      toastIcon.value = 'fa fa-exclamation-circle';
      break;
    default:
      toastClass.value = 'bg-primary/90 text-white';
      toastIcon.value = 'fa fa-info-circle';
  }

  // 显示提示框（带动画）
  const toastEl = document.getElementById('toast');
  toastEl.classList.remove('hidden');
  setTimeout(() => {
    toastEl.classList.remove('translate-y-20', 'opacity-0');
  }, 10);

  // 3秒后隐藏
  setTimeout(() => {
    toastEl.classList.add('translate-y-20', 'opacity-0');
    setTimeout(() => {
      toastEl.classList.add('hidden');
    }, 300);
  }, 3000);
};

// 已移除“开始考试”按钮

// 「开始测验」跳转综合平时测验（随机抽题）
const enterPracticeExam = (examId) => {
  const exam = practiceExams.value.find((item) => item.id === examId);
  if (!exam) return;
  // 跳转到考试开始页，使用随机抽题功能
  const category = '综合'; // 综合分类，随机抽取所有分类的题目
  const limit = exam.questions; // 使用测验设定的题目数量
  router.push({ path: '/online-exam/start', query: { category, limit, random: true } });
};

// 「参加考试」跳转正式考试界面（固定题目，不使用随机抽题）
const enterFormalExam = (exam) => {
  if (!exam) {
    showToast('未找到该考试', 'warning');
    return;
  }
  const examId = exam.examContentId || exam.id;
  if (!examId) {
    showToast('该考试缺少试卷信息', 'warning');
    return;
  }
  // 跳转到考试开始页，使用考试ID来加载固定题目
  const query = {
    examId: examId,
    title: exam.title,
    limit: exam.questions,
    random: false
  };
  if (exam.duration !== undefined && exam.duration !== null) {
    query.duration = exam.duration;
  }
  if (exam.passScore !== undefined && exam.passScore !== null) {
    query.passScore = exam.passScore;
  }
  router.push({
    path: '/online-exam/start',
    query
  });
};

// 监听登录事件
const handleUserLogin = async (event) => {
  logger.debug('收到登录事件:', event.detail);
  const token = localStorage.getItem('authToken');
  if (!token || !isValidUserInfo(event.detail)) {
    const ok = await checkLoginStatus();
    if (!ok) {
      unifiedLogout('登录事件缺少有效 token 或用户信息');
      return;
    }
  } else {
    isLoggedIn.value = true;
    userInfo.value = {
      ...event.detail,
      profileCompletion: event.detail?.profileCompletion || userInfo.value?.profileCompletion || null
    };
    localStorage.setItem('userInfo', JSON.stringify(userInfo.value));
  }
  examPageNum.value = 1;
  practicePageNum.value = 1;
  await loadExams();
  await loadHistoryRecords();
};

const handleUserLogout = () => {
  clearExamStorage();
  unifiedLogout('收到登出事件');
};

const handleExamFinished = async () => {
  showExamStart.value = false;
  selectedExamId.value = null;
  await loadExams();
  await loadHistoryRecords();
};

const showPracticeTypeModal = ref(false);
const pendingPracticeExam = ref(null);

const clearExamSessionCache = (category, limit, bank) => {
  const userId = getStorageUserId();
  const key = `exam_session_u_${userId}_${bank || 'default'}_${category || 'default'}_${limit || 20}`;
  const legacyKey = `exam_session_${bank || 'default'}_${category || 'default'}_${limit || 20}`;
  try {
    sessionStorage.removeItem(key);
    sessionStorage.removeItem(legacyKey);
  } catch (e) {}
};

const clearExamStorage = () => {
  try {
    const sessionKeys = [];
    for (let i = 0; i < sessionStorage.length; i += 1) {
      const key = sessionStorage.key(i);
      if (key && key.startsWith('exam_session_')) {
        sessionKeys.push(key);
      }
    }
    sessionKeys.forEach((key) => sessionStorage.removeItem(key));

    const localKeys = [];
    for (let i = 0; i < localStorage.length; i += 1) {
      const key = localStorage.key(i);
      if (key && key.startsWith('exam_progress_')) {
        localKeys.push(key);
      }
    }
    localKeys.forEach((key) => localStorage.removeItem(key));
  } catch (e) {}
};

const openPracticeTypeModal = (examId) => {
  const exam = practiceExams.value.find((item) => item.id === examId);
  if (!exam) return;
  pendingPracticeExam.value = exam;
  showPracticeTypeModal.value = true;
};

const closePracticeTypeModal = () => {
  showPracticeTypeModal.value = false;
  pendingPracticeExam.value = null;
};

const startPracticeExam = (type) => {
  const exam = pendingPracticeExam.value;
  if (!exam) return;

  const limit = exam.questions || 20;
  let category = '综合';

  if (type === 'dept') {
    category = '部门题库';
    clearExamSessionCache(category, limit, 'dept');
    closePracticeTypeModal();
    router.push({ path: '/online-exam/start', query: { category, limit, random: true, bank: 'dept', title: '部门知识测验' } });
    return;
  } else if (type === 'ota') {
    category = 'OTA题库';
    clearExamSessionCache(category, limit, 'ota');
    closePracticeTypeModal();
    router.push({ path: '/online-exam/start', query: { category, limit, random: true, bank: 'ota', title: 'OTA测验' } });
    return;
  } else {
    category = '综合';
  }

  clearExamSessionCache(category, limit);
  closePracticeTypeModal();
  router.push({ path: '/online-exam/start', query: { category, limit, random: true } });
};

// 组件挂载时的初始化逻辑
onMounted(async () => {
  await checkLoginStatus();
  window.addEventListener('userLogin', handleUserLogin);
  window.addEventListener('userLogout', handleUserLogout);
  window.addEventListener('examCompleted', handleExamFinished);
  if (isLoggedIn.value) {
    await loadExams();
    await loadHistoryRecords();
  }
});

onUnmounted(() => {
  window.removeEventListener('userLogin', handleUserLogin);
  window.removeEventListener('userLogout', handleUserLogout);
  window.removeEventListener('examCompleted', handleExamFinished);
});
</script>

<style scoped>
/* 补充自定义阴影与过渡效果 */
.shadow-card {
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.07);
}
.shadow-card-hover {
  box-shadow: 0 6px 16px rgba(15, 82, 186, 0.12);
}
.transition-custom {
  transition: all 0.3s ease;
}

/* 横向滚动条样式 */
.scrollbar-thin {
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 transparent;
}
.scrollbar-thin::-webkit-scrollbar {
  height: 4px;
}
.scrollbar-thin::-webkit-scrollbar-track {
  background: transparent;
}
.scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 4px;
}

.exam-card-glyph {
  letter-spacing: 0.08em;
  line-height: 1;
}

@media (max-width: 768px) {
  .practice-type-handle {
    width: 42px;
    height: 4px;
    border-radius: 9999px;
    background: #cbd5e1;
    margin: 10px auto 2px;
  }

  .practice-type-sheet-wrap {
    align-items: flex-end;
    padding: 0 12px 12px;
  }

  .practice-type-sheet {
    max-width: none !important;
    border-radius: 20px 20px 16px 16px !important;
    box-shadow: 0 -12px 32px rgba(15, 23, 42, 0.18);
  }

  .practice-type-option {
    padding: 14px 16px !important;
  }

  .practice-type-option:active {
    transform: scale(0.98);
  }

  .practice-type-option .w-10.h-10 {
    width: 2.5rem !important;
    height: 2.5rem !important;
  }

  .scrollbar-thin {
    scroll-snap-type: x proximity;
  }

  .scrollbar-thin > div {
    scroll-snap-align: start;
  }

  .history-stats-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
    gap: 0.65rem !important;
    margin-bottom: 1rem !important;
  }

  .history-stat-card {
    padding: 0.65rem 0.75rem !important;
    border-radius: 0.9rem !important;
    min-height: 0;
    min-width: 0;
    width: 100%;
    display: flex;
    align-items: center;
    gap: 0.65rem;
  }

  .history-stat-icon {
    margin-bottom: 0 !important;
    flex: 0 0 auto;
  }

  .history-stat-card .w-10.h-10,
  .history-stat-card .w-12.h-12 {
    width: 1.9rem !important;
    height: 1.9rem !important;
    border-radius: 0.65rem !important;
  }

  .history-stat-card .text-lg {
    font-size: 0.88rem !important;
  }

  .history-stat-label {
    font-size: 0.64rem !important;
    line-height: 1.15 !important;
    margin-bottom: 0.1rem !important;
    white-space: nowrap;
  }

  .history-stat-value {
    font-size: 1.2rem !important;
    line-height: 1 !important;
    white-space: nowrap;
  }

  .history-stat-card > :last-child {
    min-width: 0;
    flex: 1 1 auto;
  }
}

@media (max-width: 420px) {
  .practice-type-sheet-wrap {
    padding: 0 10px 10px;
  }

  .practice-type-sheet .px-5.py-4 {
    padding: 16px 16px 12px !important;
  }

  .practice-type-sheet .p-5 {
    padding: 14px 16px !important;
  }

  .practice-type-option {
    padding: 12px 14px !important;
  }

  .practice-type-option .gap-3 {
    gap: 0.7rem !important;
  }

  .practice-type-option .text-xs {
    font-size: 0.68rem !important;
  }

  .exam-overview-stats .overflow-x-auto {
    gap: 0.5rem !important;
  }

  .exam-overview-stats .min-w-\[140px\] {
    min-width: 132px !important;
  }

  .history-stats-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
    gap: 0.55rem !important;
  }

  .history-stat-card {
    padding: 0.54rem 0.58rem !important;
    gap: 0.45rem;
  }

  .history-stat-card .w-10.h-10,
  .history-stat-card .w-12.h-12 {
    width: 1.5rem !important;
    height: 1.5rem !important;
    border-radius: 0.55rem !important;
  }

  .history-stat-card .text-lg,
  .history-stat-card .text-xl {
    font-size: 0.8rem !important;
  }

  .history-stat-label {
    font-size: 0.54rem !important;
  }

  .history-stat-value {
    font-size: 0.95rem !important;
  }
}
</style>



