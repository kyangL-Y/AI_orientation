/**
 * 日志工具 - 用于控制和过滤控制台日志
 *
 * 功能：
 * 1. 生产环境只显示重要日志（warn、error、关键info）
 * 2. 过滤敏感信息（验证码、手机号、邮箱、密码、token等）
 * 3. 提供统一的日志接口
 *
 * 日志级别：
 * - error: 错误信息（始终显示）
 * - warn: 警告信息（始终显示）
 * - info: 重要信息（始终显示，带 ✅❌🔔 等标记）
 * - log: 普通日志（仅开发环境显示）
 * - debug: 调试日志（仅开发环境显示）
 */

const isDevelopment = (() => {
  try {
    if (typeof import.meta !== 'undefined' && import.meta.env) return !!import.meta.env.DEV
  } catch {}
  return typeof process !== 'undefined' && process.env && process.env.NODE_ENV === 'development'
})()

function getRuntimeConsole() {
  if (typeof globalThis !== 'undefined' && globalThis.console) {
    return globalThis.console
  }

  return {
    log: () => {},
    warn: () => {},
    error: () => {},
    info: () => {},
    debug: () => {},
    group: () => {},
    groupEnd: () => {},
    table: () => {}
  }
}

function callConsole(method, ...args) {
  const runtimeConsole = getRuntimeConsole()
  const fn = runtimeConsole[method]
  if (typeof fn === 'function') {
    fn.apply(runtimeConsole, args)
  }
}

// 敏感信息关键词列表
const SENSITIVE_KEYWORDS = [
  '验证码', 'code', 'captcha', 'verification',
  '手机', 'phone', 'mobile', 'tel',
  '邮箱', 'email', 'mail',
  '密码', 'password', 'pwd',
  'token', 'authorization', 'auth',
  'secret', 'key', 'credential'
]

// 敏感字段名（用于对象过滤）
const SENSITIVE_FIELDS = [
  'password', 'pwd', 'token', 'authorization', 'auth',
  'secret', 'key', 'credential', 'code', 'captcha',
  'phone', 'mobile', 'email', 'idCard', 'bankCard'
]

/**
 * 检查内容是否包含敏感信息
 */
function containsSensitiveInfo(content) {
  if (typeof content !== 'string') {
    try {
      content = JSON.stringify(content)
    } catch (e) {
      return false
    }
  }

  return SENSITIVE_KEYWORDS.some(keyword =>
    content.toLowerCase().includes(keyword.toLowerCase())
  )
}

/**
 * 深度过滤对象中的敏感字段
 */
function filterSensitiveFields(obj, depth = 0) {
  if (depth > 5) return obj // 防止无限递归
  if (obj === null || obj === undefined) return obj
  if (typeof obj !== 'object') return obj

  if (Array.isArray(obj)) {
    return obj.map(item => filterSensitiveFields(item, depth + 1))
  }

  const filtered = {}
  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase()
    if (SENSITIVE_FIELDS.some(field => lowerKey.includes(field))) {
      filtered[key] = '***'
    } else if (typeof value === 'object' && value !== null) {
      filtered[key] = filterSensitiveFields(value, depth + 1)
    } else {
      filtered[key] = value
    }
  }
  return filtered
}

/**
 * 过滤敏感信息
 */
function filterSensitiveInfo(arg) {
  if (typeof arg === 'string') {
    // 过滤手机号
    arg = arg.replace(/1[3-9]\d{9}/g, (match) => match.slice(0, 3) + '****' + match.slice(7))
    // 过滤邮箱
    arg = arg.replace(/[\w.-]+@[\w.-]+\.\w+/g, (match) => {
      const [name, domain] = match.split('@')
      return name.slice(0, 2) + '***@' + domain
    })
    return arg
  }
  if (typeof arg === 'object' && arg !== null) {
    try {
      return filterSensitiveFields(arg)
    } catch (e) {
      return '[对象]'
    }
  }
  return arg
}

/**
 * 格式化日志时间
 */
function getTimestamp() {
  const now = new Date()
  return now.toLocaleTimeString('zh-CN', { hour12: false }) + '.' + String(now.getMilliseconds()).padStart(3, '0')
}

/**
 * 日志对象 - 生产环境友好版本
 */
