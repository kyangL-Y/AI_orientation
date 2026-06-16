<template>
  <div class="ranking-page min-h-screen bg-slate-50 font-sans selection:bg-indigo-100 selection:text-indigo-600 pb-10">
    <HeaderBar />
    <!-- 顶部背景装饰 -->
    <div class="fixed top-0 left-0 right-0 h-[500px] bg-gradient-to-b from-indigo-50 via-white to-transparent -z-10 pointer-events-none"></div>
    <div class="fixed top-[-20%] right-[-10%] w-[600px] h-[600px] bg-indigo-200/30 rounded-full blur-[100px] -z-10"></div>
    <div class="fixed top-[10%] left-[-10%] w-[400px] h-[400px] bg-pink-200/20 rounded-full blur-[80px] -z-10"></div>

    <!-- 顶部导航与个人信息 -->
    <div class="relative pt-16 pb-8 md:pt-28 md:pb-32 px-3 sm:px-4 overflow-hidden">
      <div class="max-w-5xl mx-auto">
        <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 md:gap-6 mb-6 md:mb-8">
          <div class="w-full md:w-auto text-left">
            <h1 class="text-xl sm:text-2xl md:text-4xl font-extrabold text-slate-800 tracking-tight mb-1.5 md:mb-2">
              <span class="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-violet-600">Learner</span> Leaderboard
            </h1>
            <p class="text-slate-500 font-medium text-xs sm:text-sm md:text-base">与优秀者同行，见证每一次进步 🚀</p>
          </div>
          
          <!-- 筛选区域 (时间 + 范围) -->
          <div class="flex flex-col sm:flex-row gap-2 md:gap-3 w-full md:w-auto">
            <!-- 范围筛选 -->
            <div class="ranking-filter-group bg-white/80 backdrop-blur-md p-1 rounded-2xl md:rounded-full shadow-sm border border-slate-100 flex flex-wrap items-center justify-start">
              <button 
                v-for="s in scopeOptions" 
                :key="s.value"
                @click="scope = s.value; loadData()"
                :class="[
                  'px-3 py-1.5 rounded-xl md:rounded-full text-xs sm:text-sm font-semibold transition-all duration-300',
                  scope === s.value 
                    ? 'bg-emerald-600 text-white shadow-md shadow-emerald-200' 
                    : 'text-slate-500 hover:text-emerald-600 hover:bg-emerald-50'
                ]"
              >
                {{ s.label }}
              </button>
            </div>

            <!-- 时间筛选 -->
            <div class="ranking-filter-group bg-white/80 backdrop-blur-md p-1 rounded-2xl md:rounded-full shadow-sm border border-slate-100 flex flex-wrap items-center justify-start">
              <button 
                v-for="time in timeOptions" 
                :key="time.value"
                @click="timeRange = time.value; loadData()"
                :class="[
                  'px-3 py-1.5 rounded-xl md:rounded-full text-xs sm:text-sm font-semibold transition-all duration-300',
                  timeRange === time.value 
                    ? 'bg-indigo-600 text-white shadow-md shadow-indigo-200' 
                    : 'text-slate-500 hover:text-indigo-600 hover:bg-indigo-50'
                ]"
              >
                {{ time.label }}
              </button>
            </div>
          </div>
        </div>

        <!-- 我的排名卡片 (悬浮玻璃态) -->
        <div v-if="myRanking" class="bg-white/70 backdrop-blur-xl rounded-[1.5rem] p-3 sm:p-4 border border-white/50 shadow-xl shadow-indigo-100/50 flex items-center justify-between gap-3 max-w-2xl mx-auto md:mx-0 transform transition-all hover:scale-[1.01]">
          <div class="flex items-center gap-3 sm:gap-4 min-w-0">
            <div class="relative">
              <div class="w-14 h-14 sm:w-16 sm:h-16 rounded-full p-1 bg-gradient-to-br from-indigo-100 to-white shadow-inner">
                <img :src="myRanking.avatar || defaultAvatar" class="w-full h-full rounded-full object-cover" />
              </div>
              <div class="absolute -bottom-1 -right-1 bg-slate-800 text-white text-xs font-bold px-2 py-0.5 rounded-full shadow-lg border-2 border-white">
                No.{{ myRanking.rank }}
              </div>
            </div>
            <div class="min-w-0">
              <div class="font-bold text-slate-800 text-base sm:text-lg truncate">{{ myRanking.nickName || '我' }}</div>
              <div class="text-xs font-semibold text-indigo-500 bg-indigo-50 px-2 py-0.5 rounded-md inline-block mt-1">
                {{ myRanking.deptName || '暂无部门' }}
              </div>
            </div>
          </div>
            <div class="text-right pl-3 sm:pl-4 border-l border-slate-100 shrink-0">
              <div class="text-2xl sm:text-3xl font-black text-transparent bg-clip-text bg-gradient-to-br from-indigo-600 to-violet-600 leading-none">
              {{ myRanking.score || 0 }}<span v-if="myRankingUnit" class="text-sm font-semibold ml-1">{{ myRankingUnit }}</span>
              </div>
            <div class="text-xs font-bold text-slate-400 uppercase tracking-wide">{{ myRankingLabel }}</div>
            <div class="text-[10px] text-slate-400 mt-1 font-medium bg-slate-100 px-1.5 py-0.5 rounded-full inline-block cursor-pointer hover:bg-indigo-100 hover:text-indigo-600 transition-colors" v-if="activeTab !== 'courseQuiz' && myRanking.totalPoints !== undefined" @click="goToMall">
              总余额: {{ myRanking.totalPoints }} >
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 主要内容区域 (上移覆盖) -->
    <div class="max-w-5xl mx-auto px-3 sm:px-4 -mt-6 md:-mt-20 relative z-10">
      <!-- 榜单切换 Tab -->
      <div class="flex justify-center mb-5 md:mb-8">
        <div class="bg-white p-1 rounded-2xl shadow-lg shadow-slate-200/50 flex gap-1.5 w-full max-w-sm md:w-auto">
          <button 
            v-for="tab in tabs" 
            :key="tab.key"
            @click="activeTab = tab.key"
            :class="[
              'flex-1 md:flex-initial flex items-center justify-center gap-1.5 px-3 sm:px-4 md:px-6 py-2 rounded-xl font-bold text-sm transition-all duration-300',
              activeTab === tab.key 
                ? 'bg-slate-800 text-white shadow-lg' 
                : 'text-slate-500 hover:bg-slate-50'
            ]"
          >
            <component :is="tab.icon" class="w-4 h-4" />
            {{ tab.label }}
          </button>
        </div>
      </div>

      <!-- 加载状态 -->
      <div v-if="loading" class="flex flex-col items-center justify-center py-32 bg-white/50 backdrop-blur-sm rounded-3xl border border-white/60">
        <div class="w-10 h-10 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin mb-4"></div>
        <p class="text-slate-400 font-medium animate-pulse">正在同步数据...</p>
      </div>

      <!-- 个人榜单内容 -->
      <div v-else-if="activeTab === 'personal' || activeTab === 'courseQuiz'" class="animate-fade-in-up">
        <!-- 前三名领奖台 -->
        <div v-if="topThree.length > 0" class="grid grid-cols-2 items-stretch md:items-end md:flex md:justify-center gap-3 md:gap-8 mb-8 md:mb-12">
          
          <!-- 第二名 -->
          <div class="order-2 md:order-1 w-full md:w-1/3 max-w-none md:max-w-[280px]">
            <div class="relative group">
              <div class="absolute inset-0 bg-gradient-to-b from-slate-200 to-slate-50 rounded-t-3xl transform translate-y-4 group-hover:translate-y-3 transition-transform duration-300"></div>
              <div class="relative bg-white rounded-[1.6rem] md:rounded-3xl p-4 md:p-6 shadow-xl shadow-slate-200/50 border border-white/60 text-center z-10 h-full">
                <div class="absolute -top-4 md:-top-6 left-1/2 transform -translate-x-1/2">
                  <div class="w-7 h-7 md:w-8 md:h-8 bg-slate-200 rounded-full flex items-center justify-center text-slate-600 font-black text-xs md:text-sm shadow-md ring-4 ring-white">2</div>
                </div>
                <div class="mt-3 md:mt-4 mb-2.5 md:mb-3 relative inline-block">
                  <img :src="topThree[1]?.avatar || defaultAvatar" class="w-14 h-14 md:w-16 md:h-16 rounded-full object-cover border-4 border-slate-100 shadow-inner" />
                  <div class="absolute bottom-0 right-0 text-xl md:text-2xl">🥈</div>
                </div>
                <h3 class="font-bold text-sm md:text-base text-slate-800 truncate px-1">{{ topThree[1]?.nickName || '-' }}</h3>
                <p class="text-[11px] md:text-xs text-slate-400 mb-1 truncate">
                  {{ topThree[1]?.companyName ? topThree[1]?.companyName + ' · ' : '' }}{{ topThree[1]?.deptName || '-' }}
                </p>
                <div class="flex items-center justify-center gap-1.5 md:gap-2 text-[10px] text-slate-500 mb-2.5 md:mb-3 bg-slate-50 px-2 py-1 rounded-lg">
                  <span>{{ rankingValueLabel }} {{ topThree[1]?.answerCount || 0 }}</span>
                  <div class="w-px h-3 bg-slate-300"></div>
                  <span>正确率 {{ formatRate(topThree[1]?.correctRate) }}%</span>
                </div>
                <div class="text-lg md:text-xl font-black text-slate-700 leading-none">
                  {{ topThree[1]?.score || 0 }}
                  <span class="text-xs font-medium text-slate-400 ml-0.5">{{ activeTab === 'courseQuiz' ? '分' : '积分' }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- 第一名 (C位) -->
          <div class="order-1 md:order-2 col-span-2 md:col-span-1 w-full md:w-1/3 max-w-none md:max-w-[320px] z-20">
            <div class="relative group">
              <div class="absolute inset-0 bg-gradient-to-b from-yellow-100 to-orange-50 rounded-t-[2.5rem] transform translate-y-4 group-hover:translate-y-3 transition-transform duration-300"></div>
              <div class="relative bg-white rounded-[1.7rem] md:rounded-[2rem] p-5 md:p-8 shadow-2xl shadow-orange-100/50 border border-white/60 text-center">
                <div class="absolute -top-7 md:-top-10 left-1/2 transform -translate-x-1/2">
                   <div class="text-4xl md:text-5xl drop-shadow-lg filter">👑</div>
                </div>
                <div class="mt-4 md:mt-6 mb-3 md:mb-4 relative inline-block">
                  <div class="absolute inset-0 bg-yellow-400 rounded-full blur-lg opacity-20 animate-pulse"></div>
                  <img :src="topThree[0]?.avatar || defaultAvatar" class="relative w-20 h-20 md:w-24 md:h-24 rounded-full object-cover border-4 border-yellow-100 shadow-lg" />
                  <div class="absolute -bottom-2 -right-2 bg-yellow-400 text-yellow-900 text-xs font-black px-2 py-0.5 rounded-full border-2 border-white shadow-sm">
                    NO.1
                  </div>
                </div>
                <h3 class="text-base md:text-lg font-bold text-slate-900 truncate px-2">{{ topThree[0]?.nickName || '-' }}</h3>
                <p class="text-xs md:text-sm text-slate-400 mb-2 truncate">
                  {{ topThree[0]?.companyName ? topThree[0]?.companyName + ' · ' : '' }}{{ topThree[0]?.deptName || '-' }}
                </p>
                <div class="flex items-center justify-center gap-2 md:gap-3 text-[11px] md:text-xs font-medium text-slate-500 mb-3 md:mb-4 bg-orange-50/50 px-3 py-1.5 rounded-lg border border-orange-100/50">
                  <span>{{ rankingValueLabel }} {{ topThree[0]?.answerCount || 0 }}</span>
                  <div class="w-px h-3 bg-orange-200"></div>
                  <span>正确率 {{ formatRate(topThree[0]?.correctRate) }}%</span>
                </div>
                <div class="inline-block bg-gradient-to-r from-yellow-500 to-orange-500 text-white px-5 md:px-6 py-1.5 rounded-full font-black text-xl md:text-2xl shadow-lg shadow-orange-200">
                  {{ topThree[0]?.score || 0 }}
                  <span class="text-xs font-medium opacity-80 ml-1">{{ activeTab === 'courseQuiz' ? '分' : '积分' }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- 第三名 -->
          <div class="order-3 md:order-3 w-full md:w-1/3 max-w-none md:max-w-[280px]">
            <div class="relative group">
              <div class="absolute inset-0 bg-gradient-to-b from-orange-100 to-orange-50 rounded-t-3xl transform translate-y-4 group-hover:translate-y-3 transition-transform duration-300"></div>
              <div class="relative bg-white rounded-[1.6rem] md:rounded-3xl p-4 md:p-6 shadow-xl shadow-orange-100/50 border border-white/60 text-center z-10 h-full">
                <div class="absolute -top-4 md:-top-6 left-1/2 transform -translate-x-1/2">
                  <div class="w-7 h-7 md:w-8 md:h-8 bg-orange-100 rounded-full flex items-center justify-center text-orange-600 font-black text-xs md:text-sm shadow-md ring-4 ring-white">3</div>
                </div>
                <div class="mt-3 md:mt-4 mb-2.5 md:mb-3 relative inline-block">
                  <img :src="topThree[2]?.avatar || defaultAvatar" class="w-14 h-14 md:w-16 md:h-16 rounded-full object-cover border-4 border-orange-50 shadow-inner" />
                  <div class="absolute bottom-0 right-0 text-xl md:text-2xl">🥉</div>
                </div>
                <h3 class="font-bold text-sm md:text-base text-slate-800 truncate px-1">{{ topThree[2]?.nickName || '-' }}</h3>
                <p class="text-[11px] md:text-xs text-slate-400 mb-1 truncate">
                  {{ topThree[2]?.companyName ? topThree[2]?.companyName + ' · ' : '' }}{{ topThree[2]?.deptName || '-' }}
                </p>
                <div class="flex items-center justify-center gap-1.5 md:gap-2 text-[10px] text-slate-500 mb-2.5 md:mb-3 bg-slate-50 px-2 py-1 rounded-lg">
                  <span>{{ rankingValueLabel }} {{ topThree[2]?.answerCount || 0 }}</span>
                  <div class="w-px h-3 bg-slate-300"></div>
                  <span>正确率 {{ formatRate(topThree[2]?.correctRate) }}%</span>
                </div>
                <div class="text-lg md:text-xl font-black text-slate-700 leading-none">
                  {{ topThree[2]?.score || 0 }}
                  <span class="text-xs font-medium text-slate-400 ml-0.5">{{ activeTab === 'courseQuiz' ? '分' : '积分' }}</span>
                </div>
              </div>
            </div>
          </div>

        </div>

        <!-- 剩余排名列表 -->
        <div class="bg-white rounded-3xl shadow-xl shadow-slate-200/50 overflow-hidden border border-slate-100">
          <div class="px-4 md:px-6 py-3 md:py-4 border-b border-slate-50 bg-slate-50/50 flex items-center justify-between">
            <h3 class="font-bold text-slate-700">排行榜</h3>
            <span class="text-xs font-medium text-slate-400">Top 100</span>
          </div>
          
          <div class="divide-y divide-slate-50">
            <div 
              v-for="(user, index) in restRankings" 
              :key="user.userId"
              :class="[
                'group flex items-center gap-3 md:gap-4 px-4 md:px-6 py-3 md:py-4 transition-all duration-200',
                user.isMe ? 'bg-indigo-50/60' : 'hover:bg-slate-50'
              ]"
            >
              <div class="w-6 md:w-8 font-bold text-sm md:text-base text-slate-400 text-center group-hover:text-indigo-500 transition-colors shrink-0">
                {{ index + 4 }}
              </div>
              
              <div class="relative w-9 h-9 md:w-10 md:h-10 shrink-0">
                <img :src="user.avatar || defaultAvatar" class="w-full h-full rounded-full object-cover border border-slate-100" />
              </div>
              
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-1.5 md:gap-2">
                  <div class="font-bold text-sm md:text-base text-slate-700 truncate group-hover:text-indigo-600 transition-colors">{{ user.nickName }}</div>
                  <span v-if="user.isMe" class="px-1.5 py-0.5 bg-indigo-500 text-white text-[10px] font-bold rounded uppercase tracking-wider">Me</span>
                </div>
                <div class="text-[11px] md:text-xs text-slate-400 truncate">
                  {{ user.companyName ? user.companyName + ' · ' : '' }}{{ user.deptName }}
                </div>
              </div>
              
              <div class="text-right hidden md:block w-24">
                <div class="text-xs text-slate-400 mb-0.5">{{ rankingValueLabel }}</div>
                <div class="font-semibold text-slate-600">{{ user.answerCount || 0 }}</div>
              </div>

              <div class="text-right hidden md:block w-24">
                <div class="text-xs text-slate-400 mb-0.5">正确率</div>
                <div class="font-semibold text-slate-600">{{ formatRate(user.correctRate) }}%</div>
              </div>
              
              <div class="text-right w-auto min-w-[48px] md:min-w-[80px] shrink-0">
                <div class="text-base md:text-lg font-black text-indigo-600 leading-none">{{ user.score || 0 }}</div>
              </div>
            </div>
          </div>
          
          <!-- 空状态 -->
          <div v-if="currentRankingList.length === 0" class="py-20 text-center">
            <div class="w-20 h-20 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-4 text-4xl grayscale opacity-50">🏆</div>
            <p class="text-slate-400 font-medium">{{ activeTab === 'courseQuiz' ? '暂无结课测验排行数据' : '暂无排名数据，快来占领榜首吧！' }}</p>
          </div>
        </div>
      </div>

      <!-- 部门榜单内容 -->
      <div v-else-if="activeTab === 'department' || activeTab === 'courseQuizDept'" class="animate-fade-in-up space-y-4">
        <div 
          v-for="(dept, index) in departmentRankings" 
          :key="dept.deptId"
          class="bg-white rounded-2xl p-4 md:p-6 shadow-lg shadow-slate-100 hover:shadow-xl transition-all duration-300 border border-transparent hover:border-indigo-100 group"
        >
          <div class="flex items-center gap-4 md:gap-6">
            <!-- 排名勋章 -->
            <div class="relative flex-shrink-0">
              <div :class="[
                'w-12 h-12 md:w-14 md:h-14 rounded-2xl flex items-center justify-center text-lg md:text-xl font-black shadow-inner',
                index === 0 ? 'bg-yellow-50 text-yellow-600 ring-2 ring-yellow-100' :
                index === 1 ? 'bg-slate-100 text-slate-600 ring-2 ring-slate-200' :
                index === 2 ? 'bg-orange-50 text-orange-600 ring-2 ring-orange-100' :
                'bg-slate-50 text-slate-400'
              ]">
                {{ index + 1 }}
              </div>
              <div v-if="index < 3" class="absolute -top-2 -right-2 text-xl">
                {{ index === 0 ? '🏆' : index === 1 ? '🥈' : '🥉' }}
              </div>
            </div>
            
            <div class="flex-1 min-w-0">
              <div class="flex items-center justify-between gap-3 mb-2">
                <h3 class="font-bold text-slate-800 text-base md:text-lg group-hover:text-indigo-600 transition-colors truncate">{{ dept.deptName }}</h3>
                <div class="text-xl md:text-2xl font-black text-indigo-600 shrink-0">{{ dept.avgScore || 0 }} <span class="text-xs font-medium text-slate-400 ml-1">Avg</span></div>
              </div>
              
              <!-- 数据指标 -->
              <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs md:text-sm text-slate-500 mb-3">
                <div class="flex items-center gap-1.5">
                  <div class="w-2 h-2 rounded-full bg-indigo-400"></div>
                  <span>{{ dept.memberCount || 0 }} 成员</span>
                </div>
                <div class="flex items-center gap-1.5">
                  <div class="w-2 h-2 rounded-full bg-pink-400"></div>
                  <span>{{ dept.totalAnswers || 0 }} {{ activeTab === 'courseQuizDept' ? '题' : '答题' }}</span>
                </div>
              </div>
              
              <!-- 进度条 -->
              <div class="relative pt-1">
                <div class="flex items-center justify-between text-xs font-semibold mb-1">
                  <span class="text-slate-400">正确率</span>
                  <span class="text-indigo-600">{{ formatRate(dept.avgCorrectRate) }}%</span>
                </div>
                <div class="overflow-hidden h-2 mb-4 text-xs flex rounded-full bg-slate-100">
                  <div 
                    :style="{ width: (dept.avgCorrectRate || 0) + '%' }" 
                    class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-gradient-to-r from-indigo-500 to-purple-500 transition-all duration-1000 ease-out"
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- 空状态 -->
        <div v-if="departmentRankings.length === 0" class="py-20 text-center bg-white rounded-3xl border border-slate-100 border-dashed">
          <div class="text-6xl mb-4 grayscale opacity-30">🏢</div>
          <p class="text-slate-400">{{ activeTab === 'courseQuizDept' ? '暂无结课测验部门排行数据' : '暂无部门数据' }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted, markRaw, watch } from 'vue'
