<template>
  <section class="growth-panel">
    <div class="panel-header">
      <div>
        <p class="eyebrow">成长趋势</p>
        <h2>把“这段时间变强了多少”直接看出来</h2>
        <p class="panel-description">
          用连续周期的变化轨迹，判断你是在稳定上升、阶段突破，还是进入了新的积累期。
        </p>
      </div>
      <div class="period-chip">
        最近 {{ trendSeries.length || 1 }} 期
      </div>
    </div>

    <div v-if="trendSeries.length" class="growth-layout">
      <div class="hero-card">
        <div class="hero-top">
          <div>
            <p class="hero-label">{{ activeMetricMeta.label }}</p>
            <div class="hero-value-row">
              <strong>{{ currentMetricValue }}</strong>
              <span class="delta-pill" :class="deltaClass">{{ metricDeltaLabel }}</span>
            </div>
          </div>
          <div class="tab-row">
            <button
              v-for="metric in metrics"
              :key="metric.key"
              type="button"
              class="metric-tab"
              :class="{ active: metric.key === activeMetric }"
              @click="activeMetric = metric.key"
            >
              {{ metric.shortLabel }}
            </button>
          </div>
        </div>

        <div v-if="progressSpotlight.ready" class="spotlight-card" :class="{ 'is-initial': !progressSpotlight.hasPrevious }">
          <div class="spotlight-copy">
            <p class="spotlight-kicker">{{ progressSpotlight.periodCompareLabel }}</p>
            <h3>{{ progressSpotlight.title }}</h3>
            <p>{{ progressSpotlight.summary }}</p>
          </div>

          <div class="spotlight-board">
            <div class="spotlight-period previous">
              <span class="spotlight-period-tag">{{ progressSpotlight.previousPeriodLabel }}</span>
              <strong>{{ progressSpotlight.previousScoreLabel }}</strong>
              <span>{{ progressSpotlight.previousStageLabel }}</span>
            </div>

            <div class="spotlight-middle">
              <span class="spotlight-delta" :class="`is-${progressSpotlight.scoreDirection}`">
                {{ progressSpotlight.scoreDeltaLabel }}
              </span>
              <span class="spotlight-stage">{{ progressSpotlight.stageLabel }}</span>
              <small>{{ progressSpotlight.stageDetail }}</small>
            </div>

            <div class="spotlight-period current">
              <span class="spotlight-period-tag">{{ progressSpotlight.currentPeriodLabel }}</span>
              <strong>{{ progressSpotlight.currentScoreLabel }}</strong>
              <span>{{ progressSpotlight.currentStageLabel }}</span>
            </div>
          </div>

          <div v-if="progressSpotlight.metricHighlights.length" class="spotlight-metrics">
            <article
              v-for="item in progressSpotlight.metricHighlights"
              :key="item.key"
              class="spotlight-metric-card"
              :style="{ '--accent': item.accent, '--soft-accent': item.softAccent }"
            >
              <p>{{ item.label }}</p>
              <strong>{{ item.deltaText }}</strong>
              <span>{{ item.journeyLabel }}</span>
            </article>
          </div>
        </div>

        <div class="badge-ribbon">
          <div
            v-for="badge in growthBadges"
            :key="badge.key"
            class="growth-badge"
            :class="`tone-${badge.tone}`"
          >
            <strong>{{ badge.title }}</strong>
            <span>{{ badge.detail }}</span>
          </div>
        </div>

        <div v-if="hasComparisonData" class="chart-shell">
          <svg class="trend-chart" viewBox="0 0 680 240" preserveAspectRatio="none">
            <defs>
              <linearGradient :id="gradientId" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" :stop-color="activeMetricMeta.accent" stop-opacity="0.32" />
                <stop offset="100%" :stop-color="activeMetricMeta.accent" stop-opacity="0.02" />
              </linearGradient>
            </defs>

            <line
              v-for="gridY in gridLines"
              :key="gridY"
              x1="24"
              :x2="656"
              :y1="gridY"
              :y2="gridY"
              class="grid-line"
            />

            <path class="trend-area" :d="areaPath" :fill="`url(#${gradientId})`" />
            <path class="trend-line" :d="linePath" :stroke="activeMetricMeta.accent" />

            <g v-for="point in chartPoints" :key="point.reportId || point.periodLabel">
              <circle
                :cx="point.x"
                :cy="point.y"
                r="5.5"
                :fill="point === latestPoint ? activeMetricMeta.accent : '#ffffff'"
                :stroke="activeMetricMeta.accent"
                stroke-width="2.5"
              />
            </g>
          </svg>

          <div class="axis-row">
            <span
              v-for="point in chartPoints"
              :key="point.reportId || `${point.periodLabel}-label`"
              class="axis-label"
            >
              {{ point.periodLabel }}
            </span>
          </div>
        </div>

        <div v-else class="baseline-shell">
          <div class="baseline-copy">
            <strong>当前只有一期记录，先把这次成绩作为成长基线。</strong>
            <p>等生成下一期后，这里会自动切换成趋势曲线和前后对比，不再出现大面积空白。</p>
          </div>
          <div class="baseline-grid">
            <article
              v-for="item in comparisonItems"
              :key="`baseline-${item.key}`"
              class="baseline-card"
              :style="{ '--accent': item.accent, '--soft-accent': item.softAccent }"
            >
              <p>{{ item.label }}</p>
              <strong>{{ item.currentLabel }}</strong>
              <span>首期基线</span>
            </article>
          </div>
        </div>

        <div class="compare-strip">
          <article
            v-for="item in comparisonItems"
            :key="item.key"
            class="compare-card"
            :style="{ '--accent': item.accent, '--soft-accent': item.softAccent }"
          >
            <p class="compare-label">{{ item.label }}</p>
            <div class="compare-main">
              <strong>{{ item.currentLabel }}</strong>
              <span class="compare-delta" :class="`is-${item.direction}`">{{ item.deltaLabel }}</span>
            </div>
            <p class="compare-prev">上期：{{ item.previousLabel }}</p>
          </article>
        </div>
      </div>

      <div class="growth-sidebar">
        <article class="insight-card status-card">
          <p class="eyebrow">成长结论</p>
          <h3>{{ growthStatus.title }}</h3>
          <p>{{ growthStatus.description }}</p>
        </article>

        <div class="summary-grid">
          <article class="insight-card compact-card">
            <p class="card-caption">连续上升</p>
            <strong>{{ riseStreakLabel }}</strong>
            <span>以综合得分走势计算</span>
          </article>

          <article class="insight-card compact-card">
            <p class="card-caption">成长亮点</p>
            <strong>{{ bestGrowthTitle }}</strong>
            <span>{{ bestGrowthSubtitle }}</span>
          </article>

          <article class="insight-card compact-card">
            <p class="card-caption">进步定位</p>
            <strong>{{ growthBreakthroughTitle }}</strong>
            <span>{{ growthBreakthroughDetail }}</span>
          </article>
        </div>

        <article class="insight-card milestones-card">
          <p class="eyebrow">成长节点</p>
          <ul class="milestone-list">
            <li v-for="item in milestones" :key="item.title" class="milestone-item">
              <span class="milestone-dot"></span>
              <div>
                <strong>{{ item.title }}</strong>
                <p>{{ item.detail }}</p>
              </div>
            </li>
          </ul>
        </article>
      </div>
    </div>

    <div v-else class="empty-card">
      <h3>成长趋势即将生成</h3>
      <p>至少生成一份学习报告后，这里会自动展示你的成长曲线和关键节点。</p>
    </div>
  </section>
