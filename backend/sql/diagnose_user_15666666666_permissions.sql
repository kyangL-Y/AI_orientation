-- 诊断用户15666666666的权限问题

USE hz-vue;

-- 1. 查看用户基本信息
SELECT 
    user_id,
    user_name,
    phonenumber,
    status,
    admin_type,
    admin_level,
    del_flag,
    create_time,
    update_time
FROM sys_user 
WHERE phonenumber = '15666666666';

-- 2. 查看用户角色关联
SELECT 
    u.user_id,
    u.user_name,
    u.phonenumber,
    ur.role_id,
    r.role_name,
    r.role_key,
    r.status as role_status,
    r.del_flag as role_del_flag
FROM sys_user u
LEFT JOIN sys_user_role ur ON u.user_id = ur.user_id
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE u.phonenumber = '15666666666';

-- 3. 查看角色权限（如果有角色）
SELECT DISTINCT
    r.role_name,
    m.menu_name,
    m.perms,
    m.menu_type,
    m.status as menu_status
FROM sys_user u
JOIN sys_user_role ur ON u.user_id = ur.user_id
JOIN sys_role r ON ur.role_id = r.role_id
JOIN sys_role_menu rm ON r.role_id = rm.role_id
JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE u.phonenumber = '15666666666'
AND r.status = '0' 
AND m.status = '0'
ORDER BY r.role_name, m.menu_name;

-- 4. 检查平台管理员角色是否存在
SELECT 
    role_id,
    role_name,
    role_key,
    status,
    del_flag,
    create_time
FROM sys_role 
WHERE role_name LIKE '%平台%' OR role_key LIKE '%platform%' OR role_key LIKE '%admin%'
ORDER BY create_time DESC;

-- 5. 检查是否有admin_type字段的设置
SELECT 
    user_id,
    user_name,
    phonenumber,
    admin_type,
    admin_level
FROM sys_user 
WHERE admin_type IS NOT NULL 
ORDER BY admin_type, admin_level;