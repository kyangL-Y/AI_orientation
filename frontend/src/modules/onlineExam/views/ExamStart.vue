<template>
	<div class="min-h-screen bg-gray-100 flex flex-col font-sans" v-if="paper">
		<!-- 顶部栏 -->
		<header class="h-12 md:h-16 bg-white border-b border-gray-200 fixed top-0 w-full z-50 shadow-sm">
			<div class="max-w-7xl mx-auto h-full px-3 md:px-6 flex items-center justify-between">
				<div class="flex items-center gap-2 md:gap-4 flex-1 min-w-0">
					<button @click="goBack" class="w-7 h-7 md:w-8 md:h-8 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors text-gray-600 flex-shrink-0">
						<el-icon><ArrowLeft /></el-icon>
					</button>
					<h1 class="text-sm md:text-lg font-bold text-gray-800 truncate">{{ paper?.name || '在线考试' }}</h1>
				</div>
				
				<!-- 移动端倒计时 -->
				<div class="flex md:hidden items-center gap-1 bg-blue-50 px-2 py-1 rounded text-blue-600 text-xs flex-shrink-0" data-guide="exam-countdown-mobile">
					<el-icon class="text-xs"><Clock /></el-icon>
					<span class="font-mono font-bold">{{ formatTime(timeLeft) }}</span>
				</div>
				
				<!-- 桌面端倒计时 -->
				<div class="hidden md:flex items-center gap-2 bg-blue-50 px-4 py-1.5 rounded-md border border-blue-100 text-blue-600" data-guide="exam-countdown-desktop">
					<el-icon><Clock /></el-icon>
					<span class="font-mono font-bold text-lg">{{ formatTime(timeLeft) }}</span>
				</div>

				<!-- 移动端菜单按钮 -->
				<button @click="showSidebar = true" class="md:hidden p-1.5 ml-2 text-gray-600 hover:bg-gray-100 rounded-lg flex-shrink-0" data-guide="exam-answer-sheet-mobile-trigger">
					<el-icon class="text-lg"><Menu /></el-icon>
				</button>
			</div>
		</header>

		<!-- 主要内容区 -->
		<main class="flex-1 mt-14 md:mt-20 p-3 md:p-6 max-w-7xl mx-auto w-full grid grid-cols-1 md:grid-cols-12 gap-4 md:gap-6" v-if="!showResult">
			
			<!-- 左侧题目区域 -->
			<div class="md:col-span-8 flex flex-col gap-4 md:gap-6" data-guide="exam-question-workspace">
				<!-- 题目卡片 -->
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden flex flex-col relative min-h-[350px] md:min-h-[450px]">
					<!-- 顶部进度条 -->
					<div class="h-1 bg-gray-100 w-full">
						<div class="h-full bg-blue-600 transition-all duration-300 ease-out" :style="{ width: `${progressPercentage}%` }"></div>
					</div>

					<!-- 模式切换 & 题号 -->
					<div class="px-4 md:px-8 pt-4 md:pt-8 flex justify-between items-center border-b border-gray-50 pb-3 md:pb-4 mx-3 md:mx-8 mt-1 md:mt-2">
						<div class="flex items-baseline gap-1 md:gap-2">
							<span class="text-xs md:text-sm font-medium text-gray-500">Question</span>
							<span class="text-xl md:text-2xl font-bold text-gray-900">{{ currentIndex + 1 }}</span>
							<span class="text-xs md:text-sm font-medium text-gray-400">/ {{ totalQuestions }}</span>
						</div>
						<div class="flex bg-gray-100 p-0.5 md:p-1 rounded-lg">
							<button 
								@click="currentMode = 'single'"
								:class="['px-2.5 py-1 md:px-4 md:py-1.5 text-[10px] md:text-xs font-bold rounded-md transition-all duration-200', currentMode === 'single' ? 'bg-white text-blue-600 shadow-sm' : 'text-gray-500 hover:text-gray-700']"
							>单题</button>
							<button 
								@click="currentMode = 'all'"
								:class="['px-2.5 py-1 md:px-4 md:py-1.5 text-[10px] md:text-xs font-bold rounded-md transition-all duration-200', currentMode === 'all' ? 'bg-white text-blue-600 shadow-sm' : 'text-gray-500 hover:text-gray-700']"
							>全览</button>
						</div>
					</div>

					<div class="p-3 md:p-8 flex-1">
						<div v-if="currentMode === 'single' && paper" class="h-full flex flex-col">
							<transition name="fade" mode="out-in">
								<div :key="currentIndex" v-if="paper.questions && paper.questions.length > 0" class="flex-1">
									<exam-question
										:question="paper.questions[currentIndex]"
										v-model:answer="answers[paper.questions[currentIndex].id]"
										:index="currentIndex"
										:total="totalQuestions"
									/>
								</div>
								<div v-else class="flex items-center justify-center h-full text-gray-400">
									暂无题目数据
								</div>
							</transition>
						</div>
						
						<div v-else-if="paper && paper.questions" class="space-y-8 md:space-y-12 pb-16 md:pb-20">
							<div v-for="(question, idx) in paper.questions" :key="question.id" :id="'q-'+idx" class="scroll-mt-20 md:scroll-mt-24 border-b border-gray-100 last:border-0 pb-6 md:pb-8 last:pb-0">
								<div class="flex items-center gap-2 mb-3 md:mb-4">
									<span class="w-6 h-6 md:w-8 md:h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center font-bold text-xs md:text-sm">{{ idx + 1 }}</span>
									<span class="text-[10px] md:text-xs font-medium px-1.5 py-0.5 md:px-2 md:py-1 rounded bg-gray-100 text-gray-500">{{ getQuestionTypeName(question.type) }}</span>
								</div>
								<exam-question
									:question="question"
									v-model:answer="answers[question.id]"
									:index="idx"
									:total="totalQuestions"
									:hide-title="true"
								/>
							</div>
						</div>
					</div>

					<!-- 底部导航栏 (仅单题模式) -->
					<div v-if="currentMode === 'single'" class="bg-gray-50 px-3 md:px-8 py-3 md:py-6 border-t border-gray-100 flex justify-between items-center">
						<button 
							@click="prev" 
							:disabled="!canGoPrev"
							:class="['px-3 py-1.5 md:px-6 md:py-2.5 rounded-lg font-medium transition-all flex items-center gap-1 md:gap-2 text-xs md:text-base', !canGoPrev ? 'text-gray-300 cursor-not-allowed' : 'text-gray-600 hover:bg-white hover:shadow-sm hover:text-blue-600 border border-transparent hover:border-gray-200']"
						>
							<el-icon><ArrowLeft /></el-icon> <span class="hidden md:inline">上一题</span><span class="md:hidden">上一题</span>
						</button>
						
						<button 
							@click="next" 
							class="px-4 py-1.5 md:px-8 md:py-2.5 bg-blue-600 text-white rounded-lg font-bold hover:bg-blue-700 shadow-md hover:shadow-lg transition-all flex items-center gap-1 md:gap-2 text-xs md:text-base"
						>
							{{ isLastQuestion ? '提交' : '下一题' }} <el-icon v-if="!isLastQuestion"><ArrowRight /></el-icon>
						</button>
					</div>
				</div>
			</div>

			<!-- 右侧答题卡 (Desktop) -->
			<div class="hidden md:block md:col-span-4 space-y-6" data-guide="exam-answer-sheet-desktop">
				<div class="bg-white rounded-xl p-6 shadow-sm border border-gray-200 sticky top-24">
					<div class="flex items-center justify-between mb-6 border-b border-gray-100 pb-4">
						<h3 class="text-base font-bold text-gray-800 flex items-center gap-2">
							<span class="w-1 h-4 bg-blue-600 rounded-full"></span>
							答题卡
						</h3>
						<div class="text-xs text-gray-500 font-medium bg-gray-100 px-2 py-1 rounded">
							<span class="text-blue-600 font-bold">{{ answeredCount }}</span> / {{ totalQuestions }}
						</div>
					</div>
					
					<div class="grid grid-cols-5 gap-3 max-h-[calc(100vh-300px)] overflow-y-auto custom-scrollbar pr-1">
						<button 
							v-for="(q, idx) in paper?.questions" 
							:key="q.id"
							@click="jumpToQuestion(idx)"
							:class="[
								'aspect-square rounded-lg text-sm font-bold transition-all duration-200 flex items-center justify-center border',
								currentIndex === idx ? 'bg-blue-600 text-white border-blue-600 shadow-md' : 
								(isAnswered(q.id) ? 'bg-blue-50 text-blue-600 border-blue-200' : 'bg-white text-gray-500 border-gray-200 hover:border-blue-300 hover:text-blue-600')
							]"
						>
							{{ idx + 1 }}
						</button>
					</div>

					<div class="mt-6 flex items-center justify-center gap-6 text-xs text-gray-400 border-t border-gray-100 pt-4">
						<div class="flex items-center gap-2"><span class="w-2 h-2 rounded-full bg-blue-600"></span> 当前</div>
						<div class="flex items-center gap-2"><span class="w-2 h-2 rounded-full bg-blue-50 border border-blue-200"></span> 已答</div>
						<div class="flex items-center gap-2"><span class="w-2 h-2 rounded-full bg-white border border-gray-300"></span> 未答</div>
					</div>

					<button 
						@click="submitExam"
						class="w-full mt-6 py-3 bg-blue-600 text-white rounded-lg font-bold text-base shadow-md hover:bg-blue-700 transition-all flex items-center justify-center gap-2"
					>
						<span>提交试卷</span>
					</button>
				</div>
			</div>
			
			<!-- 移动端侧边栏 -->
			<div v-if="isMobile" :class="['fixed inset-0 z-50 transition-opacity duration-300', showSidebar ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none']">
				<div class="absolute inset-0 bg-gray-900/20 backdrop-blur-sm" @click="showSidebar = false"></div>
				<div :class="['absolute right-0 top-0 bottom-0 w-80 bg-white/95 backdrop-blur-xl shadow-2xl transform transition-transform duration-300 flex flex-col', showSidebar ? 'translate-x-0' : 'translate-x-full']">
					<div class="p-6 border-b border-gray-100 flex justify-between items-center bg-white/50">
						<h3 class="text-lg font-bold text-gray-800">答题卡</h3>
						<button @click="showSidebar = false" class="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100 transition-colors"><el-icon><Close /></el-icon></button>
					</div>
					<div class="flex-1 overflow-y-auto p-6">
						<div class="grid grid-cols-5 gap-3">
							<button 
								v-for="(q, idx) in paper?.questions" 
								:key="q.id"
								@click="jumpToQuestion(idx); showSidebar = false"
								:class="[
									'aspect-square rounded-xl text-sm font-medium transition-all duration-200 flex items-center justify-center shadow-sm',
									currentIndex === idx ? 'bg-blue-600 text-white shadow-blue-500/30' : 
									(isAnswered(q.id) ? 'bg-blue-50 text-blue-600 border border-blue-100' : 'bg-gray-50 text-gray-500 border border-transparent')
								]"
							>
								{{ idx + 1 }}
							</button>
						</div>
					</div>
					<div class="p-6 border-t border-gray-100 bg-white/50">
						<button @click="submitExam" class="w-full py-3.5 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl font-bold shadow-lg shadow-blue-500/20">提交试卷</button>
					</div>
				</div>
			</div>
		</main>

		<!-- 结果页 -->
		<div v-else class="min-h-screen bg-gray-50 py-4 md:py-10 px-3 md:px-6 lg:px-8 font-sans mt-12 md:mt-16">
			<div class="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-8">
				
				<!-- 左侧侧边栏 (大屏常驻) -->
				<div class="hidden lg:block lg:col-span-4 xl:col-span-3 space-y-6">
					<div class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 sticky top-24">
						<div class="flex items-center justify-between mb-6 pb-4 border-b border-gray-100">
							<div class="flex items-center gap-2">
								<el-icon class="text-blue-600"><Menu /></el-icon>
								<span class="font-bold text-gray-800 text-lg">题目导航</span>
							</div>
							<button @click="scrollToTop" class="text-gray-400 hover:text-blue-600 text-sm flex items-center gap-1 transition-colors px-2 py-1 rounded hover:bg-gray-50">
								<el-icon><Top /></el-icon> 顶部
							</button>
						</div>
						<div class="grid grid-cols-5 gap-2.5 overflow-y-auto custom-scrollbar max-h-[calc(100vh-250px)] pr-1">
							<button 
								v-for="(item, idx) in result?.detail || []" 
								:key="'side-map-'+idx"
								@click="scrollToResultQuestion(idx)"
								class="aspect-square rounded-lg flex items-center justify-center text-sm font-bold transition-all hover:scale-105 hover:shadow-md border-2"
								:class="item.isCorrect ? 'bg-green-50 text-green-600 border-green-100 hover:border-green-200' : 'bg-red-50 text-red-600 border-red-100 hover:border-red-200'"
							>
								{{ idx + 1 }}
							</button>
						</div>
						<div class="mt-6 pt-4 border-t border-gray-100 flex justify-around text-xs font-medium text-gray-500">
							<span class="flex items-center gap-2"><span class="w-2.5 h-2.5 bg-green-500 rounded-full"></span> {{ result?.correctCount || 0 }} 正确</span>
							<span class="flex items-center gap-2"><span class="w-2.5 h-2.5 bg-red-500 rounded-full"></span> {{ (totalQuestions - (result?.correctCount || 0)) }} 错误</span>
						</div>
					</div>
				</div>

				<!-- 右侧主内容区 -->
				<div class="lg:col-span-8 xl:col-span-9 space-y-4 md:space-y-6">
					<!-- 保存状态提示卡片 -->
					<div v-if="examSaveStatus" class="rounded-xl shadow-sm border-2 p-4 md:p-6 relative overflow-hidden" :class="examSaveStatus === 'success' ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'">
						<div class="flex items-start gap-3 md:gap-4">
							<div class="shrink-0">
								<div v-if="examSaveStatus === 'success'" class="w-10 h-10 md:w-12 md:h-12 bg-green-500 rounded-full flex items-center justify-center">
									<el-icon class="text-xl md:text-2xl text-white"><Check /></el-icon>
								</div>
								<div v-else class="w-10 h-10 md:w-12 md:h-12 bg-red-500 rounded-full flex items-center justify-center">
									<el-icon class="text-xl md:text-2xl text-white"><Warning /></el-icon>
								</div>
							</div>
							<div class="flex-1 min-w-0">
								<h3 v-if="examSaveStatus === 'success'" class="text-base md:text-lg font-bold text-green-800 mb-1">✅ 考试记录已保存</h3>
								<h3 v-else class="text-base md:text-lg font-bold text-red-800 mb-1">❌ 考试记录保存失败</h3>
								
								<p v-if="examSaveStatus === 'success'" class="text-sm md:text-base text-green-700">
									您的考试成绩已成功保存到系统，可以在"考试历史"中查看。
								</p>
								<p v-else class="text-sm md:text-base text-red-700 mb-2">
									{{ examSaveError || '网络错误或后端服务异常，考试记录未能保存到数据库。' }}
								</p>
								
								<div v-if="examSaveStatus === 'failed'" class="mt-3 flex flex-wrap gap-2">
									<button @click="retrySubmit" class="px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 transition-all">
										重新提交
									</button>
									<button @click="copyErrorInfo" class="px-4 py-2 bg-white border border-red-300 text-red-700 rounded-lg text-sm font-medium hover:bg-red-50 transition-all">
										复制错误信息
									</button>
								</div>
							</div>
						</div>
					</div>
					
					<!-- 成绩概览卡片 -->
					<div class="bg-white rounded-xl md:rounded-2xl shadow-sm border border-gray-200 p-4 md:p-8 text-center relative overflow-hidden">
						<!-- 装饰背景 -->
						<div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-500 via-indigo-500 to-purple-500"></div>
						<div class="hidden md:block absolute -top-10 -right-10 w-32 h-32 bg-blue-50 rounded-full blur-3xl opacity-60"></div>
						<div class="hidden md:block absolute -bottom-10 -left-10 w-32 h-32 bg-purple-50 rounded-full blur-3xl opacity-60"></div>

						<div class="relative z-10">
							<div class="result-celebration mb-3 md:mb-8" :class="celebrationTheme.themeClass">
								<div class="result-celebration__spark result-celebration__spark--left">{{ celebrationTheme.sparkLeft }}</div>
								<div class="result-celebration__spark result-celebration__spark--right">{{ celebrationTheme.sparkRight }}</div>
								<div class="result-celebration__orb">
									<span class="result-celebration__ring result-celebration__ring--outer"></span>
									<span class="result-celebration__ring result-celebration__ring--middle"></span>
									<div class="result-celebration__icon">
										<el-icon class="text-xl md:text-4xl"><Trophy /></el-icon>
									</div>
								</div>
								<p class="result-celebration__eyebrow">{{ celebrationTheme.eyebrow }}</p>
								<h2 class="result-celebration__headline">{{ celebrationTheme.headline }}</h2>
								<p class="result-celebration__message">{{ resultSummaryMessage }}</p>
								<div class="result-celebration__chips">
									<span v-for="chip in celebrationTheme.chips" :key="chip" class="result-celebration__chip">{{ chip }}</span>
								</div>
							</div>
							
							<div class="bg-gray-50 rounded-lg md:rounded-xl p-2.5 md:p-6 border border-gray-100 max-w-xl mx-auto">
								<div class="text-[10px] md:text-xs text-gray-500 mb-0.5 md:mb-2 font-medium">{{ resultDisplayTitle }}</div>
								<div class="text-3xl md:text-6xl font-bold mb-2 md:mb-6" :class="resultDisplayValueClass">{{ resultDisplayValue }}</div>
								<div class="flex justify-center gap-6 md:gap-8 border-t border-gray-200 pt-2 md:pt-6">
									<div class="text-center">
										<span class="text-gray-400 text-[10px] md:text-xs block">正确率</span>
										<span class="font-bold text-gray-700 text-sm md:text-xl">{{ correctRate }}%</span>
									</div>
									<div class="text-center border-l border-gray-200 pl-6">
										<span class="text-gray-400 text-[10px] md:text-xs block">用时</span>
										<span class="font-bold text-gray-700 text-sm md:text-xl">{{ formatTime(Math.max(0, resolveExamDurationSeconds() - timeLeft)) }}</span>
									</div>
								</div>
							</div>

							<div class="flex gap-2 md:gap-4 justify-center mt-3 md:mt-8">
								<button @click="restartExam" class="px-3 md:px-8 py-1.5 md:py-3 bg-white border border-gray-200 text-gray-700 rounded-lg font-medium text-xs md:text-base hover:bg-gray-50 transition-all shadow-sm">再测一次</button>
								<button @click="goBack" class="px-3 md:px-8 py-1.5 md:py-3 bg-blue-600 text-white rounded-lg font-medium text-xs md:text-base hover:bg-blue-700 shadow-md transition-all">返回列表</button>
							</div>
						</div>
					</div>

					<!-- 能力分析与推荐 -->
					<div class="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
						<!-- 雷达图 -->
						<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 md:p-6">
							<h3 class="text-base font-bold text-gray-800 mb-4 flex items-center gap-2">
								<span class="w-1 h-4 bg-purple-600 rounded-full"></span>
								能力雷达图
								<span v-if="aiAnalysisLoading" class="text-xs text-gray-400 font-normal ml-2">AI分析中...</span>
							</h3>
							<div class="relative aspect-square max-h-[300px] mx-auto">
								<canvas ref="radarChartRef" class="w-full h-full" style="position: relative; z-index: 1;"></canvas>
								<div v-if="aiAnalysisLoading" class="absolute inset-0 flex items-center justify-center bg-white/80 z-10">
									<div class="flex flex-col items-center gap-2">
										<div class="w-8 h-8 border-3 border-purple-200 border-t-purple-600 rounded-full animate-spin"></div>
										<span class="text-sm text-gray-500">AI正在分析您的能力...</span>
									</div>
								</div>
								<div v-else-if="!radarReady" class="absolute inset-0 flex items-center justify-center text-sm text-gray-400 z-10 bg-white">
									暂无能力分析数据
								</div>
							</div>
							<div v-if="aiAnalysisResult && aiAnalysisResult.summary" class="mt-4 p-3 bg-purple-50 rounded-lg text-sm text-purple-700">
								<span class="font-medium">AI评价：</span>{{ aiAnalysisResult.summary }}
							</div>
						</div>

						<!-- 推荐课程 -->
						<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 md:p-6">
							<h3 class="text-base font-bold text-gray-800 mb-4 flex items-center gap-2">
								<span class="w-1 h-4 bg-green-600 rounded-full"></span>
								智能推荐课程
								<span v-if="aiAnalysisLoading" class="text-xs text-gray-400 font-normal ml-2">AI推荐中...</span>
							</h3>
							<div v-if="aiAnalysisLoading" class="h-[300px] flex items-center justify-center">
								<div class="flex flex-col items-center gap-2">
									<div class="w-8 h-8 border-3 border-green-200 border-t-green-600 rounded-full animate-spin"></div>
									<span class="text-sm text-gray-500">AI正在为您推荐课程...</span>
								</div>
							</div>
							<div v-else-if="recommendedCourses && recommendedCourses.length" class="space-y-3">
								<div v-for="(course, idx) in recommendedCourses" :key="idx" class="flex gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors cursor-pointer group">
									<div class="w-20 h-14 bg-gray-200 rounded overflow-hidden shrink-0">
										<img :src="course.cover" class="w-full h-full object-cover" />
									</div>
									<div class="flex-1 min-w-0">
										<h4 class="text-sm font-bold text-gray-800 truncate group-hover:text-blue-600">{{ course.title }}</h4>
										<p class="text-xs text-gray-500 mt-1 line-clamp-2">{{ course.reason }}</p>
									</div>
								</div>
							</div>
							<div v-else class="h-[300px] flex items-center justify-center text-sm text-gray-400">
								暂无推荐课程
							</div>
						</div>
					</div>

					<!-- 详细解析列表 -->
					<div v-if="result?.detail" class="bg-white rounded-xl md:rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
						<div class="px-4 md:px-8 py-3 md:py-6 border-b border-gray-100 bg-gray-50/50 flex items-center justify-between">
							<h3 class="text-sm md:text-lg font-bold text-gray-800 flex items-center gap-2">
								<div class="w-1 h-4 md:h-5 bg-blue-600 rounded-full"></div>
								题目解析
							</h3>
							<div class="text-xs md:text-sm text-gray-500">
								共 {{ result.detail.length }} 题
							</div>
						</div>
						
						<div class="p-3 md:p-8 space-y-4 md:space-y-8">
							<div 
								v-for="(item, idx) in result.detail" 
								:key="item.id" 
								:id="'result-q-'+idx"
								class="scroll-mt-20 md:scroll-mt-32 pb-4 md:pb-8 border-b border-gray-100 last:border-0 last:pb-0"
							>
								<div class="flex justify-between items-start gap-2 md:gap-4 mb-2 md:mb-4">
									<div class="flex gap-2 md:gap-4 flex-1">
										<span 
											class="shrink-0 w-6 h-6 md:w-8 md:h-8 rounded-md md:rounded-lg text-xs md:text-sm font-bold flex items-center justify-center text-white shadow-sm"
											:class="item.isCorrect ? 'bg-green-500' : 'bg-red-500'"
										>{{ idx + 1 }}</span>
										<div class="flex-1 min-w-0">
											<div class="flex flex-wrap items-center gap-1 md:gap-2 mb-1 md:mb-2">
												<span class="text-[10px] md:text-xs font-bold px-1.5 md:px-2.5 py-0.5 md:py-1 rounded text-gray-600 bg-gray-100">{{ getQuestionTypeName(item.type) }}</span>
												<span class="text-[10px] md:text-xs font-bold px-1.5 md:px-2.5 py-0.5 md:py-1 rounded" :class="item.isCorrect ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-600'">
													{{ item.isCorrect ? '正确' : '错误' }}
												</span>
											</div>
											<p class="text-gray-800 font-medium text-sm md:text-lg leading-relaxed">{{ item.title }}</p>
										</div>
									</div>
									
									<!-- 收藏按钮 -->
									<button 
										@click="handleToggleFavorite(item)"
										class="shrink-0 p-1 md:p-2 rounded-full transition-colors hover:bg-gray-50"
										:class="item.isFavorite ? 'text-yellow-400' : 'text-gray-300'"
										:disabled="favoriteLoading[item.id]"
									>
										<el-icon class="text-lg md:text-2xl">
											<StarFilled v-if="item.isFavorite" />
											<Star v-else />
										</el-icon>
									</button>
								</div>
								
								<!-- 选项展示 -->
								<div class="pl-8 md:pl-12 mb-3 md:mb-5 space-y-1.5 md:space-y-3" v-if="item.options && item.options.length > 0">
									<div v-for="(opt, optIdx) in item.options" :key="optIdx" class="text-xs md:text-base text-gray-600 flex gap-2 md:gap-3 p-2 md:p-3 rounded-lg hover:bg-gray-50">
										<span class="font-mono font-bold text-gray-400">{{ String.fromCharCode(65 + optIdx) }}.</span>
										<span class="leading-relaxed">{{ opt }}</span>
									</div>
								</div>
								
								<div class="grid grid-cols-2 gap-2 md:gap-6 mb-3 md:mb-5 pl-8 md:pl-12">
									<div class="p-2 md:p-4 rounded-lg md:rounded-xl border" :class="item.isCorrect ? 'bg-green-50/50 border-green-100' : 'bg-red-50/50 border-red-100'">
										<span class="text-[10px] md:text-xs font-bold block mb-1" :class="item.isCorrect ? 'text-green-600' : 'text-red-600'">你的答案</span>
										<span class="font-bold text-sm md:text-lg break-all" :class="item.isCorrect ? 'text-green-700' : 'text-red-700'">
											{{ formatAnswerDisplay(item.userAnswer, item) }}
										</span>
									</div>
									<div class="bg-blue-50/50 p-2 md:p-4 rounded-lg md:rounded-xl border border-blue-100">
										<span class="text-[10px] md:text-xs font-bold text-blue-600 block mb-1">正确答案</span>
										<span class="font-bold text-sm md:text-lg text-blue-700 break-all">{{ formatAnswerDisplay(item.correctAnswer, item) }}</span>
									</div>
								</div>
								
								<div class="bg-gray-50 p-3 md:p-5 rounded-lg md:rounded-xl border border-gray-200 text-gray-600 ml-8 md:ml-12 relative overflow-hidden">
									<div class="absolute top-0 left-0 w-1 h-full bg-gray-300"></div>
									<div class="flex items-start gap-2 md:gap-3 relative z-10">
										<el-icon class="mt-0.5 text-blue-500 shrink-0 text-sm md:text-lg"><InfoFilled /></el-icon>
										<div>
											<span class="font-bold text-gray-800 text-xs md:text-sm block mb-0.5 md:mb-1">解析</span>
											<span class="leading-relaxed text-xs md:text-base">{{ item.analysis }}</span>
										</div>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- 小屏悬浮按钮 -->
				<div class="lg:hidden fixed right-4 bottom-6 flex flex-col gap-3 z-50 print:hidden">
					<el-popover placement="top-end" :width="280" trigger="click" popper-class="!p-0 rounded-xl shadow-xl border-gray-100 !max-w-[calc(100vw-32px)]">
						<template #reference>
							<button class="w-12 h-12 bg-blue-600 text-white rounded-full shadow-lg shadow-blue-500/30 flex items-center justify-center hover:bg-blue-700 transition-all hover:scale-110 active:scale-95" title="题目导航">
								<el-icon class="text-xl"><Menu /></el-icon>
							</button>
						</template>
						<div class="p-4 bg-white rounded-xl">
							<div class="flex items-center justify-between mb-3 pb-2 border-b border-gray-100">
								<h4 class="font-bold text-gray-800 text-sm">题目导航</h4>
								<div class="flex gap-2 text-xs">
									<span class="flex items-center gap-1"><span class="w-2 h-2 bg-green-500 rounded-full"></span> 对</span>
									<span class="flex items-center gap-1"><span class="w-2 h-2 bg-red-500 rounded-full"></span> 错</span>
								</div>
							</div>
							<div class="grid grid-cols-6 gap-1.5 max-h-[250px] overflow-y-auto custom-scrollbar">
								<button v-for="(item, idx) in result?.detail || []" :key="'float-map-'+idx" @click="scrollToResultQuestion(idx)" class="w-full aspect-square rounded-md flex items-center justify-center text-xs font-bold transition-all hover:ring-2 hover:ring-blue-300 border" :class="item.isCorrect ? 'bg-green-50 text-green-600 border-green-100' : 'bg-red-50 text-red-600 border-red-100'">{{ idx + 1 }}</button>
							</div>
						</div>
					</el-popover>
					<button @click="scrollToTop" class="w-14 h-14 bg-white text-gray-600 rounded-full shadow-lg border border-gray-100 flex items-center justify-center hover:bg-gray-50 transition-all hover:scale-110 active:scale-95" title="回到顶部">
						<el-icon class="text-2xl"><Top /></el-icon>
					</button>
				</div>

			</div>
		</div>
	</div>

	<div v-else-if="loadError" class="min-h-screen flex items-center justify-center bg-gray-50">
		<div class="text-center">
			<el-icon class="text-4xl text-gray-400 mb-4"><Warning /></el-icon>
			<h2 class="text-xl font-bold text-gray-800 mb-2">无法加载考试数据</h2>
			<p class="text-gray-500 mb-4">该考试缺少必要的试卷信息，请联系管理员解决。</p>
			<button
				@click="goBack"
				class="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-all"
			>
				返回列表
			</button>
		</div>
	</div>

	<div v-else class="min-h-screen flex items-center justify-center bg-gray-50">
		<div class="text-center">
			<div class="w-16 h-16 border-4 border-blue-200 border-t-blue-500 rounded-full animate-spin mx-auto mb-4"></div>
			<p class="text-gray-500 font-medium">试卷加载中...</p>
		</div>
	</div>
