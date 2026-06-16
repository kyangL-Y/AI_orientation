import { api } from '@/utils/api'

// 生成学习报告
export function generateReport(params) {
  return api({
    url: '/train/user/report/generate',
    method: 'post',
    params
  }).then(res => res.data)
}

// 获取最新报告
export function getLatestReport(params) {
  return api({
    url: '/train/user/report/latest',
    method: 'get',
    params
  }).then(res => res.data)
}

// 查询我的报告列表
export function listMyReports(params) {
  return api({
    url: '/train/user/report/list',
    method: 'get',
    params
  }).then(res => res.data)
}

// 获取报告详情
export function getReportDetail(reportId) {
  return api({
    url: '/train/user/report/' + reportId,
    method: 'get'
  }).then(res => res.data)
}
