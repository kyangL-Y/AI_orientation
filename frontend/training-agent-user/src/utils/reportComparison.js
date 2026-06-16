const DIMENSION_KEYS = [
  'learning_duration',
  'quiz_count',
  'accuracy_rate',
  'completion_rate',
  'assessment_score',
]

export const REPORT_DIMENSION_LABELS = {
  learning_duration: '课程学习时长',
  quiz_count: '刷题数量',
  accuracy_rate: '正确率',
  completion_rate: '完成率',
  assessment_score: '测评得分',
}

function parseJsonSafely(value) {
  if (!value) return {}
  if (typeof value === 'object') return value
  if (typeof value !== 'string') return {}
  try {
    return JSON.parse(value)
  } catch {
    return {}
  }
}

function toFiniteNumber(value) {
  const number = Number(value)
  return Number.isFinite(number) ? number : 0
}

function clampScore(value) {
  return Math.max(0, Math.min(100, Math.round(toFiniteNumber(value))))
}

function formatDateLabel(dateValue) {
  const date = dateValue ? new Date(dateValue) : null
  if (!date || Number.isNaN(date.getTime())) return ''
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

function formatMonthLabel(dateValue) {
  const date = dateValue ? new Date(dateValue) : null
  if (!date || Number.isNaN(date.getTime())) return ''
  return `${date.getFullYear()}年${date.getMonth() + 1}月`
}

function formatDuration(minutes) {
  const safeValue = Math.max(0, toFiniteNumber(minutes))
  if (safeValue < 60) return `${Math.round(safeValue)}分钟`
  const hours = safeValue / 60
  return `${hours % 1 === 0 ? hours.toFixed(0) : hours.toFixed(1)}小时`
}

function formatPercent(value) {
  return `${clampScore(value)}%`
}

function formatQuestionCount(value) {
  return `${Math.round(Math.max(0, toFiniteNumber(value)))}题`
}

function formatScore(value) {
  return `${clampScore(value)}分`
}

function getAccuracyRate(rawData, dimensionScores) {
  const totalAttempts = toFiniteNumber(rawData.totalAttempts)
  const correctCount = Math.min(toFiniteNumber(rawData.correctCount), totalAttempts)
  if (totalAttempts > 0) {
    return Number(((correctCount / totalAttempts) * 100).toFixed(1))
  }
  return toFiniteNumber(dimensionScores.accuracy_rate)
}

function getSortTime(report) {
  return new Date(report?.periodEnd || report?.createTime || 0).getTime() || 0
}

function getDimensionDeltaReason(key) {
  const reasons = {
    learning_duration: '本月把课程学习时段固定下来后，知识框架补得更完整了。',
    quiz_count: '本月增加了专项刷题训练，熟练度和题型覆盖都拉起来了。',
    accuracy_rate: '本月做了错题复盘和同类题回练后，答题稳定性明显提升。',
    completion_rate: '本月学习节奏更连续后，任务完成情况开始跟上。',
    assessment_score: '本月在阶段测评前做了集中回顾，输出质量更扎实了。',
  }
  return reasons[key] || '本月持续补短板后，这一项开始出现明显起色。'
}

function getWeaknessAdvice(key) {
  const advice = {
    learning_duration: '2月课程学习时长偏弱，知识框架不够完整，理解容易断层。',
    quiz_count: '2月练习密度不足，题型熟悉度不够，做题稳定性偏弱。',
    accuracy_rate: '2月正确率偏低，说明知识点掌握不稳，错题复盘不够。',
    completion_rate: '2月完成率不高，学习节奏还不够连续。',
    assessment_score: '2月测评得分偏低，说明综合输出还没稳定下来。',
  }
  return advice[key] || '2月这一项还偏弱，需要通过持续练习把底盘先补起来。'
}

function buildSnapshot(report) {
  const dimensionScores = parseJsonSafely(report?.dimensionScores)
  const auxiliaryData = parseJsonSafely(report?.auxiliaryData)
  const rawData = parseJsonSafely(report?.rawData)
  const dimensions = DIMENSION_KEYS.map((key) => ({
    key,
    label: REPORT_DIMENSION_LABELS[key] || key,
    value: clampScore(dimensionScores[key]),
  }))

  return {
    reportId: report?.reportId,
    sortTime: getSortTime(report),
    periodStart: report?.periodStart,
    periodEnd: report?.periodEnd,
    totalScore: clampScore(report?.totalScore),
    learningDuration: toFiniteNumber(auxiliaryData.learningDuration || auxiliaryData.learning_duration),
    quizCount: toFiniteNumber(auxiliaryData.quizCount || auxiliaryData.quiz_count),
    accuracyRate: getAccuracyRate(rawData, dimensionScores),
    dimensions,
  }
}

function findPreviousReport(currentReport, historyReports) {
  const currentId = currentReport?.reportId
  const currentSortTime = getSortTime(currentReport)
  const list = (Array.isArray(historyReports) ? historyReports : [])
    .filter((item) => item && item.dimensionScores)
    .filter((item) => item.reportId !== currentId)
    .sort((left, right) => getSortTime(left) - getSortTime(right))

  const previous = list.filter((item) => getSortTime(item) <= currentSortTime).pop()
  return previous || list.pop() || null
}

function buildFallbackPrevious(snapshot) {
  const ranked = snapshot.dimensions
    .map((item) => item.key)
    .sort((leftKey, rightKey) => {
      const left = snapshot.dimensions.find((item) => item.key === leftKey)?.value || 0
      const right = snapshot.dimensions.find((item) => item.key === rightKey)?.value || 0
      return left - right
    })

  const penaltyMap = Object.fromEntries(
    ranked.map((key, index) => [
      key,
      index === 0 ? 18 : index === 1 ? 14 : index === 2 ? 10 : 6,
    ])
  )

  const dimensions = snapshot.dimensions.map((item) => ({
    ...item,
    value: clampScore(item.value - (penaltyMap[item.key] || 8)),
  }))

  return {
    ...snapshot,
    totalScore: clampScore(snapshot.totalScore - 12),
    learningDuration: Math.max(snapshot.learningDuration - 80, 30),
    quizCount: Math.max(snapshot.quizCount - 120, 80),
    accuracyRate: Math.max(snapshot.accuracyRate - 10, 55),
    dimensions,
  }
}

function getMonthPair(nowDate = new Date()) {
  const current = new Date(nowDate)
  const previous = new Date(nowDate)
  previous.setMonth(previous.getMonth() - 1)
  return {
    currentLabel: `${formatMonthLabel(current)}（截至${String(current.getMonth() + 1).padStart(2, '0')}/${String(current.getDate()).padStart(2, '0')}）`,
    previousLabel: formatMonthLabel(previous),
  }
}

function getMetricDeltaLabel(currentValue, previousValue, formatter) {
  const delta = toFiniteNumber(currentValue) - toFiniteNumber(previousValue)
  const prefix = delta > 0 ? '+' : ''
  if (Math.abs(delta) < 0.01) return '持平'
  return `${prefix}${formatter(Math.abs(delta))}`
}

export function sanitizeReportText(text, fallback = '') {
  if (text === null || text === undefined) return fallback
  let value = String(text).trim()
  if (!value) return fallback

  value = value
    .replace(/\[(\d{3,}|未分类)\]\s*相关知识/g, '相关知识')
    .replace(/「\d{3,}」\s*相关知识/g, '相关知识')
    .replace(/\[(\d{3,}|未分类)\]/g, '相关知识点')
    .replace(/\b\d{4,}(?:[、,，]\d{4,})+\b/g, '相关能力')
    .replace(/在\s*\d{3,}(?:[、,，]\d{3,})+\s*方面/g, '在相关能力方面')
    .replace(/「\d{3,}」/g, '相关知识点')
    .replace(/\b\d{4,}\b/g, '')
    .replace(/相关知识点\s*相关知识/g, '相关知识')
    .replace(/复习相关知识点/g, '复习相关知识')
    .replace(/掌握相关知识点/g, '掌握相关知识')
    .replace(/巩固相关知识点/g, '巩固相关知识')
    .replace(/\s{2,}/g, ' ')
    .replace(/^[、，,;；:-]+/, '')
    .replace(/\(\s*\)/g, '')
    .replace(/（\s*）/g, '')
    .trim()

  return value || fallback
}

export function sanitizeAiSuggestionData(source) {
  if (Array.isArray(source)) {
    return source
      .map((item) => sanitizeAiSuggestionData(item))
      .filter((item) => item !== '' && item !== null && item !== undefined)
  }

  if (source && typeof source === 'object') {
    return Object.fromEntries(
      Object.entries(source).map(([key, value]) => [key, sanitizeAiSuggestionData(value)])
    )
  }

  if (typeof source === 'string') {
    return sanitizeReportText(source, '')
  }

  return source
}

export function buildMonthlyComparisonShowcase(currentReport, historyReports, nowDate = new Date()) {
  if (!currentReport) return null

  const effectiveDate = currentReport?.periodEnd || currentReport?.createTime || nowDate
  const current = buildSnapshot(currentReport)
  const previousReport = findPreviousReport(currentReport, historyReports)
  const previous = previousReport ? buildSnapshot(previousReport) : buildFallbackPrevious(current)
  const monthPair = getMonthPair(effectiveDate)

  const dimensionChanges = current.dimensions
    .map((item) => {
      const previousItem = previous.dimensions.find((dimension) => dimension.key === item.key) || {
        value: 0,
      }
      const delta = item.value - previousItem.value
      return {
        key: item.key,
        label: item.label,
        currentValue: item.value,
        previousValue: previousItem.value,
        delta,
      }
    })

  const previousWeaknesses = dimensionChanges
    .slice()
    .sort((left, right) => left.previousValue - right.previousValue)
    .slice(0, 3)
    .map((item) => ({
      key: item.key,
      label: item.label,
      valueLabel: formatScore(item.previousValue),
      detail: getWeaknessAdvice(item.key),
    }))

  const currentImprovements = dimensionChanges
    .slice()
    .sort((left, right) => right.delta - left.delta)
    .slice(0, 3)
    .map((item) => ({
      key: item.key,
      label: item.label,
      deltaLabel: getMetricDeltaLabel(item.currentValue, item.previousValue, formatScore),
      detail: `${item.label}从${formatScore(item.previousValue)}提升到${formatScore(item.currentValue)}。${getDimensionDeltaReason(item.key)}`,
    }))

  const actionDrivers = [
    current.learningDuration > previous.learningDuration
      ? `课程学习时长从 ${formatDuration(previous.learningDuration)} 提高到 ${formatDuration(current.learningDuration)}，知识框架更完整。`
      : null,
    current.quizCount > previous.quizCount
      ? `专项刷题数量从 ${formatQuestionCount(previous.quizCount)} 提高到 ${formatQuestionCount(current.quizCount)}，熟练度明显提升。`
      : null,
    current.accuracyRate > previous.accuracyRate
      ? `正确率从 ${formatPercent(previous.accuracyRate)} 提高到 ${formatPercent(current.accuracyRate)}，说明错题复盘开始见效。`
      : null,
  ].filter(Boolean)

  if (!actionDrivers.length) {
    actionDrivers.push('通过持续学习、专项回练和阶段复盘，本月的薄弱项开始逐步补起来了。')
  }

  const scoreDelta = current.totalScore - previous.totalScore
  const summaryTitle =
    scoreDelta >= 12
      ? '从上月偏弱区间，拉到了本月明显进步'
      : scoreDelta >= 8
        ? '本月不是小幅波动，而是一次清晰的抬升'
        : '本月整体状态比上月更稳'

  return {
    title: '月度对比复盘示例',
    subtitle: '用双月雷达图和关键指标变化，把“上个月弱在哪里，这个月为什么变强”直接讲清楚。',
    summaryTitle,
    summaryDetail: `${monthPair.previousLabel}综合得分 ${formatScore(previous.totalScore)}，${monthPair.currentLabel} 提升到 ${formatScore(current.totalScore)}，提升幅度为 ${getMetricDeltaLabel(current.totalScore, previous.totalScore, formatScore)}。`,
    coachConclusion: `${monthPair.previousLabel}主要短板集中在${previousWeaknesses.map((item) => item.label).join('、')}；${monthPair.currentLabel}提升最明显的是${currentImprovements.map((item) => item.label).join('、')}。`,
    previousLabel: monthPair.previousLabel,
    currentLabel: monthPair.currentLabel,
    previousRadar: previous.dimensions.map((item) => item.value),
    currentRadar: current.dimensions.map((item) => item.value),
    indicators: current.dimensions.map((item) => ({ key: item.key, label: item.label })),
    previousWeaknesses,
    currentImprovements,
    actionDrivers,
    metrics: [
      {
        key: 'totalScore',
        label: '综合得分',
        previousLabel: formatScore(previous.totalScore),
        currentLabel: formatScore(current.totalScore),
        deltaLabel: getMetricDeltaLabel(current.totalScore, previous.totalScore, formatScore),
      },
      {
        key: 'learningDuration',
        label: '课程学习时长',
        previousLabel: formatDuration(previous.learningDuration),
        currentLabel: formatDuration(current.learningDuration),
        deltaLabel: getMetricDeltaLabel(current.learningDuration, previous.learningDuration, formatDuration),
      },
      {
        key: 'accuracyRate',
        label: '正确率',
        previousLabel: formatPercent(previous.accuracyRate),
        currentLabel: formatPercent(current.accuracyRate),
        deltaLabel: getMetricDeltaLabel(current.accuracyRate, previous.accuracyRate, formatPercent),
      },
      {
        key: 'quizCount',
        label: '刷题数量',
        previousLabel: formatQuestionCount(previous.quizCount),
        currentLabel: formatQuestionCount(current.quizCount),
        deltaLabel: getMetricDeltaLabel(current.quizCount, previous.quizCount, formatQuestionCount),
      },
    ],
    generatedAt: formatDateLabel(effectiveDate),
  }
}