</template>

<script setup>
import { ref, reactive, onMounted, watch, onBeforeUnmount, computed, nextTick } from 'vue';
import { useRoute, useRouter, onBeforeRouteLeave } from 'vue-router';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Loading, Clock, ArrowLeft, ArrowRight, Menu, Close, Check, Trophy, InfoFilled, Star, StarFilled, Top, Warning } from '@element-plus/icons-vue';
import ExamQuestion from './components/ExamQuestion.vue';
import { fetchExamPaper, generateCustomPaper, submitExamResult, saveExamQuestions, analyzeExamResult, formatLocalDateTime } from '../api/question';
import { generateCustomPaper as generateFromBank, toggleFavorite, submitAnswer } from '@/api/question';
import { getDeptDailyQuestions } from '@/api/deptQuestion';
import { getMembershipUsageLimits } from '@/api/membership';
import { getUserId } from '@/utils/userStorage';
import { Chart, RadarController, RadialLinearScale, PointElement, LineElement, Filler, Tooltip, Legend } from 'chart.js';
import logger from '@/utils/logger'
import { getResultDisplayTextClass, getResultDisplayTitle, getResultDisplayValue, normalizeLevelThresholds, normalizeResultDisplayMode, resolveScoreLevel, usesLevelResultDisplay } from '../utils/resultDisplay';
Chart.register(RadarController, RadialLinearScale, PointElement, LineElement, Filler, Tooltip, Legend);

