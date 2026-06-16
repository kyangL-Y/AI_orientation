<template>
  <div class="min-h-screen bg-slate-50/50">
    <div class="container mx-auto px-4 py-8 max-w-screen-lg">
      <PageVisitTracker pageName="PersonalCenter" />
      <main class="main-content">
        <!-- 导航栏占位符 -->
        <div class="w-full h-[56px] md:h-[80px]"></div>

        <!-- 顶部个人信息区域 -->
        <div class="relative mb-32 md:mb-24">
          <!-- 封面背景 -->
          <div class="h-48 md:h-80 rounded-b-[3rem] overflow-hidden relative shadow-lg shadow-blue-900/5 group">
            <div class="absolute inset-0 bg-gradient-to-r from-blue-600 via-indigo-600 to-violet-600">
              <!-- 装饰纹理 -->
              <div class="absolute inset-0 opacity-20" style="background-image: radial-gradient(circle at 2px 2px, white 1px, transparent 0); background-size: 32px 32px;"></div>
              <div class="absolute top-0 right-0 w-96 h-96 bg-white/10 rounded-full blur-3xl -mr-20 -mt-20"></div>
              <div class="absolute bottom-0 left-0 w-64 h-64 bg-black/10 rounded-full blur-3xl -ml-10 -mb-10"></div>
            </div>
          
            <!-- 封面图片 -->
            <div v-if="userInfo.coverPhoto" class="absolute inset-0 transition-transform duration-700 group-hover:scale-105">
              <img :src="userInfo.coverPhoto" alt="" class="w-full h-full object-cover">
              <div class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent"></div>
            </div>
            
            <!-- 封面编辑按钮 -->
            <div class="absolute top-6 right-6 opacity-0 group-hover:opacity-100 transition-all duration-300 transform translate-y-2 group-hover:translate-y-0">
              <button 
                @click="editCoverPhoto"
                class="bg-black/30 backdrop-blur-md text-white px-4 py-2 rounded-full text-sm hover:bg-black/40 transition-all flex items-center gap-2 border border-white/20 shadow-lg"
              >
                <i class="fa fa-camera"></i>
                <span>更换封面</span>
              </button>
            </div>

            <button
              @click="editCoverPhoto"
              class="md:hidden absolute right-3 bottom-3 z-20 px-3 py-1.5 rounded-full bg-black/45 backdrop-blur-sm text-white text-xs font-medium border border-white/15 shadow-lg flex items-center gap-1.5"
            >
              <i class="fa fa-camera"></i>
              <span>封面</span>
            </button>
          </div>

        <!-- 用户信息悬浮卡片 -->
        <div class="absolute inset-x-0 -bottom-24 md:left-12 md:right-auto md:-bottom-16 flex flex-col md:flex-row items-center md:items-end z-10">
          <div class="relative z-10">
            <!-- 头像容器 -->
            <div class="relative group">
              <div class="w-28 h-28 md:w-40 md:h-40 rounded-full border-[6px] border-white shadow-2xl overflow-hidden bg-white relative z-10 ring-1 ring-slate-100">
                <img 
                  v-if="userInfo.avatar" 
                  :src="userInfo.avatar" 
                  alt="头像" 
                  class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                  @error="logger.error('头像加载失败:', userInfo.avatar)"
                >
                <div v-else class="w-full h-full bg-slate-50 flex items-center justify-center text-slate-300 text-4xl md:text-5xl">
                  <i class="fa fa-user"></i>
                </div>
                
                <!-- 头像编辑遮罩 -->
                <div 
                  @click="editAvatar"
                  class="hidden md:flex absolute inset-0 bg-black/40 items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer backdrop-blur-[2px]"
                >
                  <i class="fa fa-camera text-white text-2xl drop-shadow-md"></i>
                </div>
              </div>
              
              <!-- 在线状态指示器 -->
              <div class="absolute bottom-2 right-2 md:bottom-3 md:right-3 z-20 w-5 h-5 md:w-7 md:h-7 bg-green-500 border-4 border-white rounded-full shadow-sm" title="在线"></div>

              <button
                @click="editAvatar"
                class="md:hidden absolute top-1 right-1 z-20 w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm text-slate-700 shadow-md border border-white flex items-center justify-center"
                aria-label="编辑头像"
              >
                <i class="fa fa-camera text-xs"></i>
              </button>
            </div>
          </div>
          
          <!-- 文字信息 -->
             <div class="profile-info-card mt-3 md:mt-0 md:mb-4 md:ml-6 pb-2 text-center md:text-left bg-white/90 backdrop-blur-sm p-4 rounded-2xl shadow-sm border border-white/50">
             <div class="profile-identity flex flex-col md:flex-row items-center gap-2 md:gap-4 mb-1">
               <h1 class="text-2xl md:text-3xl font-bold text-slate-800 tracking-tight">{{ userInfo.name }}</h1>
               <span v-if="userInfo.company" class="profile-company-badge px-3 py-1 bg-blue-50 text-blue-600 text-xs rounded-full border border-blue-100 font-medium">
                 {{ userInfo.company }}
               </span>
             </div>
             <p class="profile-meta text-slate-500 text-sm md:text-base font-medium flex flex-wrap justify-center md:justify-start items-center gap-3">
               <span class="flex items-center gap-1.5">
                 <i class="fa fa-building-o"></i> {{ userInfo.department }}
               </span>
               <span class="w-1 h-1 bg-slate-300 rounded-full"></span>
               <span class="flex items-center gap-1.5">
                 <i class="fa fa-id-badge"></i> {{ userInfo.position }}
               </span>
             </p>
             
             <p class="profile-contact text-slate-500 text-sm md:text-base font-medium flex flex-wrap justify-center md:justify-start items-center gap-3 mt-2">
               <span v-if="userInfo.phonenumber" class="flex items-center gap-1.5">
                 <i class="fa fa-phone"></i> {{ userInfo.phonenumber }}
               </span>
               <span v-if="userInfo.phonenumber && userInfo.email" class="hidden md:inline-block w-1 h-1 bg-slate-300 rounded-full"></span>
               <span v-if="userInfo.email" class="flex items-center gap-1.5">
                 <i class="fa fa-envelope"></i> {{ userInfo.email }}
               </span>
             </p>
          </div>
        </div>
        
        <!-- 顶部操作栏 (桌面端) -->
        <div class="hidden md:flex absolute right-6 top-6 gap-2 z-20">
           <button 
              @click="userInfo.name === '未登录用户' ? goToLogin() : openEditModal()"
              class="px-4 py-2 bg-white/90 backdrop-blur-sm text-slate-700 rounded-full font-medium hover:bg-white transition-all shadow-lg flex items-center gap-2 text-sm"
            >
              <i :class="userInfo.name === '未登录用户' ? 'fa fa-sign-in' : 'fa fa-pencil'" class="text-blue-500"></i>
              <span>{{ userInfo.name === '未登录用户' ? '立即登录' : '编辑资料' }}</span>
            </button>
        </div>
      </div>

      <!-- 移动端操作栏 -->
      <div class="md:hidden mb-8 px-2 space-y-2">
        <button 
          @click="userInfo.name === '未登录用户' ? goToLogin() : openEditModal()"
          class="w-full px-4 py-3 bg-white text-slate-700 rounded-xl font-semibold shadow-sm border border-slate-100 flex items-center justify-center gap-2 active:scale-[0.98] transition-transform"
        >
          <i :class="userInfo.name === '未登录用户' ? 'fa fa-sign-in' : 'fa fa-pencil'"></i>
          <span>{{ userInfo.name === '未登录用户' ? '立即登录' : '编辑资料' }}</span>
        </button>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- 左侧栏 -->
        <div class="space-y-8">
          <!-- 培训统计概览 -->
          <div class="bg-white rounded-2xl shadow-xl shadow-slate-200/50 p-6 border border-slate-50">
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-lg font-bold text-slate-800 flex items-center gap-2">
                <span class="w-1 h-6 bg-blue-600 rounded-full"></span>
                培训数据
              </h3>
              <button 
                @click="refreshStats" 
                class="hidden md:block text-blue-600 hover:text-blue-700 transition-colors p-2 rounded-lg hover:bg-blue-50"
                title="刷新统计数据"
              >
                <i class="fa fa-refresh" :class="{'fa-spin': isRefreshing}"></i>
              </button>
            </div>
            
            <!-- 移动端：列表样式 / 桌面端：垂直列表样式 -->
            <div class="hidden md:flex flex-col gap-3">
              <!-- 已完成培训 -->
              <div class="bg-blue-50/50 rounded-xl p-4 hover:bg-blue-50 transition-colors group cursor-default flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-lg bg-blue-100 flex items-center justify-center text-blue-600 group-hover:scale-110 transition-transform">
                    <i class="fa fa-check-circle"></i>
                  </div>
                  <span class="text-sm font-medium text-slate-600">已修课程</span>
                </div>
                <div class="text-xl font-bold text-slate-800">{{ stats.coursesCompleted }} <span class="text-sm text-slate-400 font-normal">门</span></div>
              </div>
              
              <!-- 今日时长 -->
              <div class="bg-violet-50/50 rounded-xl p-4 hover:bg-violet-50 transition-colors group cursor-default flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-lg bg-violet-100 flex items-center justify-center text-violet-600 group-hover:scale-110 transition-transform">
                    <i class="fa fa-clock"></i>
                  </div>
                  <span class="text-sm font-medium text-slate-600">今日时长</span>
                </div>
                <div class="text-xl font-bold text-slate-800">{{ formatTrainingDuration(stats.todaySeconds || 0) }}</div>
              </div>
              
              <!-- 平均成绩 -->
              <div class="bg-emerald-50/50 rounded-xl p-4 hover:bg-emerald-50 transition-colors group cursor-default flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-lg bg-emerald-100 flex items-center justify-center text-emerald-600 group-hover:scale-110 transition-transform">
                    <i class="fa fa-bar-chart"></i>
                  </div>
                  <span class="text-sm font-medium text-slate-600">平均分</span>
                </div>
                <div class="text-xl font-bold text-slate-800">{{ stats.averageScore }} <span class="text-sm text-slate-400 font-normal">分</span></div>
              </div>
            </div>
            
            <!-- 移动端：列表样式（与学习概览一致） -->
            <div class="md:hidden space-y-3">
              <div class="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors">
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 rounded-full bg-white shadow-sm flex items-center justify-center text-blue-500">
                    <i class="fa fa-check-circle"></i>
                  </div>
                  <div>
                    <div class="text-sm text-slate-500">已修课程</div>
                    <div class="font-bold text-slate-800">{{ stats.coursesCompleted }} 门</div>
                  </div>
                </div>
                <i class="fa fa-chevron-right text-slate-300 text-xs"></i>
              </div>
              
              <div class="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors">
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 rounded-full bg-white shadow-sm flex items-center justify-center text-violet-500">
                    <i class="fa fa-clock"></i>
                  </div>
                  <div>
                    <div class="text-sm text-slate-500">今日时长</div>
                    <div class="font-bold text-slate-800">{{ formatTrainingDuration(stats.todaySeconds || 0) }}</div>
                  </div>
                </div>
                <i class="fa fa-chevron-right text-slate-300 text-xs"></i>
              </div>
              
              <div class="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors">
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 rounded-full bg-white shadow-sm flex items-center justify-center text-emerald-500">
                    <i class="fa fa-bar-chart"></i>
                  </div>
                  <div>
                    <div class="text-sm text-slate-500">平均分</div>
                    <div class="font-bold text-slate-800">{{ stats.averageScore }} 分</div>
                  </div>
                </div>
                <i class="fa fa-chevron-right text-slate-300 text-xs"></i>
              </div>
            </div>
          </div>

          <!-- 学习统计列表 -->
          <div class="bg-white rounded-2xl shadow-xl shadow-slate-200/50 p-6 border border-slate-50">
             <h3 class="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2">
              <span class="w-1 h-6 bg-indigo-600 rounded-full"></span>
              学习概览
            </h3>
            
            <div v-if="!isLoggedIn" class="py-10 text-center">
               <div class="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-3">
                 <i class="fa fa-lock text-slate-300 text-2xl"></i>
               </div>
               <p class="text-slate-500 text-sm">登录后查看详细数据</p>
            </div>
            
            <div v-else class="space-y-4">
              <div class="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors">
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 rounded-full bg-white shadow-sm flex items-center justify-center text-blue-500">
                    <i class="fa fa-pencil"></i>
                  </div>
                  <div>
                    <div class="text-sm text-slate-500">总答题数</div>
                    <div class="font-bold text-slate-800">{{ stats.totalQuestions || 0 }}</div>
                  </div>
                </div>
                <i class="fa fa-chevron-right text-slate-300 text-xs"></i>
              </div>

              <div class="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors">
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 rounded-full bg-white shadow-sm flex items-center justify-center text-green-500">
                    <i class="fa fa-check-circle"></i>
                  </div>
                  <div>
                    <div class="text-sm text-slate-500">正确率</div>
                    <div class="font-bold text-slate-800">{{ stats.accuracyRate || 0 }}%</div>
                  </div>
                </div>
                <i class="fa fa-chevron-right text-slate-300 text-xs"></i>
              </div>

              <div class="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors">
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 rounded-full bg-white shadow-sm flex items-center justify-center text-orange-500">
                    <i class="fa fa-trophy"></i>
                  </div>
                  <div>
                    <div class="text-sm text-slate-500">当前排名</div>
                    <div class="font-bold text-slate-800">{{ stats.ranking || 0 }}</div>
                  </div>
                </div>
                <i class="fa fa-chevron-right text-slate-300 text-xs"></i>
              </div>
            </div>
          </div>
        </div>

        <!-- 右侧栏 -->
        <div class="lg:col-span-2 flex flex-col gap-8">
          <!-- 学习路径入口 Banner -->
          <div class="relative overflow-hidden rounded-3xl bg-gradient-to-r from-blue-600 to-teal-400 shadow-xl shadow-blue-500/20 group transition-all hover:shadow-blue-500/30 flex-shrink-0">
             <!-- 背景装饰 -->
             <div class="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-20 -mt-20 group-hover:scale-110 transition-transform duration-700"></div>
             <div class="absolute bottom-0 left-0 w-40 h-40 bg-cyan-300/20 rounded-full blur-2xl -ml-10 -mb-10"></div>
             <!-- 替换原来的 svg 引用为 CSS 点阵纹理 -->
             <div class="absolute inset-0 opacity-10" style="background-image: radial-gradient(circle at 2px 2px, rgba(255,255,255,0.8) 1px, transparent 0); background-size: 24px 24px;"></div>

             <div class="relative z-10 p-6 md:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6">
               <div class="flex-1">
                 <div class="inline-flex items-center gap-2 px-3 py-1 bg-white/10 backdrop-blur-md rounded-full text-white/90 text-xs font-medium mb-3 border border-white/10">
                   <span class="w-2 h-2 bg-cyan-300 rounded-full animate-pulse"></span>
                   专属定制规划
                 </div>
                 <h3 class="text-2xl font-bold text-white mb-2 tracking-tight">我的学习路径</h3>
                 <p class="text-blue-50 text-base mb-4 max-w-md leading-relaxed opacity-90">
                   基于您的岗位和能力定制的职业成长规划，清晰追踪每一步成长。
                 </p>
                 
                 <div class="flex flex-wrap gap-4">
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg">
                     <i class="fa fa-book text-cyan-200"></i>
                     <span class="text-sm font-medium">系统课程</span>
                   </div>
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg">
                     <i class="fa fa-check-square-o text-cyan-200"></i>
                     <span class="text-sm font-medium">阶段考核</span>
                   </div>
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg">
                     <i class="fa fa-trophy text-cyan-200"></i>
                     <span class="text-sm font-medium">技能认证</span>
                   </div>
                 </div>
               </div>

               <div class="flex-shrink-0">
                 <router-link 
                   to="/learning-plans"
                   class="inline-flex items-center justify-center px-8 py-4 bg-white text-blue-600 rounded-2xl font-bold hover:bg-blue-50 transition-all duration-300 shadow-lg hover:shadow-xl hover:-translate-y-1 group/btn min-w-[160px]"
                 >
                   <span>进入学习路径</span>
                   <i class="fa fa-arrow-right ml-2 group-hover/btn:translate-x-1 transition-transform"></i>
                 </router-link>
               </div>
             </div>
          </div>

          <!-- 学习报告入口 Banner -->
          <div class="relative overflow-hidden rounded-3xl bg-gradient-to-r from-violet-600 to-purple-500 shadow-xl shadow-violet-500/20 group transition-all hover:shadow-violet-500/30 flex-shrink-0">
             <!-- 背景装饰 -->
             <div class="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-20 -mt-20 group-hover:scale-110 transition-transform duration-700"></div>
             <div class="absolute bottom-0 left-0 w-40 h-40 bg-purple-300/20 rounded-full blur-2xl -ml-10 -mb-10"></div>
             <div class="absolute inset-0 opacity-10" style="background-image: radial-gradient(circle at 2px 2px, rgba(255,255,255,0.8) 1px, transparent 0); background-size: 24px 24px;"></div>

             <div class="relative z-10 p-6 md:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6">
               <div class="flex-1">
                 <div class="inline-flex items-center gap-2 px-3 py-1 bg-white/10 backdrop-blur-md rounded-full text-white/90 text-xs font-medium mb-3 border border-white/10">
                   <span class="w-2 h-2 bg-purple-300 rounded-full animate-pulse"></span>
                   智能评估分析
                 </div>
                 <h3 class="text-2xl font-bold text-white mb-2 tracking-tight">我的学习报告</h3>
                 <p class="text-purple-50 text-base mb-4 max-w-md leading-relaxed opacity-90">
                   查看您的学习能力评估报告，获取AI个性化学习建议，追踪成长轨迹。
                 </p>
                 
                 <div class="flex flex-wrap gap-4">
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg">
                     <i class="fa fa-line-chart text-purple-200"></i>
                     <span class="text-sm font-medium">能力雷达图</span>
                   </div>
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg">
                     <i class="fa fa-lightbulb-o text-purple-200"></i>
                     <span class="text-sm font-medium">AI学习建议</span>
                   </div>
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg">
                     <i class="fa fa-bar-chart text-purple-200"></i>
                     <span class="text-sm font-medium">部门排名</span>
                   </div>
                 </div>
               </div>

               <div class="flex-shrink-0">
                 <router-link 
                   to="/learning-report"
                   class="inline-flex items-center justify-center px-8 py-4 bg-white text-violet-600 rounded-2xl font-bold hover:bg-purple-50 transition-all duration-300 shadow-lg hover:shadow-xl hover:-translate-y-1 group/btn min-w-[160px]"
                 >
                   <span>查看学习报告</span>
                   <i class="fa fa-arrow-right ml-2 group-hover/btn:translate-x-1 transition-transform"></i>
                 </router-link>
               </div>
             </div>
          </div>

          <!-- 结课测验记录入口 -->
          <div class="relative overflow-hidden rounded-3xl bg-gradient-to-r from-slate-900 via-slate-800 to-indigo-900 shadow-xl shadow-slate-300/40 group transition-all hover:shadow-slate-400/50 flex-shrink-0">
             <div class="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -mr-20 -mt-20 group-hover:scale-110 transition-transform duration-700"></div>
             <div class="absolute bottom-0 left-0 w-40 h-40 bg-indigo-300/20 rounded-full blur-2xl -ml-10 -mb-10"></div>
             <div class="absolute inset-0 opacity-10" style="background-image: radial-gradient(circle at 2px 2px, rgba(255,255,255,0.8) 1px, transparent 0); background-size: 24px 24px;"></div>

             <div class="relative z-10 p-6 md:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6">
               <div class="flex-1">
                 <div class="inline-flex items-center gap-2 px-3 py-1 bg-white/10 backdrop-blur-md rounded-full text-white/90 text-xs font-medium mb-3 border border-white/10">
                   <span class="w-2 h-2 bg-emerald-300 rounded-full animate-pulse"></span>
                   视频完播自动测验
                 </div>
                 <h3 class="text-2xl font-bold text-white mb-2 tracking-tight">结课测验记录</h3>
                 <p class="text-slate-100 text-base mb-4 max-w-2xl leading-relaxed opacity-90">
                   查看视频课程完播后的自动测验记录、成绩、用时与题目回看。
                 </p>

                 <div class="flex flex-wrap gap-4">
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg">
                     <i class="fa fa-list-check text-emerald-200"></i>
                     <span class="text-sm font-medium">最近 20 条内命中 {{ recentCourseQuizCount }} 条</span>
                   </div>
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg" v-if="recentCourseQuiz">
                     <i class="fa fa-trophy text-amber-200"></i>
                     <span class="text-sm font-medium">最近成绩 {{ recentCourseQuiz.score ?? 0 }} 分</span>
                   </div>
                   <div class="flex items-center gap-2 text-white/80 bg-black/10 px-3 py-1.5 rounded-lg" v-if="recentCourseQuiz">
                     <i class="fa fa-clock-o text-cyan-200"></i>
                     <span class="text-sm font-medium">{{ formatDuration(recentCourseQuiz.durationSeconds) }}</span>
                   </div>
                 </div>
               </div>

               <div class="flex-shrink-0 flex flex-col gap-3 min-w-[180px]">
                 <router-link
                   to="/online-exam"
                   class="inline-flex items-center justify-center px-8 py-4 bg-white text-slate-900 rounded-2xl font-bold hover:bg-slate-100 transition-all duration-300 shadow-lg hover:shadow-xl hover:-translate-y-1 group/btn"
                 >
                   <span>查看全部记录</span>
                   <i class="fa fa-arrow-right ml-2 group-hover/btn:translate-x-1 transition-transform"></i>
                 </router-link>
                 <router-link
                   v-if="recentCourseQuiz"
                   :to="`/online-exam/review/${recentCourseQuiz.attemptId}`"
                   class="inline-flex items-center justify-center px-6 py-3 bg-white/10 text-white rounded-2xl font-semibold hover:bg-white/15 transition-all duration-300 border border-white/15"
                 >
                   <span>回看最近一次</span>
                 </router-link>
               </div>
             </div>
          </div>

          <!-- 学习进度概览图表 -->
          <div class="bg-white rounded-2xl shadow-xl shadow-slate-200/50 p-8 border border-slate-50 flex-1 flex flex-col">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-8 flex-shrink-0">
              <div>
                <h3 class="text-xl font-bold text-slate-800 flex items-center gap-2">
                  <span class="w-1 h-6 bg-emerald-500 rounded-full"></span>
                  学习趋势分析
                </h3>
                <p class="text-slate-500 text-sm mt-1">追踪您在不同时间段的学习投入时长</p>
              </div>
              
              <div class="flex bg-slate-100 p-1 rounded-xl mt-4 sm:mt-0 self-start sm:self-auto">
                <button 
                  class="px-4 py-1.5 text-sm font-medium rounded-lg transition-all duration-200" 
                  :class="chartPeriod === 'daily' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'" 
                  @click="switchChartPeriod('daily')"
                >按天</button>
                <button 
                  class="px-4 py-1.5 text-sm font-medium rounded-lg transition-all duration-200" 
                  :class="chartPeriod === 'monthly' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'" 
                  @click="switchChartPeriod('monthly')"
                >月度</button>
              </div>
            </div>
            
            <div class="w-full relative flex-1 min-h-[300px]">
              <div v-if="!isLoggedIn" class="absolute inset-0 flex flex-col items-center justify-center bg-slate-50/50 backdrop-blur-[1px] rounded-xl border border-dashed border-slate-200 z-10">
                <div class="w-16 h-16 bg-white rounded-full shadow-sm flex items-center justify-center mb-4">
                  <i class="fa fa-bar-chart text-3xl text-slate-300"></i>
                </div>
                <h4 class="text-lg font-semibold text-slate-700 mb-1">暂无趋势数据</h4>
                <p class="text-slate-500 text-sm mb-4">请登录后查看您的学习成长轨迹</p>
                <button @click="goToLogin" class="px-6 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700 transition-colors">立即登录</button>
              </div>
              
              <div v-else class="absolute inset-0">
                <canvas ref="hoursChart"></canvas>
              </div>
            </div>
          </div>

        </div>
      </div>

      <!-- 账号管理 (页面底部) -->
      <div class="bg-white rounded-2xl shadow-xl shadow-slate-200/50 p-4 border border-slate-50 flex items-center justify-between mt-8" v-if="userInfo.name !== '未登录用户'">
        <div class="flex items-center gap-2">
          <span class="w-1 h-4 bg-red-500 rounded-full"></span>
          <span class="font-bold text-slate-700 text-sm">账号管理</span>
        </div>
        <button 
          @click="showDeleteAccountModal = true"
          class="px-3 py-1.5 bg-red-50 text-red-500 rounded-lg text-xs font-bold hover:bg-red-100 transition-colors border border-red-100 flex items-center gap-1"
        >
          <i class="fa fa-trash-o"></i>
          注销
        </button>
      </div>

      </main>
    </div>
    
    <!-- 编辑个人资料模态框 -->
    <EditProfileModal 
      :show="showEditModal" 
      :userInfo="userInfo"
      @close="closeEditModal"
      @success="handleProfileUpdate"
    />
    
    <!-- 图片上传模态框 -->
    <ImageUploadModal 
      :show="showImageUpload" 
      :title="uploadTitle"
      :maxSize="uploadMaxSize"
      @close="closeImageUpload"
      @confirm="handleImageUpload"
    />
    
    <!-- 注销账号确认弹窗 -->
    <div v-if="showDeleteAccountModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div class="bg-white rounded-2xl p-6 max-w-md mx-4 shadow-2xl">
        <div class="text-center mb-6">
          <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <i class="fa fa-exclamation-triangle text-3xl text-red-500"></i>
          </div>
          <h3 class="text-xl font-bold text-slate-800 mb-2">确认注销账号？</h3>
          <p class="text-slate-500 text-sm">
            注销后，您的所有数据将被永久删除，包括学习记录、考试成绩等，此操作<strong class="text-red-600">不可恢复</strong>！
          </p>
        </div>
        
        <!-- 确认输入 -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-slate-700 mb-2">
            请输入 <span class="text-red-600 font-bold">DELETE</span> 确认注销
          </label>
          <input 
            v-model="deleteConfirmText"
            type="text"
            placeholder="请输入 DELETE"
            class="w-full px-4 py-3 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
          >
        </div>
        
        <div class="flex gap-3">
          <button 
            @click="showDeleteAccountModal = false; deleteConfirmText = ''"
            class="flex-1 px-4 py-3 bg-slate-100 text-slate-700 rounded-xl font-semibold hover:bg-slate-200 transition-colors"
          >
            取消
          </button>
          <button 
            @click="confirmDeleteAccount"
            :disabled="deleteConfirmText !== 'DELETE' || isDeletingAccount"
            class="flex-1 px-4 py-3 bg-red-600 text-white rounded-xl font-semibold hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <span v-if="isDeletingAccount">注销中...</span>
            <span v-else>确认注销</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import EditProfileModal from '@/components/modals/EditProfileModal.vue'
