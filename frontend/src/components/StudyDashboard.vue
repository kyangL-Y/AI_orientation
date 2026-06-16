<template>
  <div class="study-dashboard">
    <div class="dashboard-header mb-2">
      <h3 class="section-header mb-0">我的学习路径</h3>
      <div class="dashboard-actions">
        <button 
          @click="isCalendarExpanded = !isCalendarExpanded"
          class="calendar-toggle-btn dashboard-calendar-btn text-xs px-2.5 py-1 rounded-lg border border-gray-200 text-gray-600 hover:text-blue-600 hover:border-blue-200 hover:bg-blue-50 transition-all flex items-center gap-1.5"
        >
          <el-icon><Calendar /></el-icon>
          {{ isCalendarExpanded ? '收起日历' : '查看日历' }}
        </button>
        <div class="calendar-current-label text-xs text-gray-400" v-if="isCalendarExpanded">{{ currentYear }}年{{ currentMonth }}月</div>
      </div>
    </div>
    
    <!-- 进度统计 -->
    <div class="progress-section grid grid-cols-1 md:grid-cols-3 gap-3 mb-3">
      <div class="stat-card stat-card-progress bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-100">
        <div class="stat-card-top">
          <div class="stat-main">
            <div class="stat-value text-blue-700">{{ stats.progress }}%</div>
            <div class="stat-label text-blue-400">总体进度</div>
          </div>
          <div class="stat-icon stat-icon-box p-2 bg-white rounded-lg shadow-sm text-blue-500">
            <el-icon><TrendCharts /></el-icon>
          </div>
        </div>
        <el-progress :percentage="stats.progress" :show-text="false" class="progress-bar mt-2" status="primary" :stroke-width="6" color="#3b82f6" />
      </div>
      
      <div class="stat-card stat-card-remaining bg-white border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
        <div class="stat-card-top">
          <div class="stat-main">
            <div class="stat-value text-gray-800"><span class="stat-number">{{ stats.remainingDays }}</span><span class="stat-unit">天</span></div>
            <div class="stat-label">剩余时间</div>
          </div>
          <div class="stat-icon stat-icon-box p-2 bg-orange-50 rounded-lg text-orange-500">
            <el-icon><Timer /></el-icon>
          </div>
        </div>
        <div class="stat-tip mt-2 text-xs text-orange-400 flex items-center gap-1">
          <el-icon><Warning /></el-icon> 请注意规划时间
        </div>
      </div>
      
      <div class="stat-card stat-card-completed bg-white border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
        <div class="stat-card-top">
          <div class="stat-main">
            <div class="stat-value text-gray-800"><span class="stat-number">{{ stats.completedTasks }}</span><span class="stat-separator">/</span><span class="stat-total">{{ stats.totalTasks }}</span></div>
            <div class="stat-label">已修模块</div>
          </div>
          <div class="stat-icon stat-icon-box p-2 bg-green-50 rounded-lg text-green-500">
            <el-icon><CircleCheck /></el-icon>
          </div>
        </div>
        <div class="stat-tip mt-2 text-xs text-green-500 flex items-center gap-1">
          <el-icon><CaretTop /></el-icon> 较上月提升 12%
        </div>
      </div>
    </div>

    <!-- 学习日历 (可折叠) -->
    <transition name="el-zoom-in-top">
      <div v-show="isCalendarExpanded" class="calendar-section bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden mb-3">
        <div class="calendar-header p-3 border-b border-gray-50 flex flex-col md:flex-row justify-between items-center gap-4">
          <div class="month-selector flex items-center bg-gray-50 rounded-lg p-1">
           <button class="p-1.5 hover:bg-white rounded-md transition-all text-gray-500 hover:text-blue-600 hover:shadow-sm" @click="changeMonth(-1)">
             <el-icon><ArrowLeft /></el-icon>
           </button>
           <span class="month-title mx-4 font-bold text-gray-700 min-w-[5rem] text-center">{{ currentYear }}年{{ currentMonth }}月</span>
           <button class="p-1.5 hover:bg-white rounded-md transition-all text-gray-500 hover:text-blue-600 hover:shadow-sm" @click="changeMonth(1)">
             <el-icon><ArrowRight /></el-icon>
           </button>
        </div>
        <div class="calendar-legend flex gap-4 text-xs font-medium">
          <span class="legend-item flex items-center gap-1.5"><span class="w-2 h-2 rounded-full bg-green-500 shadow-sm shadow-green-200"></span> 完成</span>
          <span class="legend-item flex items-center gap-1.5"><span class="w-2 h-2 rounded-full bg-yellow-400 shadow-sm shadow-yellow-200"></span> 待办</span>
          <span class="legend-item flex items-center gap-1.5"><span class="w-2 h-2 rounded-full bg-red-500 shadow-sm shadow-red-200"></span> 逾期</span>
        </div>
      </div>
      <el-calendar v-model="calendarDate">
        <template #dateCell="{ data }">
          <div class="calendar-cell h-full flex flex-col items-center pt-2 relative group hover:bg-blue-50/30 transition-colors">
            <span 
              class="day-number text-sm font-medium w-7 h-7 flex items-center justify-center rounded-full transition-all" 
              :class="{ 
                'bg-blue-600 text-white shadow-md shadow-blue-200': isToday(data.day),
                'text-gray-700': !isToday(data.day),
                'group-hover:text-blue-600': !isToday(data.day)
              }"
            >
              {{ data.day.split('-')[2] }}
            </span>
            <div class="task-dots flex gap-1 mt-1.5 flex-wrap justify-center px-1">
              <el-tooltip 
                v-for="(task, index) in getTasksForDate(data.day)" 
                :key="index"
                :content="task.title + ' (' + (task.status === 'completed' ? '已完成' : task.status === 'overdue' ? '已逾期' : '待办') + ')'"
                placement="top"
                :show-after="200"
              >
                <span 
                    class="task-dot w-1.5 h-1.5 rounded-full transition-transform hover:scale-150"
                    :class="{
                      'bg-green-500': task.status === 'completed',
                      'bg-yellow-400': task.status === 'pending',
                      'bg-red-500': task.status === 'overdue'
                    }">
                </span>
              </el-tooltip>
            </div>
          </div>
        </template>
      </el-calendar>
      </div>
    </transition>
  </div>