const route = useRoute();
const router = useRouter();
const props = defineProps(['examId']);
const DEFAULT_EXAM_DURATION_SECONDS = 60 * 60;
const DEFAULT_PASS_SCORE = 80;

const paper = ref(null);
const answers = reactive({});
const timeLeft = ref(DEFAULT_EXAM_DURATION_SECONDS);
const startTime = ref(null); // 考试开始时间
let timer = null;
const isDark = ref(false);
const currentMode = ref('single');

const currentIndex = ref(0);
const submitted = ref(false);
const showResult = ref(false);
const result = ref(null);

// 考试保存状态
const examSaveStatus = ref(null); // 'success' | 'failed' | null
const examSaveError = ref('');
const lastSubmitData = ref(null); // 保存最后一次提交的数据，用于重试
const freeQuizDailyLimit = ref(1); // 默认值，优先以后端下发为准

const loadMembershipLimits = async () => {
	try {
		const res = await getMembershipUsageLimits();
		const payload = res?.data || res;
		if (payload?.code === 200 && payload?.data?.freeQuizDailyLimit) {
			freeQuizDailyLimit.value = Number(payload.data.freeQuizDailyLimit) || freeQuizDailyLimit.value;
		}
	} catch {
		logger.debug('获取考试限额失败，使用默认值');
	}
};

const showQuizLimitUpgradeDialog = async () => {
	try {
		await ElMessageBox.confirm(
			buildQuizLimitMessage(),
			'今日测试次数已达上限',
			{
				confirmButtonText: '立即升级',
				cancelButtonText: '知道了',
				type: 'warning',
				center: true
			}
		);
		router.push('/member-center');
	} catch {}
};

const toPositiveNumber = (value) => {
	const numeric = Number(value);
	if (!Number.isFinite(numeric) || numeric <= 0) return null;
	return numeric;
};

const getStorageUserId = () => {
	const userId = getUserId();
	if (userId === null || userId === undefined || userId === '') return 'guest';
	return String(userId);
};