import ImageUploadModal from '@/components/ImageUploadModal.vue'
import PageVisitTracker from '@/components/PageVisitTracker.vue'
import { ref, onMounted, watch, onBeforeUnmount, nextTick } from 'vue'
import { Chart, registerables } from 'chart.js'
import { getUserInfo } from '@/api/auth'
import { getUserStats, getUserLearningTrend, getUserCategoryStats, getDailyRecords, updateUserProfile } from '@/api/user'
import { getMyExamRecords } from '@/api/examRecord'
import { ElMessage } from 'element-plus'
Chart.register(...registerables)

const chartPeriod = ref('daily')
const currentCertificate = ref(0)
let certificateInterval = null

const hoursChart = ref(null)
const categoriesChart = ref(null)
let hoursChartInstance = null
let categoriesChartInstance = null

// 用户信息和统计数据
const userInfo = ref({ 
  name: '未登录用户', 
  userName: null, // user_name 字段，用户的显示昵称
  department: '未设置', 
  position: '未设置',
  company: null,
  avatar: null,
  coverPhoto: null,
  email: null,
  phonenumber: null
})
const dailyRecords = ref([])
const dateRangeType = ref(30)

const stats = ref({ 
  coursesCompleted: 0, 
  totalHours: 0, 
  totalSeconds: 0,
  certificates: 0, 
  averageScore: 0, 
  targetCompletion: 0, 
  currentHours: 0, 
  targetHours: 0 
})
const recentCourses = ref([])
const courseCategories = ref([])
const recentCourseQuiz = ref(null)
const recentCourseQuizCount = ref(0)
// 学习时长趋势数据：后端返回 { labels: [...], data: [...] }
const hoursData = ref({
  labels: [],
  data: []
})