</template>

<script setup>
import { computed, ref } from 'vue'
import {
  GROWTH_METRICS,
  buildAreaPath,
  buildComparisonItems,
  buildGrowthBadges,
  buildGrowthBreakthrough,
  buildGrowthMilestones,
  buildProgressSpotlight,
  buildGrowthStatus,
  buildLinePath,
  buildTrendSeries,
  createSparklinePoints,
  describeGrowthDelta,
  formatGrowthMetric,
  getBestGrowthMetric,
  getRiseStreak,
} from '@/utils/reportGrowth'

const props = defineProps({
  reports: {
    type: Array,
    default: () => [],
  },
  periodType: {
    type: String,
    default: 'monthly',
  },
})

const metrics = GROWTH_METRICS
const activeMetric = ref('totalScore')
const gradientId = `growth-gradient-${Math.random().toString(36).slice(2, 8)}`

const trendSeries = computed(() => buildTrendSeries(props.reports, activeMetric.value, props.periodType))
const chartPoints = computed(() => createSparklinePoints(trendSeries.value))
const linePath = computed(() => buildLinePath(chartPoints.value))
const areaPath = computed(() => buildAreaPath(chartPoints.value))
const latestPoint = computed(() => chartPoints.value[chartPoints.value.length - 1] || null)