const resolveExamDurationSeconds = (paperLike = paper.value) => {
	const durationSeconds = toPositiveNumber(
		paperLike?.durationSeconds ?? paperLike?.timeLimitSeconds ?? route.query.durationSeconds
	);
	if (durationSeconds) return Math.floor(durationSeconds);
	const durationMinutes = toPositiveNumber(
		paperLike?.duration ?? paperLike?.timeLimit ?? route.query.duration
	);
	if (durationMinutes) return Math.floor(durationMinutes * 60);
	return DEFAULT_EXAM_DURATION_SECONDS;
};

const resolvePassScore = (paperLike = paper.value) => {
	const passScore = toPositiveNumber(
		paperLike?.passScore ?? paperLike?.passingScore ?? route.query.passScore
	);
	return passScore ?? DEFAULT_PASS_SCORE;
};

const getLegacySessionKey = () => {
	const examId = route.query.examId || route.query.id || props.examId;
	if (examId) return `exam_session_exam_${examId}`;
	const bank = route.query.bank != null ? String(route.query.bank) : 'default';
	const category = route.query.category || 'default';
	const limit = route.query.limit || 20;
	return `exam_session_${bank}_${category}_${limit}`;
};

const getSessionKey = () => {
	const userId = getStorageUserId();
	const examId = route.query.examId || route.query.id || props.examId;
	if (examId) return `exam_session_u_${userId}_exam_${examId}`;
	const bank = route.query.bank != null ? String(route.query.bank) : 'default';
	const category = route.query.category || 'default';
	const limit = route.query.limit || 20;
	return `exam_session_u_${userId}_${bank}_${category}_${limit}`;
};

const removeSessionCache = () => {
	const sessionKey = getSessionKey();
	const legacySessionKey = getLegacySessionKey();
	sessionStorage.removeItem(sessionKey);
	if (legacySessionKey !== sessionKey) {
		sessionStorage.removeItem(legacySessionKey);
	}
};

// 移动端相关
const isMobile = ref(false);
const showSidebar = ref(false);

const loadError = ref(false);

// 防作弊相关
const switchCount = ref(0);
const MAX_SWITCH_COUNT = 3;

// 用户信息
const totalScore = ref(0);
const recommendedCourses = ref([]);
const radarChartRef = ref(null);
const radarReady = ref(false);
let radarInitTries = 0;
let radarChartInstance = null;

// AI分析相关
const aiAnalysisLoading = ref(false);
const aiAnalysisResult = ref(null);
const resultDisplayMode = computed(() => normalizeResultDisplayMode(paper.value?.resultDisplayMode ?? route.query.resultDisplayMode));
const resultDisplayConfig = computed(() => normalizeLevelThresholds(paper.value || route.query || {}));
const isLevelResultDisplay = computed(() => usesLevelResultDisplay(resultDisplayMode.value));
const resultLevel = computed(() => resolveScoreLevel(totalScore.value, resultDisplayConfig.value));
const resultDisplayTitle = computed(() => getResultDisplayTitle(resultDisplayMode.value));
const resultDisplayValue = computed(() => getResultDisplayValue(totalScore.value, resultDisplayMode.value, resultDisplayConfig.value));
const resultDisplayValueClass = computed(() => {
	const baseClass = getResultDisplayTextClass(totalScore.value, resultDisplayMode.value, resultDisplayConfig.value);
	return isLevelResultDisplay.value ? baseClass : `${baseClass} font-mono`;
});
const resultSummaryMessage = computed(() => {
	return isLevelResultDisplay.value ? `本试卷按等级展示结果，当前评估为${resultLevel.value.label}` : '恭喜你完成了所有题目';
});
const correctRate = computed(() => {
	const total = totalQuestions.value;
	return total > 0 ? Math.round(((result.value?.correctCount || 0) / total) * 100) : 0;
});

const celebrationTheme = computed(() => {
	const score = Number(totalScore.value) || 0;
	const currentCorrectRate = correctRate.value;
	const levelLabel = resultLevel.value?.label || '';
	const byLevel = isLevelResultDisplay.value;

	if ((byLevel && levelLabel === '优秀') || (!byLevel && score >= 90)) {
		return {
			themeClass: 'result-celebration--excellent',
			eyebrow: '高光时刻',
			headline: '这次发挥很亮眼',
			sparkLeft: '优秀',
			sparkRight: '继续保持',
			chips: [`正确率 ${currentCorrectRate}%`, '状态在线', '值得表扬']
		};
	}

	if ((byLevel && levelLabel === '合格') || (!byLevel && score >= 60)) {
		return {
			themeClass: 'result-celebration--pass',
			eyebrow: '稳稳过关',
			headline: '这次表现很扎实',
			sparkLeft: '合格',
			sparkRight: '再冲一把',
			chips: [`正确率 ${currentCorrectRate}%`, '基础稳住了', '继续精进']
		};
	}

	return {
		themeClass: 'result-celebration--effort',
		eyebrow: '别急，继续向前',
		headline: '这次是下一次进步的起点',
		sparkLeft: '继续努力',
		sparkRight: '你会更好',
		chips: [`正确率 ${currentCorrectRate}%`, '找到了提升点', '下次会更稳']
	};
});

const setDefaultRecommendations = () => {
	const score = Number(totalScore.value) || 0;
	if (recommendedCourses.value && recommendedCourses.value.length) return;
	if (score >= 80) {
		recommendedCourses.value = [
			{
				title: '服务标准化进阶训练',
				cover: 'https://images.unsplash.com/photo-1556740758-90de374c12ad?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
				reason: '成绩优秀，建议进一步巩固服务标准化与细节管理。'
			},
			{
				title: '沟通与影响力提升',
				cover: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
				reason: '高分基础上提升沟通影响力，增强客诉与协作能力。'
			},
			{
				title: '突发事件处置复盘',
				cover: 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
				reason: '补齐应急处置与复盘方法，提升稳定输出。'
			}
		];
		return;
	}
	if (score >= 60) {
		recommendedCourses.value = [
			{
				title: '酒店服务礼仪进阶',
				cover: 'https://images.unsplash.com/photo-1556740758-90de374c12ad?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
				reason: '巩固服务流程与礼仪细节，提升一致性与稳定性。'
			},
			{
				title: '客诉沟通艺术',
				cover: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
				reason: '提升沟通技巧，掌握结构化表达与同理应对。'
			},
			{
				title: '岗位合规与风险防控',
				cover: 'https://images.unsplash.com/photo-1551836022-deb4988cc6c0?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
				reason: '梳理关键合规点，降低操作风险与差错率。'
			}
		];
		return;
	}
	recommendedCourses.value = [
		{
			title: '基础服务流程速成',
			cover: 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
			reason: '从基础流程入手，先把关键动作做对、做熟。'
		},
		{
			title: '突发事件应急预案',
			cover: 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
			reason: '建立应急处理框架，提升临场判断与处置效率。'
		},
		{
			title: '沟通技巧入门',
			cover: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
			reason: '提升沟通基本功，减少误解与升级冲突。'
		}
	];
};

const normalizeRadarDimensions = (aiData = null) => {
	const rawDimensions = Array.isArray(aiData?.radarDimensions) ? aiData.radarDimensions : [];
	const normalized = rawDimensions
		.map(item => {
			if (!item || typeof item !== 'object') return null;
			const label = String(item.label || item.name || '').trim();
			const score = Number(item.score);
			if (!label || !Number.isFinite(score)) return null;
			return {
				label: label.slice(0, 8),
				score: Math.max(0, Math.min(100, Math.round(score)))
			};
		})
		.filter(Boolean)
		.slice(0, 6);

	if (normalized.length >= 3) {
		return normalized;
	}

	const labels = Array.isArray(aiData?.radarLabels) ? aiData.radarLabels : [];
	const values = Array.isArray(aiData?.radarData) ? aiData.radarData : [];
	if (labels.length >= 3 && labels.length === values.length) {
		return labels.slice(0, 6).map((label, index) => ({
			label: String(label || '').trim().slice(0, 8) || `维度${index + 1}`,
			score: Math.max(0, Math.min(100, Math.round(Number(values[index]) || 0)))
		}));
	}

	const fallbackLabels = ['服务流程', '业务规范', '场景判断', '沟通应对', '细节执行'];
	const base = Math.max(40, Number(totalScore.value) || 0);
	return fallbackLabels.map((label, index) => ({
		label,
		score: Math.min(100, Math.max(20, Math.round(base + (index - 2) * 4)))
	}));
};

const initRadarChart = (aiData = null) => {
	const canvas = radarChartRef.value;
	if (!canvas) {
		if (radarInitTries < 10) {
			radarInitTries += 1;
			logger.warn('⏳ 等待canvas渲染，重试次数:', radarInitTries);
			// 使用setTimeout延迟重试，给DOM更多时间渲染
			setTimeout(() => initRadarChart(aiData), 200);
		} else {
			logger.error('❌ canvas未找到，使用默认推荐');
			setDefaultRecommendations();
		}
		return;
	}

	// 检查canvas尺寸
	const rect = canvas.getBoundingClientRect();
	logger.warn('📐 canvas尺寸:', rect.width, 'x', rect.height);

	if (rect.width === 0 || rect.height === 0) {
		if (radarInitTries < 10) {
			radarInitTries += 1;
			logger.warn('⏳ canvas尺寸为0，等待渲染，重试次数:', radarInitTries);
			setTimeout(() => initRadarChart(aiData), 200);
		} else {
			logger.error('❌ canvas尺寸始终为0，使用默认推荐');
			setDefaultRecommendations();
		}
		return;
	}

	logger.warn('✅ canvas已找到，开始绑定雷达图');
	radarInitTries = 0;
	radarReady.value = false;

	try {
		if (radarChartInstance) radarChartInstance.destroy();

		const radarDimensions = normalizeRadarDimensions(aiData);
		const labels = radarDimensions.map(item => item.label);
		const data = radarDimensions.map(item => item.score);
		logger.warn('📊 使用雷达图维度数据:', radarDimensions);

		radarChartInstance = new Chart(canvas, {
			type: 'radar',
			data: {
				labels,
				datasets: [{
					label: '能力模型',
					data: data,
					fill: true,
					backgroundColor: 'rgba(147, 51, 234, 0.2)',
					borderColor: 'rgb(147, 51, 234)',
					pointBackgroundColor: 'rgb(147, 51, 234)',
					pointBorderColor: '#fff',
					pointHoverBackgroundColor: '#fff',
					pointHoverBorderColor: 'rgb(147, 51, 234)'
				}]
			},
			options: {
				responsive: true,
				maintainAspectRatio: false,
				elements: {
					line: { borderWidth: 3 }
				},
				scales: {
					r: {
						angleLines: { display: false },
						suggestedMin: 0,
						suggestedMax: 100,
						pointLabels: {
							font: { size: 12, weight: 'bold' }
						}
					}
				},
				plugins: {
					legend: { display: false }
				}
			}
		});

		radarReady.value = true;
		logger.warn('✅ 雷达图初始化成功, radarReady:', radarReady.value);
	} catch (e) {
		logger.error('❌ 雷达图初始化失败:', e);
		radarReady.value = false;
	} finally {
		// 如果有AI推荐课程，使用AI推荐；否则使用默认推荐
		if (aiData && aiData.recommendedCourses && aiData.recommendedCourses.length > 0) {
			recommendedCourses.value = aiData.recommendedCourses.map(course => ({
				id: course.id,
				title: course.title,
				cover: course.cover || getDefaultCourseCover(),
				reason: course.reason || '根据您的考试表现推荐'
			}));
			logger.warn('📚 使用AI推荐课程:', recommendedCourses.value);
		} else {
			setDefaultRecommendations();
		}
	}
};

