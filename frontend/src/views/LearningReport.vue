<template>
  <div class="learning-report-page">
    <div class="page-container">
      <!-- 顶部导航区 -->
      <header class="report-header">
        <div class="header-left">
          <div class="back-button" @click="$router.back()">
            <el-icon><ArrowLeft /></el-icon>
          </div>
          <div class="header-titles">
            <div class="badge">
              <span class="dot"></span> 学习报告
            </div>
            <h1>我的成长档案</h1>
            <p>追踪学习进度，获取 AI 智能分析与个性化建议</p>
          </div>
        </div>
        <div class="header-right">
          <div v-if="isDemoMode" class="demo-chip">演示数据 · 2月初次接触，3月显著提升</div>
          <div v-if="!isDemoMode" class="period-selector">
            <el-select v-model="periodType" placeholder="选择周期" @change="handlePeriodChange" class="modern-select">
              <el-option label="本日" value="daily" />
              <el-option label="本周" value="weekly" />
              <el-option label="本月" value="monthly" />
              <el-option label="本季" value="quarterly" />
              <el-option label="自定义范围" value="custom" />
            </el-select>
          </div>
          <el-date-picker
            v-if="!isDemoMode && periodType === 'custom'"
            v-model="customDateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
            class="custom-range-picker"
            @change="handleCustomRangeChange"
          />
          <el-switch
            v-if="!isDemoMode"
            v-model="USE_MULTI_AGENT"
            inactive-text="标准报告"
            active-text="🤖 AI多智能体"
            :disabled="!multiAgentAvailable"
            class="multi-agent-switch"
            @change="handleMultiAgentToggle"
          />
          <el-button v-if="!isDemoMode" type="primary" class="action-btn generate" @click="handleGenerateReport" :loading="generating">
            <el-icon><MagicStick /></el-icon>
            <span>{{ generating ? '分析中...' : '生成新报告' }}</span>
          </el-button>
          <el-button v-if="report" class="action-btn export" @click="handleExportReport" :loading="exporting">
            <el-icon><Download /></el-icon>
            <span>导出</span>
          </el-button>
        </div>
      </header>

      <!-- 加载状态 -->
      <div v-if="loading" class="state-container">
        <div class="loading-spinner">
          <div class="spinner-ring"></div>
          <el-icon class="icon"><Loading /></el-icon>
        </div>
        <p>正在生成您的学习画像...</p>
      </div>

      <!-- 空状态 -->
      <div v-else-if="!report" class="state-container empty">
        <div class="empty-illustration">📊</div>
        <h3>暂无学习报告</h3>
        <p>生成第一份报告，开启您的智能成长之旅</p>
        <el-button type="primary" size="large" @click="handleGenerateReport" :loading="generating" class="start-btn">
          立即生成
        </el-button>
      </div>

      <!-- 报告内容 -->
      <div v-else class="report-body">

        <section
          class="identity-hero"
          :style="{ '--identity-accent': growthIdentity.accent, '--identity-accent-soft': growthIdentity.softAccent }"
        >
          <div class="identity-main">
            <div class="identity-badge">阶段称号 · {{ growthIdentity.badge }}</div>
            <h2>{{ growthIdentity.title }}</h2>
            <p>{{ growthIdentity.summary }}</p>
          </div>
          <div class="identity-side">
            <div class="identity-metric">
              <label>当前综合得分</label>
              <strong>{{ growthIdentity.scoreLabel }}</strong>
            </div>
            <div class="identity-metric">
              <label>当前正确率</label>
              <strong>{{ growthIdentity.accuracyLabel }}</strong>
            </div>
            <div class="identity-progress">
              <div class="identity-progress-top">
                <span>距离下一阶段</span>
                <strong>{{ growthIdentity.nextTitle }}</strong>
              </div>
              <div class="identity-progress-bar">
                <div class="identity-progress-fill" :style="{ width: `${growthIdentity.progress}%` }"></div>
              </div>
            </div>
          </div>
        </section>
        
        <!-- 核心指标卡片 -->
        <section class="metrics-grid">
          <!-- 综合得分 -->
          <div class="metric-card score-card">
            <div class="card-header">
              <span class="label">综合得分</span>
              <el-tag :type="getScoreTagType(report.totalScore)" effect="dark" round size="small">
                {{ getScoreLevel(report.totalScore) }}
              </el-tag>
            </div>
            <div class="score-display">
              <span class="number">{{ report.totalScore }}</span>
              <span class="total">/100</span>
            </div>
            <div class="score-footer">
              <div class="rank-info">
                <span class="label">部门排名</span>
                <span class="value">No.{{ report.deptRank || '-' }}</span>
                <span class="total-users">/ {{ report.totalInDept || '-' }}人</span>
              </div>
              <div class="trend-icon up" v-if="report.totalScore >= 80"><el-icon><Top /></el-icon></div>
            </div>
          </div>

          <!-- 学习时长 -->
          <div class="metric-card duration-card">
            <div class="card-header">
              <span class="label">课程学习时长</span>
              <div class="icon-box blue"><el-icon><Timer /></el-icon></div>
            </div>
            <div class="metric-value">
              {{ formatDuration(auxiliaryData.learningDuration || auxiliaryData.learning_duration || 0) }}
            </div>
            <div class="metric-sub">
              <span>口径：课程/视频/文章学习时长</span>
            </div>
            <div class="metric-sub">
              <span>周期：{{ formatPeriodRange(report.periodStart, report.periodEnd) }}</span>
            </div>
          </div>

          <!-- 刷题数量 -->
          <div class="metric-card quiz-card">
            <div class="card-header">
              <span class="label">刷题训练</span>
              <div class="icon-box purple"><el-icon><Edit /></el-icon></div>
            </div>
            <div class="metric-value">
              {{ auxiliaryData.quizCount || auxiliaryData.quiz_count || 0 }} <span class="unit">题</span>
            </div>
            <div class="metric-sub">
              <span>普通训练正确率：{{ calculateAccuracyRate() }}</span>
            </div>
            <div class="metric-sub">
              <span>结课测验：{{ auxiliaryData.courseQuizCount || 0 }} 次 / 均分 {{ formatAssessmentScore(auxiliaryData.courseQuizAverageScore) }}</span>
            </div>
          </div>
        </section>

        <GrowthTrendPanel
          :reports="historyReports"
          :period-type="periodType"
        />

        <MonthlyComparisonShowcase
          :report="report"
          :history-reports="historyReports"
        />

        <!-- 能力分析区域 -->
        <section class="analysis-grid">
          <!-- 雷达图 -->
          <div class="content-card radar-section">
            <div class="section-header">
              <h3>学习能力分析</h3>
              <p>五维能力分布概览</p>
            </div>
            <div class="chart-container">
              <canvas ref="radarChartRef"></canvas>
            </div>
          </div>

          <!-- 维度列表 -->
          <div class="content-card dimension-section">
            <div class="section-header">
              <h3>维度详情</h3>
            </div>
            <div class="dimension-list">
              <div v-for="(score, code) in dimensionScores" :key="code" class="dimension-row">
                <div class="row-info">
                  <div class="dim-name">
                    <span class="icon">{{ getDimensionIcon(dimensionNameMap[code] || code) }}</span>
                    {{ dimensionNameMap[code] || code }}
                  </div>
                  <span class="dim-score">{{ score }}分</span>
                </div>
                <div class="progress-bg">
                  <div class="progress-bar"
                       :style="{ width: Math.min(score, 100) + '%', background: getProgressColor(score) }">
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- 业务能力分析区域 -->
        <section class="analysis-grid" style="margin-top: 24px;" v-if="Object.keys(abilityScores).length > 0">
          <!-- 业务能力雷达图 -->
          <div class="content-card radar-section">
            <div class="section-header">
              <h3>业务能力分析</h3>
              <p>岗位核心能力评估</p>
            </div>
            <div class="chart-container">
              <canvas ref="abilityChartRef"></canvas>
            </div>
          </div>

          <!-- 业务能力维度列表 -->
          <div class="content-card dimension-section">
            <div class="section-header">
              <h3>能力详情</h3>
            </div>
            <div class="dimension-list">
              <div v-for="(score, code) in abilityScores" :key="code" class="dimension-row">
                <div class="row-info">
                  <div class="dim-name">
                    <span class="icon">{{ getAbilityIcon(abilityNameMap[code] || code) }}</span>
                    {{ abilityNameMap[code] || code }}
                  </div>
                  <span class="dim-score">{{ normalizeScore(score) }}分</span>
                </div>
                <div class="progress-bg">
                  <div class="progress-bar"
                       :style="{ width: normalizeScore(score) + '%', background: getAbilityProgressColor(score) }">
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- AI 深度报告 -->
        <section class="ai-report-section" v-if="sanitizedAiSuggestion">
          <div class="report-paper">
            <div class="paper-header">
              <div class="ai-badge">
                <el-icon><Cpu /></el-icon> AI 智能分析
              </div>
              <h2>学习成效深度复盘</h2>
            </div>

            <div class="growth-story-strip" v-if="growthNarrative">
              <article class="story-card primary">
                <label>成长判断</label>
                <strong>{{ growthNarrative.title }}</strong>
                <p>{{ growthNarrative.summary }}</p>
              </article>
              <article class="story-card">
                <label>当前动能</label>
                <strong>{{ growthNarrative.momentumLabel }}</strong>
                <p>{{ growthNarrative.momentumDetail }}</p>
              </article>
              <article class="story-card">
                <label>下一步重点</label>
                <strong>{{ growthNarrative.focusLabel }}</strong>
                <p>{{ growthNarrative.focusDetail }}</p>
              </article>
            </div>

            <div class="growth-goals" v-if="nextGrowthGoals.length">
              <div class="goals-header">
                <div>
                  <p class="goals-eyebrow">下周期成长目标</p>
                  <h3>把成长变成可执行的冲刺目标</h3>
                </div>
                <span class="goals-hint">目标会随最新趋势自动调整</span>
              </div>

              <div class="goal-list">
                <article
                  v-for="goal in nextGrowthGoals"
                  :key="goal.key"
                  class="goal-card"
                  :style="{ '--goal-accent': goal.accent, '--goal-accent-soft': goal.softAccent }"
                >
                  <div class="goal-top">
                    <div>
                      <label>{{ goal.title }}</label>
                      <strong>{{ goal.currentLabel }} → {{ goal.targetLabel }}</strong>
                    </div>
                    <span class="goal-gap">还差 {{ goal.gapLabel }}</span>
                  </div>

                  <div class="goal-progress">
                    <div class="goal-progress-bar" :style="{ width: `${goal.progress}%` }"></div>
                  </div>

                  <p class="goal-action">{{ goal.action }}</p>
                </article>
              </div>
            </div>

            <!-- 引言 -->
            <div class="paper-intro">
              <p>{{ aiSummary }}</p>
            </div>

            <div class="divider"></div>

            <!-- 核心内容 -->
            <div class="paper-body">
              
              <!-- 学习画像 -->
              <div class="paper-chapter" v-if="sanitizedAiSuggestion.learning_profile">
                <h3>01. 整体画像</h3>
                <div class="profile-grid">
                   <div class="profile-item">
                     <label>课程学习时长</label>
                     <div class="val">{{ sanitizedAiSuggestion.learning_profile.duration_value || formatDuration(auxiliaryData.learningDuration || 0) }}</div>
                     <div class="eval">{{ sanitizedAiSuggestion.learning_profile.duration_eval }}</div>
                   </div>
                   <div class="profile-item">
                     <label>答题表现</label>
                     <div class="val">{{ sanitizedAiSuggestion.learning_profile.accuracy_value || calculateAccuracyRate() }}</div>
                     <div class="eval">{{ sanitizedAiSuggestion.learning_profile.accuracy_eval }}</div>
                   </div>
                   <div class="profile-item">
                     <label>综合评定</label>
                     <div class="val">{{ sanitizedAiSuggestion.learning_profile.score_value || report.totalScore + '分' }}</div>
                     <div class="eval">{{ sanitizedAiSuggestion.learning_profile.score_eval }}</div>
                   </div>
                </div>
                <div class="profile-summary-box" v-if="sanitizedAiSuggestion.learning_profile.one_sentence">
                  <strong>💡 总结：</strong> {{ sanitizedAiSuggestion.learning_profile.one_sentence }}
                </div>
              </div>

              <!-- 深度分析 -->
              <div class="paper-chapter" v-if="sanitizedAiSuggestion.dimension_analysis && sanitizedAiSuggestion.dimension_analysis.length > 0">
                <h3>02. 深度剖析</h3>
                <div class="analysis-cards">
                  <div v-for="(dim, index) in sanitizedAiSuggestion.dimension_analysis" :key="index" class="analysis-block">
                    <h4>{{ dim.dimension }} <span class="sub">—— {{ dim.title }}</span></h4>
                    <p>{{ dim.analysis }}</p>
                    <div class="tip" v-if="dim.tip">
                      <el-icon><Bell /></el-icon> {{ dim.tip }}
                    </div>
                  </div>
                </div>
              </div>

              <!-- 行动计划 -->
              <div class="paper-chapter" v-if="sanitizedAiSuggestion.action_plan">
                <h3>03. 行动建议</h3>
                <div class="plan-flex">
                  <div class="plan-col consolidate" v-if="sanitizedAiSuggestion.action_plan.consolidate && sanitizedAiSuggestion.action_plan.consolidate.length > 0">
                    <h4><el-icon><CircleCheck /></el-icon> 保持优势</h4>
                    <ul>
                      <li v-for="(item, i) in sanitizedAiSuggestion.action_plan.consolidate" :key="i">{{ item }}</li>
                    </ul>
                  </div>
                  <div class="plan-col improve" v-if="sanitizedAiSuggestion.action_plan.improve && sanitizedAiSuggestion.action_plan.improve.length > 0">
                    <h4><el-icon><TrendCharts /></el-icon> 提升重点</h4>
                    <ul>
                      <li v-for="(item, i) in sanitizedAiSuggestion.action_plan.improve" :key="i">{{ item }}</li>
                    </ul>
                  </div>
                </div>
              </div>
              
              <!-- 兼容旧数据 -->
              <div class="paper-chapter" v-if="!sanitizedAiSuggestion.action_plan && fallbackSuggestion">
                <h3>改进建议</h3>
                <p>{{ fallbackSuggestion }}</p>
              </div>

              <div class="paper-footer">
                 <p>{{ sanitizedAiSuggestion.closing_message || '持续学习，遇见更好的自己。' }}</p>
              </div>

            </div>
          </div>
        </section>

      </div>
    </div>
  </div>