const activeMetricMeta = computed(
  () => metrics.find((metric) => metric.key === activeMetric.value) || metrics[0]
)

const currentMetricValue = computed(() => {
  const current = trendSeries.value[trendSeries.value.length - 1]
  return formatGrowthMetric(activeMetric.value, current?.value || 0)
})

const metricDeltaLabel = computed(() => {
  const current = trendSeries.value[trendSeries.value.length - 1]
  const previous = trendSeries.value[trendSeries.value.length - 2]
  return describeGrowthDelta(activeMetric.value, current?.value || 0, previous?.value)
})

const deltaClass = computed(() => {
  if (metricDeltaLabel.value.includes('+')) return 'is-up'
  if (metricDeltaLabel.value.includes('-')) return 'is-down'
  return 'is-flat'
})

const growthStatus = computed(() => buildGrowthStatus(props.reports, props.periodType))
const growthBadges = computed(() => buildGrowthBadges(props.reports, props.periodType))
const progressSpotlight = computed(() => buildProgressSpotlight(props.reports, props.periodType))
const comparisonItems = computed(() => buildComparisonItems(props.reports, props.periodType))
const milestones = computed(() => buildGrowthMilestones(props.reports, props.periodType))
const totalScoreSeries = computed(() => buildTrendSeries(props.reports, 'totalScore', props.periodType))
const hasComparisonData = computed(() => trendSeries.value.length > 1)
const riseStreak = computed(() => getRiseStreak(totalScoreSeries.value))

const riseStreakLabel = computed(() => {
  if (riseStreak.value <= 0) return '等待突破'
  return `连续 ${riseStreak.value + 1} 期`
})

const bestGrowth = computed(() => getBestGrowthMetric(props.reports, props.periodType))

const bestGrowthTitle = computed(() => bestGrowth.value?.label || '继续积累中')
const bestGrowthSubtitle = computed(() => bestGrowth.value?.deltaLabel || '更多数据后会出现更清晰的亮点')
const growthBreakthrough = computed(() => buildGrowthBreakthrough(props.reports, props.periodType))
const growthBreakthroughTitle = computed(() => growthBreakthrough.value?.title || '等待趋势形成')
const growthBreakthroughDetail = computed(
  () => growthBreakthrough.value?.detail || '生成更多周期报告后，会出现更清晰的突破判断'
)

const gridLines = [32, 84, 136, 188]
</script>

<style scoped>
.growth-panel {
  margin-bottom: 24px;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 18px;
}

.eyebrow {
  margin: 0 0 8px;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #0f766e;
}

.panel-header h2 {
  margin: 0;
  font-size: 22px;
  line-height: 1.2;
  color: #0f172a;
}

