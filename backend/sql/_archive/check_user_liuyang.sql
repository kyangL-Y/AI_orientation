-- 检查用户刘洋的信息
USE `hz-vue`;

SELECT 
    u.user_id,
    u.user_name,
    u.nick_name,
    u.dept_id,
    d.dept_name,
    d.parent_id,
    u.tenant_id
FROM sys_user u
LEFT JOIN sys_dept d ON u.dept_id = d.dept_id
WHERE u.nick_name = '刘洋'
LIMIT 5;
