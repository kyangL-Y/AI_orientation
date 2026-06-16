<template>
  <section v-if="comparison" class="monthly-showcase">
    <div class="showcase-header">
      <div>
        <p class="eyebrow">月度对比复盘示例</p>
        <h2>{{ comparison.summaryTitle }}</h2>
        <p class="header-desc">{{ comparison.subtitle }}</p>
      </div>
      <div class="generated-chip">生成于 {{ comparison.generatedAt }}</div>
    </div>

    <div class="summary-hero">
      <div class="summary-copy">
        <p class="summary-caption">{{ comparison.title }}</p>
        <h3>{{ comparison.summaryDetail }}</h3>
        <p>{{ comparison.coachConclusion }}</p>
      </div>

      <div class="summary-metrics">
        <article v-for="item in comparison.metrics" :key="item.key" class="summary-metric">
          <label>{{ item.label }}</label>
          <strong>{{ item.currentLabel }}</strong>
          <span>{{ item.previousLabel }} → {{ item.currentLabel }}</span>
          <em>{{ item.deltaLabel }}</em>
        </article>
      </div>
    </div>

    <div class="radar-grid">
      <article class="radar-card">
        <div class="radar-card-head">
          <div>
            <p class="radar-tag previous">{{ comparison.previousLabel }}</p>
            <h3>上个月短板画像</h3>
          </div>
        </div>
        <div class="radar-shell">
          <svg viewBox="0 0 220 220" class="radar-svg">
            <polygon
              v-for="level in radarLevels"
              :key="`prev-grid-${level}`"
              :points="buildPolygonPoints(level)"
              class="radar-grid-line"
            />
            <line
              v-for="(indicator, index) in comparison.indicators"
              :key="`prev-axis-${indicator.key}`"
              x1="110"
              y1="110"
              :x2="getAxisPoint(index).x"
              :y2="getAxisPoint(index).y"
              class="radar-axis"
            />
            <polygon :points="buildValuePolygon(comparison.previousRadar)" class="radar-fill previous-fill" />
            <text
              v-for="(indicator, index) in comparison.indicators"
              :key="`prev-label-${indicator.key}`"
              :x="getLabelPoint(index).x"
              :y="getLabelPoint(index).y"
              class="radar-label"
            >
              {{ indicator.label }}
            </text>
          </svg>
        </div>
      </article>

      <article class="radar-card">
        <div class="radar-card-head">
          <div>
            <p class="radar-tag current">{{ comparison.currentLabel }}</p>
            <h3>这个月提升画像</h3>
          </div>
        </div>
        <div class="radar-shell">
          <svg viewBox="0 0 220 220" class="radar-svg">
            <polygon
              v-for="level in radarLevels"
              :key="`curr-grid-${level}`"
              :points="buildPolygonPoints(level)"
              class="radar-grid-line"
            />
            <line
              v-for="(indicator, index) in comparison.indicators"
              :key="`curr-axis-${indicator.key}`"
              x1="110"
              y1="110"
              :x2="getAxisPoint(index).x"
              :y2="getAxisPoint(index).y"
              class="radar-axis"
            />
            <polygon :points="buildValuePolygon(comparison.currentRadar)" class="radar-fill current-fill" />
            <text
              v-for="(indicator, index) in comparison.indicators"
              :key="`curr-label-${indicator.key}`"
              :x="getLabelPoint(index).x"
              :y="getLabelPoint(index).y"
              class="radar-label"
            >
              {{ indicator.label }}
            </text>
          </svg>
        </div>
      </article>
    </div>

    <div class="insight-grid">
      <article class="insight-card weak-card">
        <p class="eyebrow">上个月哪里不行</p>
        <ul class="insight-list">
          <li v-for="item in comparison.previousWeaknesses" :key="item.key">
            <strong>{{ item.label }} · {{ item.valueLabel }}</strong>
            <span>{{ item.detail }}</span>
          </li>
        </ul>
      </article>

      <article class="insight-card rise-card">
        <p class="eyebrow">这个月哪些提升明显</p>
        <ul class="insight-list">
          <li v-for="item in comparison.currentImprovements" :key="item.key">
            <strong>{{ item.label }} · {{ item.deltaLabel }}</strong>
            <span>{{ item.detail }}</span>
          </li>
        </ul>
      </article>
    </div>

    <article class="action-card">
      <div class="action-copy">
        <p class="eyebrow">经过什么之后变强</p>
        <h3>把“为什么这个月提升了”说透</h3>
      </div>
      <ul class="action-list">
        <li v-for="(item, index) in comparison.actionDrivers" :key="`${index}-${item}`">{{ item }}</li>
      </ul>
    </article>
  </section>