// 获取默认课程封面
const getDefaultCourseCover = () => {
	const covers = [
		'https://images.unsplash.com/photo-1556740758-90de374c12ad?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
		'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
		'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80'
	];
	return covers[Math.floor(Math.random() * covers.length)];
};

// 计算属性
const totalQuestions = computed(() => paper.value?.questions.length || 0);
const answeredCount = computed(() => {
	return Object.values(answers).filter(answer => 
		answer !== '' && answer !== null && answer !== undefined && 
		(Array.isArray(answer) ? answer.length > 0 : true)
	).length;
});
const progressPercentage = computed(() => {
	return totalQuestions.value > 0 ? (answeredCount.value / totalQuestions.value) * 100 : 0;
});

// 计算是否可以上一题
const canGoPrev = computed(() => {
	if (!paper.value) return false;
	return currentIndex.value > 0;
});

// 计算是否是最后一题
const isLastQuestion = computed(() => {
	if (!paper.value) return false;
	return currentIndex.value === paper.value.questions.length - 1;
});

// 检测移动端
const checkMobile = () => {
	isMobile.value = window.innerWidth <= 768;
};

// 切换侧边栏显示
const toggleSidebar = () => {
	showSidebar.value = !showSidebar.value;
};

// 格式化时间
function formatTime(sec) {
	const m = Math.floor(sec / 60)
		.toString()
		.padStart(2, '0');
	const s = (sec % 60).toString().padStart(2, '0');
	return `${m}:${s}`;
}

// 获取题型名称
function getQuestionTypeName(type) {
	const map = {
		'single': '单选题',
		'multiple': '多选题',
		'judge': '判断题',
		'text': '简答题',
		'fill': '填空题',
		'code': '代码题'
	};
	return map[type] || '未知题型';
}

// 判断题目是否已作答
function isAnswered(questionId) {
	const answer = answers[questionId];
	return answer !== '' && answer !== null && answer !== undefined && 
		(Array.isArray(answer) ? answer.length > 0 : true);
}

// 跳转到指定题目
function jumpToQuestion(index) {
	currentIndex.value = index;
	// 如果是全览模式，滚动到对应位置
	if (currentMode.value === 'all') {
		setTimeout(() => {
			const el = document.getElementById(`q-${index}`);
			if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
		}, 100);
	}
}

// 上一题
function prev() {
	if (currentIndex.value > 0) {
		currentIndex.value--;
	}
}

// 下一题
function next() {
	if (isLastQuestion.value) {
		handleSubmit();
	} else {
		currentIndex.value++;
	}
}

// 返回
function goBack() {
	const hasId = route.query.id || route.query.examId || props.examId;
	const isRandom = route.query.random === 'true' || route.query.random === true || !hasId;

	// 只有在考试中（未出结果且未提交）才提示
	if (!showResult.value && !submitted.value) {
		ElMessageBox.confirm(
			isRandom
				? '测验正在进行中，退出将不保存当前进度，确定要退出吗？'
				: '考试正在进行中，退出将无法保存当前进度，确定要退出吗？',
			'退出考试', 
			{
				confirmButtonText: isRandom ? '退出' : '确定退出',
				cancelButtonText: '继续答题',
				type: 'warning',
				draggable: true,
			}
		).then(() => {
			try {
				removeSessionCache();
			} catch (e) {}
			clearProgress();
			router.back();
		}).catch(() => {});
	} else {
		router.back();
	}
}

// 提交试卷
function handleSubmit() {
	if (answeredCount.value < totalQuestions.value) {
		ElMessageBox.confirm(
			`还有 ${totalQuestions.value - answeredCount.value} 道题未完成，确定要提交吗？`, 
			'提示', 
			{
				confirmButtonText: '确认提交',
				cancelButtonText: '继续答题',
				type: 'warning'
			}
		).then(() => {
			submitExam();
		}).catch(() => {});
	} else {
		ElMessageBox.confirm('确认提交试卷吗？', '提示', {
			confirmButtonText: '确认',
			cancelButtonText: '取消',
			type: 'info'
		}).then(() => {
			submitExam();
		}).catch(() => {});
	}
}

// 重新考试
function restartExam() {
	submitted.value = false;
	showResult.value = false;
	result.value = null;
	totalScore.value = 0;
	// 清空答案
	Object.keys(answers).forEach(key => {
		answers[key] = Array.isArray(answers[key]) ? [] : '';
	});
	currentIndex.value = 0;
	timeLeft.value = resolveExamDurationSeconds();
	startTime.value = Date.now();
	startTimer();
	clearProgress();
}

// 核心提交逻辑
async function submitExam() {
	if (submitted.value) return;
	submitted.value = true;
	if (timer) clearInterval(timer);

	// 清除考试缓存（提交后下次可以重新生成题目）
	removeSessionCache();

	// 自动批改
	const gradeResult = autoGrade();
	result.value = gradeResult;
	totalScore.value = gradeResult.score;
	showResult.value = true;

	// 启动AI分析（异步，不阻塞结果显示）
	aiAnalysisLoading.value = true;
	const examDetailsForAI = gradeResult.details.map(d => ({
		title: d.title,
		type: d.type,
		isCorrect: d.isCorrect,
		userAnswer: d.userAnswer,
		correctAnswer: d.correctAnswer
	}));

	// 异步调用AI分析
	analyzeExamResult(
		examDetailsForAI,
		gradeResult.score,
		gradeResult.correctCount,
		gradeResult.totalCount,
		resultDisplayMode.value,
		resultDisplayConfig.value
	)
		.then(aiData => {
			aiAnalysisLoading.value = false;
			if (aiData) {
				aiAnalysisResult.value = aiData;
				logger.warn('🤖 AI分析完成:', aiData);
				logger.warn('🤖 radarData:', aiData.radarData);
				logger.warn('🤖 recommendedCourses:', aiData.recommendedCourses);
				// 使用AI数据更新雷达图和推荐课程，延迟500ms确保DOM渲染完成
				setTimeout(() => {
					radarInitTries = 0;
					initRadarChart(aiData);
				}, 500);
			} else {
				logger.warn('🤖 AI分析返回空数据，使用默认数据');
				// AI分析失败，使用默认数据
				setTimeout(() => {
					radarInitTries = 0;
					initRadarChart(null);
				}, 500);
			}
		})
		.catch(err => {
			aiAnalysisLoading.value = false;
			logger.error('AI分析失败:', err);
			setTimeout(() => {
				radarInitTries = 0;
				initRadarChart(null);
			}, 500);
		});

	const totalDurationSeconds = resolveExamDurationSeconds();
	const durationByTimer = Math.max(0, totalDurationSeconds - timeLeft.value);
	const duration = startTime.value
		? Math.max(0, Math.floor((Date.now() - startTime.value) / 1000))
		: durationByTimer;
	const passScore = resolvePassScore();
	const isPassed = totalScore.value >= passScore;
	
	const categoryFromRoute = route.query.category ? decodeURIComponent(route.query.category) : undefined;
	const limitFromRoute = route.query.limit ? Number(route.query.limit) : undefined;
	const hasId = route.query.id || route.query.examId || props.examId;
	const isRandom = route.query.random === 'true' || route.query.random === true || (!hasId && (limitFromRoute !== undefined || categoryFromRoute !== undefined));
	const attemptType = isRandom ? 'practice' : 'exam';
	const attemptScene = isRandom ? 'practice' : 'exam';
	
	// 获取考试名称
	const examName = paper.value?.name || route.query.title || (attemptType === 'practice' ? '综合平时测验' : '正式考试');
	
	logger.debug('📋 准备提交考试结果:', {
		examId: props.examId || route.query.examId || route.query.id,
		examName: examName,
		score: totalScore.value,
		isPassed: isPassed,
		passScore,
		attemptType: attemptType,
		attemptScene: attemptScene,
		duration: duration
	});
	
	// 构建提交数据
	const submitData = {
		examId: props.examId || route.query.examId || route.query.id || null,
		examName: examName,
		title: examName,
		resultDisplayMode: resultDisplayMode.value,
		levelPassScore: resultDisplayConfig.value.levelPassScore,
		levelExcellentScore: resultDisplayConfig.value.levelExcellentScore,
		score: totalScore.value,
		isPassed: isPassed ? 1 : 0,
		passScore,
		questionCount: totalQuestions.value,
		correctCount: gradeResult.correctCount,
		duration: duration,
		submittedAt: formatLocalDateTime(),
		attemptType: attemptType,
		attemptScene: attemptScene
	};
	
	// 保存提交数据，用于重试
	lastSubmitData.value = submitData;
	
	try {
		// 提交考试结果到后端
		const submitResult = await submitExamResult(submitData);

		logger.debug('📋 考试结果提交完成:', submitResult);

		// 检查是否真的保存成功
		if (submitResult && submitResult.data) {
			// 检查是否是非会员限制错误
			const errorMsg = submitResult.data.msg || submitResult.data.error || '';
			if (errorMsg.includes('非会员') || errorMsg.includes('升级会员')) {
				examSaveStatus.value = 'failed';
				examSaveError.value = buildQuizLimitMessage();
				logger.warn('⚠️ 非会员测试次数限制:', errorMsg);

				// 显示升级会员弹窗
				await showQuizLimitUpgradeDialog();
				return;
			}

			if (submitResult.data.saved === false) {
				// API调用失败
				examSaveStatus.value = 'failed';
				examSaveError.value = submitResult.data.msg || submitResult.data.error || '网络错误，请检查后端服务是否正常运行';
				logger.error('❌ 考试记录未保存到服务器:', examSaveError.value);

				ElMessage.error({
					message: '考试记录保存失败：' + examSaveError.value,
					duration: 5000,
					showClose: true
				});
			} else if (submitResult.data.code === 200 && submitResult.data.saved !== false) {
				// 保存成功，获取 attemptId
				const attemptId = submitResult.data.attemptId;
				logger.debug('✅ 考试记录已成功保存到数据库, attemptId:', attemptId);
				
				// 批量保存所有题目的答题详情
				if (attemptId && paper.value && paper.value.questions) {
					try {
						logger.debug(`📝 开始保存 ${paper.value.questions.length} 道题目的详情`);
						
						// 构建题目详情列表
						const questionDetails = paper.value.questions.map(q => {
							const userAnswer = answers[q.id];
							const isCorrect = gradeResult.details.find(d => d.id === q.id)?.isCorrect || false;
							
							return {
								questionId: q.originalId || q.id,
								questionText: q.title,
								questionType: q.type,
								questionSource: q.questionSource || q.source || q.bank || 'ota',
								userAnswer: formatUserAnswer(userAnswer, q.type),
								correctAnswer: formatCorrectAnswer(q.answer, q.type),
								explanation: q.analysis || '暂无解析',
								optionA: q.options && q.options[0] ? q.options[0] : null,
								optionB: q.options && q.options[1] ? q.options[1] : null,
								optionC: q.options && q.options[2] ? q.options[2] : null,
								optionD: q.options && q.options[3] ? q.options[3] : null,
								isCorrect: isCorrect
							};
						});
						
						// 调用批量保存 API
						await saveExamQuestions(attemptId, questionDetails);
						logger.debug('✅ 题目详情保存成功');
					} catch (err) {
						logger.error('❌ 保存题目详情失败:', err);
						// 题目详情保存失败不影响考试记录的保存状态
					}
				}
				
				examSaveStatus.value = 'success';
				examSaveError.value = '';

				ElMessage.success('考试已提交，成绩已保存！');
			} else {
				// 其他错误
				examSaveStatus.value = 'failed';
				examSaveError.value = '保存状态未知，请联系管理员确认';
				logger.warn('⚠️ 考试记录保存状态未知:', submitResult.data);
				ElMessage.warning('考试已提交，但保存状态未知，请联系管理员确认');
			}
		} else {
			examSaveStatus.value = 'failed';
			examSaveError.value = '响应格式异常';
			logger.error('❌ 提交响应格式异常:', submitResult);
			ElMessage.error('考试记录保存失败：响应格式异常');
		}
	} catch (error) {
		examSaveStatus.value = 'failed';
		const errorMsg = error.response?.data?.msg || error.message || '未知错误';
		examSaveError.value = errorMsg;
		logger.error('❌ 保存考试结果异常:', error);

		// 检查是否是非会员限制错误
		if (errorMsg.includes('非会员') || errorMsg.includes('升级会员')) {
			await showQuizLimitUpgradeDialog();
		} else {
			ElMessage.error({
				message: '考试记录保存失败：' + examSaveError.value,
				duration: 5000,
				showClose: true
			});
		}
	}

	// 通知外部刷新
	try {
		window.dispatchEvent(new CustomEvent('examCompleted', {
			detail: {
				examId: props.examId || route.query.id || null,
				examName: examName,
				score: totalScore.value,
				isPassed
			}
		}));
	} catch (err) {}

	clearProgress();
}

