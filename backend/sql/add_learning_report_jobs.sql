-- 学习报告定时生成任务注册
-- 周报：每周一凌晨3点
INSERT INTO sys_job (job_name, job_group, invoke_target, cron_expression, misfire_policy, concurrent, status, create_by, create_time, remark)
VALUES ('学习周报生成', 'DEFAULT', 'learningReportTask.generate(''weekly'')', '0 0 3 ? * MON', '3', '1', '1', 'admin', NOW(), '每周一凌晨3点自动生成上周学习报告');

-- 月报：每月1日凌晨3点
INSERT INTO sys_job (job_name, job_group, invoke_target, cron_expression, misfire_policy, concurrent, status, create_by, create_time, remark)
VALUES ('学习月报生成', 'DEFAULT', 'learningReportTask.generate(''monthly'')', '0 0 3 1 * ?', '3', '1', '1', 'admin', NOW(), '每月1日凌晨3点自动生成上月学习报告');

-- 季报：每季度第一天凌晨3点（1月/4月/7月/10月）
INSERT INTO sys_job (job_name, job_group, invoke_target, cron_expression, misfire_policy, concurrent, status, create_by, create_time, remark)
VALUES ('学习季报生成', 'DEFAULT', 'learningReportTask.generate(''quarterly'')', '0 0 3 1 1,4,7,10 ?', '3', '1', '1', 'admin', NOW(), '每季度第一天凌晨3点自动生成上季度学习报告');