</template>

<script>
import logger from '@/utils/logger';
import { getLearningCalendar, getProgressStats } from '@/api/learningPlan'
import { getCourseProgressList } from '@/api/study'
import { ArrowLeft, ArrowRight, TrendCharts, Timer, CircleCheck, Warning, CaretTop, Calendar } from '@element-plus/icons-vue'

export default {
  name: 'StudyDashboard',
  components: { ArrowLeft, ArrowRight, TrendCharts, Timer, CircleCheck, Warning, CaretTop, Calendar },
  data() {
    return {
      isCalendarExpanded: false,
      calendarDate: new Date(),
      stats: {
        progress: 0,
        remainingDays: 0,
        completedTasks: 0,
        totalTasks: 0
      },
      calendarTasks: []
    }
  },
  // ... (rest of the logic remains the same)
  computed: {
    currentYear() {
      return this.calendarDate.getFullYear()
    },
    currentMonth() {
      return this.calendarDate.getMonth() + 1
    }
  },
  watch: {
    calendarDate: {
      handler(newVal) {
        this.fetchCalendarData(newVal.getFullYear(), newVal.getMonth() + 1)
      },
      immediate: true
    }
  },
  created() {
    this.fetchStats()
  },
  methods: {
    async fetchStats() {
      try {
        const res = await getCourseProgressList()
        const progressItems = res?.data?.data || res?.data?.rows || []
        if (Array.isArray(progressItems)) {
          this.stats = this.buildStatsFromProgress(progressItems)
          return
        }
      } catch (e) {
        logger.error(e)
      }

      try {
        const res = await getProgressStats()
        const payload = res?.data || res
        if (payload?.code === 200) {
          this.stats = this.normalizeStats(payload.data)
        }
      } catch (e) {
        logger.error(e)
      }
    },
    normalizeStats(rawStats = {}) {
      return {
        progress: Number(rawStats.progress || rawStats.completionRate || 0),
        remainingDays: Number(rawStats.remainingDays || 0),
        completedTasks: Number(rawStats.completedTasks || rawStats.completed || 0),
        totalTasks: Number(rawStats.totalTasks || rawStats.total || 0)
      }
    },
    buildStatsFromProgress(progressItems) {
      const totalTasks = progressItems.length
      const completedTasks = progressItems.filter(item => item.status === 'completed' || Number(item.progress || 0) >= 100).length
      const progress = totalTasks > 0
        ? Math.round(progressItems.reduce((sum, item) => sum + Number(item.progress || 0), 0) / totalTasks)
        : 0

      return {
        progress,
        remainingDays: 0,
        completedTasks,
        totalTasks
      }
    },
    async fetchCalendarData(year, month) {
      try {
        const res = await getLearningCalendar(year, month)
        const payload = res?.data || res
        if (payload?.code === 200) {
          const rows = payload.data || payload.rows || []
          this.calendarTasks = Array.isArray(rows) ? rows.map(this.normalizeCalendarTask).filter(task => task.date) : []
        }
      } catch (e) {
        logger.error(e)
      }
    },
    normalizeCalendarTask(item) {
      const date = item.date || item.endDate || item.startDate || item.updateTime || item.startedAt
      const status = item.status === 'completed' || Number(item.progress || 0) >= 100
        ? 'completed'
        : item.status === 'overdue'
          ? 'overdue'
          : 'pending'
      return {
        date: typeof date === 'string' ? date.slice(0, 10) : '',
        title: item.title || item.courseName || '学习任务',
        status
      }
    },
    getTasksForDate(dateStr) {
      return this.calendarTasks.filter(t => t.date === dateStr)
    },
    changeMonth(delta) {
        const newDate = new Date(this.calendarDate);
        newDate.setMonth(newDate.getMonth() + delta);
        this.calendarDate = newDate;
    },
    isToday(dateStr) {
        const today = new Date();
        const d = new Date(dateStr);
        return today.getFullYear() === d.getFullYear() &&
               today.getMonth() === d.getMonth() &&
               today.getDate() === d.getDate();
    }
  }
}
</script>