// 重试提交
async function retrySubmit() {
	if (!lastSubmitData.value) {
		ElMessage.warning('没有可重试的数据');
		return;
	}
	
	ElMessage.info('正在重新提交...');
	examSaveStatus.value = null;
	examSaveError.value = '';
	
	try {
		const submitResult = await submitExamResult(lastSubmitData.value);
		
		if (submitResult && submitResult.data) {
			if (submitResult.data.saved === false) {
				examSaveStatus.value = 'failed';
				examSaveError.value = submitResult.data.msg || submitResult.data.error || '网络错误';
				ElMessage.error('重新提交失败：' + examSaveError.value);
			} else if (submitResult.data.code === 200 && submitResult.data.saved !== false) {
				examSaveStatus.value = 'success';
				examSaveError.value = '';
				ElMessage.success('考试记录已成功保存！');
			} else {
				examSaveStatus.value = 'failed';
				examSaveError.value = '保存状态未知';
				ElMessage.warning('重新提交完成，但保存状态未知');
			}
		} else {
			examSaveStatus.value = 'failed';
			examSaveError.value = '响应格式异常';
			ElMessage.error('重新提交失败：响应格式异常');
		}
	} catch (error) {
		examSaveStatus.value = 'failed';
		examSaveError.value = error.message || '未知错误';
		ElMessage.error('重新提交失败：' + examSaveError.value);
	}
}

// 复制错误信息
function copyErrorInfo() {
	const failedResultMode = normalizeResultDisplayMode(lastSubmitData.value?.resultDisplayMode);
	const failedResultTitle = getResultDisplayTitle(failedResultMode);
	const failedResultValue = getResultDisplayValue(lastSubmitData.value?.score, failedResultMode, lastSubmitData.value || {});
	const errorInfo = `
考试记录保存失败

错误信息：${examSaveError.value}

考试信息：
- 考试名称：${lastSubmitData.value?.examName || '未知'}
- ${failedResultTitle}：${failedResultValue}
- 题目数：${lastSubmitData.value?.questionCount || 0}
- 正确数：${lastSubmitData.value?.correctCount || 0}
- 考试类型：${lastSubmitData.value?.attemptType === 'practice' ? '平时测验' : '正式考试'}
- 提交时间：${lastSubmitData.value?.submittedAt || '未知'}

请将此信息发送给技术支持人员。
	`.trim();
	
	// 复制到剪贴板
	if (navigator.clipboard && navigator.clipboard.writeText) {
		navigator.clipboard.writeText(errorInfo).then(() => {
			ElMessage.success('错误信息已复制到剪贴板');
		}).catch(() => {
			// 降级方案
			fallbackCopy(errorInfo);
		});
	} else {
		// 降级方案
		fallbackCopy(errorInfo);
	}
}

// 降级复制方案
function fallbackCopy(text) {
	const textarea = document.createElement('textarea');
	textarea.value = text;
	textarea.style.position = 'fixed';
	textarea.style.opacity = '0';
	document.body.appendChild(textarea);
	textarea.select();
	try {
		document.execCommand('copy');
		ElMessage.success('错误信息已复制到剪贴板');
	} catch (err) {
		ElMessage.error('复制失败，请手动复制错误信息');
		logger.error('复制失败:', err);
	}
	document.body.removeChild(textarea);
}

// 自动判分逻辑
function autoGrade() {
	let rightCount = 0;
	let totalCount = 0;
	const details = []; // 修正变量名为 details 以匹配模板
	
	if (paper.value && paper.value.questions) {
		paper.value.questions.forEach((q, idx) => {
			const userAnswer = answers[q.id];
			const isCorrect = isAnswerCorrect(userAnswer, q);
			
			if (['single', 'multiple', 'judge', 'fill', 'text'].includes(q.type)) {
				totalCount++;
				if (isCorrect) rightCount++;
			}
			
			details.push({
				id: q.id,
				title: q.title,
				type: q.type,
				userAnswer: userAnswer,
				correctAnswer: q.answer,
				isCorrect: isCorrect,
				comment: isCorrect ? '回答正确' : '回答错误',
				analysis: q.analysis,
				options: q.options,
				isFavorite: q.isFavorite,
				originalId: q.originalId
			});
		});
	}
	
	const score = totalCount > 0 ? Math.round((rightCount / totalCount) * 100) : 0;
	
	return {
		score,
		correctCount: rightCount,
		totalCount,
		details, // 使用 details
		detail: details // 兼容旧代码可能使用的字段
	};
}

// 判断答案是否正确
function isAnswerCorrect(userAnswer, question) {
    if (!userAnswer && userAnswer !== 0 && userAnswer !== false) return false;
    if (!question) return false;
    
    if (question.type === 'single') {
        // 单选题比较
		// 尝试将用户答案转换为选项字母（如果它是文本）
		let userVal = String(userAnswer).trim();
		let correctVal = String(question.answer).trim();
		
		// 简单归一化比较
        return userVal.toLowerCase() === correctVal.toLowerCase();
    } else if (question.type === 'judge') {
        // 判断题比较
		const userBool = normalizeJudgeAnswer(userAnswer);
		const correctBool = normalizeJudgeAnswer(question.answer);
		return userBool === correctBool;
    } else if (question.type === 'multiple') {
        // 多选题比较
        const correctAnswers = Array.isArray(question.answer) ? question.answer : String(question.answer).split(/[,，]/).map(s => s.trim());
		const userAnswers = Array.isArray(userAnswer) ? userAnswer : String(userAnswer).split(/[,，]/).map(s => s.trim());
		
		if (userAnswers.length !== correctAnswers.length) return false;
		
		// 排序后比较字符串
		const sortedUser = [...userAnswers].sort().join(',');
		const sortedCorrect = [...correctAnswers].sort().join(',');
		return sortedUser === sortedCorrect;
    } else if (question.type === 'fill') {
		const correctAnswers = splitTextAnswers(question.answer);
		const userAnswers = splitTextAnswers(userAnswer);
		if (correctAnswers.length === 0 || userAnswers.length === 0 || correctAnswers.length !== userAnswers.length) return false;
		return correctAnswers.every((correct, index) => normalizeTextAnswer(userAnswers[index]) === normalizeTextAnswer(correct));
    } else if (question.type === 'text') {
		const userText = normalizeTextAnswer(userAnswer);
		const correctText = normalizeTextAnswer(question.answer);
		if (!userText || !correctText) return false;
		if (userText === correctText) return true;
		const keywords = extractKeywords(question.answer);
		if (keywords.length === 0) return false;
		const matchedCount = keywords.filter(keyword => userText.includes(keyword)).length;
		return matchedCount >= Math.max(1, Math.ceil(keywords.length / 2));
    }
    return false;
}

function normalizeTextAnswer(value) {
	return String(value == null ? '' : value)
		.replace(/[，。；、,.;\s]+/g, '')
		.trim()
		.toLowerCase();
}

function splitTextAnswers(value) {
	return String(value == null ? '' : value)
		.split(/[;；\n]/)
		.map(item => item.trim())
		.filter(Boolean);
}

function extractKeywords(value) {
	return String(value == null ? '' : value)
		.split(/[;；，。,、\n]/)
		.map(item => normalizeTextAnswer(item))
		.filter(item => item.length >= 2);
}

// 规范化判断题答案
function normalizeJudgeAnswer(val) {
	if (val === true || val === 'true' || val === '正确' || val === '对' || val === 'T' || val === 'A') return true;
	if (val === false || val === 'false' || val === '错误' || val === '错' || val === 'F' || val === 'B') return false;
	return null;
}

// 格式化答案显示
function formatAnswerDisplay(answer, question) {
	if (question.type === 'judge') {
		const boolVal = normalizeJudgeAnswer(answer);
		if (boolVal === true) return '正确';
		if (boolVal === false) return '错误';
		return '未作答';
	}
	if (question.type === 'fill') {
		return splitTextAnswers(answer).join('；') || '未作答';
	}
	if (question.type === 'text') {
		return answer ? String(answer).trim() : '未作答';
	}
	if (Array.isArray(answer)) return answer.join(', ');
	return answer || '未作答';
}

// 格式化用户答案（用于保存到数据库）
function formatUserAnswer(answer, questionType) {
	if (questionType === 'judge') {
		const boolVal = normalizeJudgeAnswer(answer);
		if (boolVal === true) return '正确';
		if (boolVal === false) return '错误';
		return '';
	}
	if (questionType === 'fill') {
		return splitTextAnswers(answer).join(';');
	}
	if (Array.isArray(answer)) return answer.join(',');
	return answer ? String(answer) : '';
}

// 格式化正确答案（用于保存到数据库）
function formatCorrectAnswer(answer, questionType) {
	if (questionType === 'judge') {
		if (answer === true || answer === 'true') return '正确';
		if (answer === false || answer === 'false') return '错误';
		return String(answer);
	}
	if (questionType === 'fill') {
		return splitTextAnswers(answer).join(';');
	}
	if (Array.isArray(answer)) return answer.join(',');
	return answer ? String(answer) : '';
}

// 计时器
function startTimer() {
	if (timer) clearInterval(timer);
	timer = setInterval(() => {
		if (timeLeft.value > 0) {
			timeLeft.value--;
		} else {
			clearInterval(timer);
			if (!submitted.value) {
				submitExam();
			}
		}
	}, 1000);
}

// 收藏相关
const favoriteLoading = ref({});

