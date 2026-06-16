import logger from '@/utils/logger'
import { getUserInfo, setUserInfo } from '@/utils/userStorage'

const TENANT_CUSTOMIZATION_KEY = 'tenantCustomization'
const TENANT_ID_KEYS = ['tenant_id', 'tenantId']
const TENANT_COOKIE_NAME = 'Tenant-Id'

function safeParseJSON(value) {
  if (!value || typeof value !== 'string') return null

  try {
    return JSON.parse(value)
  } catch (error) {
    logger.warn('解析租户上下文失败，已忽略损坏缓存:', error)
    return null
  }
}

function normalizeTenantId(value) {
  if (value === null || value === undefined) return ''
  const normalized = String(value).trim()
  return normalized
}

function readLocalStorage(key) {
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}

function writeLocalStorage(key, value) {
  try {
    localStorage.setItem(key, value)
  } catch (error) {
    logger.warn(`写入租户上下文失败 [${key}]`, error)
  }
}

function removeLocalStorage(key) {
  try {
    localStorage.removeItem(key)
  } catch (error) {
    logger.warn(`清理租户上下文失败 [${key}]`, error)
  }
}

function writeTenantCookie(tenantId) {
  if (typeof document === 'undefined') return
  document.cookie = `${encodeURIComponent(TENANT_COOKIE_NAME)}=${encodeURIComponent(tenantId)}; path=/; SameSite=Lax`
}

function clearTenantCookie() {
  if (typeof document === 'undefined') return
  document.cookie = `${encodeURIComponent(TENANT_COOKIE_NAME)}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; SameSite=Lax`
}

export function getTenantCookieValue() {
  try {
    if (typeof document === 'undefined' || !document.cookie) return ''
    const encodedName = `${encodeURIComponent(TENANT_COOKIE_NAME)}=`
    const parts = document.cookie.split(';')
    for (const part of parts) {
      const trimmed = part.trim()
      if (trimmed.startsWith(encodedName)) {
        return decodeURIComponent(trimmed.substring(encodedName.length))
      }
    }
  } catch {}

  return ''
}

export function extractTenantId(source) {
  if (!source || typeof source !== 'object') return ''

  return normalizeTenantId(
    source.tenantId ||
    source.tenant_id ||
    source.user?.tenantId ||
    source.user?.tenant_id ||
    source.data?.tenantId ||
    source.data?.tenant_id
  )
}

export function normalizeTenantCustomization(customization, fallbackTenantId = '') {
  if (!customization || typeof customization !== 'object') return null

  const tenantId = normalizeTenantId(extractTenantId(customization) || fallbackTenantId)
  const normalized = { ...customization }

  if (tenantId) {
    normalized.tenantId = tenantId
    normalized.tenant_id = tenantId
  }

  return normalized
}

export function getStoredTenantCustomization() {
  const stored = readLocalStorage(TENANT_CUSTOMIZATION_KEY)
  return normalizeTenantCustomization(safeParseJSON(stored))
}

export function getTenantId() {
  const candidates = [
    getTenantCookieValue(),
    ...TENANT_ID_KEYS.map((key) => readLocalStorage(key)),
    extractTenantId(getStoredTenantCustomization()),
    extractTenantId(getUserInfo())
  ]

  for (const candidate of candidates) {
    const normalized = normalizeTenantId(candidate)
    if (normalized) return normalized
  }

  return ''
}

export function setTenantId(tenantId) {
  const normalized = normalizeTenantId(tenantId)
  if (!normalized) {
    clearTenantId()
    return ''
  }

  TENANT_ID_KEYS.forEach((key) => writeLocalStorage(key, normalized))
  writeTenantCookie(normalized)
  return normalized
}

export function clearTenantId() {
  TENANT_ID_KEYS.forEach(removeLocalStorage)
  clearTenantCookie()
}

export function hasBrandingPayload(customization) {
  if (!customization || typeof customization !== 'object') return false

  const keys = [
    'logoUrl',
    'companyName',
    'pageTitle',
    'themeColor',
    'welcomeMessage',
    'customCss',
    'hotelPageContent',
    'customPagesConfig'
  ]

  return keys.some((key) => {
    const value = customization[key]
    if (typeof value === 'string') return value.trim() !== ''
    return value !== null && value !== undefined && value !== false
  })
}

export function mergeTenantCustomization(currentCustomization, nextCustomization, fallbackTenantId = '') {
  const current = normalizeTenantCustomization(currentCustomization)
  const next = normalizeTenantCustomization(nextCustomization, fallbackTenantId)

  if (!next) return current
  if (!current) return next

  const currentTenantId = extractTenantId(current)
  const nextTenantId = extractTenantId(next)

  if (currentTenantId && nextTenantId && currentTenantId !== nextTenantId) {
    return next
  }

  const merged = { ...current }
  for (const [key, value] of Object.entries(next)) {
    if (value === null || value === undefined) continue
    if (typeof value === 'string' && value.trim() === '') continue
    merged[key] = value
  }

  if (nextTenantId) {
    merged.tenantId = nextTenantId
    merged.tenant_id = nextTenantId
  }

  return merged
}

export function setTenantCustomization(customization, options = {}) {
  const { merge = true, tenantId = '' } = options
  const current = getStoredTenantCustomization()
  const next = merge
    ? mergeTenantCustomization(current, customization, tenantId)
    : normalizeTenantCustomization(customization, tenantId)

  if (!next) return null

  const resolvedTenantId = extractTenantId(next)
  if (resolvedTenantId) {
    setTenantId(resolvedTenantId)
  }

  writeLocalStorage(TENANT_CUSTOMIZATION_KEY, JSON.stringify(next))
  return next
}

export function clearTenantCustomization() {
  removeLocalStorage(TENANT_CUSTOMIZATION_KEY)
}

export function syncTenantContextFromUser(userInfo, options = {}) {
  const { persistUser = false } = options

  if (persistUser && userInfo && typeof userInfo === 'object') {
    setUserInfo(userInfo)
  }

  const tenantId = extractTenantId(userInfo)
  if (tenantId) {
    setTenantId(tenantId)
  }

  return tenantId
}

export function clearTenantContext(options = {}) {
  const { preserveAuthToken = false, preserveUserInfo = false } = options

  clearTenantCustomization()
  clearTenantId()

  if (!preserveAuthToken) {
    removeLocalStorage('authToken')
  }

  if (!preserveUserInfo) {
    removeLocalStorage('userInfo')
  }
}