// 检查是否已登录
const isLoggedIn = ref(false)

// 刷新状态
const isRefreshing = ref(false)

// 注销账号相关
const showDeleteAccountModal = ref(false)
const deleteConfirmText = ref('')
const isDeletingAccount = ref(false)

// 编辑个人资料模态框
const showEditModal = ref(false)

// 图片上传模态框
const showImageUpload = ref(false)
const uploadTitle = ref('')
const uploadMaxSize = ref(5 * 1024 * 1024) // 5MB
const uploadType = ref('') // 'avatar' 或 'cover'

const nextCertificate = () => { currentCertificate.value = (currentCertificate.value + 1) % 3 }
const prevCertificate = () => { currentCertificate.value = (currentCertificate.value - 1 + 3) % 3 }

const formatTrainingDuration = (totalSeconds) => {
  const s = Number(totalSeconds || 0)
  if (s <= 0) return '0分钟'

  const minute = 60
  const hour = 60 * minute
  const day = 24 * hour
  const month = 30 * day
  const year = 365 * day

  if (s < hour) {
    const minutes = Math.max(1, Math.floor(s / minute))
    return `${minutes}分钟`
  }

  if (s < day) {
    const hours = Math.round((s / hour) * 10) / 10
    return `${hours}小时`
  }

  if (s < month) {
    const days = Math.floor(s / day)
    return `${days}天`
  }

  if (s < year) {
    const totalDays = Math.floor(s / day)
    const months = Math.floor(totalDays / 30)
    const remainDays = totalDays % 30
    if (remainDays === 0) return `${months}个月`
    return `${months}个月${remainDays}天`
  }

  const totalDays = Math.floor(s / day)
  const years = Math.floor(totalDays / 365)
  let remainDays = totalDays % 365
  const months = Math.floor(remainDays / 30)
  remainDays = remainDays % 30

  const parts = []
  if (years > 0) parts.push(`${years}年`)
  if (months > 0) parts.push(`${months}个月`)
  if (remainDays > 0) parts.push(`${remainDays}天`)
  return parts.join('')
}