</template>

<script setup>
import { computed } from 'vue'
import { buildMonthlyComparisonShowcase } from '@/utils/reportComparison'

const props = defineProps({
  report: {
    type: Object,
    default: null,
  },
  historyReports: {
    type: Array,
    default: () => [],
  },
})

const comparison = computed(() => buildMonthlyComparisonShowcase(props.report, props.historyReports))
const radarLevels = [20, 40, 60, 80, 100]
const center = 110
const radius = 68

function getAngle(index) {
  const total = comparison.value?.indicators?.length || 5
  return (Math.PI * 2 * index) / total - Math.PI / 2
}

function getAxisPoint(index) {
  const angle = getAngle(index)
  return {
    x: center + Math.cos(angle) * radius,
    y: center + Math.sin(angle) * radius,
  }
}

function getLabelPoint(index) {
  const angle = getAngle(index)
  const labelRadius = radius + 24
  return {
    x: center + Math.cos(angle) * labelRadius,
    y: center + Math.sin(angle) * labelRadius,
  }
}

function buildPolygonPoints(level) {
  const ratio = level / 100
  return (comparison.value?.indicators || []).map((_, index) => {
    const angle = getAngle(index)
    const pointRadius = radius * ratio
    return `${(center + Math.cos(angle) * pointRadius).toFixed(2)},${(center + Math.sin(angle) * pointRadius).toFixed(2)}`
  }).join(' ')
}

function buildValuePolygon(values) {
  return (values || []).map((value, index) => {
    const angle = getAngle(index)
    const pointRadius = radius * (Math.max(0, Math.min(100, Number(value) || 0)) / 100)
    return `${(center + Math.cos(angle) * pointRadius).toFixed(2)},${(center + Math.sin(angle) * pointRadius).toFixed(2)}`
  }).join(' ')
}
</script>

<style scoped>
.monthly-showcase {
  margin-bottom: 24px;
  padding: 24px;
  border-radius: 28px;
  background:
    radial-gradient(circle at top left, rgba(59, 130, 246, 0.12), transparent 28%),
    linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #dbeafe;
  box-shadow: 0 22px 44px rgba(15, 23, 42, 0.06);
}

.showcase-header,
.summary-hero,
.radar-grid,
.insight-grid,
.action-card,
.summary-metrics {
  display: grid;
  gap: 16px;
}

.showcase-header {
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: start;
  margin-bottom: 18px;
}

