import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  getMyExamRecords,
  getMyExamStats,
  getMyExamStatsByType,
} from './examRecord'
import { api } from '@/utils/api'
import { getUserId } from '@/utils/userStorage'
import logger from '@/utils/logger'

vi.mock('@/utils/api', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

vi.mock('@/utils/userStorage', () => ({
  getUserId: vi.fn(),
}))

vi.mock('@/utils/logger', () => ({
  default: {
    warn: vi.fn(),
    error: vi.fn(),
    info: vi.fn(),
    log: vi.fn(),
    success: vi.fn(),
    debug: vi.fn(),
    sensitive: vi.fn(),
    api: vi.fn(),
    group: vi.fn(),
    table: vi.fn(),
  },
}))

describe('examRecord API error handling', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    getUserId.mockReturnValue(1001)
  })

  it('getMyExamRecords 成功时透传 response', async () => {
    const response = { status: 200, data: { items: [{ id: 1 }] } }
    api.get.mockResolvedValue(response)

    const result = await getMyExamRecords({ pageNum: 1 })

    expect(api.get).toHaveBeenCalledWith('/train/quiz/my-records', {
      params: { pageNum: 1, userId: 1001 },
    })
    expect(result).toBe(response)
  })

  it('getMyExamRecords 在 api.get reject 时抛错', async () => {
    const error = new Error('records request failed')
    api.get.mockRejectedValue(error)

    await expect(getMyExamRecords()).rejects.toBe(error)
    expect(logger.error).toHaveBeenCalledWith('❌ 获取考试记录失败:', error)
  })

  it('getMyExamStats 在 api.get reject 时抛错', async () => {
    const error = new Error('stats request failed')
    api.get.mockRejectedValue(error)

    await expect(getMyExamStats()).rejects.toBe(error)
    expect(logger.error).toHaveBeenCalledWith('❌ 获取考试统计失败:', error)
  })

  it('getMyExamStatsByType 在 api.get reject 时抛错', async () => {
    const error = new Error('stats by type request failed')
    api.get.mockRejectedValue(error)

    await expect(getMyExamStatsByType()).rejects.toBe(error)
    expect(logger.error).toHaveBeenCalledWith('❌ 获取分类型统计失败:', error)
  })
})
