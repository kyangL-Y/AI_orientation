-- 添加 AI 对话历史清理定时任务（幂等）
-- 每天凌晨 2 点执行，清理超过 30 天的历史记录

INSERT INTO sys_job (
  job_name,
  job_group,
  invoke_target,
  cron_expression,
  misfire_policy,
  concurrent,
  status,
  create_by,
  create_time,
  remark
)
SELECT
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
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1
  FROM sys_job
  WHERE invoke_target = 'aiChatHistoryCleanTask.cleanExpiredHistory'
);
