-- 调整数据同步定时任务频率
-- 日期: 2026-01-23
-- 目的: 减少频繁的数据源切换日志

USE hz-vue;

-- 方案1: 改为每小时执行一次（推荐）
UPDATE sys_job 
SET cron_expression = '0 0 * * * ?'  -- 每小时整点执行
WHERE job_id IN (100, 101, 102);

-- 方案2: 改为每30分钟执行一次
-- UPDATE sys_job 
-- SET cron_expression = '0 0/30 * * * ?'  -- 每30分钟执行
-- WHERE job_id IN (100, 101, 102);

-- 方案3: 改为每天凌晨2点执行一次（如果数据不需要实时同步）
-- UPDATE sys_job 
-- SET cron_expression = '0 0 2 * * ?'  -- 每天凌晨2点执行
-- WHERE job_id IN (100, 101, 102);

-- 查看修改后的配置
SELECT 
    job_id, 
    job_name, 
    cron_expression,
    status,
    CASE status 
        WHEN '0' THEN '正常'
        WHEN '1' THEN '暂停'
    END as status_desc
FROM sys_job 
WHERE job_id IN (100, 101, 102, 103, 4);