const initHoursChart = () => {
  logger.debug('📊 开始初始化图表...')
  logger.debug('📊 hoursData.value:', JSON.parse(JSON.stringify(hoursData.value)))
  logger.debug('📊 labels 数量:', hoursData.value?.labels?.length)
  logger.debug('📊 labels 内容:', JSON.parse(JSON.stringify(hoursData.value?.labels)))
  logger.debug('📊 data 数量:', hoursData.value?.data?.length)
  logger.debug('📊 data 内容:', JSON.parse(JSON.stringify(hoursData.value?.data)))
  
  // 检查canvas元素是否存在
  if (!hoursChart.value) {
    logger.warn('hoursChart canvas element not found, skipping chart initialization')
    return
  }
  
  const ctx = hoursChart.value.getContext('2d')
  if (hoursChartInstance) hoursChartInstance.destroy()

  // 确保即使没有数据也能有基本框架
  let labels = Array.isArray(hoursData.value?.labels) ? hoursData.value.labels : []
  let rawValues = Array.isArray(hoursData.value?.data) ? hoursData.value.data : []
  
  // 如果没有数据，不显示默认占位符，直接显示空图表
  // 删除了默认月份标签的逻辑，只显示真实数据
  
  logger.debug('📊 处理后的 labels:', labels)
  logger.debug('📊 处理后的 rawValues:', rawValues)

  // 根据数据范围自动选择显示单位：小时 / 天 / 月
  let unit = '小时'
  let displayValues = rawValues.slice()
  const max = rawValues.length ? Math.max(...rawValues) : 0

  // 单位转换
  if (max > 0) {
    if (max < 24) {
      // 小于 24 小时，直接用小时
      unit = '小时'
    } else if (max < 24 * 30) {
      // 小于 30 天，用天
      unit = '天'
      displayValues = rawValues.map(v => Math.round((v / 24) * 10) / 10)
    } else {
      // 更大范围，用月
      unit = '月'
      displayValues = rawValues.map(v => Math.round((v / 24 / 30) * 10) / 10)
    }
  }

  hoursChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: `学习时长(${unit})`,
        data: displayValues,
        backgroundColor: 'rgba(15, 82, 186, 0.7)',
        borderRadius: 6,
        barThickness: 24,
        hoverBackgroundColor: 'rgba(15, 82, 186, 0.9)'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { 
        legend: { display: false },
        // 添加无数据时的提示
        tooltip: {
          callbacks: {
            title: function(context) {
              return context[0].label || '无数据';
            },
            label: function(context) {
              const value = context.parsed.y || 0;
              return `学习时长: ${value}${unit}`;
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: { color: 'rgba(0,0,0,0.05)' },
          ticks: { callback: v => v + unit },
          // 保证Y轴至少显示几个刻度
          suggestedMin: 0.5
        },
        x: { 
          grid: { display: false },
          // 确保即使无数据也显示X轴
          ticks: { display: true }
        }
      }
    }
  })
}

