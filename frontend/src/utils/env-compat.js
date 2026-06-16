import logger from '@/utils/logger';
/**
 * 环境变量兼容层
 * 确保 Vue CLI (VUE_APP_) 和 Vite (VITE_) 环境变量的无缝过渡
 * 优先使用 VITE_，fallback 到 VUE_APP_，保证向后兼容
 */

// 获取所有环境变量（Vite 优先，其次兼容 Vue CLI）
const env = {
  ...(typeof import.meta !== 'undefined' && import.meta.env ? import.meta.env : {}),
  ...(typeof process !== 'undefined' && process.env ? process.env : {}),
}

// 存储迁移警告的记录，避免重复警告
const warnedKeys = new Set()

/**
 * 获取环境变量，支持 VITE_ 和 VUE_APP_ 前缀
 * @param {string} key - 不含前缀的环境变量键名
 * @param {string} defaultValue - 默认值
 * @returns {string} 环境变量值
 */
export function getEnv(key, defaultValue = '') {
  const viteKey = `VITE_${key}`
  const vueKey = `VUE_APP_${key}`

  // 优先使用 VITE_ 前缀
  if (env[viteKey] !== undefined) {
    // 如果同时存在 VUE_APP_ 且值不同，发出迁移警告
    if (env[vueKey] !== undefined && env[vueKey] !== env[viteKey] && !warnedKeys.has(key)) {
      logger.warn(
        `%c[env-compat] ⚠️ 环境变量冲突检测`,
        'color: #ff9800; font-weight: bold',
        `\n  检测到同时存在 VITE_${key} 和 VUE_APP_${key}`,
        `\n  VITE_${key} = ${env[viteKey]} (已采用)`,
        `\n  VUE_APP_${key} = ${env[vueKey]} (已忽略)`,
        `\n  建议: 移除 VUE_APP_${key}，统一使用 VITE_${key}`
      )
      warnedKeys.add(key)
    }
    return env[viteKey]
  }

  // Fallback 到 VUE_APP_ 前缀
  if (env[vueKey] !== undefined) {
    // 发出迁移提示
    if (!warnedKeys.has(key)) {
      logger.info(
        `%c[env-compat] 📦 迁移提示`,
        'color: #2196f3; font-weight: bold',
        `\n  正在使用 VUE_APP_${key} = ${env[vueKey]}`,
        `\n  建议: 创建 VITE_${key} 并设置相同值，然后移除 VUE_APP_${key}`,
        `\n  这有助于 Vue CLI 到 Vite 的平滑迁移`
      )
      warnedKeys.add(key)
    }
    return env[vueKey]
  }

  // 返回默认值
  return defaultValue
}

/**
 * 批量获取环境变量对象
 * @param {Object} config - 配置对象
 * @param {Array<string>} config.keys - 需要获取的键名数组
 * @param {Object} config.defaults - 默认值对象
 * @returns {Object} 环境变量对象
 */
export function getEnvObject({ keys = [], defaults = {} } = {}) {
  const result = {}

  keys.forEach(key => {
    result[key] = getEnv(key, defaults[key])
  })

  return result
}

/**
 * 导出兼容的环境变量对象
 * 常用环境变量的快捷访问
 */
export const compatEnv = {
  // API 相关
  API_BASE_URL: getEnv('API_BASE_URL'),
  API_TIMEOUT: getEnv('API_TIMEOUT', '10000'),

  // 应用配置
  APP_TITLE: getEnv('APP_TITLE', 'Training Agent'),
  APP_VERSION: getEnv('APP_VERSION'),

  // 功能开关
  ENABLE_MOCK: getEnv('ENABLE_MOCK', 'false') === 'true',
  ENABLE_DEBUG: getEnv('ENABLE_DEBUG', 'false') === 'true',

  // 第三方服务
  GOOGLE_ANALYTICS_ID: getEnv('GOOGLE_ANALYTICS_ID'),
  SENTRY_DSN: getEnv('SENTRY_DSN'),

  // 自定义配置
  ...getEnvObject({
    keys: [
      'ENVIRONMENT',
      'BASE_URL',
      'MODE',
      'NODE_ENV'
    ]
  })
}

/**
 * 检查是否存在冲突的环境变量
 * @returns {Array<string>} 冲突的键名列表
 */
export function checkConflicts() {
  const conflicts = []
  const viteKeys = Object.keys(env).filter(key => key.startsWith('VITE_'))

  viteKeys.forEach(viteKey => {
    const key = viteKey.replace('VITE_', '')
    const vueKey = `VUE_APP_${key}`

    if (env[vueKey] !== undefined && env[vueKey] !== env[viteKey]) {
      conflicts.push(key)
    }
  })

  return conflicts
}

/**
 * 打印迁移报告
 */
export function printMigrationReport() {
  logger.debug('%c[env-compat] 📊 迁移状态报告', 'color: #4caf50; font-weight: bold')

  // 统计环境变量
  const viteCount = Object.keys(env).filter(key => key.startsWith('VITE_')).length
  const vueCount = Object.keys(env).filter(key => key.startsWith('VUE_APP_')).length

  logger.debug(`Vite 变量 (VITE_): ${viteCount} 个`)
  logger.debug(`Vue CLI 变量 (VUE_APP_): ${vueCount} 个`)

  // 检查冲突
  const conflicts = checkConflicts()
  if (conflicts.length > 0) {
    logger.warn(`⚠️ 发现 ${conflicts.length} 个冲突:`, conflicts)
  } else {
    logger.debug('✅ 未发现冲突')
  }

  // 进度提示
  const total = viteCount + vueCount
  const migrationProgress = total > 0 ? Math.round((viteCount / total) * 100) : 100
  logger.debug(`📈 迁移进度: ${migrationProgress}% (${viteCount}/${total})`)

  logger.debug()
}

// 开发环境下自动打印报告
const isDev = (() => {
  try {
    if (typeof import.meta !== 'undefined' && import.meta.env) return !!import.meta.env.DEV
  } catch {}
  return env.NODE_ENV === 'development'
})()

if (isDev) {
  // 延迟执行，确保在主应用之后打印
  setTimeout(() => {
    printMigrationReport()
  }, 100)
}

// 默认导出兼容环境对象
export default compatEnv