import { useRouter } from 'vue-router'
import { User, OfficeBuilding, Refresh, Document } from '@element-plus/icons-vue'
import { getPersonalRanking, getDepartmentRanking, getMyRanking, getCourseQuizRanking } from '@/api/ranking'
import HeaderBar from '@/components/HeaderBar.vue'

const defaultAvatar = 'https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png'

const loading = ref(false)
const activeTab = ref('personal')
const timeRange = ref('all')
const scope = ref('tenant')

const tabs = [
  { key: 'personal', label: '个人榜', icon: markRaw(User) },
  { key: 'department', label: '部门榜', icon: markRaw(OfficeBuilding) },
  { key: 'courseQuiz', label: '结课个人榜', icon: markRaw(Document) },
  { key: 'courseQuizDept', label: '结课部门榜', icon: markRaw(OfficeBuilding) }
]

const router = useRouter()
const goToMall = () => {
  router.push('/mall')
}

const timeOptions = [
  { label: '全部', value: 'all' },
  { label: '本月', value: 'month' },
  { label: '本周', value: 'week' },
  { label: '今日', value: 'today' }
]

const scopeOptions = [
  { label: '集团榜', value: 'tenant' },
  { label: '公司榜', value: 'company' },
  { label: '部门榜', value: 'department' }
]