const initCategoriesChart = () => {
  // 检查canvas元素是否存在
  if (!categoriesChart.value) {
    logger.warn('categoriesChart canvas element not found, skipping chart initialization')
    return
  }
  
  const ctx = categoriesChart.value.getContext('2d')
  if (categoriesChartInstance) categoriesChartInstance.destroy()
  const cats = Array.isArray(courseCategories.value) ? courseCategories.value : []
  categoriesChartInstance = new Chart(ctx, { type: 'doughnut', data: { labels: cats.map(c => c.name), datasets: [{ data: cats.map(c => parseInt(c.percentage)), backgroundColor: cats.map(c => c.color), borderWidth: 0, hoverOffset: 8 }] }, options: { responsive: true, maintainAspectRatio: false, cutout: '70%', plugins: { legend: { display: false } } } })
}

// chartPeriod的变化现在由switchChartPeriod函数处理
// watch(chartPeriod, () => { 
//   initHoursChart()
//   loadUserStats()
//   if (chartPeriod.value === 'daily') {
//     loadDailyRecords(dateRangeType.value)
//   }
// })

onMounted(() => { 
  // 只在已登录时初始化图表
  if (isLoggedIn.value) {
    initHoursChart()
    initCategoriesChart()
  }
  certificateInterval = setInterval(() => nextCertificate(), 5000) 
})

onBeforeUnmount(() => { if (certificateInterval) clearInterval(certificateInterval); if (hoursChartInstance) hoursChartInstance.destroy(); if (categoriesChartInstance) categoriesChartInstance.destroy() })

// 默认资源
// 默认头像：简洁的中性灰色人像
const DEFAULT_AVATAR = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDAgMjAwIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0iI2YxZjVmOSIvPjxjaXJjbGUgY3g9IjEwMCIgY3k9IjgwIiByPSI0MCIgZmlsbD0iI2NiZDVlMSIvPjxwYXRoIGQ9Ik00MCAxODBjMC00MCA2MC01MCA2MC01MHM2MCAxMCA2MCA1MCIgZmlsbD0iI2NiZDVlMSIvPjwvc3ZnPg=='
// 默认封面：null (直接使用底层的CSS渐变背景作为默认封面，避免图片加载失败的破损图标)
const DEFAULT_COVER = null

// 从API获取用户信息
async function loadUserInfoFromAPI() {
  try {
    const token = localStorage.getItem('authToken')
    if (!token) {
      isLoggedIn.value = false
      // 如果没有token，不要重置userInfo，保持从localStorage加载的数据
      // userInfo.value = { name: '未登录用户', department: '未设置', position: '未设置' }
      // 清空所有数据
      clearAllData()
      return
    }
    
    const response = await getUserInfo()
    if (response.data.code === 200) {
      isLoggedIn.value = true
      const userData = response.data.user || response.data.data
      // 后端返回的 deptName 和 companyName 在响应的顶级字段中，不在 data 对象里
      const deptName = response.data.deptName
      const companyName = response.data.companyName
      const postGroup = response.data.postGroup
      const profileCompletion = response.data.profileCompletion || userData?.profileCompletion || null
      
      logger.debug('🔍 API返回的完整用户数据:', userData)
      logger.debug('🔍 API返回的部门名称:', deptName)
      logger.debug('🔍 API返回的公司名称:', companyName)
      logger.debug('🔍 API返回的职位:', postGroup)
      logger.debug('🔍 完整响应:', response.data)
      
      // 检查API数据是否有效
      if (!userData) {
        logger.debug('❌ API返回的数据为空，使用默认值')
        userInfo.value = {
          name: '用户',
          userName: null,
          department: '未设置部门',
          position: '未设置职位',
          company: null,
          avatar: DEFAULT_AVATAR,
          coverPhoto: DEFAULT_COVER,
          email: null,
          phonenumber: null
        }
      } else {
        // 完全使用服务器数据，不从本地加载
        logger.debug('🔄 完全使用服务器数据，不从本地加载')
        
        // 尝试读取本地缓存的旧数据，用于补全后端缺失的字段
        const localInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
        const isSameUser = localInfo.userName === (userData.userName || userData.username)
        
        userInfo.value = {
          // user_name 现在是用户的显示昵称，优先使用
          name: userData.userName || userData.username || userData.user_name || (userData.email ? userData.email.split('@')[0] : '用户'),
          userName: userData.userName || userData.username || userData.user_name || null, // 保留原始 userName 字段供编辑使用
          // 优先使用后端返回的部门名称（在响应顶级字段中）
          department: deptName || userData.dept?.deptName || userData.deptName || (isSameUser ? localInfo.department : null) || '未设置部门',
          deptId: userData.deptId || null,
          position: userData.position || postGroup || userData.postGroup || '未设置职位',
          // 优先使用后端返回的公司名称（在响应顶级字段中）
          company: companyName || userData.companyName || (isSameUser ? localInfo.company : null) || null,
          // 使用默认值兜底
          avatar: userData.avatar || DEFAULT_AVATAR, 
          coverPhoto: userData.coverPhoto || DEFAULT_COVER,
          email: userData.email || null,
          phonenumber: userData.phonenumber || userData.phoneNumber || userData.phone_number || null,
          profileCompletion
        }
      }
      logger.debug('✅ 更新后的用户信息:', userInfo.value)
      logger.debug('✅ 最终头像:', userInfo.value.avatar)
      logger.debug('✅ 最终封面:', userInfo.value.coverPhoto)
      
      // 更新localStorage中的用户信息
      const storedUserInfo = localStorage.getItem('userInfo')
      if (storedUserInfo) {
        try {
          const parsed = JSON.parse(storedUserInfo)
          Object.assign(parsed, userInfo.value)
          parsed.profileCompletion = userInfo.value.profileCompletion || parsed.profileCompletion || null
          localStorage.setItem('userInfo', JSON.stringify(parsed))
          logger.debug('💾 同步到localStorage成功:', parsed)
        } catch (error) {
          logger.error('同步到localStorage失败:', error)
        }
      }
    } else {
      throw new Error(response.data.msg || '获取用户信息失败')
    }
  } catch (error) {
    logger.error('获取用户信息失败:', error)
    isLoggedIn.value = false
    // 如果API调用失败，使用默认值，不从localStorage获取
    logger.debug('❌ API调用失败，使用默认值')
    userInfo.value = {
      name: '用户',
      userName: null,
      department: '未设置部门',
      position: '未设置职位',
      company: null,
      avatar: DEFAULT_AVATAR,
      coverPhoto: DEFAULT_COVER,
      email: null,
      phonenumber: null
    }
  }
}

// 清空所有数据
function clearAllData() {
  stats.value = { 
    coursesCompleted: 0, 
    totalHours: 0, 
    totalSeconds: 0,
    certificates: 0, 
    averageScore: 0, 
    targetCompletion: 0, 
    currentHours: 0, 
    targetHours: 0 
  }
  recentCourses.value = []
  courseCategories.value = []
  hoursData.value = {
    labels: [],
    data: []
  }
  // 重新初始化图表显示空白数据
  initHoursChart()
  initCategoriesChart()
}

// 从localStorage获取用户信息（备用）
function loadUserInfoFromStorage() {
  try {
    const stored = localStorage.getItem('userInfo')
    if (stored) {
      isLoggedIn.value = true
      const parsed = JSON.parse(stored)
      userInfo.value = {
        name: parsed.username || parsed.name || '用户',
        nickName: parsed.nickName || parsed.nickname || null,
        department: parsed.deptName || parsed.department || '未设置部门',
        deptId: parsed.deptId || null,
        position: parsed.postGroup || parsed.position || '未设置职位',
        company: parsed.companyName || parsed.hotelName || null,
        avatar: parsed.avatar || DEFAULT_AVATAR,
        coverPhoto: parsed.coverPhoto || DEFAULT_COVER,
        email: parsed.email || null,
        phonenumber: parsed.phonenumber || parsed.phone || null
      }
      logger.debug('📱 从localStorage加载用户信息:', userInfo.value)
      logger.debug('📱 从localStorage加载的头像:', userInfo.value.avatar)
      logger.debug('📱 从localStorage加载的封面:', userInfo.value.coverPhoto)
    } else {
      isLoggedIn.value = false
      clearAllData()
    }
  } catch {
    isLoggedIn.value = false
    clearAllData()
  }
}

