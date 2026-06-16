const SCORE_MODE = 'score'
const LEVEL_MODE = 'level'
const DEFAULT_LEVEL_PASS_SCORE = 60
const DEFAULT_LEVEL_EXCELLENT_SCORE = 85

const LEVEL_STYLE_MAP = {
  excellent: {
    label: '优秀',
    textClass: 'text-green-600',
    badgeClass: 'bg-green-100 text-green-700'
  },
  pass: {
    label: '合格',
    textClass: 'text-blue-600',
    badgeClass: 'bg-blue-100 text-blue-700'
  },
  effort: {
    label: '继续努力',
    textClass: 'text-amber-600',
    badgeClass: 'bg-amber-100 text-amber-700'
  }
}

const parseThresholdValue = (value) => {
  const numeric = Number(value)
  return Number.isFinite(numeric) ? Math.round(numeric) : null
}

export const normalizeResultDisplayMode = (value) => {
  return String(value || SCORE_MODE).trim().toLowerCase() === LEVEL_MODE ? LEVEL_MODE : SCORE_MODE
}

export const usesLevelResultDisplay = (value) => normalizeResultDisplayMode(value) === LEVEL_MODE

export const normalizeLevelThresholds = (source = {}) => {
  const parsedPass = parseThresholdValue(source?.levelPassScore ?? source?.level_pass_score)
  const levelPassScore = parsedPass != null && parsedPass >= 1 && parsedPass <= 99
    ? parsedPass
    : DEFAULT_LEVEL_PASS_SCORE

  const parsedExcellent = parseThresholdValue(source?.levelExcellentScore ?? source?.level_excellent_score)
  const levelExcellentScore = parsedExcellent != null && parsedExcellent > levelPassScore && parsedExcellent <= 100
    ? parsedExcellent
    : Math.min(100, Math.max(levelPassScore + 1, DEFAULT_LEVEL_EXCELLENT_SCORE))

  return {
    levelPassScore,
    levelExcellentScore
  }
}

export const getScoreTextClass = (score) => {
  if (score == null || score === '') return 'text-neutral-500'
  const numeric = Number(score)
  if (!Number.isFinite(numeric)) return 'text-neutral-500'
  if (numeric >= 90) return 'text-green-600'
  if (numeric >= 60) return 'text-blue-600'
  return 'text-red-500'
}

export const resolveScoreLevel = (score, config = {}) => {
  const numeric = Number(score)
  const safeScore = Number.isFinite(numeric) ? numeric : 0
  const { levelPassScore, levelExcellentScore } = normalizeLevelThresholds(config)

  if (safeScore >= levelExcellentScore) {
    return { ...LEVEL_STYLE_MAP.excellent, levelPassScore, levelExcellentScore }
  }
  if (safeScore >= levelPassScore) {
    return { ...LEVEL_STYLE_MAP.pass, levelPassScore, levelExcellentScore }
  }
  return { ...LEVEL_STYLE_MAP.effort, levelPassScore, levelExcellentScore }
}

export const getResultDisplayTitle = (mode) => {
  return usesLevelResultDisplay(mode) ? '评估结果' : '得分'
}

export const getResultDisplayValue = (score, mode, config = {}) => {
  if (score == null || score === '') {
    return '--'
  }
  if (usesLevelResultDisplay(mode)) {
    return resolveScoreLevel(score, config).label
  }
  return score
}

export const getResultDisplayTextClass = (score, mode, config = {}) => {
  if (usesLevelResultDisplay(mode)) {
    return resolveScoreLevel(score, config).textClass
  }
  return getScoreTextClass(score)
}

export const getResultDisplayBadgeClass = (score, mode, config = {}) => {
  if (usesLevelResultDisplay(mode)) {
    return resolveScoreLevel(score, config).badgeClass
  }
  return ''
}
