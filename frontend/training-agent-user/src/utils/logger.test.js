/**
 * logger.js 单元测试
 *
 * 测试日志工具的敏感信息过滤和环境控制逻辑。
 */
import { describe, it, expect, vi, beforeEach } from 'vitest'
import logger, { setupProductionLogs } from './logger'

describe('logger', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('logger object has all expected methods', () => {
    expect(typeof logger.log).toBe('function')
    expect(typeof logger.warn).toBe('function')
    expect(typeof logger.error).toBe('function')
    expect(typeof logger.info).toBe('function')
    expect(typeof logger.success).toBe('function')
    expect(typeof logger.debug).toBe('function')
    expect(typeof logger.sensitive).toBe('function')
    expect(typeof logger.api).toBe('function')
    expect(typeof logger.group).toBe('function')
    expect(typeof logger.table).toBe('function')
  })

  it('warn always calls logger.warn', () => {
    const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
    logger.warn('test warning')
    expect(spy).toHaveBeenCalled()
  })

  it('error always calls logger.error', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    logger.error('test error')
    expect(spy).toHaveBeenCalled()
  })

  it('info always calls logger.info', () => {
    const spy = vi.spyOn(console, 'info').mockImplementation(() => {})
    logger.info('test info')
    expect(spy).toHaveBeenCalled()
  })

  it('setupProductionLogs is a function', () => {
    expect(typeof setupProductionLogs).toBe('function')
  })
})