<style scoped>
.study-dashboard {
  background: white;
  border-radius: 12px;
  padding: 0.85rem;
  margin-bottom: 0.75rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
  border: 1px solid #f3f4f6;
}

.dashboard-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.75rem;
}

.dashboard-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.calendar-toggle-btn {
  white-space: nowrap;
  flex-shrink: 0;
}

.calendar-current-label {
  white-space: nowrap;
}

.section-header {
  font-size: 1rem;
  font-weight: 700;
  color: #1f2937;
  line-height: 1.4;
}

.progress-section {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  align-items: stretch;
}

.stat-card {
  padding: 0.85rem;
  border-radius: 12px;
  transition: all 0.3s ease;
  min-width: 0;
}

.stat-card-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 0.6rem;
}

.stat-main {
  min-width: 0;
  flex: 1;
}

@media (max-width: 768px) {
  .study-dashboard {
    padding: 0.75rem 0.7rem;
    border-radius: 10px;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
  }

  .section-header {
    font-size: 0.95rem;
  }

  .dashboard-header {
    align-items: center;
    gap: 0.5rem;
  }

  .dashboard-actions {
    margin-left: auto;
    width: auto;
    justify-content: flex-end;
    gap: 0.4rem;
  }

  .calendar-toggle-btn {
    width: auto;
    justify-content: center;
    padding: 0.5rem 0.7rem;
    font-size: 0.78rem;
    border-radius: 10px;
  }

  .calendar-current-label {
    width: auto;
    text-align: right;
    font-size: 0.72rem;
  }

  .stat-card {
    padding: 0.7rem;
    border-radius: 8px;
  }

  .stat-value {
    font-size: 1.02rem;
    margin-bottom: 0.1rem;
  }

  .stat-label {
    font-size: 0.72rem;
  }

  .progress-section {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.45rem;
    margin-bottom: 0.75rem;
  }

  .stat-card-top {
    align-items: flex-start;
    gap: 0.55rem;
  }

  .stat-card-completed {
    grid-column: 1 / -1;
  }

  .stat-icon-box {
    padding: 0.55rem !important;
    border-radius: 10px !important;
  }

  .progress-bar {
    margin-top: 0.6rem !important;
  }

  .stat-tip {
    margin-top: 0.55rem !important;
    font-size: 0.68rem;
    line-height: 1.35;
  }

  .calendar-header {
    align-items: stretch;
  }

  .month-selector,
  .calendar-legend {
    width: 100%;
  }

  .calendar-legend {
    flex-wrap: wrap;
    gap: 0.5rem 0.75rem;
  }
}

