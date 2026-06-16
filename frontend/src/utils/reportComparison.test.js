import { describe, expect, it } from 'vitest'
import { buildMonthlyComparisonShowcase, sanitizeReportText } from './reportComparison'

function createReport({
  reportId,
  periodStart,
  periodEnd,
  totalScore,
  dimensionScores,
  learningDuration,
  quizCount,
  totalAttempts,
  correctCount,
}) {
  return {
    reportId,
    periodStart,
    periodEnd,
    totalScore,
    dimensionScores: JSON.stringify(dimensionScores),
    auxiliaryData: JSON.stringify({
      learningDuration,
      quizCount,
    }),
    rawData: JSON.stringify({
      totalAttempts,
      correctCount,
    }),
  }
}

describe('reportComparison helpers', () => {
  it('builds a monthly showcase with before-and-after radar data', () => {
    const previous = createReport({
      reportId: 1,
      periodStart: '2026-02-01T00:00:00',
      periodEnd: '2026-02-29T23:59:59',
      totalScore: 68,
      dimensionScores: {
        learning_duration: 56,
        quiz_count: 58,
        accuracy_rate: 60,
        completion_rate: 62,
        assessment_score: 59,
      },
      learningDuration: 120,
      quizCount: 220,
      totalAttempts: 100,
      correctCount: 62,
    })

    const current = createReport({
      reportId: 2,
      periodStart: '2026-03-01T00:00:00',
      periodEnd: '2026-03-21T23:59:59',
      totalScore: 84,
      dimensionScores: {
        learning_duration: 76,
        quiz_count: 82,
        accuracy_rate: 80,
        completion_rate: 78,
        assessment_score: 85,
      },
      learningDuration: 260,
      quizCount: 460,
      totalAttempts: 120,
      correctCount: 96,
    })

    const showcase = buildMonthlyComparisonShowcase(current, [previous, current])

    expect(showcase.previousLabel).toContain('2026年2月')
    expect(showcase.currentLabel).toContain('2026年3月')
    expect(showcase.previousRadar).toHaveLength(5)
    expect(showcase.currentImprovements[0].detail).toContain('提升到')
    expect(showcase.actionDrivers.length).toBeGreaterThan(0)
  })

  it('sanitizes legacy numeric ai text', () => {
    expect(sanitizeReportText('继续发挥你在1872、1881方面的优势')).toContain('相关能力方面')
    expect(sanitizeReportText('重点复习[1365]相关知识')).not.toContain('1365')
    expect(sanitizeReportText('重点复习[1365]相关知识')).toBe('重点复习相关知识')
  })
})