.eyebrow {
  margin: 0 0 8px;
  color: #1d4ed8;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.showcase-header h2,
.summary-copy h3,
.radar-card h3,
.action-copy h3 {
  margin: 0;
  color: #0f172a;
}

.header-desc,
.summary-copy p,
.generated-chip,
.insight-list span,
.summary-metric span,
.action-list li {
  color: #475569;
}

.header-desc {
  margin: 8px 0 0;
  font-size: 14px;
  line-height: 1.7;
}

.generated-chip {
  padding: 10px 14px;
  border-radius: 999px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  font-size: 12px;
  font-weight: 700;
}

.summary-hero {
  grid-template-columns: minmax(0, 1.1fr) minmax(340px, 0.9fr);
  margin-bottom: 18px;
}

.summary-copy {
  padding: 22px;
  border-radius: 22px;
  background: linear-gradient(135deg, #0f172a 0%, #1d4ed8 100%);
  color: #eff6ff;
}

.summary-caption {
  margin: 0 0 10px;
  color: rgba(219, 234, 254, 0.9);
  font-size: 13px;
  font-weight: 700;
}

.summary-copy h3 {
  color: #ffffff;
  font-size: 26px;
  line-height: 1.35;
  margin-bottom: 10px;
}

.summary-copy p {
  margin: 0;
  color: rgba(226, 232, 240, 0.9);
  line-height: 1.8;
}

.summary-metrics {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.summary-metric,
.radar-card,
.insight-card,
.action-card {
  padding: 18px;
  border-radius: 22px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
}

.summary-metric label,
.radar-tag {
  display: block;
  margin-bottom: 8px;
  font-size: 12px;
  font-weight: 700;
}

.summary-metric strong {
  display: block;
  margin-bottom: 6px;
  color: #0f172a;
  font-size: 24px;
  line-height: 1.2;
}

.summary-metric em {
  display: inline-flex;
  width: fit-content;
  margin-top: 10px;
  padding: 6px 10px;
  border-radius: 999px;
  background: #dcfce7;
  color: #166534;
  font-size: 11px;
  font-style: normal;
  font-weight: 700;
}

.radar-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
  margin-bottom: 18px;
}

.radar-card-head {
  margin-bottom: 12px;
}

.radar-tag.previous {
  color: #b91c1c;
}

.radar-tag.current {
  color: #0f766e;
}

.radar-shell {
  min-height: 240px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.radar-svg {
  width: 100%;
  max-width: 260px;
  height: auto;
}

.radar-grid-line {
  fill: none;
  stroke: rgba(148, 163, 184, 0.28);
  stroke-width: 1;
}

.radar-axis {
  stroke: rgba(148, 163, 184, 0.35);
  stroke-width: 1;
}

.radar-fill {
  stroke-width: 2.5;
}

.previous-fill {
  fill: rgba(248, 113, 113, 0.18);
  stroke: #dc2626;
}

.current-fill {
  fill: rgba(16, 185, 129, 0.2);
  stroke: #059669;
}

.radar-label {
  fill: #334155;
  font-size: 11px;
  font-weight: 700;
  text-anchor: middle;
  dominant-baseline: middle;
}

.insight-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
  margin-bottom: 18px;
}

.weak-card {
  background: linear-gradient(180deg, #fff7ed 0%, #ffffff 100%);
  border-color: #fed7aa;
}

.rise-card {
  background: linear-gradient(180deg, #ecfdf5 0%, #ffffff 100%);
  border-color: #bbf7d0;
}

.insight-list,
.action-list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.insight-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.insight-list strong {
  display: block;
  margin-bottom: 5px;
  color: #0f172a;
  font-size: 15px;
}

.insight-list span {
  font-size: 13px;
  line-height: 1.7;
}

.action-card {
  grid-template-columns: minmax(0, 280px) minmax(0, 1fr);
  align-items: start;
  background:
    radial-gradient(circle at top left, rgba(250, 204, 21, 0.14), transparent 34%),
    linear-gradient(180deg, #fffdf7 0%, #ffffff 100%);
  border-color: #fde68a;
}

.action-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.action-list li {
  position: relative;
  padding-left: 18px;
  font-size: 14px;
  line-height: 1.8;
}

.action-list li::before {
  content: '';
  position: absolute;
  left: 0;
  top: 10px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #d97706;
}

@media (max-width: 1100px) {
  .summary-hero,
  .radar-grid,
  .insight-grid,
  .action-card,
  .showcase-header {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .summary-metrics {
    grid-template-columns: 1fr;
  }
}
</style>
