-- 验证平台管理员角色权限配置
-- 执行时间: 2026-01-27

USE `hz-vue`;

-- 1. 查看平台管理员角色信息
SELECT 
    role_id,
    role_name,
    role_key,
    role_sort,
    status,
    create_time
FROM sys_role
WHERE role_id = 105;

-- 2. 查看平台管理员角色拥有的菜单权限数量
SELECT 
    COUNT(*) as menu_count,
    '平台管理员角色的菜单权限数量' as description
FROM sys_role_menu
WHERE role_id = 105;

-- 3. 查看用户15666666666的角色分配情况
SELECT 
    u.user_id,
    u.user_name,
    u.phonenumber,
    r.role_id,
    r.role_name,
    r.role_key
FROM sys_user u
LEFT JOIN sys_user_role ur ON u.user_id = ur.user_id
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE u.phonenumber = '15666666666';

-- 4. 查看该用户通过角色获得的菜单权限数量
SELECT 
    COUNT(DISTINCT m.menu_id) as accessible_menu_count,
    '用户15666666666通过角色获得的菜单数量' as description
FROM sys_user u
JOIN sys_user_role ur ON u.user_id = ur.user_id
JOIN sys_role_menu rm ON ur.role_id = rm.role_id
JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE u.phonenumber = '15666666666'
  AND m.status = '0';

-- 5. 列出该用户可访问的主要菜单模块
SELECT DISTINCT
    m.menu_id,
    m.menu_name,
    m.parent_id,
    m.order_num,
    r.role_name as granted_by_role
FROM sys_user u
JOIN sys_user_role ur ON u.user_id = ur.user_id
JOIN sys_role r ON ur.role_id = r.role_id
JOIN sys_role_menu rm ON r.role_id = rm.role_id
JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE u.phonenumber = '15666666666'
  AND m.status = '0'
  AND m.parent_id = 0
ORDER BY m.order_num;

-- 6. 验证权限传递机制是否正常
-- 检查是否存在其他用户也使用平台管理员角色
SELECT 
    u.user_id,
    u.user_name,
    u.phonenumber,
    COUNT(DISTINCT rm.menu_id) as menu_count
FROM sys_user u
JOIN sys_user_role ur ON u.user_id = ur.user_id
JOIN sys_role_menu rm ON ur.role_id = rm.role_id
WHERE ur.role_id = 105
GROUP BY u.user_id, u.user_name, u.phonenumber;