</template>

<script setup>
import logger from '@/utils/logger';
import { ref, computed, onMounted, onBeforeUnmount, nextTick, watch } from 'vue'
import { useRoute } from 'vue-router'
import { generateReport, getLatestReport, listMyReports } from '@/api/assessment'
import {
  generateMultiAgentReport,
  getMultiAgentReport,
  checkMultiAgentHealth
} from '@/api/userStatistics'
import GrowthTrendPanel from '@/components/report/GrowthTrendPanel.vue'
import MonthlyComparisonShowcase from '@/components/report/MonthlyComparisonShowcase.vue'
import { buildGrowthIdentity, buildGrowthNarrative, buildNextGrowthGoals } from '@/utils/reportGrowth'
import { sanitizeAiSuggestionData, sanitizeReportText } from '@/utils/reportComparison'
import { getDemoLearningReportPayload } from '@/mock/demoLearningReport'
import { exportElementToPdf } from '@/utils/reportPdf'
import {
  TrendCharts, Cpu, Loading, ArrowLeft, Download, MagicStick,
  Timer, Edit, Top, Bell, CircleCheck
} from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

// 多智能体功能开关（设置为 true 启用多智能体报告）
const USE_MULTI_AGENT = ref(false)
const multiAgentAvailable = ref(false)

