export const GROWTH_METRICS = [
  {
    key: 'totalScore',
    label: '综合得分',
    shortLabel: '得分',
    unit: '分',
    precision: 0,
    accent: '#0f766e',
    softAccent: 'rgba(15, 118, 110, 0.14)',
    normalizeBase: 100,
  },
  {
    key: 'learningDuration',
    label: '课程学习时长',
    shortLabel: '课程时长',
    unit: '分钟',
    precision: 0,
    accent: '#2563eb',
    softAccent: 'rgba(37, 99, 235, 0.14)',
    normalizeBase: 240,
  },
  {
    key: 'accuracyRate',
    label: '正确率',
    shortLabel: '正确率',
    unit: '%',
    precision: 0,
    accent: '#ca8a04',
    softAccent: 'rgba(202, 138, 4, 0.14)',
    normalizeBase: 100,
  },
  {
    key: 'quizCount',
    label: '刷题数量',
    shortLabel: '刷题',
    unit: '题',
    precision: 0,
    accent: '#dc2626',
    softAccent: 'rgba(220, 38, 38, 0.14)',
    normalizeBase: 120,
  },
  {
    key: 'abilityAverage',
    label: '业务能力均值',
    shortLabel: '能力',
    unit: '分',
    precision: 0,
    accent: '#7c3aed',
    softAccent: 'rgba(124, 58, 237, 0.14)',
    normalizeBase: 100,
  },
]

const METRIC_MAP = Object.fromEntries(GROWTH_METRICS.map((metric) => [metric.key, metric]))

function parseJsonSafely(source) {
  if (!source) return {}
  if (typeof source === 'object') return source
  if (typeof source !== 'string') return {}
  try {
    return JSON.parse(source)
  } catch {
    return {}
  }
}

function toFiniteNumber(value) {
  const number = Number(value)
  return Number.isFinite(number) ? number : 0
}

function getMetricMeta(metricKey) {
  return METRIC_MAP[metricKey] || METRIC_MAP.totalScore
}

function getMetricNormalizeBase(metricKey) {
  return getMetricMeta(metricKey)?.normalizeBase || 100
}

function getPeriodCompareMeta(periodType) {
  if (periodType === 'daily') {
    return { current: '今日', previous: '昨日', unit: '天' }
  }

  if (periodType === 'weekly') {
    return { current: '本周', previous: '上周', unit: '周' }
  }

  if (periodType === 'monthly') {
    return { current: '本月', previous: '上月', unit: '月' }
  }

  if (periodType === 'quarterly') {
    return { current: '本季度', previous: '上季度', unit: '季度' }
  }

  if (periodType === 'custom') {
    return { current: '当前区间', previous: '前一区间', unit: '区间' }
  }

  return { current: '本期', previous: '上期', unit: '期' }
}

function getScoreStageLabel(score) {
  const safeScore = toFiniteNumber(score)

  if (safeScore >= 90) return '高位兑现'
  if (safeScore >= 80) return '明显强势'
  if (safeScore >= 70) return '稳步抬升'
  if (safeScore >= 60) return '起势回升'
  return '基础修复'
}

function buildMetricJourney(item) {
  const deltaValue = toFiniteNumber(item.delta)

  return {
    ...item,
    journeyLabel:
      item.previousLabel && item.previousLabel !== '暂无'
        ? `${item.previousLabel} → ${item.currentLabel}`
        : item.currentLabel,
    deltaText:
      item.direction === 'up'
        ? `提升 ${formatGrowthMetric(item.key, deltaValue)}`
        : item.direction === 'down'
          ? `回落 ${formatGrowthMetric(item.key, Math.abs(deltaValue))}`
          : item.direction === 'new'
            ? '已建立当前基线'
            : '与上期持平',
  }
}

function getTopGrowthJourneys(items, count = 3) {
  return (Array.isArray(items) ? items : [])
    .slice()
    .sort((left, right) => {
      const weightGap =
        toFiniteNumber(right.delta) / getMetricNormalizeBase(right.key) -
        toFiniteNumber(left.delta) / getMetricNormalizeBase(left.key)
      if (Math.abs(weightGap) > 0.0001) {
        return weightGap
      }
      return toFiniteNumber(right.delta) - toFiniteNumber(left.delta)
    })
    .slice(0, count)
    .map(buildMetricJourney)
}

export function getReportMetricValue(report, metricKey) {
  const safeReport = report || {}
  const auxiliaryData = parseJsonSafely(safeReport.auxiliaryData)
  const rawData = parseJsonSafely(safeReport.rawData)
  const dimensionScores = parseJsonSafely(safeReport.dimensionScores)
  const abilityScores = parseJsonSafely(safeReport.abilityScores)

  if (metricKey === 'learningDuration') {
    return toFiniteNumber(auxiliaryData.learningDuration || auxiliaryData.learning_duration)
  }

  if (metricKey === 'quizCount') {
    return toFiniteNumber(auxiliaryData.quizCount || auxiliaryData.quiz_count)
  }

  if (metricKey === 'accuracyRate') {
    const totalAttempts = toFiniteNumber(rawData.totalAttempts)
    const correctCount = Math.min(toFiniteNumber(rawData.correctCount), totalAttempts)
    if (totalAttempts > 0) {
      return Number(((correctCount / totalAttempts) * 100).toFixed(1))
    }
    return toFiniteNumber(dimensionScores.accuracy_rate)
  }

  if (metricKey === 'abilityAverage') {
    const values = Object.values(abilityScores)
      .map((value) => toFiniteNumber(value))
      .filter((value) => value > 0)
    if (!values.length) return 0
    const total = values.reduce((sum, value) => sum + value, 0)
    return Number((total / values.length).toFixed(1))
  }

  return toFiniteNumber(safeReport.totalScore)
}