const personalRankings = ref([])
const departmentRankings = ref([])
const courseQuizRankings = ref([])
const myRanking = ref(null)

const currentRankingList = computed(() => activeTab.value === 'courseQuiz' ? courseQuizRankings.value : personalRankings.value)
const topThree = computed(() => currentRankingList.value.slice(0, 3))
const restRankings = computed(() => currentRankingList.value.slice(3))
const myRankingLabel = computed(() => activeTab.value === 'courseQuiz' ? '本期均分' : '本期积分')
const myRankingUnit = computed(() => activeTab.value === 'courseQuiz' ? '分' : '')
const rankingValueLabel = computed(() => activeTab.value === 'courseQuiz' ? '测验' : '答题')

// 格式化正确率，保留一位小数
const formatRate = (rate) => {
  if (rate === null || rate === undefined) return '0.0'
  return Number(rate).toFixed(1)
}

const loadData = async () => {
  loading.value = true
  try {
    if (activeTab.value === 'personal') {
      const res = await getPersonalRanking({ timeRange: timeRange.value, scope: scope.value })
      if (res.data?.code === 200) {
        personalRankings.value = res.data.data || []
      }
    } else if (activeTab.value === 'courseQuiz') {
      const res = await getCourseQuizRanking({ timeRange: timeRange.value, scope: scope.value })
      if (res.data?.code === 200) {
        courseQuizRankings.value = res.data.data || []
      }
    } else {
      const res = await getDepartmentRanking({ timeRange: timeRange.value, scope: scope.value, type: activeTab.value === 'courseQuizDept' ? 'course_quiz' : 'personal' })
      if (res.data?.code === 200) {
        departmentRankings.value = res.data.data || []
      }
    }
    
    if (activeTab.value === 'personal' || activeTab.value === 'courseQuiz') {
      const myRes = await getMyRanking({ timeRange: timeRange.value, type: activeTab.value === 'courseQuiz' ? 'course_quiz' : 'personal' })
      if (myRes.data?.code === 200) {
        myRanking.value = myRes.data.data
      }
    } else {
      myRanking.value = null
    }
  } catch (error) {
    logger.error('Failed to load ranking data:', error)
  } finally {
    loading.value = false
  }
}

watch(activeTab, () => {
  loadData()
})

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.bg-clip-text {
  -webkit-background-clip: text;
  background-clip: text;
}

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

.animate-fade-in-up {
  animation: fadeInUp 0.6s ease-out forwards;
}

@media (max-width: 768px) {
  .ranking-page {
    overflow-x: hidden;
  }

  .ranking-page :deep(.bg-white),
  .ranking-page :deep([class*='rounded-']) {
    margin-bottom: 0;
  }

  .ranking-filter-group {
    gap: 0.25rem;
  }

  .ranking-filter-group > button {
    flex: 1 1 auto;
  }
}
</style>