let chartModule = null
let chartRegistered = false
const route = useRoute()

async function ensureChartModule() {
  if (!chartModule) {
    chartModule = await import('chart.js')
  }
  if (!chartRegistered) {
    chartModule.Chart.register(...chartModule.registerables)
    chartRegistered = true
  }
  return chartModule.Chart
}

const loading = ref(false)
const generating = ref(false)
const exporting = ref(false)
const periodType = ref('monthly')
const customDateRange = ref([])
const report = ref(null)
const historyReports = ref([])
const radarChartRef = ref(null)
const abilityChartRef = ref(null)
let chartInstance = null
let abilityChartInstance = null
let requestId = 0
let abilityChartInitId = 0
const isDemoMode = computed(() => route.name === 'LearningReportDemo' || route.query.demo === 'showcase')

watch(
  [report, loading],
  async ([currentReport, isLoading]) => {
    if (!currentReport || isLoading) return
    await nextTick()
    void initRadarChart().catch((err) => {
      logger.error('雷达图初始化失败:', err)
    })
    void initAbilityChart().catch((err) => {
      logger.error('业务能力雷达图初始化失败:', err)
    })
  },
  { flush: 'post' }
)

const periodTypeMap = { daily: '日报', weekly: '周报', monthly: '月报', quarterly: '季报', custom: '自定义报告' }
const dimensionNameMap = {
  learning_duration: '课程学习时长',
  quiz_count: '刷题数量',
  accuracy_rate: '正确率',
  completion_rate: '完成率',
  assessment_score: '测评得分'
}

const abilityNameMap = {
  cost_control: '成本控制',
  customer_service: '客户服务',
  team_collaboration: '团队协作',
  professional_skills: '专业技能',
  safety_compliance: '安全合规'
}

const dimensionScores = computed(() => {
  if (!report.value || !report.value.dimensionScores) return {}
  try { return JSON.parse(report.value.dimensionScores) } catch { return {} }
})

const auxiliaryData = computed(() => {
  if (!report.value || !report.value.auxiliaryData) return {}
  try { return JSON.parse(report.value.auxiliaryData) } catch { return {} }
})

