import { api } from '@/utils/api'

// 查询会员等级列表
export function listMembershipLevels(query) {
  return api.get('/train/membership/level/list', { params: query })
}

// 获取所有可用会员等级 (公开接口)
export function getActiveLevels() {
  return api.get('/train/membership/level/active')
}

// 获取会员等级详细信息
export function getMembershipLevel(levelId) {
  return api.get('/train/membership/level/' + levelId)
}

// 获取当前用户会员信息
export function getMyMembership() {
  return api.get('/train/membership/user/info')
}

// 获取会员限制配置（后端统一下发）
export function getMembershipUsageLimits() {
  return api.get('/train/membership/user/limits')
}

// 检查当前用户是否有权限访问内容
export function checkContentAccess(contentType, contentId) {
  return api.get('/train/membership/user/check-access', { params: { contentType, contentId } })
}

// 创建B2B订单
export function createB2BOrder(data) {
  return api.post('/train/membership/purchase/create-b2b', data)
}

// 模拟支付
export function payOrder(data) {
  return api.post('/train/membership/purchase/pay', data)
}