.panel-description {
  margin: 8px 0 0;
  max-width: 720px;
  color: #64748b;
  font-size: 14px;
  line-height: 1.7;
}

.period-chip {
  flex-shrink: 0;
  padding: 10px 14px;
  border-radius: 999px;
  background: #ecfeff;
  border: 1px solid #a5f3fc;
  color: #155e75;
  font-size: 12px;
  font-weight: 700;
}

.growth-layout {
  display: grid;
  grid-template-columns: minmax(0, 1.32fr) minmax(360px, 1fr);
  gap: 20px;
}

.hero-card,
.insight-card,
.empty-card {
  border-radius: 24px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  box-shadow: 0 18px 40px rgba(15, 23, 42, 0.06);
}

.hero-card {
  padding: 24px;
  background:
    radial-gradient(circle at top left, rgba(34, 211, 238, 0.12), transparent 34%),
    linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}

.hero-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 16px;
}

.hero-label {
  margin: 0 0 10px;
  color: #475569;
  font-size: 14px;
  font-weight: 600;
}

.hero-value-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.hero-value-row strong {
  font-size: clamp(34px, 3vw, 42px);
  line-height: 1;
  color: #0f172a;
}

.delta-pill {
  padding: 8px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
}

.delta-pill.is-up {
  background: #dcfce7;
  color: #166534;
}

.delta-pill.is-down {
  background: #fee2e2;
  color: #b91c1c;
}

.delta-pill.is-flat {
  background: #e2e8f0;
  color: #475569;
}

.tab-row {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 8px;
}

.metric-tab {
  border: 0;
  padding: 9px 14px;
  border-radius: 999px;
  background: #f1f5f9;
  color: #475569;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.metric-tab:hover {
  background: #e2e8f0;
}

.metric-tab.active {
  background: #0f172a;
  color: #ffffff;
  box-shadow: 0 12px 22px rgba(15, 23, 42, 0.16);
}