const logger = {
  // 普通日志 - 仅开发环境显示
  log: (...args) => {
    if (isDevelopment) {
      callConsole('log', `[${getTimestamp()}]`, ...args.map(filterSensitiveInfo))
    }
  },

  // 警告日志 - 始终显示（黄色）
  warn: (...args) => {
    callConsole('warn', `[${getTimestamp()}] ⚠️`, ...args.map(filterSensitiveInfo))
  },

  // 错误日志 - 始终显示（红色）
  error: (...args) => {
    callConsole('error', `[${getTimestamp()}] ❌`, ...args.map(filterSensitiveInfo))
  },

  // 重要信息 - 始终显示（带图标的关键日志）
  info: (...args) => {
    callConsole('info', `[${getTimestamp()}] ℹ️`, ...args.map(filterSensitiveInfo))
  },

  // 成功日志 - 始终显示
  success: (...args) => {
    callConsole('log', `[${getTimestamp()}] ✅`, ...args.map(filterSensitiveInfo))
  },

  // 调试日志 - 仅开发环境
  debug: (...args) => {
    if (isDevelopment) {
      callConsole('log', `[${getTimestamp()}] 🔍 DEBUG:`, ...args.map(filterSensitiveInfo))
    }
  },

  // 敏感信息日志 - 仅开发环境，且会被过滤
  sensitive: (...args) => {
    if (isDevelopment) {
      callConsole('log', `[${getTimestamp()}] 🔒 SENSITIVE:`, ...args.map(filterSensitiveInfo))
    }
  },

  // API请求日志 - 仅开发环境
  api: (method, url, data) => {
    if (isDevelopment) {
      callConsole('log', `[${getTimestamp()}] 🌐 ${method.toUpperCase()} ${url}`, data ? filterSensitiveInfo(data) : '')
    }
  },

  // 分组日志 - 用于复杂数据展示
  group: (title, fn) => {
    if (isDevelopment) {
      callConsole('group', `[${getTimestamp()}] 📁 ${title}`)
      fn()
      callConsole('groupEnd')
    }
  },

  // 表格日志 - 用于数组/对象展示
  table: (data, title) => {
    if (isDevelopment) {
      if (title) callConsole('log', `[${getTimestamp()}] 📊 ${title}`)
      callConsole('table', filterSensitiveInfo(data))
    }
  }
}

/**
 * 生产环境日志控制
 * 重写 console 方法，只保留重要日志
 */
export function setupProductionLogs() {
  const runtimeConsole = getRuntimeConsole()

  if (isDevelopment) {
    callConsole('info', '🔧 开发环境：所有日志已启用')
    return
  }

  // 保存原始方法
  const originalConsole = {
    log: typeof runtimeConsole.log === 'function' ? runtimeConsole.log.bind(runtimeConsole) : () => {},
    warn: typeof runtimeConsole.warn === 'function' ? runtimeConsole.warn.bind(runtimeConsole) : () => {},
    error: typeof runtimeConsole.error === 'function' ? runtimeConsole.error.bind(runtimeConsole) : () => {},
    info: typeof runtimeConsole.info === 'function' ? runtimeConsole.info.bind(runtimeConsole) : () => {},
    debug: typeof runtimeConsole.debug === 'function' ? runtimeConsole.debug.bind(runtimeConsole) : () => {}
  }

  // 保存到 window 供紧急调试使用
  if (typeof window !== 'undefined') {
    window.__originalConsole = originalConsole
    window.__restoreConsole = () => {
      runtimeConsole.log = originalConsole.log
      runtimeConsole.warn = originalConsole.warn
      runtimeConsole.error = originalConsole.error
      runtimeConsole.info = originalConsole.info
      runtimeConsole.debug = originalConsole.debug
      originalConsole.log('✅ 控制台日志已完全恢复')
    }
  }

  // 重写 log - 生产环境完全禁用
  runtimeConsole.log = () => {}

  // warn 和 error 始终显示
  runtimeConsole.warn = (...args) => {
    originalConsole.warn(...args.map(filterSensitiveInfo))
  }

  runtimeConsole.error = (...args) => {
    originalConsole.error(...args.map(filterSensitiveInfo))
  }

  // info - 生产环境禁用
  runtimeConsole.info = () => {}

  // debug - 生产环境禁用
  runtimeConsole.debug = () => {}

  // 静默提示，只显示恢复方法
  originalConsole.log('%cwindow.__restoreConsole()', 'color: #999; font-size: 10px;')
}

/**
 * 禁用所有控制台日志（完全静默模式）
 */
export function disableConsoleLogs() {
  const runtimeConsole = getRuntimeConsole()

  if (isDevelopment) {
    callConsole('warn', '⚠️ 开发环境不应禁用控制台日志，跳过执行')
    return
  }

  const noop = () => {}

  if (typeof window !== 'undefined') {
    window.__originalConsole = {
      log: typeof runtimeConsole.log === 'function' ? runtimeConsole.log.bind(runtimeConsole) : () => {},
      warn: typeof runtimeConsole.warn === 'function' ? runtimeConsole.warn.bind(runtimeConsole) : () => {},
      error: typeof runtimeConsole.error === 'function' ? runtimeConsole.error.bind(runtimeConsole) : () => {},
      info: typeof runtimeConsole.info === 'function' ? runtimeConsole.info.bind(runtimeConsole) : () => {},
      debug: typeof runtimeConsole.debug === 'function' ? runtimeConsole.debug.bind(runtimeConsole) : () => {}
    }

    window.__restoreConsole = () => {
      if (window.__originalConsole) {
        runtimeConsole.log = window.__originalConsole.log
        runtimeConsole.warn = window.__originalConsole.warn
        runtimeConsole.error = window.__originalConsole.error
        runtimeConsole.info = window.__originalConsole.info
        runtimeConsole.debug = window.__originalConsole.debug
        callConsole('log', '✅ 控制台日志已恢复')
      }
    }
  }

  runtimeConsole.log = noop
  runtimeConsole.warn = noop
  runtimeConsole.error = noop
  runtimeConsole.info = noop
  runtimeConsole.debug = noop

  if (typeof window !== 'undefined' && window.__originalConsole) {
    window.__originalConsole.info('🔒 生产环境：控制台日志已完全禁用')
    window.__originalConsole.info('如需调试，请输入: window.__restoreConsole()')
  }
}

export default logger
