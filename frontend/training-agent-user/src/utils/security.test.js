/**
 * security.js 单元测试
 *
 * 在 node 环境下测试 escapeHtml 和 sanitizeHtml 的 fallback 行为。
 * sanitizeHtml 在无 DOMParser 时回退到 escapeHtml。
 */
import { describe, it, expect } from 'vitest'
import { escapeHtml, sanitizeHtml } from './security'

describe('escapeHtml', () => {
  it('escapes & < > " \'', () => {
    expect(escapeHtml('&<>"\'')).toBe('&amp;&lt;&gt;&quot;&#39;')
  })

  it('returns empty string for null/undefined', () => {
    expect(escapeHtml(null)).toBe('')
    expect(escapeHtml(undefined)).toBe('')
  })

  it('converts numbers to string', () => {
    expect(escapeHtml(123)).toBe('123')
  })

  it('handles empty string', () => {
    expect(escapeHtml('')).toBe('')
  })

  it('preserves safe text', () => {
    expect(escapeHtml('Hello World')).toBe('Hello World')
  })

  it('escapes script tags', () => {
    const input = '<script>alert("xss")</script>'
    const result = escapeHtml(input)
    expect(result).not.toContain('<script>')
    expect(result).toContain('&lt;script&gt;')
  })

  it('escapes nested HTML', () => {
    const input = '<div onclick="alert(1)">text</div>'
    const result = escapeHtml(input)
    expect(result).not.toContain('<div')
    expect(result).toContain('&lt;div')
  })
})

describe('sanitizeHtml (node fallback)', () => {
  it('falls back to escapeHtml in node environment', () => {
    const input = '<b>bold</b>'
    // In node, no DOMParser → falls back to escapeHtml
    expect(sanitizeHtml(input)).toBe('&lt;b&gt;bold&lt;/b&gt;')
  })

  it('returns empty string for falsy values', () => {
    expect(sanitizeHtml('')).toBe('')
    expect(sanitizeHtml(null)).toBe('')
    expect(sanitizeHtml(undefined)).toBe('')
  })

  it('escapes XSS payloads in fallback mode', () => {
    const xss = '<img src=x onerror=alert(1)>'
    const result = sanitizeHtml(xss)
    // In node fallback, escapeHtml escapes all angle brackets
    expect(result).not.toContain('<img')
    expect(result).toContain('&lt;img')
    // The tag is fully escaped, so even though 'onerror' text exists,
    // it cannot execute as an attribute
    expect(result).not.toContain('<')
    expect(result).not.toContain('>')
  })
})
