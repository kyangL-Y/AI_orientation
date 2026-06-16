import { describe, expect, it } from 'vitest'
import {
  buildComparisonItems,
  buildGrowthBadges,
  buildGrowthBreakthrough,
  buildGrowthIdentity,
  buildGrowthMilestones,
  buildGrowthNarrative,
  buildProgressSpotlight,
  buildNextGrowthGoals,
  buildGrowthStatus,
  buildTrendSeries,
  describeGrowthDelta,
  formatGrowthMetric,
  getBestGrowthMetric,
  getRiseStreak,
} from './reportGrowth'

function createReport({
  reportId,
  periodStart,
  periodEnd,
  periodType = 'monthly',
  totalScore,
  learningDuration,
  quizCount,
  totalAttempts,
  correctCount,
  abilityScores,
}) {
  return {
    reportId,
    periodType,
    periodStart,
    periodEnd,
    totalScore,
    auxiliaryData: JSON.stringify({
      learningDuration,
      quizCount,
    }),
    rawData: JSON.stringify({
      totalAttempts,
      correctCount,
    }),
    abilityScores: JSON.stringify(abilityScores),
  }
}

const reports = [
  createReport({
    reportId: 1,
    periodStart: '2026-01-01T00:00:00',
    periodEnd: '2026-01-31T00:00:00',
    totalScore: 72,
    learningDuration: 80,
    quizCount: 28,
    totalAttempts: 40,
    correctCount: 28,
    abilityScores: { cost_control: 68, customer_service: 74, team_collaboration: 70 },
  }),
  createReport({
    reportId: 2,
    periodStart: '2026-02-01T00:00:00',
    periodEnd: '2026-02-28T00:00:00',
    totalScore: 79,
    learningDuration: 120,
    quizCount: 44,
    totalAttempts: 50,
    correctCount: 40,
    abilityScores: { cost_control: 74, customer_service: 78, team_collaboration: 76 },
  }),
  createReport({
    reportId: 3,
    periodStart: '2026-03-01T00:00:00',
    periodEnd: '2026-03-31T00:00:00',
    totalScore: 88,
    learningDuration: 180,
    quizCount: 66,
    totalAttempts: 60,
    correctCount: 54,
    abilityScores: { cost_control: 82, customer_service: 84, team_collaboration: 86 },
  }),
]

describe('reportGrowth helpers', () => {
  it('formats metrics with readable units', () => {
    expect(formatGrowthMetric('learningDuration', 150)).toBe('2.5小时')
    expect(formatGrowthMetric('accuracyRate', 90)).toBe('90%')
  })

  it('builds ordered trend series and rise streak', () => {
    const series = buildTrendSeries(reports, 'totalScore', 'monthly')
    expect(series.map((item) => item.value)).toEqual([72, 79, 88])
    expect(series.map((item) => item.periodLabel)).toEqual(['2026年1月', '2026年2月', '2026年3月'])
    expect(getRiseStreak(series)).toBe(2)
  })

  it('describes delta and best growth metric', () => {
    expect(describeGrowthDelta('totalScore', 88, 79)).toBe('较上期 +9分')
    const bestGrowth = getBestGrowthMetric(reports, 'monthly')
    expect(bestGrowth?.label).toBe('课程学习时长')
    expect(bestGrowth?.deltaLabel).toContain('+1小时')
  })

  it('creates positive growth status and milestones', () => {
    const status = buildGrowthStatus(reports, 'monthly')
    const milestones = buildGrowthMilestones(reports, 'monthly')

    expect(status.title).toContain('稳定上升')
    expect(milestones.length).toBeGreaterThan(0)
    expect(milestones[0].title).toContain('综合得分')
  })

  it('creates badges and comparison cards for latest period', () => {
    const badges = buildGrowthBadges(reports, 'monthly')
    const comparisonItems = buildComparisonItems(reports, 'monthly')

    expect(badges.length).toBeGreaterThan(0)
    expect(badges.some((item) => item.title.includes('学习') || item.title.includes('阶段'))).toBe(true)
    expect(comparisonItems).toHaveLength(4)
    expect(comparisonItems[0].deltaLabel).toContain('+9分')
  })

  it('builds a spotlight summary that shows before and after growth', () => {
    const spotlight = buildProgressSpotlight(reports, 'monthly')
    const breakthrough = buildGrowthBreakthrough(reports, 'monthly')

    expect(spotlight.hasPrevious).toBe(true)
    expect(spotlight.previousScoreLabel).toBe('79分')
    expect(spotlight.currentScoreLabel).toBe('88分')
    expect(spotlight.stageLabel).toContain('突破')
    expect(spotlight.metricHighlights.length).toBeGreaterThan(0)
    expect(breakthrough.detail).toContain('79分')
    expect(breakthrough.detail).toContain('88分')
  })

  it('builds readable growth narrative for ai recap area', () => {
    const narrative = buildGrowthNarrative(reports, 'monthly')

    expect(narrative.title.length).toBeGreaterThan(0)
    expect(narrative.summary).toContain('79分')
    expect(narrative.summary).toContain('88分')
    expect(narrative.focusLabel.length).toBeGreaterThan(0)
    expect(narrative.focusDetail.length).toBeGreaterThan(0)
  })

  it('builds next growth goals with target and progress', () => {
    const goals = buildNextGrowthGoals(reports, 'monthly')

    expect(goals).toHaveLength(3)
    expect(goals[0].targetLabel).not.toBe(goals[0].currentLabel)
    expect(goals[0].progress).toBeGreaterThan(0)
    expect(goals[0].action.length).toBeGreaterThan(0)
  })

  it('prefers real short boards and milestone targets for growth goals', () => {
    const shortBoardReports = [
      createReport({
        reportId: 11,
        periodStart: '2026-01-01T00:00:00',
        periodEnd: '2026-01-31T00:00:00',
        totalScore: 72,
        learningDuration: 5,
        quizCount: 1500,
        totalAttempts: 100,
        correctCount: 85,
        abilityScores: { cost_control: 70, customer_service: 74, team_collaboration: 72 },
      }),
      createReport({
        reportId: 12,
        periodStart: '2026-02-01T00:00:00',
        periodEnd: '2026-02-28T00:00:00',
        totalScore: 75,
        learningDuration: 2,
        quizCount: 1587,
        totalAttempts: 100,
        correctCount: 87,
        abilityScores: { cost_control: 74, customer_service: 77, team_collaboration: 75 },
      }),
    ]

    const goals = buildNextGrowthGoals(shortBoardReports, 'monthly')

    expect(goals[0].targetLabel).toBe('80分')
    expect(goals[1].targetLabel).toBe('90%')
    expect(goals[2].key).toBe('learningDuration')
    expect(goals[2].currentLabel).toBe('2分钟')
    expect(goals[2].targetLabel).toBe('2小时')
  })

  it('builds growth identity badge and next stage progress', () => {
    const identity = buildGrowthIdentity(reports, 'monthly')

    expect(identity.title.length).toBeGreaterThan(0)
    expect(identity.badge.length).toBeGreaterThan(0)
    expect(identity.progress).toBeGreaterThanOrEqual(0)
    expect(identity.progress).toBeLessThanOrEqual(100)
    expect(identity.scoreLabel).toContain('分')
  })
})