// 加载每日学习记录
async function loadDailyRecords(days = dateRangeType.value) {
  try {
    logger.debug('📅 开始加载每日学习记录...', '天数:', days)
    
    const response = await getDailyRecords(days)
    logger.debug('📅 响应数据:', response.data)
    
    if (response.data.code === 200 && response.data.data) {
      logger.debug('📅 原始记录数量:', response.data.data.length)
      dailyRecords.value = response.data.data.map(record => ({
        date: record.date,
        dateLabel: record.dateLabel,
        weekday: record.weekday,
        duration: record.duration || 0,
        totalQuestions: record.totalQuestions || 0,
        correctQuestions: record.correctQuestions || 0,
        accuracyRate: record.totalQuestions > 0 
          ? Math.round((record.correctQuestions / record.totalQuestions) * 100) 
          : 0
      }))
      logger.debug('📅 处理后的记录数量:', dailyRecords.value.length)
      logger.debug('📅 dailyRecords.value:', dailyRecords.value)
    } else {
      logger.warn('📅 响应格式不正确或无数据:', response.data)
    }
  } catch (error) {
    logger.error('📅 加载每日学习记录失败:', error)
  }
}



// 切换图表周期
function switchChartPeriod(period) {
  logger.debug('📈 切换图表周期为:', period)
  chartPeriod.value = period.trim() // 确保去除空格
  // 重新加载数据
  loadUserStats()
}

// 选择日期范围
function selectDateRange(days) {
  logger.debug('📅 选择日期范围:', days)
  dateRangeType.value = days
  // 重新加载图表数据
  loadUserStats()
}

// 格式化时长显示
function formatDuration(seconds) {
  if (!seconds || seconds === 0) return '0分钟'
  
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  
  if (hours > 0) {
    if (minutes > 0) {
      return `${hours}小时${minutes}分钟`
    }
    return `${hours}小时`
  }
  
  return `${Math.max(1, minutes)}分钟`
}

async function loadCourseQuizPreview() {
  if (!isLoggedIn.value) {
    recentCourseQuiz.value = null
    recentCourseQuizCount.value = 0
    return
  }

  try {
    const res = await getMyExamRecords({
      pageNum: 1,
      pageSize: 20,
      attemptType: 'practice'
    })
    const rows = res?.data?.rows || res?.data?.data || []
    const courseQuizRows = rows.filter(item => item.attemptScene === 'course_quiz' || String(item.examName || '').includes('结课测验'))
    recentCourseQuizCount.value = courseQuizRows.length
    recentCourseQuiz.value = courseQuizRows[0] || null
  } catch (error) {
    logger.error('❌ 加载结课测验预览失败:', error)
    recentCourseQuiz.value = null
    recentCourseQuizCount.value = 0
  }
}

// 加载用户统计数据
async function loadUserStats() {
  logger.debug('🔵 loadUserStats 被调用')
  try {
    const token = localStorage.getItem('authToken')
    logger.debug('🔵 Token 检查:', token ? '存在' : '不存在')
    if (!token) {
      logger.debug('⚠️ 未登录，跳过统计数据加载')
      // 未登录时清空数据
      clearAllData()
      return
    }
    
    logger.debug('📊 开始加载用户统计数据...')
    logger.debug('📊 chartPeriod.value:', chartPeriod.value)
    logger.debug('📊 dateRangeType.value:', dateRangeType.value)
    
    const periodValue = chartPeriod.value.trim()
    logger.debug('🔵 即将调用 getUserLearningTrend 参数:', periodValue, dateRangeType.value)
    
    const [statsResponse, trendResponse, categoryResponse] = await Promise.all([
      getUserStats(),
      getUserLearningTrend(periodValue, dateRangeType.value),
      getUserCategoryStats()
    ])
    
    // 直接打印接口原始响应
    logger.debug('🔵 原始响应:', trendResponse)
    
    logger.debug('🔵 API调用完成')
    
    logger.debug('📊 统计数据API响应:', {
      stats: statsResponse?.data,
      trend: trendResponse?.data,
      category: categoryResponse?.data
    })
    logger.debug('📊 趋势数据详情:', JSON.parse(JSON.stringify(trendResponse?.data)))
    
    if (statsResponse.data.code === 200) {
      stats.value = statsResponse.data.data
      logger.debug('✅ 用户统计数据加载成功:', stats.value)
    } else {
      logger.warn('⚠️ 用户统计数据API返回错误:', statsResponse.data)
    }
    
    if (trendResponse.data.code === 200) {
      hoursData.value = trendResponse.data.data
      logger.debug('✅ 学习趋势数据加载成功:', hoursData.value)
      // 重新初始化图表
      nextTick(() => {
        initHoursChart()
      })
    } else {
      logger.warn('⚠️ 学习趋势数据API返回错误:', trendResponse.data)
    }
    
    if (categoryResponse.data.code === 200) {
      courseCategories.value = categoryResponse.data.data
      logger.debug('✅ 分类统计数据加载成功:', courseCategories.value)
      // 重新初始化图表
      nextTick(() => {
        initCategoriesChart()
      })
    } else {
      logger.warn('⚠️ 分类统计数据API返回错误:', categoryResponse.data)
    }
  } catch (error) {
    logger.error('❌ 获取统计数据失败:', error)
    logger.error('错误详情:', error.response?.data || error.message)
    // 出错时也清空数据
    clearAllData()
  }
}

// 刷新统计数据
const refreshStats = async () => {
  if (isRefreshing.value) return
  
  isRefreshing.value = true
  logger.debug('🔄 手动刷新统计数据...')
  
  try {
    await loadUserStats()
    logger.debug('✅ 统计数据刷新成功')
  } catch (error) {
    logger.error('❌ 刷新统计数据失败:', error)
  } finally {
    setTimeout(() => {
      isRefreshing.value = false
    }, 500) // 等待动画完成
  }
}

// 跳转到登录页面
const goToLogin = () => {
  // 触发HeaderBar中的登录模态框
  window.dispatchEvent(new CustomEvent('showLoginModal'))
}

// 确认注销账号
const confirmDeleteAccount = async () => {
  if (deleteConfirmText.value !== 'DELETE') {
    ElMessage.warning('请输入 DELETE 确认注销')
    return
  }
  
  try {
    isDeletingAccount.value = true
    
    // 调用后端注销账号接口
    const token = localStorage.getItem('authToken')
    const response = await fetch('/dev-api/system/user/profile/delete', {
      method: 'DELETE',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json'
      }
    })
    
    const data = await response.json()
    
    if (data.code === 200) {
      // 清除本地存储
      localStorage.removeItem('authToken')
      localStorage.removeItem('userInfo')
      
      // 触发全局登出事件
      window.dispatchEvent(new CustomEvent('userLogout'))
      
      ElMessage.success('账号已注销成功')
      
      // 跳转到首页
      setTimeout(() => {
        window.location.href = '/'
      }, 1500)
    } else {
      throw new Error(data.msg || '注销失败')
    }
  } catch (error) {
    logger.error('注销账号失败:', error)
    ElMessage.error(error.message || '注销账号失败，请稍后重试')
  } finally {
    isDeletingAccount.value = false
    showDeleteAccountModal.value = false
    deleteConfirmText.value = ''
  }
}

// 打开编辑模态框
const openEditModal = () => {
  // 检查用户是否已登录
  const token = localStorage.getItem('authToken')
  if (!token) {
    // 用户未登录，提示登录
    ElMessage.warning('请先登录后再编辑个人资料')
    return
  }
  
  // 检查用户信息是否有效
  if (userInfo.value.name === '未登录用户') {
    ElMessage.warning('请先登录后再编辑个人资料')
    return
  }
  
  logger.debug('🔍 打开编辑模态框时的用户信息:', userInfo.value)
  showEditModal.value = true
}

// 关闭编辑模态框
const closeEditModal = () => {
  showEditModal.value = false
}

