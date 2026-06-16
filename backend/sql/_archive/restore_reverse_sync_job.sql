-- 重新创建反向同步定时任务
-- 删除可能存在的旧任务记录
DELETE FROM sys_job WHERE job_name = '从库到主库数据反向同步';

-- 插入反向同步定时任务
INSERT INTO sys_job (
    job_id, 
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
) VALUES (
    4,
    '从库到主库数据反向同步',
    'DEFAULT',
    'trainSyncTask.syncDeptsToMaster',
    '0 0 2 * * ?',
    '2',
    '1', 
    '1',
    'admin',
    sysdate(),
    '将从库train_depts_ref表数据同步到主库sys_dept表，每天凌晨2点执行'
);

-- 验证任务是否创建成功
SELECT job_id, job_name, job_group, invoke_target, cron_expression, status, remark 
FROM sys_job 
WHERE job_name = '从库到主库数据反向同步';