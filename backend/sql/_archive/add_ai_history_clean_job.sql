-- 添加AI对话历史清理定时任务
-- 每天凌晨2点执行，清理30天前的对话记录

INSERT INTO `sys_job` (
  `job_name`, 
  `job_group`, 
  `invoke_target`, 
  `cron_expression`, 
  `misfire_policy`, 
  `concurrent`, 
  `status`, 
  `create_by`, 
  `create_time`, 
  `remark`
) VALUES (
  'AI对话历史清理', 
  'DEFAULT', 
  'aiChatHistoryCleanTask.cleanExpiredHistory', 
  '0 0 2 * * ?', 
  '3', 
  '1', 
  '0', 
  'admin', 
  NOW(), 
  '每天凌晨2点清理30天前的AI对话历史记录'
);