.spotlight-card {
  margin-bottom: 16px;
  padding: 18px;
  border-radius: 22px;
  background:
    radial-gradient(circle at top left, rgba(15, 118, 110, 0.14), transparent 34%),
    linear-gradient(135deg, #0f172a 0%, #134e4a 100%);
  color: #f8fafc;
}

.spotlight-card.is-initial {
  background:
    radial-gradient(circle at top left, rgba(59, 130, 246, 0.18), transparent 34%),
    linear-gradient(135deg, #0f172a 0%, #1d4ed8 100%);
}

.spotlight-copy {
  margin-bottom: 16px;
}

.spotlight-kicker {
  margin: 0 0 8px;
  color: rgba(240, 253, 250, 0.8);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.spotlight-copy h3 {
  margin: 0 0 8px;
  font-size: clamp(24px, 2.4vw, 30px);
  line-height: 1.2;
  color: #ffffff;
}

.spotlight-copy p {
  margin: 0;
  color: rgba(240, 253, 250, 0.92);
  font-size: 14px;
  line-height: 1.7;
}

.spotlight-board {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr);
  gap: 14px;
  align-items: center;
  margin-bottom: 14px;
}

.spotlight-period,
.spotlight-middle,
.spotlight-metric-card {
  min-width: 0;
  border-radius: 18px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(10px);
}

.spotlight-period {
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.spotlight-period-tag {
  color: rgba(226, 232, 240, 0.82);
  font-size: 12px;
  font-weight: 700;
}

.spotlight-period strong {
  font-size: clamp(28px, 2.6vw, 34px);
  line-height: 1;
  color: #ffffff;
}

.spotlight-period span:last-child {
  color: rgba(226, 232, 240, 0.88);
  font-size: 13px;
  line-height: 1.5;
}

.spotlight-middle {
  padding: 14px 18px;
  text-align: center;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.spotlight-delta {
  display: inline-flex;
  justify-content: center;
  align-self: center;
  padding: 8px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 700;
}

.spotlight-delta.is-up {
  background: #dcfce7;
  color: #166534;
}

.spotlight-delta.is-down {
  background: #fee2e2;
  color: #b91c1c;
}

.spotlight-delta.is-flat,
.spotlight-delta.is-new {
  background: #e2e8f0;
  color: #334155;
}

.spotlight-stage {
  font-size: 18px;
  font-weight: 700;
  color: #ffffff;
}

.spotlight-middle small {
  color: rgba(226, 232, 240, 0.84);
  font-size: 12px;
  line-height: 1.6;
}

.spotlight-metrics {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.spotlight-metric-card {
  padding: 14px;
  background: linear-gradient(180deg, var(--soft-accent) 0%, rgba(255, 255, 255, 0.08) 100%);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.08);
}

.spotlight-metric-card p,
.spotlight-metric-card span {
  margin: 0;
  color: rgba(226, 232, 240, 0.86);
}

.spotlight-metric-card p {
  font-size: 12px;
  font-weight: 700;
}

.spotlight-metric-card strong {
  display: block;
  margin: 8px 0 6px;
  color: #ffffff;
  font-size: 20px;
  line-height: 1.2;
}

.spotlight-metric-card span {
  display: block;
  font-size: 12px;
  line-height: 1.6;
}

.baseline-shell {
  margin-bottom: 12px;
  padding: 18px;
  border-radius: 20px;
  background: linear-gradient(180deg, #eff6ff 0%, #ffffff 100%);
  border: 1px solid #bfdbfe;
}

.baseline-copy {
  margin-bottom: 14px;
}

.baseline-copy strong {
  display: block;
  margin-bottom: 6px;
  color: #0f172a;
  font-size: 18px;
  line-height: 1.4;
}

.baseline-copy p,
.baseline-card span,
.baseline-card p {
  margin: 0;
  color: #475569;
}

.baseline-copy p {
  font-size: 13px;
  line-height: 1.7;
}

.baseline-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.baseline-card {
  padding: 14px;
  border-radius: 18px;
  background: linear-gradient(180deg, var(--soft-accent) 0%, #ffffff 100%);
  border: 1px solid rgba(148, 163, 184, 0.22);
}

.baseline-card p {
  font-size: 12px;
  font-weight: 700;
}

.baseline-card strong {
  display: block;
  margin: 8px 0 6px;
  color: #0f172a;
  font-size: 24px;
  line-height: 1.2;
}

.baseline-card span {
  font-size: 12px;
}

.chart-shell {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.badge-ribbon {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 14px;
}

.growth-badge {
  min-width: 0;
  padding: 11px 13px;
  border-radius: 18px;
  border: 1px solid transparent;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.growth-badge strong {
  font-size: 13px;
  color: #0f172a;
}

.growth-badge span {
  font-size: 12px;
  line-height: 1.5;
  color: #475569;
}

.growth-badge.tone-emerald {
  background: #ecfdf5;
  border-color: #bbf7d0;
}

.growth-badge.tone-amber,
.growth-badge.tone-gold {
  background: #fffbeb;
  border-color: #fde68a;
}

.growth-badge.tone-blue {
  background: #eff6ff;
  border-color: #bfdbfe;
}

.growth-badge.tone-rose {
  background: #fff1f2;
  border-color: #fecdd3;
}

.growth-badge.tone-slate {
  background: #f8fafc;
  border-color: #cbd5e1;
}

.trend-chart {
  width: 100%;
  height: 216px;
}

.grid-line {
  stroke: rgba(148, 163, 184, 0.28);
  stroke-width: 1;
  stroke-dasharray: 4 6;
}

.trend-area {
  transition: all 0.3s ease;
}

.trend-line {
  fill: none;
  stroke-width: 4;
  stroke-linecap: round;
  stroke-linejoin: round;
  transition: all 0.3s ease;
}

.axis-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(48px, 1fr));
  gap: 6px;
}

.axis-label {
  text-align: center;
  font-size: 11px;
  line-height: 1.35;
  word-break: keep-all;
  color: #64748b;
}

.compare-strip {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  margin-top: 8px;
}

.compare-card {
  padding: 16px;
  border-radius: 18px;
  background: linear-gradient(180deg, var(--soft-accent) 0%, #ffffff 100%);
  border: 1px solid rgba(148, 163, 184, 0.22);
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.65);
}

.compare-label {
  margin: 0 0 10px;
  color: #475569;
  font-size: 12px;
  font-weight: 700;
}

.compare-main {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.compare-main strong {
  color: #0f172a;
  font-size: 22px;
  line-height: 1.2;
}

.compare-delta {
  width: fit-content;
  padding: 6px 10px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
}

.compare-delta.is-up {
  background: #dcfce7;
  color: #166534;
}

.compare-delta.is-down {
  background: #fee2e2;
  color: #b91c1c;
}

.compare-delta.is-flat,
.compare-delta.is-new {
  background: #e2e8f0;
  color: #475569;
}

.compare-prev {
  margin: 10px 0 0;
  color: #64748b;
  font-size: 12px;
}

.growth-sidebar {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.insight-card {
  padding: 18px;
}

.status-card {
  background:
    radial-gradient(circle at top right, rgba(250, 204, 21, 0.15), transparent 32%),
    linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  color: #e2e8f0;
  border-color: transparent;
}

.status-card .eyebrow,
.status-card h3,
.status-card p {
  color: inherit;
}

.status-card h3 {
  margin: 0 0 10px;
  font-size: 24px;
  line-height: 1.25;
}

.status-card p {
  margin: 0;
  line-height: 1.7;
  font-size: 14px;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.compact-card {
  min-height: 0;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  gap: 10px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}

.summary-grid .compact-card:last-child {
  grid-column: 1 / -1;
}

.card-caption {
  margin: 0;
  color: #64748b;
  font-size: 12px;
  font-weight: 700;
}

.compact-card strong {
  display: block;
  margin: 0;
  font-size: clamp(20px, 2vw, 24px);
  line-height: 1.1;
  white-space: nowrap;
  color: #0f172a;
}

.compact-card span {
  display: block;
  color: #64748b;
  font-size: 12px;
  line-height: 1.5;
}

.milestones-card {
  background:
    linear-gradient(180deg, rgba(240, 253, 250, 0.92) 0%, rgba(255, 255, 255, 1) 100%);
}

.milestone-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.milestone-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.milestone-dot {
  flex-shrink: 0;
  width: 12px;
  height: 12px;
  margin-top: 6px;
  border-radius: 50%;
  background: linear-gradient(135deg, #0f766e 0%, #22c55e 100%);
  box-shadow: 0 0 0 5px rgba(16, 185, 129, 0.12);
}

.milestone-item strong {
  display: block;
  margin-bottom: 5px;
  color: #0f172a;
  font-size: 14px;
}

.milestone-item p {
  margin: 0;
  color: #475569;
  font-size: 13px;
  line-height: 1.7;
}

.empty-card {
  padding: 28px;
  text-align: center;
}

.empty-card h3 {
  margin: 0 0 10px;
  color: #0f172a;
}

.empty-card p {
  margin: 0;
  color: #64748b;
}

@media (max-width: 1200px) {
  .growth-layout {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .panel-header,
  .hero-top {
    flex-direction: column;
  }

  .spotlight-board,
  .spotlight-metrics,
  .baseline-grid {
    grid-template-columns: 1fr;
  }

  .tab-row {
    justify-content: flex-start;
  }

  .summary-grid {
    grid-template-columns: 1fr;
  }

  .compare-strip {
    grid-template-columns: 1fr;
  }

  .hero-card,
  .insight-card {
    border-radius: 20px;
  }
}
</style>