const aiSuggestion = computed(() => {
  if (!report.value || !report.value.aiSuggestion) return null
  try { return JSON.parse(report.value.aiSuggestion) } catch { return null }
})
const sanitizedAiSuggestion = computed(() => sanitizeAiSuggestionData(aiSuggestion.value))

const abilityScores = computed(() => {
  const raw = report.value?.abilityScores
  if (!raw) return {}
  if (typeof raw === 'object') return raw
  if (typeof raw === 'string') {
    try { return JSON.parse(raw) } catch { return {} }
  }
  return {}
})

const growthNarrative = computed(() => buildGrowthNarrative(historyReports.value, periodType.value))
const nextGrowthGoals = computed(() => buildNextGrowthGoals(historyReports.value, periodType.value))
const growthIdentity = computed(() => buildGrowthIdentity(historyReports.value, periodType.value))
const aiSummary = computed(() => sanitizeReportText(
  sanitizedAiSuggestion.value?.report_intro || sanitizedAiSuggestion.value?.summary || sanitizedAiSuggestion.value?.overall_comment,
  '暂无引言'
))
const fallbackSuggestion = computed(() => sanitizeReportText(
  sanitizedAiSuggestion.value?.improvement_plan || sanitizedAiSuggestion.value?.weakness_analysis,
  ''
))

function getScoreLevel(score) {
  if (score >= 90) return '卓越'
  if (score >= 80) return '优秀'
  if (score >= 60) return '良好'
  return '需努力'
}

