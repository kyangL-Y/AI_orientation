-- 检查用户刘洋的租户ID
-- 在主库 hz-vue 执行

SELECT 
    user_id,
    user_name,
    dept_id,
    tenant_id,
    status
FROM sys_user
WHERE user_name = '刘洋';

-- 检查部门的租户ID
SELECT 
    d.dept_id,
    d.dept_name,
    d.tenant_id,
    d.status
FROM sys_dept d
WHERE d.dept_id IN (
    SELECT dept_id FROM sys_user WHERE user_name = '刘洋'
);