const handleToggleFavorite = async (question) => {
    if (question.bank === 'dept') {
        ElMessage.warning('部门题库题目暂不支持收藏');
        return;
    }
    if (!question.originalId) {
        ElMessage.warning('该题目暂不支持收藏');
        return;
    }
    if (favoriteLoading.value[question.id]) return;
    favoriteLoading.value[question.id] = true;
    try {
        const newStatus = !question.isFavorite;
        // 注意：toggleFavorite 第一个参数是 questionId
        await toggleFavorite(question.originalId, newStatus);
        question.isFavorite = newStatus;
        ElMessage.success(newStatus ? '收藏成功' : '已取消收藏');
    } catch (e) {
        logger.error('收藏失败:', e);
        ElMessage.error('操作失败，请重试');
    } finally {
        favoriteLoading.value[question.id] = false;
    }
};

const scrollToResultQuestion = (index) => {
    const el = document.getElementById(`result-q-${index}`);
    if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        // 添加闪烁效果提示
        el.classList.add('ring-2', 'ring-blue-400');
        setTimeout(() => el.classList.remove('ring-2', 'ring-blue-400'), 1500);
    }
};

const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
};

// 加载数据
const loadExamData = async () => {
	let paperData = null;
	loadError.value = false;
	paper.value = null;
	
	// 生成考试会话ID（用于缓存）
	const sessionKey = getSessionKey();
	const legacySessionKey = getLegacySessionKey();
	
	// 检查是否有缓存的考试数据（防止刷新页面题目变化）
	let cachedExam = sessionStorage.getItem(sessionKey);
	let useLegacySession = false;
	if (!cachedExam && legacySessionKey !== sessionKey) {
		cachedExam = sessionStorage.getItem(legacySessionKey);
		useLegacySession = !!cachedExam;
	}
	if (cachedExam) {
		try {
			const cached = JSON.parse(cachedExam);
			// 检查缓存是否在30分钟内（考试时间内有效）
			if (cached.timestamp && Date.now() - cached.timestamp < 30 * 60 * 1000) {
				logger.debug('使用缓存的考试数据');
				paper.value = cached.paper;
				// 恢复用户答案
				if (cached.answers) {
					Object.assign(answers, cached.answers);
				}
				// 恢复当前题目索引
				if (cached.currentIndex !== undefined) {
					currentIndex.value = cached.currentIndex;
				}
				// 恢复剩余时间
				if (cached.timeLeft !== undefined) {
					timeLeft.value = cached.timeLeft;
				}
				const cachedDurationSeconds = toPositiveNumber(cached.durationSeconds) || resolveExamDurationSeconds(cached.paper);
				if (cached.timeLeft === undefined) {
					timeLeft.value = cachedDurationSeconds;
				}
				if (cached.startTime) {
					startTime.value = cached.startTime;
				} else {
					const consumed = Math.max(0, cachedDurationSeconds - timeLeft.value);
					startTime.value = Date.now() - consumed * 1000;
				}
				if (useLegacySession) {
					sessionStorage.setItem(
						sessionKey,
						JSON.stringify({
							...cached,
							durationSeconds: cachedDurationSeconds,
							startTime: startTime.value
						})
					);
					sessionStorage.removeItem(legacySessionKey);
				}
				startTimer();
				return;
			}
		} catch (e) {
			logger.warn('解析缓存数据失败:', e);
		}
	}

	// 优先：若携带分类/数量参数，则调用后端题库随机组卷
	const bankFromRoute = route.query.bank != null ? String(route.query.bank) : '';
	let categoryFromRoute = route.query.category ? decodeURIComponent(route.query.category) : undefined;
	if (bankFromRoute === 'ota') {
		categoryFromRoute = '';
	}
	// 特殊处理：如果分类是 '综合' 或 '全部'，则视为不限分类
	if (categoryFromRoute === '综合' || categoryFromRoute === '全部') {
		categoryFromRoute = '';
	}

	const limitFromRoute = route.query.limit ? Number(route.query.limit) : undefined;
	// 宽松判断：明确指定 random=true，或者没有 ID 但有 limit/category 时也视为随机组卷
	const hasId = route.query.id || route.query.examId || props.examId;
	const isRandom = route.query.random === 'true' || (!hasId && (limitFromRoute !== undefined || categoryFromRoute !== undefined)); 
	
		if (isRandom) {
		try {
			if (bankFromRoute === 'dept') {
				logger.debug('正在从部门题库生成随机试卷...', { limit: limitFromRoute });
				const resp = await getDeptDailyQuestions(undefined, undefined, limitFromRoute || 20);
				const resData = resp?.data || resp;
				if (resData && resData.code === 200) {
					const list = Array.isArray(resData.data) ? resData.data : [];
					const validQuestions = list.filter(q => (q && (q.questionText || q.title))).map((q, i) => {
						const type = convertType(q.questionType);
						let options = [q.optionA, q.optionB, q.optionC, q.optionD].filter(Boolean);
						if (type === 'judge' && options.length === 0) options = ['正确', '错误'];
						return {
							id: i + 1,
							title: q.questionText || q.title || `题目${i + 1}`,
							type,
							options,
							answer: q.correctAnswer || q.answer || q.rightAnswer || q.correct_answer,
							originalId: q.id,
							analysis: q.analysis || q.explanation || q.description || '暂无解析',
							isFavorite: false,
							bank: 'dept'
						};
					});
					if (validQuestions.length > 0) {
						const titleFromRoute = route.query.title ? decodeURIComponent(String(route.query.title)) : undefined;
						paperData = {
							id: Date.now(),
							name: titleFromRoute || '部门知识测验',
							questions: validQuestions
						};
						sessionStorage.setItem(sessionKey, JSON.stringify({
							paper: paperData,
							answers: {},
							currentIndex: 0,
							timeLeft: resolveExamDurationSeconds(paperData),
							startTime: Date.now(),
							durationSeconds: resolveExamDurationSeconds(paperData),
							passScore: resolvePassScore(paperData),
							timestamp: Date.now()
						}));
					} else {
						ElMessage.warning('部门题库暂无可用题目，请稍后再试');
						paper.value = { questions: [] };
						return;
					}
				} else {
					ElMessage.error(resData?.msg || '生成试卷失败');
					return;
				}
			} else {
				logger.debug('正在生成随机试卷...', { category: categoryFromRoute, limit: limitFromRoute });
				const resp = await generateFromBank({ category: categoryFromRoute || '', limit: limitFromRoute || 20 });
				const resData = resp.data || resp;
				
				if (resData && resData.code === 200) {
					let list = Array.isArray(resData.data) ? resData.data : [];
					
					logger.debug('获取到随机题目:', list.length);

					if (list.length === 0 && categoryFromRoute) {
						logger.debug('指定分类无题目，尝试全库随机...');
						const retryResp = await generateFromBank({ category: '', limit: limitFromRoute || 20 });
						const retryData = retryResp.data || retryResp;
						if (retryData && retryData.code === 200) {
							list = Array.isArray(retryData.data) ? retryData.data : [];
							logger.debug('全库随机结果:', list.length);
							if (list.length > 0) {
								ElMessage.info(`分类"${categoryFromRoute}"暂无题目，已为您切换为综合随机测验`);
							}
						}
					}

					const validQuestions = list.filter(q => {
						return q.questionText || q.title;
					}).map((q, i) => ({
						id: i + 1,
						title: q.questionText || q.title || `题目${i+1}`,
						type: convertType(q.questionType),
						options: [q.optionA, q.optionB, q.optionC, q.optionD].filter(Boolean),
						answer: q.correctAnswer || q.answer || q.rightAnswer || q.correct_answer,
						originalId: q.id,
						analysis: q.analysis || q.explanation || q.description || '暂无解析',
						isFavorite: !!(q.isFavorite || q.favorite)
					}));
					
					if (validQuestions.length > 0) {
						const titleFromRoute = route.query.title ? decodeURIComponent(String(route.query.title)) : undefined;
						paperData = {
							id: Date.now(),
							name: titleFromRoute || `${categoryFromRoute || '综合'} 随机测验`,
							questions: validQuestions
						};
						
						sessionStorage.setItem(sessionKey, JSON.stringify({
							paper: paperData,
							answers: {},
							currentIndex: 0,
							timeLeft: resolveExamDurationSeconds(paperData),
							startTime: Date.now(),
							durationSeconds: resolveExamDurationSeconds(paperData),
							passScore: resolvePassScore(paperData),
							timestamp: Date.now()
						}));
					} else {
						logger.warn('生成的题目列表为空或无效');
						ElMessage.warning('该分类下暂时没有题目，请更换分类或稍后再试');
						paper.value = { questions: [] };
						return;
					}
				} else {
					logger.error('生成试卷失败:', resData);
					ElMessage.error(resData.msg || '生成试卷失败');
					return;
				}
			}
		} catch (e) { 
			logger.error('随机组卷异常:', e);
			ElMessage.error('网络请求失败，请检查网络');
			return;
		}
	}
	
	// 常规加载
	if (!paperData) {
		const idFromProp = props.examId !== undefined && props.examId !== null ? Number(props.examId) : undefined;
		// 兼容 id 和 examId 两个参数名
		const idFromRoute = route.query.id ? Number(route.query.id) : undefined;
		const examIdFromRoute = route.query.examId ? Number(route.query.examId) : undefined;
		
		// 优先顺序：props -> route.id -> route.examId
		const finalId = (idFromProp !== undefined ? idFromProp : (idFromRoute !== undefined ? idFromRoute : examIdFromRoute));
		
		logger.debug('尝试加载考试ID:', finalId, { prop: idFromProp, queryId: idFromRoute, queryExamId: examIdFromRoute });
		
		if (finalId) {
			try {
				const res = await fetchExamPaper(finalId);
				if (res && res.data) {
					// 兼容处理：如果返回结构包含 data 字段，则取 data；否则直接取 res.data
					// 通常 API 结构为 { code: 200, data: { ... } }
					paperData = res.data.data || res.data;
				}
			} catch (e) { 
				logger.error('加载考试详情失败:', e);
				loadError.value = true;
				const msg = e && e.message && e.message.includes('考试没有题目')
					? '该结业考试尚未配置试题，请联系管理员在后台为此考试添加试题后再参加。'
					: '获取试卷详情失败';
				ElMessage.error(msg);
			}
		} else {
			logger.warn('未找到有效的考试ID');
		}
	}
	
	// 赋值
	if (paperData && paperData.questions) {
		paper.value = paperData;
		// 初始化答案
		paper.value.questions.forEach(q => {
			answers[q.id] = q.type === 'multiple' ? [] : '';
		});
		// 恢复进度
		const hasRecoveredProgress = loadProgressIfAny();
		const examDurationSeconds = resolveExamDurationSeconds();
		if (!startTime.value) {
			if (hasRecoveredProgress && timeLeft.value > 0 && timeLeft.value <= examDurationSeconds) {
				const consumed = Math.max(0, examDurationSeconds - timeLeft.value);
				startTime.value = Date.now() - consumed * 1000;
			} else {
				startTime.value = Date.now();
				timeLeft.value = examDurationSeconds;
			}
		} else if (!timeLeft.value || timeLeft.value > examDurationSeconds) {
			timeLeft.value = examDurationSeconds;
		}
		startTimer();
		saveProgress();
	} else {
		loadError.value = true;
		ElMessage.error('无法加载试卷数据');
	}
};

const buildQuizLimitMessage = () => {
	return `当前账号每天只能参加 ${freeQuizDailyLimit.value} 次测试，开通会员后可解锁更多次数。`;
};