.stat-value {
  font-size: 1.2rem;
  font-weight: 800;
  line-height: 1.2;
  margin-bottom: 0.15rem;
  display: flex;
  align-items: baseline;
  gap: 0.25rem;
  flex-wrap: wrap;
  word-break: break-word;
}

.stat-label {
  font-size: 0.75rem;
  color: #6b7280;
  font-weight: 500;
}

.stat-unit,
.stat-total,
.stat-separator {
  font-size: 0.875rem;
  font-weight: 500;
  color: #9ca3af;
}

.stat-tip {
  flex-wrap: wrap;
  line-height: 1.5;
}

.stat-icon {
  flex-shrink: 0;
}

@media (max-width: 480px) {
  .study-dashboard {
    padding: 0.56rem;
    border-radius: 8px;
  }

  .dashboard-header {
    align-items: center;
    justify-content: space-between;
    gap: 0.4rem;
    margin-bottom: 0.55rem !important;
  }

  .dashboard-actions {
    width: auto;
    margin-left: auto;
    justify-content: flex-end;
    flex-wrap: nowrap;
    gap: 0.3rem;
  }

  .dashboard-calendar-btn {
    min-height: 30px;
    padding: 0.36rem 0.55rem;
    font-size: 0.72rem;
    gap: 0.25rem !important;
    border-radius: 9px;
  }

  .section-header {
    font-size: 0.84rem;
    line-height: 1.2;
    margin-bottom: 0;
    white-space: nowrap;
  }

  .progress-section {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 0.32rem;
    margin-bottom: 0.55rem !important;
  }

  .stat-card {
    padding: 0.5rem 0.48rem;
    border-radius: 7px;
  }

  .stat-card-top {
    gap: 0.3rem;
    align-items: flex-start;
  }

  .stat-value {
    font-size: 0.88rem;
    gap: 0.1rem;
    line-height: 1.05;
  }

  .stat-unit,
  .stat-total,
  .stat-separator {
    font-size: 0.6rem;
  }

  .stat-label {
    font-size: 0.62rem;
    line-height: 1.15;
  }

  .stat-icon-box {
    padding: 0.35rem !important;
    border-radius: 8px !important;
  }

  .stat-tip {
    margin-top: 0.32rem !important;
    font-size: 0.58rem;
    line-height: 1.15;
    gap: 0.15rem !important;
  }

  .stat-card-completed {
    grid-column: auto;
  }

  .progress-bar {
    margin-top: 0.4rem !important;
  }

  :deep(.progress-bar .el-progress-bar__outer) {
    height: 4px !important;
  }

  .calendar-current-label {
    display: none;
  }
}

:deep(.el-calendar) {
  --el-calendar-border: none;
  background: transparent;
}

:deep(.el-calendar__header) {
    display: none;
}

:deep(.el-calendar__body) {
    padding: 0;
}

:deep(.el-calendar-table) {
  border: none;
}

:deep(.el-calendar-table td) {
  border: none;
  border-bottom: 1px solid #f9fafb;
  border-right: 1px solid #f9fafb;
  transition: all 0.2s;
}

:deep(.el-calendar-table td:last-child) {
  border-right: none;
}

:deep(.el-calendar-table tr:last-child td) {
  border-bottom: none;
}

:deep(.el-calendar-table .el-calendar-day) {
    height: 70px;
    padding: 4px;
}

:deep(.el-calendar-table .el-calendar-day:hover) {
    background-color: transparent;
}
</style>

