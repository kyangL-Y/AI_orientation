import axios from 'axios'

/**
 * 获取公开的通知公告列表
 * @param {string} tenantId 租户ID（可选）
 * @param {number} deptId 部门ID（可选）
 * @param {number} companyId 公司ID（可选）
 */
export function getPublicNoticeList(tenantId, deptId, companyId) {
  const params = {}
  if (tenantId) params.tenantId = tenantId
  if (deptId) params.deptId = deptId
  if (companyId) params.companyId = companyId
  // 使用相对路径，走 nginx 代理
  return axios.get('/system/notice/public/list', { params })
}

/**
 * 获取公开的通知公告详情
 * @param {number} noticeId 公告ID
 */
export function getPublicNoticeDetail(noticeId) {
  return axios.get(`/system/notice/public/${noticeId}`)
}