// 处理个人资料更新成功
const handleProfileUpdate = async (updatedUserInfo) => {
  logger.debug('🔄 开始处理个人资料更新:', updatedUserInfo)
  logger.debug('🔄 头像数据:', updatedUserInfo.avatar)
  
  // 更新本地用户信息
  userInfo.value = {
    ...userInfo.value,
    ...updatedUserInfo,
    position: updatedUserInfo.postGroup || updatedUserInfo.position || userInfo.value.position
  }
  logger.debug('✅ 本地显示用户信息已更新:', userInfo.value)
  logger.debug('✅ 更新后的头像:', userInfo.value.avatar)
  logger.debug('✅ 更新后的职位:', userInfo.value.position)
  
  // 更新localStorage中的用户信息
  const storedUserInfo = localStorage.getItem('userInfo')
  if (storedUserInfo) {
    try {
      const parsed = JSON.parse(storedUserInfo)
      const updated = { ...parsed, ...updatedUserInfo }
      localStorage.setItem('userInfo', JSON.stringify(updated))
      logger.debug('✅ localStorage用户信息已更新:', updated)
    } catch (error) {
      logger.error('更新localStorage用户信息失败:', error)
    }
  }
  
  // 重新从API获取用户信息，确保数据同步
  try {
    logger.debug('🔄 正在从后端重新获取用户信息...')
    await loadUserInfoFromAPI()
    
    // 再次检查：如果API返回的数据中部门/公司名称为空，但我们刚才更新的数据里有，
    // 且deptId一致，则恢复我们刚才设置的名称（防止后端接口没返回关联名称导致显示丢失）
    if (updatedUserInfo.deptId && userInfo.value.deptId === updatedUserInfo.deptId) {
      if ((!userInfo.value.department || userInfo.value.department === '未设置部门') && updatedUserInfo.department) {
        logger.debug('🔧 修复部门名称显示:', updatedUserInfo.department)
        userInfo.value.department = updatedUserInfo.department
      }
      
      if (!userInfo.value.company && updatedUserInfo.companyName) {
        logger.debug('🔧 修复公司名称显示:', updatedUserInfo.companyName)
        userInfo.value.company = updatedUserInfo.companyName
      }
      
      if ((!userInfo.value.position || userInfo.value.position === '未设置职位') && updatedUserInfo.postGroup) {
        logger.debug('🔧 修复职位显示:', updatedUserInfo.postGroup)
        userInfo.value.position = updatedUserInfo.postGroup
      }
      
      // 更新localStorage以保存修复后的数据
      const stored = localStorage.getItem('userInfo')
      if (stored) {
        const parsed = JSON.parse(stored)
        Object.assign(parsed, userInfo.value)
        localStorage.setItem('userInfo', JSON.stringify(parsed))
      }
    }
    
    logger.debug('✅ 用户信息已从后端同步:', userInfo.value)
  } catch (error) {
    logger.warn('从后端同步用户信息失败，使用本地数据:', error)
  }
  
  // 显示成功提示
  // alert('个人资料更新成功！') // 已由EditProfileModal处理提示
}

// 编辑封面照片
const editCoverPhoto = () => {
  const token = localStorage.getItem('authToken')
  if (!token) {
    ElMessage.warning('请先登录后再编辑封面照片')
    return
  }
  
  uploadTitle.value = '上传封面照片'
  uploadMaxSize.value = 5 * 1024 * 1024 // 5MB
  uploadType.value = 'cover'
  showImageUpload.value = true
}

// 编辑头像
const editAvatar = () => {
  const token = localStorage.getItem('authToken')
  if (!token) {
    ElMessage.warning('请先登录后再编辑头像')
    return
  }
  
  uploadTitle.value = '上传头像'
  uploadMaxSize.value = 2 * 1024 * 1024 // 2MB
  uploadType.value = 'avatar'
  showImageUpload.value = true
}

// 关闭图片上传模态框
const closeImageUpload = () => {
  showImageUpload.value = false
  uploadType.value = ''
}

// 处理图片上传确认
const handleImageUpload = async (uploadData) => {
  const { previewUrl } = uploadData
  logger.debug('📸 开始处理图片上传:', uploadType.value, previewUrl)
  
  // 更新本地显示
  if (uploadType.value === 'cover') {
    userInfo.value.coverPhoto = previewUrl
    logger.debug('📸 设置封面照片:', userInfo.value.coverPhoto)
  } else if (uploadType.value === 'avatar') {
    userInfo.value.avatar = previewUrl
    logger.debug('📸 设置头像:', userInfo.value.avatar)
  }
  
  // 保存到服务器
  try {
    const updateData = {}
    if (uploadType.value === 'cover') {
      updateData.coverPhoto = previewUrl
    } else if (uploadType.value === 'avatar') {
      updateData.avatar = previewUrl
    }
    
    logger.debug('🌐 开始保存到服务器:', updateData)
    
    // 调用后端API更新用户资料
    const response = await updateUserProfile(updateData)
    if (response.data.code === 200) {
      logger.debug('✅ 头像/封面照片已保存到服务器')
      
      // 更新localStorage中的用户信息
      const storedUserInfo = localStorage.getItem('userInfo')
      if (storedUserInfo) {
        const parsed = JSON.parse(storedUserInfo)
        Object.assign(parsed, updateData)
        localStorage.setItem('userInfo', JSON.stringify(parsed))
        logger.debug('💾 更新localStorage成功:', parsed)
      }
      
      const typeText = uploadType.value === 'cover' ? '封面照片' : '头像'
               // 头像/封面照片更新成功，不显示弹窗
    } else {
      throw new Error(response.data.msg || '保存失败')
    }
  } catch (error) {
    logger.error('保存到服务器失败:', error)
    alert('保存失败，请重试')
    return
  }
}

onMounted(async () => {
  logger.debug('🚀 页面初始化开始')
  
  // 直接从API获取用户信息（包括头像和封面照片）
  logger.debug('🌐 开始从API获取用户信息')
  await loadUserInfoFromAPI()
  logger.debug('🌐 API加载完成，最终头像:', userInfo.value.avatar)
  
  logger.debug('🔵 即将调用 loadUserStats()')
  await loadUserStats()
  logger.debug('🔵 loadUserStats() 调用完成')
  await loadCourseQuizPreview()
  
  // 数据加载完成后再初始化图表
  if (isLoggedIn.value) {
    initHoursChart()
    // initCategoriesChart() // 已移除分类统计图表,不再需要初始化
    
    // 如果默认是按天统计，加载每日记录
    if (chartPeriod.value === 'daily') {
      loadDailyRecords()
    }
  }
  
  // 监听跨页登录信息变更
  window.addEventListener('storage', (e) => {
    if (e.key === 'userInfo' || e.key === 'authToken') {
      logger.debug('🔄 检测到存储变化，重新加载数据')
      // 直接从API加载数据
      loadUserInfoFromAPI()
      loadUserStats()
      loadCourseQuizPreview()
    }
  })
  // 监听登录事件
  window.addEventListener('userLogin', (event) => {
    logger.debug('🔄 检测到登录事件，重新加载数据')
    logger.debug('🔍 登录事件传递的用户信息:', event.detail)
    // 直接从API加载数据
    loadUserInfoFromAPI()
    loadUserStats()
    loadCourseQuizPreview()
  })
})
</script>

<style scoped>
@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.main-content > div {
  animation: fadeInUp 0.6s ease-out forwards;
}

.main-content > div:nth-child(2) { animation-delay: 0.1s; }
.main-content > div:nth-child(3) { animation-delay: 0.2s; }
.main-content > div:nth-child(4) { animation-delay: 0.3s; }

/* 自定义滚动条 */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}
::-webkit-scrollbar-track {
  background: transparent;
}
::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}
::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

html { 
  scroll-behavior: smooth; 
}

