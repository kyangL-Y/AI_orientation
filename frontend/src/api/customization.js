import { api } from '@/utils/api'

/**
 * 获取定制化配置
 */
export const getCustomization = (tenantId) => {
  const params = tenantId ? { tenantId } : undefined
  return api.get('/open/customization/default-config', { params })
}

/**
 * 获取默认定制化配置（未登录用户）
 */
export const getDefaultCustomization = (tenantId) => {
  const params = tenantId ? { tenantId } : undefined
  return api.get('/open/customization/default-config', { params })
}

/**
 * 获取当前用户所属租户的定制化配置（已登录用户）
 */
export const getMyCustomization = () => {
  return api.get('/system/customization/my-config')
}
