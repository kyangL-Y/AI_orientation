-- 诊断用户15666666666登录权限问题
-- 执行时间: 2026-01-27

USE `hz-vue`;

-- 1. 检查用户基本信息和状态
SELECT 
    user_id,
    user_name,
    phonenumber,
    status as user_status,
    del_flag,
    '用户基本信息' as description
FROM sys_user
WHERE phonenumber = '15666666666';

-- 2. 检查用户的角色分配
SELECT 
    u.user_id,
    u.user_name,
    ur.role_id,
    r.role_name,
    r.role_key,
    r.status as role_status,
    r.del_flag as role_del_flag,
    '用户角色分配' as description
FROM sys_user u
LEFT JOIN sys_user_role ur ON u.user_id = ur.user_id
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE u.phonenumber = '15666666666';

-- 3. 检查角色的菜单权限数量
SELECT 
    r.role_id,
    r.role_name,
    COUNT(rm.menu_id) as menu_count,
    '角色菜单权限数量' as description
FROM sys_role r
LEFT JOIN sys_role_menu rm ON r.role_id = rm.role_id
WHERE r.role_id IN (
    SELECT role_id FROM sys_user_role WHERE user_id = (
        SELECT user_id FROM sys_user WHERE phonenumber = '15666666666'
    )
)
GROUP BY r.role_id, r.role_name;

-- 4. 检查用户可访问的菜单（包括状态）
SELECT 
    m.menu_id,
    m.menu_name,
    m.parent_id,
    m.menu_type,
    m.visible,
    m.status,
    '用户可访问菜单' as description
FROM sys_user u
JOIN sys_user_role ur ON u.user_id = ur.user_id
JOIN sys_role_menu rm ON ur.role_id = rm.role_id
JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE u.phonenumber = '15666666666'
  AND m.parent_id = 0
ORDER BY m.order_num;

-- 5. 检查是否有停用的菜单
SELECT 
    COUNT(*) as disabled_menu_count,
    '停用的菜单数量' as description
FROM sys_user u
JOIN sys_user_role ur ON u.user_id = ur.user_id
JOIN sys_role_menu rm ON ur.role_id = rm.role_id
JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE u.phonenumber = '15666666666'
  AND m.status = '1';

-- 6. 检查用户的部门信息
SELECT 
    u.user_id,
    u.user_name,
    u.dept_id,
    d.dept_name,
    d.status as dept_status,
    d.del_flag as dept_del_flag,
    '用户部门信息' as description
FROM sys_user u
LEFT JOIN sys_dept d ON u.dept_id = d.dept_id
WHERE u.phonenumber = '15666666666';

-- 7. 检查是否有数据权限限制
SELECT 
    r.role_id,
    r.role_name,
    r.data_scope,
    '角色数据权限范围' as description
FROM sys_role r
WHERE r.role_id IN (
    SELECT role_id FROM sys_user_role WHERE user_id = (
        SELECT user_id FROM sys_user WHERE phonenumber = '15666666666'
    )
);

-- 8. 检查用户token或登录记录
SELECT 
    user_id,
    user_name,
    ipaddr,
    login_time,
    status as login_status,
    msg,
    '最近登录记录' as description
FROM sys_logininfor
WHERE user_name = '若依' OR user_name = '15666666666'
ORDER BY login_time DESC
LIMIT 5;
