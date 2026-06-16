import { api } from '@/utils/api'
import { getUserId } from '@/utils/userStorage'

// 查询商品列表
export function getShopItemList(query) {
  return api({
    url: '/train/shop/list',
    method: 'get',
    params: query
  }).then(res => res.data)
}

// 兑换商品
export function redeemItem(itemId) {
  return api({
    url: '/train/shop/redeem',
    method: 'post',
    data: { itemId }
  }).then(res => res.data)
}

// 查询我的兑换记录
export function getMyOrders(query) {
  return api({
    url: '/train/shop/my-orders',
    method: 'get',
    params: query
  }).then(res => res.data)
}

// 查询我的积分明细
export function getMyPointsLog(query) {
  const userId = getUserId()
  return api({
    url: '/train/points/my-log',
    method: 'get',
    params: { ...query, userId }
  }).then(res => res.data)
}

// 获取积分规则
export function getPointsRules() {
  return api({
    url: '/train/points/rules',
    method: 'get'
  }).then(res => res.data)
}

// 获取我的积分
export function getMyPoints() {
  return api({
    url: '/train/shop/my-points',
    method: 'get'
  }).then(res => res.data)
}