function formatDateFriendly(dateStr) {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  if (isNaN(date.getTime())) return dateStr.split('T')[0]
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

function formatPeriodRange(startDate, endDate) {
  if (!startDate || !endDate) return '未设置'
  return `${formatDateFriendly(startDate)} ~ ${formatDateFriendly(endDate)}`
}

function formatDuration(minutes) {
  if (!minutes) return '0分钟'
  // 假设后端传过来的是分钟
  const num = parseInt(minutes)
  if (num < 60) return `${num}分钟`
  const h = Math.floor(num / 60)
  const m = num % 60
  return m > 0 ? `${h}小时${m}分` : `${h}小时`
}

function getScoreTagType(score) {
  if (score >= 80) return 'success'
  if (score >= 60) return 'warning'
  return 'danger'
}

function getProgressColor(score) {
  if (score >= 80) return '#10b981' // emerald-500
  if (score >= 60) return '#f59e0b' // amber-500
  return '#ef4444' // red-500
}

function getDimensionIcon(name) {
  if (name.includes('时长')) return '🕒'
  if (name.includes('刷题') || name.includes('数量')) return '✍️'
  if (name.includes('正确')) return '🎯'
  if (name.includes('完成')) return '📊'
  if (name.includes('测评')) return '📝'
  return '💠'
}

function getAbilityIcon(name) {
  if (name.includes('成本')) return '💰'
  if (name.includes('客户') || name.includes('服务')) return '🤝'
  if (name.includes('团队') || name.includes('协作')) return '👥'
  if (name.includes('专业') || name.includes('技能')) return '🎯'
  if (name.includes('安全') || name.includes('合规')) return '🛡️'
  return '📊'
}

function normalizeScore(v) {
  return Math.max(0, Math.min(100, Number(v) || 0))
}

function getAbilityProgressColor(score) {
  const s = normalizeScore(score)
  if (s >= 80) return '#10b981' // emerald-500
  if (s >= 60) return '#f59e0b' // amber-500
  return '#ef4444' // red-500
}

function sanitizeFileName(name) {
  // 清洗无效字符
  let sanitized = (name || '').replace(/[\\/:*?"<>|]/g, '_').trim()
  // 移除末尾的点和空格
  sanitized = sanitized.replace(/[.\s]+$/, '')
  // Windows 保留名检查
  const reserved = /^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/i
  if (reserved.test(sanitized) || sanitized.length === 0) {
    sanitized = 'report'
  }
  return sanitized.substring(0, 50)
}

function calculateAccuracyRate() {
  if (!report.value || !report.value.rawData) return '0%'
  try {
    const rawData = JSON.parse(report.value.rawData)
    const total = Math.max(0, Number(rawData.totalAttempts) || 0)
    const correct = Math.max(0, Math.min(Number(rawData.correctCount) || 0, total))
    if (total === 0 || !Number.isFinite(correct / total)) return '0%'
    return ((correct / total) * 100).toFixed(0) + '%'
  } catch {
    return '0%'
  }
}

function formatAssessmentScore(value) {
  const score = Number(value)
  if (!Number.isFinite(score) || score <= 0) return '0分'
  return `${Math.round(score)}分`
}

async function handleGenerateReport() {
  const params = buildReportParams(true)
  if (!params) return

  generating.value = true
  try {
    let res
    // 如果启用了多智能体且服务可用，使用多智能体生成报告
    if (USE_MULTI_AGENT.value && multiAgentAvailable.value) {
      try {
        res = await generateMultiAgentReport(params)
        ElMessage.success('🤖 AI 多智能体报告生成成功')
      } catch (multiAgentError) {
        logger.warn('多智能体生成失败，降级到标准报告', multiAgentError)
        ElMessage.warning('多智能体服务暂时不可用，使用标准报告')
        res = await generateReport(params)
      }
    } else {
      // 使用标准报告生成
      res = await generateReport(params)
      ElMessage.success('报告生成成功')
    }

    const generatedReport = res?.data ?? res
    const isSuccess = !res || res.code === undefined || res.code === 200
    if (isSuccess && generatedReport) {
      report.value = generatedReport
      await loadReport()
    } else {
      throw new Error(res?.msg || '报告生成失败')
    }
  } catch (error) {
    ElMessage.error(error.message || '报告生成失败')
  } finally {
    generating.value = false
  }
}

function buildReportParams(requireRange = false) {
  if (periodType.value !== 'custom') {
    return { periodType: periodType.value }
  }

  if (!customDateRange.value || customDateRange.value.length !== 2) {
    if (requireRange) {
      ElMessage.warning('请选择自定义开始日期和结束日期')
    }
    return requireRange ? null : { periodType: 'custom' }
  }

  return {
    periodType: 'custom',
    startDate: customDateRange.value[0],
    endDate: customDateRange.value[1],
  }
}

function findCustomReportByRange(list) {
  if (!Array.isArray(list) || !customDateRange.value || customDateRange.value.length !== 2) {
    return null
  }
  const [startDate, endDate] = customDateRange.value
  return list.find((item) => {
    const itemStart = formatDateFriendly(item?.periodStart)
    const itemEnd = formatDateFriendly(item?.periodEnd)
    return itemStart === startDate && itemEnd === endDate
  }) || null
}

function handlePeriodChange() {
  if (periodType.value !== 'custom') {
    loadReport()
    return
  }

  if (customDateRange.value?.length === 2) {
    loadReport()
    return
  }

  report.value = null
  historyReports.value = []
}

function handleCustomRangeChange() {
  if (periodType.value === 'custom' && customDateRange.value?.length === 2) {
    loadReport()
  }
}

async function loadReport() {
  const currentRequestId = ++requestId
  loading.value = true
  let hasError = false
  try {
    if (isDemoMode.value) {
      const demoPayload = getDemoLearningReportPayload()
      periodType.value = demoPayload.periodType
      customDateRange.value = []
      historyReports.value = demoPayload.historyReports
      report.value = demoPayload.report
      return
    }

    const params = buildReportParams(false)

    // 如果启用了多智能体且服务可用，优先使用多智能体报告
    if (USE_MULTI_AGENT.value && multiAgentAvailable.value) {
      try {
        const multiAgentRes = await getMultiAgentReport(params)
        if (currentRequestId !== requestId) return

        if (multiAgentRes?.data?.code === 200 && multiAgentRes.data.data) {
          report.value = multiAgentRes.data.data
          // 同时加载历史报告列表
          try {
            const historyRes = await listMyReports(params)
            if (historyRes?.code === 200) {
              historyReports.value = historyRes.rows || historyRes.data || []
            }
          } catch (e) {
            logger.warn('加载历史报告失败', e)
          }
          return
        }
      } catch (multiAgentError) {
        logger.warn('多智能体报告获取失败，降级到标准报告', multiAgentError)
      }
    }

    // 使用标准报告
    const results = await Promise.allSettled([
      getLatestReport(params),
      listMyReports(params)
    ])

    // 检查是否已有更新的请求，防止乱序
    if (currentRequestId !== requestId) return

    // 分别处理结果
    if (results[0].status === 'fulfilled') {
      const latestRes = results[0].value
      if (latestRes?.code === 200) {
        report.value = latestRes.data
      } else if (latestRes && typeof latestRes === 'object' && !('code' in latestRes)) {
        // 兼容直接返回数据的情况（无 code 字段）
        report.value = latestRes
      } else {
        if (!report.value) {
          report.value = null
        }
        hasError = true
        logger.error('获取最新报告业务失败:', latestRes?.msg || latestRes)
      }
    } else {
      if (!report.value) {
        report.value = null
      }
      hasError = true
      logger.error('获取最新报告失败:', results[0].reason)
    }

    if (results[1].status === 'fulfilled') {
      const historyRes = results[1].value
      if (historyRes?.code === 200) {
        historyReports.value = historyRes.data || historyRes.rows || []
        if (periodType.value === 'custom' && customDateRange.value?.length === 2) {
          report.value = findCustomReportByRange(historyReports.value) || report.value
        }
      } else {
        historyReports.value = []
        hasError = true
        logger.warn('获取历史报告业务失败:', historyRes?.msg || historyRes)
      }
    } else {
      historyReports.value = []
      hasError = true
      logger.error('获取历史报告失败:', results[1].reason)
    }

    // 聚合错误提示，只显示一次
    if (hasError) {
      ElMessage.warning('部分数据加载失败，请稍后刷新重试')
    }

  } catch (error) {
    // 检查是否已有更新的请求
    if (currentRequestId !== requestId) return
    report.value = null
    historyReports.value = []
    ElMessage.error('加载报告失败，请稍后重试')
    logger.error('加载报告失败:', error)
  } finally {
    // 仅当是最新请求时才关闭loading
    if (currentRequestId === requestId) {
      loading.value = false
    }
  }
}

async function initRadarChart() {
  if (!radarChartRef.value || !report.value) return
  if (chartInstance) chartInstance.destroy()

  const Chart = await ensureChartModule()

  const scores = dimensionScores.value
  // 确保顺序一致
  const keys = ['learning_duration', 'quiz_count', 'accuracy_rate', 'completion_rate', 'assessment_score']
  const labels = keys.map(k => dimensionNameMap[k])
  const data = keys.map(k => scores[k] || 0)

  chartInstance = new Chart(radarChartRef.value, {
    type: 'radar',
    data: {
      labels: labels,
      datasets: [{
        label: '能力得分',
        data: data,
        backgroundColor: 'rgba(59, 130, 246, 0.2)', // blue-500 with opacity
        borderColor: '#3b82f6',
        borderWidth: 2,
        pointBackgroundColor: '#3b82f6',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: '#3b82f6'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        r: {
          min: 0,
          max: 100,
          ticks: { stepSize: 20, display: false },
          grid: { color: '#e5e7eb' },
          pointLabels: {
            font: { size: 12, family: 'sans-serif' },
            color: '#6b7280'
          }
        }
      },
      plugins: { legend: { display: false } }
    }
  })
}

async function initAbilityChart() {
  const currentInitId = ++abilityChartInitId

  if (!abilityChartRef.value || !report.value) return

  if (abilityChartInstance) {
    abilityChartInstance.destroy()
    abilityChartInstance = null
  }

  const Chart = await ensureChartModule()

  // 竞态检查：如果有新的初始化请求，放弃当前操作
  if (currentInitId !== abilityChartInitId) return
  // canvas 或 report 可能已被销毁/清空
  if (!abilityChartRef.value || !report.value) return

  const scores = abilityScores.value
  const keys = ['cost_control', 'customer_service', 'team_collaboration', 'professional_skills', 'safety_compliance']
  const labels = keys.map(k => abilityNameMap[k])
  const data = keys.map(k => normalizeScore(scores[k]))

  abilityChartInstance = new Chart(abilityChartRef.value, {
    type: 'radar',
    data: {
      labels: labels,
      datasets: [{
        label: '业务能力',
        data: data,
        backgroundColor: 'rgba(16, 185, 129, 0.2)', // emerald-500
        borderColor: '#10b981',
        borderWidth: 2,
        pointBackgroundColor: '#10b981',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: '#10b981'
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        r: {
          min: 0,
          max: 100,
          ticks: { stepSize: 20, display: false },
          grid: { color: '#e5e7eb' },
          pointLabels: {
            font: { size: 12, family: 'sans-serif' },
            color: '#6b7280'
          }
        }
      },
      plugins: { legend: { display: false } }
    }
  })
}

async function handleExportReport() {
  if (!report.value) return
  exporting.value = true
  
  try {
    const element = document.querySelector('.report-body')
    if (!element) {
      throw new Error('未找到报告内容')
    }

    const rawFileName = `${report.value.userName || '我的'}_学习报告_${formatDateFriendly(new Date())}`
    await exportElementToPdf({
      element,
      filename: sanitizeFileName(rawFileName),
      backgroundColor: '#f8fafc',
    })

    ElMessage.success('PDF导出成功')
  } catch (error) {
    logger.error('导出PDF失败:', error)
    ElMessage.error('导出PDF失败，请稍后重试')
  } finally {
    exporting.value = false
  }
}

// 检查多智能体服务健康状态
async function checkMultiAgentServiceHealth() {
  if (!USE_MULTI_AGENT.value) {
    multiAgentAvailable.value = false
    return
  }

  try {
    const healthRes = await checkMultiAgentHealth()
    multiAgentAvailable.value = healthRes?.data?.code === 200
    if (multiAgentAvailable.value) {
      logger.info('多智能体服务可用')
    } else {
      logger.warn('多智能体服务不可用，将使用标准报告')
    }
  } catch (error) {
    multiAgentAvailable.value = false
    logger.warn('多智能体服务健康检查失败', error)
  }
}

// 处理多智能体开关切换
function handleMultiAgentToggle(enabled) {
  if (enabled && !multiAgentAvailable.value) {
    ElMessage.warning('多智能体服务当前不可用')
    USE_MULTI_AGENT.value = false
    return
  }

  const mode = enabled ? '🤖 AI 多智能体模式' : '标准报告模式'
  ElMessage.success(`已切换到${mode}`)

  // 切换后重新加载报告
  if (report.value) {
    loadReport()
  }
}

onMounted(async () => {
  // 先检查多智能体服务
  await checkMultiAgentServiceHealth()
  // 再加载报告
  await loadReport()
})

onBeforeUnmount(() => {
  if (chartInstance) {
    chartInstance.destroy()
    chartInstance = null
  }
  if (abilityChartInstance) {
    abilityChartInstance.destroy()
    abilityChartInstance = null
  }
})
</script>

<style scoped>
.learning-report-page {
  min-height: 100vh;
  background-color: #f8fafc; /* Slate 50 */
  color: #1e293b; /* Slate 800 */
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  padding: 24px;
}

.page-container {
  max-width: 1200px;
  margin: 0 auto;
}

.report-header,
.header-left,
.header-right,
.header-titles,
.identity-main,
.identity-side,
.metric-card,
.content-card,
.story-card,
.goal-card,
.profile-item,
.analysis-block,
.plan-col {
  min-width: 0;
}

/* Header */
.report-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
  padding: 0 8px;
}

.header-left {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}

.back-button {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  transition: all 0.2s;
  color: #64748b;
}

.back-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
  color: #3b82f6;
}

.header-titles h1 {
  font-size: clamp(1.5rem, 2vw, 1.75rem);
  font-weight: 700;
  margin: 4px 0;
  color: #0f172a;
  line-height: 1.25;
}

.header-titles p {
  color: #64748b;
  font-size: 14px;
  margin: 0;
  line-height: 1.6;
}

.badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #eff6ff;
  color: #3b82f6;
  padding: 4px 10px;
  border-radius: 99px;
  font-size: 12px;
  font-weight: 600;
}

.badge .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #3b82f6;
}

.header-right {
  display: flex;
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.modern-select {
  width: 120px;
}

.custom-range-picker {
  width: 280px;
}

.demo-chip {
  padding: 10px 14px;
  border-radius: 999px;
  background: #ecfdf5;
  border: 1px solid #bbf7d0;
  color: #166534;
  font-size: 12px;
  font-weight: 700;
  line-height: 1.4;
}

.action-btn {
  border-radius: 10px;
  padding: 10px 20px;
  font-weight: 500;
  border: none;
  max-width: 100%;
}

.action-btn.generate {
  background: #3b82f6;
  box-shadow: 0 4px 6px -1px rgba(59, 130, 246, 0.2);
}

.action-btn.generate:hover {
  background: #2563eb;
}

.action-btn.export {
  background: white;
  color: #475569;
  border: 1px solid #e2e8f0;
}

.action-btn.export:hover {
  background: #f1f5f9;
}

/* Loading & Empty States */
.state-container {
  background: white;
  border-radius: 20px;
  padding: 60px;
  text-align: center;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.loading-spinner {
  position: relative;
  width: 60px;
  height: 60px;
  margin: 0 auto 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.spinner-ring {
  position: absolute;
  inset: 0;
  border: 4px solid #e2e8f0;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.loading-spinner .icon {
  font-size: 24px;
  color: #3b82f6;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-illustration {
  font-size: 48px;
  margin-bottom: 16px;
}

.empty h3 {
  font-size: 18px;
  color: #0f172a;
  margin-bottom: 8px;
}

.empty p {
  color: #64748b;
  margin-bottom: 24px;
}

/* Metrics Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: 1.2fr 1fr 1fr;
  gap: 20px;
  margin-bottom: 24px;
}

.identity-hero {
  display: grid;
  grid-template-columns: 1.35fr 0.95fr;
  gap: 18px;
  margin-bottom: 24px;
  padding: 24px 26px;
  border-radius: 24px;
  background:
    radial-gradient(circle at top left, var(--identity-accent-soft) 0%, transparent 34%),
    linear-gradient(135deg, #0f172a 0%, #1e293b 48%, #334155 100%);
  color: #f8fafc;
  box-shadow: 0 22px 44px rgba(15, 23, 42, 0.18);
}

.identity-main {
  display: flex;
  flex-direction: column;
  justify-content: center;
  min-width: 0;
}

.identity-badge {
  display: inline-flex;
  align-items: center;
  width: fit-content;
  margin-bottom: 14px;
  padding: 8px 12px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.18);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.06em;
}

.identity-hero h2 {
  margin: 0 0 10px;
  font-size: clamp(1.75rem, 3vw, 1.95rem);
  line-height: 1.2;
  word-break: break-word;
}

.identity-hero p {
  margin: 0;
  max-width: 640px;
  color: rgba(248, 250, 252, 0.88);
  font-size: 14px;
  line-height: 1.8;
  word-break: break-word;
}

.identity-side {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  align-content: start;
}

.identity-metric,
.identity-progress {
  padding: 16px;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(8px);
}

.identity-progress {
  grid-column: 1 / -1;
}

.identity-metric label,
.identity-progress-top span {
  display: block;
  margin-bottom: 8px;
  color: rgba(226, 232, 240, 0.82);
  font-size: 12px;
  font-weight: 600;
}

.identity-metric strong,
.identity-progress-top strong {
  color: #ffffff;
  font-size: 22px;
  line-height: 1.3;
}

.identity-progress-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.identity-progress-bar {
  height: 10px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.12);
  overflow: hidden;
}

.identity-progress-fill {
  height: 100%;
  border-radius: 999px;
  background: linear-gradient(90deg, var(--identity-accent) 0%, #ffffff 100%);
}

.metric-card {
  background: white;
  border-radius: 16px;
  padding: 24px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-height: 160px;
}

.score-card {
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #e2e8f0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
  gap: 12px;
}

.card-header .label {
  color: #64748b;
  font-size: 14px;
  font-weight: 500;
}

.icon-box {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
}

.icon-box.blue { background: #eff6ff; color: #3b82f6; }
.icon-box.purple { background: #f3e8ff; color: #a855f7; }

.score-display {
  display: flex;
  align-items: baseline;
  gap: 4px;
  flex-wrap: wrap;
}

.score-display .number {
  font-size: 42px;
  font-weight: 700;
  color: #0f172a;
  line-height: 1;
}

.score-display .total {
  color: #94a3b8;
  font-size: 14px;
}

.score-footer {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 12px;
}

.rank-info {
  display: flex;
  flex-direction: column;
}

.rank-info .value {
  font-weight: 600;
  color: #0f172a;
}

.rank-info .total-users {
  font-size: 12px;
  color: #94a3b8;
}

.metric-value {
  font-size: 28px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 8px;
}

.metric-value .unit {
  font-size: 14px;
  color: #64748b;
  font-weight: 500;
}

.metric-sub {
  font-size: 12px;
  color: #94a3b8;
}

/* Analysis Grid */
.analysis-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-bottom: 24px;
}

.content-card {
  background: white;
  border-radius: 16px;
  padding: 24px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.section-header {
  margin-bottom: 20px;
}

.section-header h3 {
  font-size: 16px;
  font-weight: 600;
  color: #0f172a;
  margin: 0;
}

.section-header p {
  font-size: 12px;
  color: #64748b;
  margin: 4px 0 0;
}

.chart-container {
  height: 240px;
  position: relative;
}

.dimension-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.dimension-row {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.row-info {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
  gap: 12px;
}

.dim-name {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #475569;
  min-width: 0;
}

.dim-score {
  font-weight: 600;
  color: #0f172a;
  flex-shrink: 0;
}

.progress-bg {
  height: 8px;
  background: #f1f5f9;
  border-radius: 4px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  border-radius: 4px;
  transition: width 0.5s ease;
}

/* AI Report Section */
.ai-report-section {
  margin-top: 24px;
}

.report-paper {
  background: white;
  border-radius: 20px;
  padding: 40px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.05);
  border: 1px solid #f1f5f9;
}

.paper-header {
  text-align: center;
  margin-bottom: 32px;
}

.ai-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: linear-gradient(90deg, #6366f1, #8b5cf6);
  color: white;
  padding: 4px 12px;
  border-radius: 99px;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 12px;
}

.paper-header h2 {
  font-size: clamp(1.4rem, 2.8vw, 1.75rem);
  color: #0f172a;
  margin: 0;
  line-height: 1.3;
}

.paper-intro {
  text-align: center;
  color: #475569;
  font-size: 15px;
  line-height: 1.6;
  max-width: 800px;
  margin: 0 auto;
  word-break: break-word;
}

.growth-story-strip {
  display: grid;
  grid-template-columns: 1.2fr 1fr 1fr;
  gap: 16px;
  margin-bottom: 28px;
}

.story-card {
  padding: 18px 20px;
  border-radius: 16px;
  background: linear-gradient(180deg, #f8fafc 0%, #ffffff 100%);
  border: 1px solid #e2e8f0;
}

.story-card.primary {
  background:
    radial-gradient(circle at top left, rgba(16, 185, 129, 0.12), transparent 40%),
    linear-gradient(180deg, #f0fdf4 0%, #ffffff 100%);
  border-color: #bbf7d0;
}

.story-card label {
  display: block;
  margin-bottom: 10px;
  color: #64748b;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.story-card strong {
  display: block;
  margin-bottom: 8px;
  color: #0f172a;
  font-size: 20px;
  line-height: 1.3;
}

.story-card p {
  margin: 0;
  color: #475569;
  font-size: 13px;
  line-height: 1.7;
}

.growth-goals {
  margin-bottom: 28px;
  padding: 22px;
  border-radius: 20px;
  background: linear-gradient(180deg, #fffdf7 0%, #ffffff 100%);
  border: 1px solid #fde68a;
}

.goals-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 16px;
}

.goals-eyebrow {
  margin: 0 0 8px;
  color: #b45309;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.goals-header h3 {
  margin: 0;
  color: #0f172a;
  font-size: 20px;
  line-height: 1.35;
}

.goals-hint {
  color: #92400e;
  font-size: 12px;
  font-weight: 600;
}

.goal-list {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.goal-card {
  padding: 18px;
  border-radius: 16px;
  background: #ffffff;
  border: 1px solid rgba(226, 232, 240, 0.9);
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.05);
}

.goal-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 14px;
}

.goal-top label {
  display: block;
  margin-bottom: 8px;
  color: #64748b;
  font-size: 12px;
  font-weight: 700;
}

.goal-top strong {
  color: #0f172a;
  font-size: 18px;
  line-height: 1.4;
  word-break: break-word;
}

.goal-gap {
  flex-shrink: 0;
  padding: 6px 10px;
  border-radius: 999px;
  background: var(--goal-accent-soft);
  color: #334155;
  font-size: 11px;
  font-weight: 700;
}

.goal-progress {
  height: 10px;
  margin-bottom: 14px;
  border-radius: 999px;
  background: #f1f5f9;
  overflow: hidden;
}

.goal-progress-bar {
  height: 100%;
  border-radius: 999px;
  background: linear-gradient(90deg, var(--goal-accent) 0%, rgba(255, 255, 255, 0.92) 100%);
}

.goal-action {
  margin: 0;
  color: #475569;
  font-size: 13px;
  line-height: 1.7;
  word-break: break-word;
}

.divider {
  height: 1px;
  background: #f1f5f9;
  margin: 32px 0;
}

.paper-chapter h3 {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.paper-chapter {
  margin-bottom: 40px;
}

/* Profile Grid */
.profile-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 16px;
}

.profile-item {
  background: #f8fafc;
  padding: 16px;
  border-radius: 12px;
  text-align: center;
}

.profile-item label {
  font-size: 12px;
  color: #64748b;
  display: block;
  margin-bottom: 8px;
}

.profile-item .val {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 4px;
}

.profile-item .eval {
  font-size: 12px;
  color: #3b82f6;
  font-weight: 500;
}

.profile-summary-box {
  background: #fffbeb;
  border: 1px solid #fef3c7;
  color: #b45309;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
}

/* Analysis Cards */
.analysis-cards {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.analysis-block {
  background: #f8fafc;
  padding: 20px;
  border-radius: 12px;
  border: 1px solid #f1f5f9;
}

.analysis-block h4 {
  margin: 0 0 8px 0;
  color: #334155;
  font-size: 15px;
}

.analysis-block h4 .sub {
  font-weight: 400;
  color: #64748b;
  font-size: 13px;
}

.analysis-block p {
  color: #475569;
  font-size: 14px;
  line-height: 1.6;
  margin-bottom: 12px;
  word-break: break-word;
}

.analysis-block .tip {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #6366f1;
  background: #eef2ff;
  padding: 8px 12px;
  border-radius: 6px;
}

/* Action Plan */
.plan-flex {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.plan-col {
  padding: 20px;
  border-radius: 16px;
}

.plan-col.consolidate {
  background: #f0fdf4;
  border: 1px solid #dcfce7;
}

.plan-col.improve {
  background: #fff1f2;
  border: 1px solid #ffe4e6;
}

.plan-col h4 {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 16px 0;
  font-size: 15px;
}

.consolidate h4 { color: #166534; }
.improve h4 { color: #be123c; }

.plan-col ul {
  padding-left: 20px;
  margin: 0;
  color: #374151;
  font-size: 14px;
  line-height: 1.8;
}

.paper-footer {
  text-align: center;
  color: #94a3b8;
  font-size: 14px;
  margin-top: 40px;
  font-style: italic;
}

@media (max-width: 768px) {
  .metrics-grid, .analysis-grid, .plan-flex, .profile-grid, .analysis-cards, .growth-story-strip {
    grid-template-columns: 1fr;
  }

  .identity-hero,
  .identity-side {
    grid-template-columns: 1fr;
  }

  .goal-list {
    grid-template-columns: 1fr;
  }
  
  .report-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
    padding: 0;
  }
  
  .header-right {
    width: 100%;
    justify-content: stretch;
    align-items: stretch;
    gap: 10px;
  }

  .header-right > * {
    width: 100%;
    min-width: 0;
  }

  .modern-select,
  .action-btn {
    width: 100%;
  }

  .action-btn {
    justify-content: center;
  }

  .goals-header {
    flex-direction: column;
  }

  .custom-range-picker {
    width: 100%;
  }

  .learning-report-page {
    padding: 16px 12px 24px;
  }

  .state-container,
  .report-paper {
    padding: 20px 16px;
  }

  .identity-hero {
    padding: 18px 16px;
    border-radius: 20px;
  }

  .identity-progress-top,
  .goal-top,
  .row-info,
  .score-footer {
    flex-direction: column;
    align-items: flex-start;
  }

  .metric-card,
  .content-card {
    padding: 18px 16px;
  }

  .growth-goals {
    padding: 18px 16px;
  }

  .goal-gap,
  .goals-hint {
    align-self: flex-start;
  }
}

@media (max-width: 480px) {
  .header-left {
    gap: 12px;
  }

  .back-button {
    width: 36px;
    height: 36px;
  }

  .header-titles h1 {
    font-size: 1.35rem;
  }

  .header-titles p,
  .identity-hero p,
  .paper-intro,
  .goal-action,
  .analysis-block p,
  .plan-col ul {
    font-size: 13px;
  }

  .identity-badge,
  .story-card label,
  .goals-eyebrow,
  .goal-top label,
  .metric-sub,
  .profile-item label {
    font-size: 11px;
  }

  .identity-metric strong,
  .identity-progress-top strong {
    font-size: 20px;
  }

  .score-display .number {
    font-size: 36px;
  }

  .metric-value,
  .story-card strong,
  .goal-top strong,
  .goals-header h3 {
    font-size: 18px;
  }
}
</style>