function formatDateValue(dateLike) {
  const date = dateLike ? new Date(dateLike) : null
  if (!date || Number.isNaN(date.getTime())) return ''
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function buildPeriodLabel(report, periodType) {
  const safePeriodType = periodType || report?.periodType
  const periodStart = report?.periodStart ? new Date(report.periodStart) : null
  const periodEnd = report?.periodEnd ? new Date(report.periodEnd) : null
  const validStart = periodStart && !Number.isNaN(periodStart.getTime())
  const validEnd = periodEnd && !Number.isNaN(periodEnd.getTime())
  const dateSource = validEnd ? periodEnd : validStart ? periodStart : report?.createTime ? new Date(report.createTime) : null

  if (!dateSource || Number.isNaN(dateSource.getTime())) {
    return formatDateValue(report?.createTime) || `记录${report?.reportId || ''}`
  }

  if (safePeriodType === 'daily') {
    return formatDateValue(validStart ? periodStart : dateSource)
  }

  if (safePeriodType === 'weekly') {
    if (validStart && validEnd) {
      return `${String(periodStart.getMonth() + 1).padStart(2, '0')}/${String(periodStart.getDate()).padStart(2, '0')} - ${String(periodEnd.getMonth() + 1).padStart(2, '0')}/${String(periodEnd.getDate()).padStart(2, '0')}`
    }
    return formatDateValue(dateSource)
  }

  if (safePeriodType === 'monthly') {
    return `${dateSource.getFullYear()}年${dateSource.getMonth() + 1}月`
  }

  if (safePeriodType === 'quarterly') {
    const quarter = Math.floor(dateSource.getMonth() / 3) + 1
    return `${dateSource.getFullYear()}年Q${quarter}`
  }

  if (safePeriodType === 'custom' && validStart && validEnd) {
    return `${formatDateValue(periodStart)} ~ ${formatDateValue(periodEnd)}`
  }

  return formatDateValue(dateSource)
}

export function normalizeGrowthReports(reports, periodType) {
  const list = Array.isArray(reports) ? reports : []
  const seen = new Set()

  return list
    .filter((report) => {
      const key = report?.reportId || `${report?.periodEnd || ''}-${report?.createTime || ''}`
      if (seen.has(key)) return false
      seen.add(key)
      return true
    })
    .map((report) => {
      const sortTime = new Date(report?.periodEnd || report?.createTime || 0).getTime()
      const metrics = Object.fromEntries(
        GROWTH_METRICS.map((metric) => [metric.key, getReportMetricValue(report, metric.key)])
      )

      return {
        reportId: report?.reportId,
        periodLabel: buildPeriodLabel(report, periodType || report?.periodType),
        sortTime: Number.isFinite(sortTime) ? sortTime : 0,
        metrics,
      }
    })
    .sort((left, right) => {
      if (left.sortTime !== right.sortTime) {
        return left.sortTime - right.sortTime
      }
      return toFiniteNumber(left.reportId) - toFiniteNumber(right.reportId)
    })
}

export function buildTrendSeries(reports, metricKey, periodType, limit = 8) {
  const normalized = normalizeGrowthReports(reports, periodType).slice(-limit)
  return normalized.map((item) => ({
    ...item,
    value: toFiniteNumber(item.metrics[metricKey]),
  }))
}

export function formatGrowthMetric(metricKey, value) {
  const meta = getMetricMeta(metricKey)
  const safeValue = toFiniteNumber(value)

  if (metricKey === 'learningDuration') {
    if (safeValue <= 0) return '0分钟'
    if (safeValue < 60) return `${Math.round(safeValue)}分钟`
    const hours = safeValue / 60
    return `${hours % 1 === 0 ? hours.toFixed(0) : hours.toFixed(1)}小时`
  }

  const fixedValue = meta.precision > 0 ? safeValue.toFixed(meta.precision) : Math.round(safeValue).toString()
  return `${fixedValue}${meta.unit}`
}

export function describeGrowthDelta(metricKey, currentValue, previousValue) {
  if (!Number.isFinite(previousValue)) {
    return '首期记录'
  }

  const diff = toFiniteNumber(currentValue) - toFiniteNumber(previousValue)
  if (Math.abs(diff) < 0.01) {
    return '与上期持平'
  }

  const prefix = diff > 0 ? '+' : ''
  const formattedDiff = formatGrowthMetric(metricKey, Math.abs(diff))
  return `较上期 ${prefix}${diff > 0 ? formattedDiff : `-${formattedDiff}`}`
}

export function getRiseStreak(series) {
  if (!Array.isArray(series) || series.length < 2) return 0
  let streak = 0
  for (let index = series.length - 1; index > 0; index -= 1) {
    if (series[index].value > series[index - 1].value) {
      streak += 1
      continue
    }
    break
  }
  return streak
}

export function getBestGrowthMetric(reports, periodType) {
  const normalized = normalizeGrowthReports(reports, periodType)
  if (normalized.length < 2) return null

  const current = normalized[normalized.length - 1]
  const previous = normalized[normalized.length - 2]

  const candidates = GROWTH_METRICS.map((metric) => {
    const currentValue = toFiniteNumber(current.metrics[metric.key])
    const previousValue = toFiniteNumber(previous.metrics[metric.key])
    const delta = currentValue - previousValue
    const normalizedDelta = delta / metric.normalizeBase

    return {
      key: metric.key,
      label: metric.label,
      delta,
      normalizedDelta,
      value: currentValue,
    }
  }).sort((left, right) => right.normalizedDelta - left.normalizedDelta)

  const best = candidates[0]
  if (!best || best.delta <= 0) return null

  return {
    ...best,
    deltaLabel: describeGrowthDelta(best.key, best.value, best.value - best.delta),
    valueLabel: formatGrowthMetric(best.key, best.value),
  }
}

export function buildComparisonItems(reports, periodType) {
  const normalized = normalizeGrowthReports(reports, periodType)
  if (!normalized.length) return []

  const current = normalized[normalized.length - 1]
  const previous = normalized[normalized.length - 2]

  return GROWTH_METRICS.slice(0, 4).map((metric) => {
    const currentValue = toFiniteNumber(current.metrics[metric.key])
    const previousValue = previous ? toFiniteNumber(previous.metrics[metric.key]) : Number.NaN
    const delta = Number.isFinite(previousValue) ? currentValue - previousValue : Number.NaN

    return {
      key: metric.key,
      label: metric.label,
      currentValue,
      previousValue,
      currentLabel: formatGrowthMetric(metric.key, currentValue),
      previousLabel: Number.isFinite(previousValue) ? formatGrowthMetric(metric.key, previousValue) : '暂无',
      delta,
      deltaLabel: describeGrowthDelta(metric.key, currentValue, previousValue),
      direction: !Number.isFinite(delta) ? 'new' : delta > 0 ? 'up' : delta < 0 ? 'down' : 'flat',
      accent: metric.accent,
      softAccent: metric.softAccent,
    }
  })
}

export function buildProgressSpotlight(reports, periodType) {
  const normalized = normalizeGrowthReports(reports, periodType)
  const compareMeta = getPeriodCompareMeta(periodType)

  if (!normalized.length) {
    return {
      ready: false,
      hasPrevious: false,
      title: '成长趋势待生成',
      summary: '继续生成更多周期报告后，这里会直接显示前后对照的成长幅度。',
      stageLabel: '等待数据',
      stageDetail: '尚未形成对比样本',
      previousPeriodLabel: compareMeta.previous,
      currentPeriodLabel: compareMeta.current,
      previousScoreLabel: '暂无',
      currentScoreLabel: '暂无',
      previousStageLabel: '等待对比',
      currentStageLabel: '等待对比',
      scoreDeltaLabel: '等待对比',
      scoreDirection: 'new',
      periodCompareLabel: `${compareMeta.current}成长概览`,
      metricHighlights: [],
    }
  }

  const current = normalized[normalized.length - 1]
  const previous = normalized[normalized.length - 2]
  const comparisonItems = buildComparisonItems(reports, periodType)
  const bestGrowth = getBestGrowthMetric(reports, periodType)
  const currentScore = toFiniteNumber(current.metrics.totalScore)
  const currentScoreLabel = formatGrowthMetric('totalScore', currentScore)

  if (!previous) {
    return {
      ready: true,
      hasPrevious: false,
      title: '成长记录已启动',
      summary: `${current.periodLabel} 已生成首份学习报告，继续生成下一${compareMeta.unit}后，这里会直接显示“上一期 vs 这一期”的进步幅度。`,
      stageLabel: '起步期',
      stageDetail: '先连续记录，再识别拐点',
      previousPeriodLabel: compareMeta.previous,
      currentPeriodLabel: current.periodLabel || compareMeta.current,
      previousScoreLabel: '暂无',
      currentScoreLabel,
      previousStageLabel: '等待对比',
      currentStageLabel: getScoreStageLabel(currentScore),
      scoreDeltaLabel: '等待下一期对比',
      scoreDirection: 'new',
      periodCompareLabel: `${compareMeta.current}成长概览`,
      metricHighlights: comparisonItems.slice(0, 3).map(buildMetricJourney),
    }
  }

  const previousScore = toFiniteNumber(previous.metrics.totalScore)
  const previousScoreLabel = formatGrowthMetric('totalScore', previousScore)
  const scoreDiff = currentScore - previousScore
  const scoreDirection = scoreDiff > 0 ? 'up' : scoreDiff < 0 ? 'down' : 'flat'
  const scoreSeries = buildTrendSeries(reports, 'totalScore', periodType)
  const streak = getRiseStreak(scoreSeries)
  const metricHighlights = getTopGrowthJourneys(
    comparisonItems.filter((item) => item.direction === 'up').length
      ? comparisonItems.filter((item) => item.direction === 'up')
      : comparisonItems,
    3
  )

  let title = '这期比上期更强了'
  let stageLabel = '持续抬升'
  let summary = `综合得分从 ${previousScoreLabel} 提到 ${currentScoreLabel}，${bestGrowth ? `${bestGrowth.label} 的提升最明显。` : '主要指标开始同步抬升。'}`

  if (scoreDiff >= 12 && previousScore < 70) {
    title = '从偏弱区间拉到了明显进步'
    stageLabel = '低位反弹'
    summary = `${previous.periodLabel} 的综合得分还在 ${previousScoreLabel}，到 ${current.periodLabel} 已经提升到 ${currentScoreLabel}，这不是小波动，而是能一眼看出来的反弹。`
  } else if (scoreDiff >= 8 && currentScore >= 85) {
    title = '这期不是小涨，是一次明显突破'
    stageLabel = '阶段突破'
    summary = `综合得分从 ${previousScoreLabel} 抬升到 ${currentScoreLabel}，而且 ${bestGrowth ? `${bestGrowth.label}${bestGrowth.deltaLabel.replace('较上期 ', '')}。` : '核心指标出现了同步跃升。'}`
  } else if (streak >= 2 && scoreDiff > 0) {
    title = '不是偶发波动，而是在连续变强'
    stageLabel = '稳定拉升'
    summary = `综合得分已连续 ${streak + 1} 期走高，本期相较 ${previous.periodLabel} 再提升 ${formatGrowthMetric('totalScore', scoreDiff)}，成长势头已经接上了。`
  } else if (Math.abs(scoreDiff) < 0.01) {
    title = '这期把表现稳住了'
    stageLabel = '状态维持'
    summary = `综合得分维持在 ${currentScoreLabel}，说明当前状态没有掉队，下一步重点是把单项优势继续拉开。`
  } else if (scoreDiff < 0) {
    title = '本期有回踩，但进步方向还清楚'
    stageLabel = '阶段波动'
    summary = `综合得分从 ${previousScoreLabel} 回落到 ${currentScoreLabel}，建议优先修复下滑指标，避免这次波动扩大。`
  }

  return {
    ready: true,
    hasPrevious: true,
    title,
    summary,
    stageLabel,
    stageDetail: `综合得分 ${previousScoreLabel} → ${currentScoreLabel}`,
    previousPeriodLabel: previous.periodLabel || compareMeta.previous,
    currentPeriodLabel: current.periodLabel || compareMeta.current,
    previousScoreLabel,
    currentScoreLabel,
    previousStageLabel: getScoreStageLabel(previousScore),
    currentStageLabel: getScoreStageLabel(currentScore),
    scoreDeltaLabel: describeGrowthDelta('totalScore', currentScore, previousScore),
    scoreDirection,
    periodCompareLabel: `${compareMeta.current} vs ${compareMeta.previous}`,
    metricHighlights,
  }
}

export function buildGrowthBreakthrough(reports, periodType) {
  const spotlight = buildProgressSpotlight(reports, periodType)

  if (!spotlight.ready) {
    return {
      title: '等待趋势形成',
      detail: '数据再多一些后，就能看清是否出现明显进步。',
    }
  }

  if (!spotlight.hasPrevious) {
    return {
      title: '成长基线已建立',
      detail: '再生成一个周期后，就能直接看到前后差距。',
    }
  }

  if (spotlight.scoreDirection === 'up') {
    return {
      title: spotlight.stageLabel,
      detail: `${spotlight.previousScoreLabel} → ${spotlight.currentScoreLabel}`,
    }
  }

  if (spotlight.scoreDirection === 'down') {
    return {
      title: '需要修复波动',
      detail: `${spotlight.previousScoreLabel} → ${spotlight.currentScoreLabel}`,
    }
  }

  return {
    title: '状态已稳住',
    detail: `综合得分保持在 ${spotlight.currentScoreLabel}`,
  }
}

export function buildGrowthStatus(reports, periodType) {
  const totalScoreSeries = buildTrendSeries(reports, 'totalScore', periodType)
  if (!totalScoreSeries.length) {
    return {
      title: '等待首份成长记录',
      description: '生成更多周期报告后，这里会自动识别你的成长走势。',
    }
  }

  if (totalScoreSeries.length === 1) {
    return {
      title: '成长档案已启动',
      description: '你已经留下第一份学习记录，继续生成后就能看到完整上升轨迹。',
    }
  }

  const current = totalScoreSeries[totalScoreSeries.length - 1].value
  const previous = totalScoreSeries[totalScoreSeries.length - 2].value
  const first = totalScoreSeries[0].value
  const streak = getRiseStreak(totalScoreSeries)

  if (streak >= 2 && current >= previous) {
    return {
      title: '正在进入稳定上升区间',
      description: `综合得分已连续 ${streak + 1} 期走高，最近的学习投入正在持续转化为结果。`,
    }
  }

  if (current > previous && current >= first) {
    return {
      title: '本期出现明显抬升',
      description: '你已经从“积累期”进入“兑现期”，近期动作对成绩拉动很直接。',
    }
  }

  if (current < previous && current >= first) {
    return {
      title: '近期有波动，但底盘仍在抬高',
      description: '当前结果比上期略有回落，不过整体仍高于起点，趋势没有被破坏。',
    }
  }

  return {
    title: '成长节奏仍在建立中',
    description: '当前数据波动较大，建议保持固定学习节奏，让成长曲线更稳定。',
  }
}

export function buildGrowthBadges(reports, periodType) {
  const normalized = normalizeGrowthReports(reports, periodType)
  if (!normalized.length) return []

  const current = normalized[normalized.length - 1]
  const previous = normalized[normalized.length - 2]
  const totalSeries = normalized.map((item) => toFiniteNumber(item.metrics.totalScore))
  const durationSeries = normalized.map((item) => toFiniteNumber(item.metrics.learningDuration))
  const accuracySeries = normalized.map((item) => toFiniteNumber(item.metrics.accuracyRate))
  const quizSeries = normalized.map((item) => toFiniteNumber(item.metrics.quizCount))
  const badges = []

  if (getRiseStreak(buildTrendSeries(reports, 'totalScore', periodType)) >= 2) {
    badges.push({
      key: 'streak',
      title: '连续进阶',
      detail: '综合得分进入连续上升通道',
      tone: 'emerald',
    })
  }

  if (previous && current.metrics.totalScore - previous.metrics.totalScore >= 8 && previous.metrics.totalScore < 70) {
    badges.push({
      key: 'rebound',
      title: '明显反弹',
      detail: '综合得分从偏弱区间重新抬头',
      tone: 'emerald',
    })
  }

  if (current.metrics.totalScore === Math.max(...totalSeries) && normalized.length > 1) {
    badges.push({
      key: 'peak',
      title: '阶段峰值',
      detail: '本期综合得分刷新最近记录',
      tone: 'amber',
    })
  }

  if (current.metrics.learningDuration === Math.max(...durationSeries) && current.metrics.learningDuration > 0) {
    badges.push({
      key: 'duration',
      title: '学习加速',
      detail: '投入时长来到当前最高点',
      tone: 'blue',
    })
  }

  if (current.metrics.accuracyRate === Math.max(...accuracySeries) && current.metrics.accuracyRate >= 80) {
    badges.push({
      key: 'accuracy',
      title: '高效吸收',
      detail: '正确率保持在高位并继续抬升',
      tone: 'gold',
    })
  }

  if (previous && current.metrics.quizCount > previous.metrics.quizCount && current.metrics.quizCount === Math.max(...quizSeries)) {
    badges.push({
      key: 'quiz',
      title: '训练加码',
      detail: '本期练习密度高于以往',
      tone: 'rose',
    })
  }

  if (!badges.length) {
    badges.push({
      key: 'growth',
      title: '成长积累中',
      detail: '继续保持记录，下一次突破会更清晰',
      tone: 'slate',
    })
  }

  return badges.slice(0, 3)
}

export function buildGrowthNarrative(reports, periodType) {
  const normalized = normalizeGrowthReports(reports, periodType)
  if (!normalized.length) {
    return {
      title: '成长轨迹待生成',
      summary: '继续生成周期报告后，这里会自动给出你的成长复盘。',
      momentumLabel: '成长动能待观察',
      momentumDetail: '当前数据不足，先保持连续记录。',
      focusLabel: '下一步重点',
      focusDetail: '先完成更多学习记录，系统才能识别真正的突破点。',
    }
  }

  const spotlight = buildProgressSpotlight(reports, periodType)
  const bestGrowth = getBestGrowthMetric(reports, periodType)
  const comparisonItems = buildComparisonItems(reports, periodType)
  const momentumLabel = spotlight.hasPrevious ? spotlight.stageLabel : '成长动能建立中'
  const momentumDetail = spotlight.summary

  const downwardItem = comparisonItems.find((item) => item.direction === 'down')
  const focusCandidate =
    downwardItem ||
    comparisonItems
      .slice()
      .sort((left, right) => {
        const leftWeight = left.currentValue / (left.key === 'learningDuration' ? 240 : left.key === 'quizCount' ? 120 : 100)
        const rightWeight = right.currentValue / (right.key === 'learningDuration' ? 240 : right.key === 'quizCount' ? 120 : 100)
        return leftWeight - rightWeight
      })[0]

  let focusDetail = '继续保持当前节奏，争取把本期的优势转成连续优势。'
  if (focusCandidate) {
    if (focusCandidate.direction === 'down') {
      focusDetail = `${focusCandidate.label}较上期出现回落，建议优先针对这一项做专项补强，先把波动收住。`
    } else {
      focusDetail = `${focusCandidate.label}当前为 ${focusCandidate.currentLabel}，仍有继续提升空间，适合作为下一周期的主攻点。`
    }
  }

  const bestGrowthText = bestGrowth
    ? `当前最明显的成长亮点是 ${bestGrowth.label}，${bestGrowth.deltaLabel}。`
    : '当前还没有出现特别突出的单项跃升，建议继续积累更多周期数据。'

  return {
    title: momentumLabel,
    summary: spotlight.hasPrevious
      ? `${spotlight.previousPeriodLabel} 到 ${spotlight.currentPeriodLabel}，综合得分从 ${spotlight.previousScoreLabel} 走到 ${spotlight.currentScoreLabel}。${bestGrowthText}`
      : `${bestGrowthText} 当前先把成长基线建立起来，下一期就能看到明确的前后差异。`,
    momentumLabel,
    momentumDetail,
    focusLabel: focusCandidate?.label || '下一步重点',
    focusDetail,
  }
}

export function buildNextGrowthGoals(reports, periodType) {
  const normalized = normalizeGrowthReports(reports, periodType)
  if (!normalized.length) {
    return []
  }

  const current = normalized[normalized.length - 1]
  const comparisons = buildComparisonItems(reports, periodType)
  const scoreItem = comparisons.find((item) => item.key === 'totalScore')
  const accuracyItem = comparisons.find((item) => item.key === 'accuracyRate')
  const durationValue = toFiniteNumber(current.metrics.learningDuration)
  const quizValue = toFiniteNumber(current.metrics.quizCount)
  const benchmarks = {
    daily: { learningDuration: 20, quizCount: 30 },
    weekly: { learningDuration: 90, quizCount: 120 },
    monthly: { learningDuration: 240, quizCount: 320 },
    quarterly: { learningDuration: 720, quizCount: 960 },
    custom: { learningDuration: 120, quizCount: 160 },
  }[periodType] || { learningDuration: 120, quizCount: 160 }
  const scoreMilestones = [60, 70, 75, 80, 85, 90, 95]
  const accuracyMilestones = [70, 75, 80, 85, 90, 93, 95]

  const createGoal = (key, title, currentValue, targetValue, action) => {
    const meta = METRIC_MAP[key]
    const safeCurrent = toFiniteNumber(currentValue)
    const safeTarget = Math.max(safeCurrent, toFiniteNumber(targetValue))
    const progressRatio = safeTarget > 0 ? Math.min(safeCurrent / safeTarget, 1) : 0

    return {
      key,
      title,
      currentLabel: formatGrowthMetric(key, safeCurrent),
      targetLabel: formatGrowthMetric(key, safeTarget),
      gapLabel: formatGrowthMetric(key, Math.max(safeTarget - safeCurrent, 0)),
      progress: Math.round(progressRatio * 100),
      accent: meta?.accent || '#0f766e',
      softAccent: meta?.softAccent || 'rgba(15, 118, 110, 0.14)',
      action,
    }
  }

  const roundUpByStep = (value, step) => Math.ceil(Math.max(toFiniteNumber(value), 0) / step) * step

  const normalizeActionTarget = (key, targetValue) => {
    const safeTarget = Math.max(toFiniteNumber(targetValue), 0)

    if (key === 'learningDuration') {
      if (safeTarget <= 60) return roundUpByStep(safeTarget, 10)
      if (safeTarget <= 180) return roundUpByStep(safeTarget, 15)
      return roundUpByStep(safeTarget, 30)
    }

    if (key === 'quizCount') {
      if (safeTarget <= 100) return roundUpByStep(safeTarget, 10)
      if (safeTarget <= 500) return roundUpByStep(safeTarget, 20)
      return roundUpByStep(safeTarget, 50)
    }

    return Math.round(safeTarget)
  }

  const buildTargetFromGap = (key, currentValue, benchmarkValue, options = {}) => {
    const safeCurrent = toFiniteNumber(currentValue)
    const safeBenchmark = Math.max(1, toFiniteNumber(benchmarkValue))
    const minStep = options.minStep || 1
    const catchUpRatio = options.catchUpRatio || 0.4
    const stretchRatio = options.stretchRatio || 0.08
    let rawTarget = safeCurrent

    if (safeCurrent < safeBenchmark) {
      const gap = safeBenchmark - safeCurrent
      rawTarget = safeCurrent + Math.max(minStep, Math.round(gap * catchUpRatio))
    } else {
      rawTarget =
        safeCurrent + Math.max(minStep, Math.round(Math.max(safeCurrent * stretchRatio, safeBenchmark * 0.12)))
    }

    return normalizeActionTarget(key, rawTarget)
  }

  const getNextMilestoneTarget = (currentValue, milestones, fallbackStep, maxValue = 100) => {
    const safeCurrent = toFiniteNumber(currentValue)
    const nextMilestone = milestones.find((milestone) => milestone > safeCurrent + 0.01)
    if (nextMilestone !== undefined) {
      return nextMilestone
    }
    return Math.min(maxValue, Math.round(safeCurrent + fallbackStep))
  }

  const scoreTarget = getNextMilestoneTarget(
    current.metrics.totalScore,
    scoreMilestones,
    scoreItem && scoreItem.direction === 'up' ? 4 : 3
  )

  const accuracyTarget = getNextMilestoneTarget(
    current.metrics.accuracyRate,
    accuracyMilestones,
    accuracyItem && accuracyItem.direction === 'down' ? 3 : 2,
    99
  )

  const durationCompletion = durationValue / Math.max(benchmarks.learningDuration, 1)
  const quizCompletion = quizValue / Math.max(benchmarks.quizCount, 1)
  const useDurationGoal = durationCompletion < 0.75 || durationCompletion <= quizCompletion

  const durationTarget = buildTargetFromGap('learningDuration', durationValue, benchmarks.learningDuration, {
    minStep: 30,
    catchUpRatio: 0.45,
    stretchRatio: 0.2,
  })

  const quizTarget = buildTargetFromGap('quizCount', quizValue, benchmarks.quizCount, {
    minStep: 20,
    catchUpRatio: 0.35,
    stretchRatio: 0.1,
  })
  const scoreTargetLabel = formatGrowthMetric('totalScore', scoreTarget)
  const accuracyTargetLabel = formatGrowthMetric('accuracyRate', accuracyTarget)

  return [
    createGoal(
      'totalScore',
      scoreTarget >= 90 ? `冲到${scoreTargetLabel}突破线` : `冲到${scoreTargetLabel}稳定档`,
      current.metrics.totalScore,
      scoreTarget,
      scoreTarget >= 90
        ? '这一阶段不要只追求多做，优先把短板项补齐，综合表现才会真正迈进高分段。'
        : '先把当前最弱项补稳，再保住已有优势项，综合得分更容易站上下一档。'
    ),
    createGoal(
      'accuracyRate',
      accuracyTarget >= 90 ? `把正确率稳定到${accuracyTargetLabel}` : `先把正确率提到${accuracyTargetLabel}`,
      current.metrics.accuracyRate,
      accuracyTarget,
      accuracyTarget >= 90
        ? '重点不是继续刷更多题，而是先做错题归因和同类题复练，把高正确率变成稳定状态。'
        : '先做错题复盘，再回练同类题，正确率会比单纯加题量更容易抬上去。'
    ),
    createGoal(
      useDurationGoal ? 'learningDuration' : 'quizCount',
      useDurationGoal
        ? durationCompletion < 0.35 ? '先补上课程学习时长' : '把课程学习节奏稳定住'
        : quizCompletion < 1 ? '提高训练密度' : '把高频训练转成专项突破',
      useDurationGoal ? durationValue : quizValue,
      useDurationGoal ? durationTarget : quizTarget,
      useDurationGoal
        ? '先把固定学习时段建立起来，再用课程内容补齐知识框架，后续提分会更稳。'
        : '保持练习频率，但把新增训练量集中在薄弱模块上，避免只刷数量不补短板。'
    ),
  ]
}

export function buildGrowthIdentity(reports, periodType) {
  const normalized = normalizeGrowthReports(reports, periodType)
  if (!normalized.length) {
    return {
      level: 0,
      title: '成长新手',
      badge: '等待点亮',
      summary: '生成更多报告后，这里会识别你的阶段称号。',
      nextTitle: '稳步进阶者',
      progress: 0,
      accent: '#64748b',
      softAccent: 'rgba(100, 116, 139, 0.14)',
    }
  }

  const current = normalized[normalized.length - 1]
  const spotlight = buildProgressSpotlight(reports, periodType)
  const totalScore = toFiniteNumber(current.metrics.totalScore)
  const accuracyRate = toFiniteNumber(current.metrics.accuracyRate)
  const streak = getRiseStreak(buildTrendSeries(reports, 'totalScore', periodType))

  const levels = [
    {
      title: '成长新手',
      badge: '起步阶段',
      minScore: 0,
      accent: '#64748b',
      softAccent: 'rgba(100, 116, 139, 0.14)',
      summary: '你已经开始积累学习轨迹，当前关键是把节奏稳定下来。',
    },
    {
      title: '稳步进阶者',
      badge: '持续投入',
      minScore: 70,
      accent: '#2563eb',
      softAccent: 'rgba(37, 99, 235, 0.16)',
      summary: '你已经摆脱随机波动，正在形成持续成长的基本盘。',
    },
    {
      title: '高效吸收者',
      badge: '理解提速',
      minScore: 82,
      accent: '#d97706',
      softAccent: 'rgba(217, 119, 6, 0.16)',
      summary: '你不只是学得多，而是开始把投入更高效地转成结果。',
    },
    {
      title: '持续领跑者',
      badge: '阶段突破',
      minScore: 90,
      accent: '#0f766e',
      softAccent: 'rgba(15, 118, 110, 0.16)',
      summary: '你已经进入高质量成长区间，优势正在持续兑现。',
    },
  ]

  let levelIndex = 0
  if (totalScore >= 90 || (totalScore >= 88 && streak >= 2 && accuracyRate >= 85)) {
    levelIndex = 3
  } else if (totalScore >= 82 || (totalScore >= 80 && accuracyRate >= 80)) {
    levelIndex = 2
  } else if (totalScore >= 70) {
    levelIndex = 1
  }

  const currentLevel = levels[levelIndex]
  const nextLevel = levels[Math.min(levelIndex + 1, levels.length - 1)]
  const sameAsTop = levelIndex === levels.length - 1
  const fromScore = currentLevel.minScore
  const toScore = sameAsTop ? 100 : nextLevel.minScore
  const progressBase = Math.max(toScore - fromScore, 1)
  const progress = sameAsTop
    ? 100
    : Math.max(0, Math.min(Math.round(((totalScore - fromScore) / progressBase) * 100), 100))

  let summary = currentLevel.summary
  if (spotlight.hasPrevious && spotlight.scoreDirection === 'up') {
    summary = `${currentLevel.summary} 相比${spotlight.previousPeriodLabel}，综合得分已从${spotlight.previousScoreLabel}提升到${spotlight.currentScoreLabel}。`
  } else if (streak >= 2) {
    summary = `${currentLevel.summary} 你已连续 ${streak + 1} 期上升，成长势能很明显。`
  } else if (accuracyRate >= 85) {
    summary = `${currentLevel.summary} 当前正确率也维持在高位，说明吸收效率不错。`
  }

  return {
    level: levelIndex,
    title: currentLevel.title,
    badge: currentLevel.badge,
    summary,
    nextTitle: sameAsTop ? '维持领先状态' : nextLevel.title,
    progress,
    accent: currentLevel.accent,
    softAccent: currentLevel.softAccent,
    scoreLabel: formatGrowthMetric('totalScore', totalScore),
    accuracyLabel: formatGrowthMetric('accuracyRate', accuracyRate),
  }
}

export function buildGrowthMilestones(reports, periodType) {
  const normalized = normalizeGrowthReports(reports, periodType)
  if (!normalized.length) return []

  const milestones = []
  const spotlight = buildProgressSpotlight(reports, periodType)
  const totalSeries = normalized.map((item) => item.metrics.totalScore)
  const durationSeries = normalized.map((item) => item.metrics.learningDuration)
  const accuracySeries = normalized.map((item) => item.metrics.accuracyRate)
  const current = normalized[normalized.length - 1]
  const previous = normalized[normalized.length - 2]

  if (spotlight.hasPrevious && spotlight.scoreDirection === 'up') {
    milestones.push({
      title: '综合得分出现明显抬升',
      detail: `${spotlight.previousPeriodLabel} 为 ${spotlight.previousScoreLabel}，${spotlight.currentPeriodLabel} 提升到 ${spotlight.currentScoreLabel}，${spotlight.stageLabel} 很清楚。`,
    })
  }

  if (current.metrics.totalScore === Math.max(...totalSeries) && normalized.length > 1) {
    milestones.push({
      title: '综合得分达到阶段峰值',
      detail: `${current.periodLabel} 的综合得分来到 ${formatGrowthMetric('totalScore', current.metrics.totalScore)}，刷新当前周期内最佳表现。`,
    })
  }

  if (current.metrics.learningDuration === Math.max(...durationSeries) && current.metrics.learningDuration > 0) {
    milestones.push({
      title: '投入时长来到新高',
      detail: `本期学习投入达到 ${formatGrowthMetric('learningDuration', current.metrics.learningDuration)}，成长的“燃料”明显更足。`,
    })
  }

  if (normalized.length > 1 && current.metrics.accuracyRate > accuracySeries[0] + 5) {
    milestones.push({
      title: '正确率明显抬升',
      detail: `从起点到现在，正确率提升了 ${formatGrowthMetric('accuracyRate', current.metrics.accuracyRate - accuracySeries[0])}，说明理解深度在变强。`,
    })
  }

  if (previous && current.metrics.quizCount > previous.metrics.quizCount) {
    milestones.push({
      title: '练习密度继续加码',
      detail: `相比上期多完成了 ${formatGrowthMetric('quizCount', current.metrics.quizCount - previous.metrics.quizCount)}，练习量在主动拉高。`,
    })
  }

  if (!milestones.length) {
    milestones.push({
      title: '成长轨迹正在积累',
      detail: '继续保持连续记录，系统会在更多数据出现后自动识别关键突破节点。',
    })
  }

  return milestones.slice(0, 3)
}

export function createSparklinePoints(series, width = 680, height = 240) {
  if (!Array.isArray(series) || !series.length) {
    return []
  }

  const values = series.map((item) => toFiniteNumber(item.value))
  const maxValue = Math.max(...values)
  const minValue = Math.min(...values)
  const range = maxValue - minValue || 1
  const leftPadding = 24
  const rightPadding = 24
  const topPadding = 18
  const bottomPadding = 28
  const usableWidth = width - leftPadding - rightPadding
  const usableHeight = height - topPadding - bottomPadding

  return series.map((item, index) => {
    const x =
      series.length === 1
        ? width / 2
        : leftPadding + (usableWidth * index) / (series.length - 1)
    const y = topPadding + ((maxValue - toFiniteNumber(item.value)) / range) * usableHeight

    return {
      ...item,
      x,
      y,
    }
  })
}

export function buildLinePath(points) {
  if (!Array.isArray(points) || !points.length) return ''
  return points
    .map((point, index) => `${index === 0 ? 'M' : 'L'} ${point.x.toFixed(2)} ${point.y.toFixed(2)}`)
    .join(' ')
}

export function buildAreaPath(points, width = 680, height = 240) {
  if (!Array.isArray(points) || !points.length) return ''
  const linePath = buildLinePath(points)
  const first = points[0]
  const last = points[points.length - 1]
  return `${linePath} L ${last.x.toFixed(2)} ${(height - 28).toFixed(2)} L ${first.x.toFixed(2)} ${(height - 28).toFixed(2)} Z`
}