function convertType(chineseType) {
	if (!chineseType) return 'single';
	const normalized = String(chineseType).trim();
	const lower = normalized.toLowerCase();
	if (normalized === '2' || lower === 'multiple' || normalized.includes('多')) return 'multiple';
	if (normalized === '3' || lower === 'judge' || lower === 'judgment' || normalized.includes('判')) return 'judge';
	if (lower === 'fill' || lower === 'blank' || normalized.includes('填')) return 'fill';
	if (normalized === '4' || lower === 'text' || lower === 'short_text' || normalized.includes('简') || normalized.includes('问答')) return 'text';
	if (normalized === '5' || lower === 'code' || normalized.includes('码')) return 'code';
	return 'single';
}

// 进度保存相关
function getProgressKey(paperId) {
	const userId = getStorageUserId();
	return `exam_progress_u_${userId}_${paperId}`;
}

function saveProgress() {
	if (!paper.value) return;
	
	// 使用与加载时相同的 sessionKey
	const sessionKey = getSessionKey();
	
	try {
		// 更新 sessionStorage 中的缓存数据
		const cachedData = sessionStorage.getItem(sessionKey);
		const cached = cachedData ? JSON.parse(cachedData) : {};
		const durationSeconds = resolveExamDurationSeconds(cached.paper || paper.value);
		cached.paper = cached.paper || paper.value;
		cached.answers = { ...answers };
		cached.currentIndex = currentIndex.value;
		cached.timeLeft = timeLeft.value;
		cached.startTime = startTime.value || Date.now();
		cached.durationSeconds = durationSeconds;
		cached.passScore = resolvePassScore(cached.paper);
		cached.timestamp = cached.timestamp || Date.now(); // 保持原始时间戳
		sessionStorage.setItem(sessionKey, JSON.stringify(cached));
		const legacySessionKey = getLegacySessionKey();
		if (legacySessionKey !== sessionKey) {
			sessionStorage.removeItem(legacySessionKey);
		}
	} catch (e) {
		logger.warn('保存进度失败:', e);
	}
}

function loadProgressIfAny() {
	if (!paper.value) return false;
	const hasId = route.query.id || route.query.examId || props.examId;
	const isRandom = route.query.random === 'true' || !hasId;
	if (isRandom) return false;
	const key = getProgressKey(paper.value.id);
	const legacyKey = `exam_progress_${paper.value.id}`;
	const raw = localStorage.getItem(key) || localStorage.getItem(legacyKey);
	if (raw) {
		try {
			const data = JSON.parse(raw);
			Object.assign(answers, data.answers);
			if (data.currentIndex) currentIndex.value = data.currentIndex;
			if (data.timeLeft) timeLeft.value = data.timeLeft;
			if (data.startTime) startTime.value = data.startTime;
			if (!localStorage.getItem(key) && localStorage.getItem(legacyKey)) {
				localStorage.setItem(key, raw);
				localStorage.removeItem(legacyKey);
			}
			return true;
		} catch (e) {}
	}
	return false;
}

function clearProgress() {
	if (!paper.value) return;
	const hasId = route.query.id || route.query.examId || props.examId;
	const isRandom = route.query.random === 'true' || !hasId;
	if (isRandom) return;
	const key = getProgressKey(paper.value.id);
	const legacyKey = `exam_progress_${paper.value.id}`;
	localStorage.removeItem(key);
	localStorage.removeItem(legacyKey);
}

// 监听变化自动保存
watch(answers, () => saveProgress(), { deep: true });
watch(currentIndex, () => saveProgress());

// 防作弊检测
const handleVisibilityChange = () => {
    // 如果已经提交或显示结果，不再检测
    if (submitted.value || showResult.value) return;

    if (document.hidden) {
        switchCount.value++;
        
        if (switchCount.value >= MAX_SWITCH_COUNT) {
            ElMessage.error(`您已切屏 ${switchCount.value} 次，达到上限，系统将自动交卷！`);
            submitExam();
        } else {
            ElMessage.warning({
                message: `警告：检测到切屏行为！当前次数：${switchCount.value}/${MAX_SWITCH_COUNT}。超过 ${MAX_SWITCH_COUNT} 次将自动交卷。`,
                duration: 5000,
                showClose: true
            });
        }
    }
};

// 浏览器刷新/关闭拦截
const handleBeforeUnload = (e) => {
	if (!showResult.value && !submitted.value) {
		e.preventDefault();
		e.returnValue = '';
		return '';
	}
};

onBeforeRouteLeave(() => {
	const hasId = route.query.id || route.query.examId || props.examId;
	const isRandom = route.query.random === 'true' || route.query.random === true || !hasId;
	if (!isRandom) return;
	if (showResult.value || submitted.value) return;
	try {
		removeSessionCache();
	} catch (e) {}
});

const handleUserLogout = () => {
	try {
		removeSessionCache();
		clearProgress();
	} catch (e) {}
};

onMounted(async () => {
	checkMobile();
	window.addEventListener('resize', checkMobile);
	window.addEventListener('beforeunload', handleBeforeUnload);
	window.addEventListener('userLogout', handleUserLogout);
    document.addEventListener('visibilitychange', handleVisibilityChange);
	await loadMembershipLimits();
	loadExamData();
});

onBeforeUnmount(() => {
	window.removeEventListener('resize', checkMobile);
	window.removeEventListener('beforeunload', handleBeforeUnload);
	window.removeEventListener('userLogout', handleUserLogout);
    document.removeEventListener('visibilitychange', handleVisibilityChange);
	if (timer) clearInterval(timer);
	if (radarChartInstance) radarChartInstance.destroy();
	if (!submitted.value) saveProgress();
});
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.result-celebration {
  position: relative;
  padding: 1.25rem 1rem 0.25rem;
  overflow: hidden;
}

.result-celebration__orb {
  position: relative;
  width: 5rem;
  height: 5rem;
  margin: 0 auto 0.9rem;
}

.result-celebration__ring {
  position: absolute;
  inset: 0;
  border-radius: 9999px;
  animation: celebration-pulse 2.4s ease-out infinite;
}

.result-celebration__ring--outer {
  transform: scale(1.18);
  opacity: 0.25;
}

.result-celebration__ring--middle {
  transform: scale(1.04);
  opacity: 0.45;
  animation-delay: 0.35s;
}

.result-celebration__icon {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 9999px;
  color: #fff;
  box-shadow: 0 20px 40px rgba(15, 23, 42, 0.12);
  animation: celebration-float 3s ease-in-out infinite;
}

.result-celebration__eyebrow {
  margin: 0 0 0.3rem;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.18em;
  text-transform: uppercase;
}

.result-celebration__headline {
  margin: 0;
  color: #1f2937;
  font-size: 1.05rem;
  font-weight: 800;
  line-height: 1.3;
}

.result-celebration__message {
  margin: 0.45rem auto 0;
  max-width: 32rem;
  color: #6b7280;
  font-size: 0.78rem;
  line-height: 1.65;
}

.result-celebration__chips {
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  gap: 0.45rem;
  margin-top: 0.95rem;
}

.result-celebration__chip {
  padding: 0.38rem 0.72rem;
  border-radius: 9999px;
  font-size: 0.72rem;
  font-weight: 700;
  backdrop-filter: blur(8px);
}

.result-celebration__spark {
  position: absolute;
  top: 0.4rem;
  padding: 0.35rem 0.7rem;
  border-radius: 9999px;
  font-size: 0.72rem;
  font-weight: 700;
  box-shadow: 0 12px 24px rgba(15, 23, 42, 0.08);
  animation: celebration-drift 3.4s ease-in-out infinite;
}

.result-celebration__spark--left {
  left: 0.25rem;
}

.result-celebration__spark--right {
  right: 0.25rem;
  animation-delay: 0.9s;
}

.result-celebration--excellent .result-celebration__ring {
  background: radial-gradient(circle, rgba(52, 211, 153, 0.22) 0%, rgba(16, 185, 129, 0.06) 60%, transparent 75%);
}

.result-celebration--excellent .result-celebration__icon {
  background: linear-gradient(135deg, #10b981 0%, #059669 55%, #047857 100%);
}

.result-celebration--excellent .result-celebration__eyebrow {
  color: #059669;
}

.result-celebration--excellent .result-celebration__chip,
.result-celebration--excellent .result-celebration__spark {
  background: rgba(236, 253, 245, 0.92);
  color: #047857;
  border: 1px solid rgba(16, 185, 129, 0.18);
}

.result-celebration--pass .result-celebration__ring {
  background: radial-gradient(circle, rgba(96, 165, 250, 0.22) 0%, rgba(59, 130, 246, 0.06) 60%, transparent 75%);
}

.result-celebration--pass .result-celebration__icon {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 55%, #1d4ed8 100%);
}

.result-celebration--pass .result-celebration__eyebrow {
  color: #2563eb;
}

.result-celebration--pass .result-celebration__chip,
.result-celebration--pass .result-celebration__spark {
  background: rgba(239, 246, 255, 0.92);
  color: #1d4ed8;
  border: 1px solid rgba(59, 130, 246, 0.18);
}

.result-celebration--effort .result-celebration__ring {
  background: radial-gradient(circle, rgba(251, 191, 36, 0.22) 0%, rgba(245, 158, 11, 0.06) 60%, transparent 75%);
}

.result-celebration--effort .result-celebration__icon {
  background: linear-gradient(135deg, #f59e0b 0%, #ea580c 55%, #dc2626 100%);
}

.result-celebration--effort .result-celebration__eyebrow {
  color: #d97706;
}

.result-celebration--effort .result-celebration__chip,
.result-celebration--effort .result-celebration__spark {
  background: rgba(255, 251, 235, 0.94);
  color: #b45309;
  border: 1px solid rgba(245, 158, 11, 0.2);
}

.animate-bounce-in {
  animation: bounce-in 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

@keyframes bounce-in {
  0% {
    opacity: 0;
    transform: scale(0.3);
  }
  50% {
    opacity: 1;
    transform: scale(1.05);
  }
  70% {
    transform: scale(0.9);
  }
  100% {
    transform: scale(1);
  }
}

@keyframes celebration-pulse {
  0% {
    transform: scale(0.82);
    opacity: 0.2;
  }
  70% {
    transform: scale(1.2);
    opacity: 0.48;
  }
  100% {
    transform: scale(1.34);
    opacity: 0;
  }
}

@keyframes celebration-float {
  0%, 100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-8px);
  }
}

@keyframes celebration-drift {
  0%, 100% {
    transform: translateY(0) rotate(0deg);
  }
  50% {
    transform: translateY(-7px) rotate(-2deg);
  }
}

@media (min-width: 768px) {
  .result-celebration {
    padding-top: 1.8rem;
  }

  .result-celebration__orb {
    width: 6.5rem;
    height: 6.5rem;
    margin-bottom: 1.25rem;
  }

  .result-celebration__eyebrow {
    font-size: 0.78rem;
  }

  .result-celebration__headline {
    font-size: 1.7rem;
  }

  .result-celebration__message {
    font-size: 0.96rem;
  }

  .result-celebration__chip {
    font-size: 0.8rem;
    padding: 0.45rem 0.9rem;
  }

  .result-celebration__spark {
    top: 0.7rem;
    font-size: 0.8rem;
  }

  .result-celebration__spark--left {
    left: 2rem;
  }

  .result-celebration__spark--right {
    right: 2rem;
  }
}

/* 自定义滚动条 */
::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>