/* 移动端专项优化 */
@media (max-width: 768px) {
  /* 页面容器 */
  .container {
    padding-left: 0.75rem !important;
    padding-right: 0.75rem !important;
  }
  
  /* 顶部封面区域优化 */
  .h-48 {
    height: 8rem !important;
  }
  
  /* 用户信息卡片优化 */
  .w-28, .h-28 {
    width: 4.5rem !important;
    height: 4.5rem !important;
  }
  
  /* 用户信息悬浮卡片 - 更紧凑 */
  .relative.mb-32 {
    margin-bottom: 6rem !important;
  }
  
  .absolute.inset-x-0.-bottom-24 {
    bottom: -5rem !important;
  }
  
  /* 用户信息文字区域 */
  .bg-white\/90.backdrop-blur-sm.p-4 {
    padding: 0.5rem 0.75rem !important;
  }
  
  .bg-white\/90 h1 {
    font-size: 1.125rem !important;
  }
  
  .bg-white\/90 p {
    font-size: 0.6875rem !important;
  }
  
  /* 编辑资料按钮 */
  .md\:hidden.mb-8 {
    margin-bottom: 0.5rem !important;
  }
  
  .md\:hidden.mb-8 button {
    padding: 0.625rem !important;
    font-size: 0.8125rem !important;
  }
  
  /* 主内容区域 - 两列布局 */
  .grid.grid-cols-1.lg\:grid-cols-3 {
    display: grid !important;
    grid-template-columns: 1fr !important;
    gap: 0.75rem !important;
  }
  
  /* 左侧栏 - 培训数据和学习概览并排 */
  .space-y-8:first-child {
    display: grid !important;
    grid-template-columns: 1fr 1fr !important;
    gap: 0.5rem !important;
  }
  
  .space-y-8:first-child > * + * {
    margin-top: 0 !important;
  }
  
  /* 培训数据卡片 */
  .space-y-8:first-child > div:first-child {
    grid-column: 1 / 2 !important;
  }
  
  /* 学习概览卡片 */
  .space-y-8:first-child > div:nth-child(2) {
    grid-column: 2 / 3 !important;
  }
  
  /* 账号管理卡片 - 占满两列 */
  .space-y-8:first-child > div:nth-child(3) {
    grid-column: 1 / -1 !important;
  }
  
  /* 卡片内部优化 */
  .bg-white.rounded-2xl.shadow-xl.p-6 {
    padding: 0.625rem !important;
    border-radius: 0.75rem !important;
  }
  
  /* 卡片标题 */
  .text-lg.font-bold {
    font-size: 0.8125rem !important;
    margin-bottom: 0.5rem !important;
  }
  
  .text-lg.font-bold .w-1.h-6 {
    width: 2px !important;
    height: 0.875rem !important;
  }
  
  /* 培训数据 - 3列网格 */
  .grid.grid-cols-3.gap-4 {
    gap: 0.375rem !important;
  }
  
  .grid.grid-cols-3 > div {
    padding: 0.5rem !important;
    border-radius: 0.5rem !important;
  }
  
  .grid.grid-cols-3 .w-8.h-8 {
    width: 1.25rem !important;
    height: 1.25rem !important;
  }
  
  .grid.grid-cols-3 .text-xs {
    font-size: 0.5rem !important;
    display: none !important;
  }
  
  .grid.grid-cols-3 .text-2xl {
    font-size: 0.9375rem !important;
  }
  
  .grid.grid-cols-3 .text-sm {
    font-size: 0.5625rem !important;
  }
  
  /* 学习概览列表 */
  .space-y-4 {
    gap: 0.25rem !important;
  }
  
  .space-y-4 > div {
    margin-top: 0.25rem !important;
  }
  
  .flex.items-center.justify-between.p-4.rounded-xl {
    padding: 0.375rem !important;
    border-radius: 0.375rem !important;
  }
  
  .flex.items-center.justify-between.p-4 .w-10.h-10 {
    width: 1.5rem !important;
    height: 1.5rem !important;
  }
  
  .flex.items-center.justify-between.p-4 .gap-4 {
    gap: 0.375rem !important;
  }
  
  .flex.items-center.justify-between.p-4 .text-sm {
    font-size: 0.5625rem !important;
  }
  
  .flex.items-center.justify-between.p-4 .font-bold {
    font-size: 0.75rem !important;
  }
  
  /* 右侧栏 */
  .lg\:col-span-2 {
    gap: 0.75rem !important;
  }
  
  /* 学习路径Banner优化 */
  .relative.overflow-hidden.rounded-3xl.bg-gradient-to-r {
    border-radius: 0.75rem !important;
  }
  
  .relative.overflow-hidden.rounded-3xl .p-6 {
    padding: 0.75rem !important;
  }
  
  .relative.overflow-hidden.rounded-3xl h3 {
    font-size: 1rem !important;
    margin-bottom: 0.25rem !important;
  }
  
  .relative.overflow-hidden.rounded-3xl p {
    font-size: 0.6875rem !important;
    margin-bottom: 0.5rem !important;
  }
  
  .relative.overflow-hidden.rounded-3xl .flex.flex-wrap.gap-4 {
    gap: 0.375rem !important;
  }
  
  .relative.overflow-hidden.rounded-3xl .px-3.py-1\.5 {
    padding: 0.25rem 0.5rem !important;
    font-size: 0.625rem !important;
  }
  
  .relative.overflow-hidden.rounded-3xl .px-8.py-4 {
    padding: 0.5rem 1rem !important;
    font-size: 0.75rem !important;
    border-radius: 0.5rem !important;
    min-width: auto !important;
  }
  
  /* 图表容器优化 */
  .bg-white.rounded-2xl.shadow-xl.p-8 {
    padding: 0.75rem !important;
  }
  
  .min-h-\[300px\] {
    min-height: 160px !important;
  }
  
  /* 图表标题 */
  .text-xl.font-bold {
    font-size: 0.875rem !important;
  }
  
  .text-slate-500.text-sm.mt-1 {
    font-size: 0.625rem !important;
    display: none !important;
  }
  
  /* 图表切换按钮 */
  .flex.bg-slate-100.p-1 {
    padding: 0.125rem !important;
  }
  
  .flex.bg-slate-100 button {
    padding: 0.25rem 0.5rem !important;
    font-size: 0.625rem !important;
  }
  
  /* 账号管理卡片 */
  .bg-white.rounded-2xl.shadow-xl.p-4.border {
    padding: 0.5rem 0.75rem !important;
  }
  
  .bg-white.rounded-2xl.shadow-xl.p-4 .font-bold.text-sm {
    font-size: 0.75rem !important;
  }
  
  .bg-white.rounded-2xl.shadow-xl.p-4 .px-3.py-1\.5 {
    padding: 0.25rem 0.5rem !important;
    font-size: 0.625rem !important;
  }
  
  /* 间距优化 */
  .gap-8 {
    gap: 0.75rem !important;
  }
  
  .mb-8 {
    margin-bottom: 0.75rem !important;
  }
  
  .mb-6 {
    margin-bottom: 0.5rem !important;
  }
  
  /* 阴影优化 */
  .shadow-xl {
    box-shadow: 0 4px 12px -2px rgba(0, 0, 0, 0.08) !important;
  }
  
  /* 移动端动画优化 - 减少动画 */
  .main-content > div {
    animation: none;
  }
}

/* 超小屏幕优化 (< 375px) */
@media (max-width: 375px) {
  .h-48 {
    height: 6rem !important;
  }
  
  .w-28, .h-28 {
    width: 3.5rem !important;
    height: 3.5rem !important;
  }
  
  .bg-white\/90 h1 {
    font-size: 1rem !important;
  }
  
  .grid.grid-cols-3 .text-2xl {
    font-size: 0.8125rem !important;
  }
  
  .relative.overflow-hidden.rounded-3xl h3 {
    font-size: 0.875rem !important;
  }
}

@media (max-width: 480px) {
  .space-y-8:first-child {
    grid-template-columns: 1fr !important;
    gap: 0.55rem !important;
  }

  .space-y-8:first-child > div:first-child,
  .space-y-8:first-child > div:nth-child(2),
  .space-y-8:first-child > div:nth-child(3) {
    grid-column: 1 / -1 !important;
  }

  .relative.mb-32 {
    margin-bottom: 5.25rem !important;
  }

  .absolute.inset-x-0.-bottom-24 {
    bottom: -4.4rem !important;
    padding-left: 0.5rem;
    padding-right: 0.5rem;
  }

  .bg-white\/90.backdrop-blur-sm.p-4 {
    width: calc(100% - 1rem);
    margin: 0 auto;
  }
}

@media (max-width: 390px) {
  .profile-identity {
    gap: 6px !important;
  }

  .profile-company-badge {
    max-width: 100%;
    white-space: normal;
    line-height: 1.35;
    text-align: center;
  }

  .profile-meta,
  .profile-contact {
    flex-direction: column;
    gap: 6px !important;
  }

  .profile-meta .w-1.h-1,
  .profile-contact .w-1.h-1 {
    display: none;
  }
}
</style>

