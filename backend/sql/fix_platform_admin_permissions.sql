-- 修复平台管理员权限问题
-- 为平台管理员角色(role_id=105)分配所有菜单权限

USE hz-vue;

-- 1. 清空平台管理员现有权限（如果有的话）
DELETE FROM sys_role_menu WHERE role_id = 105;

-- 2. 为平台管理员分配所有启用的菜单权限
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 105, menu_id 
FROM sys_menu 
WHERE status = '0';

-- 3. 验证权限分配结果
SELECT 
    r.role_name,
    COUNT(rm.menu_id) as assigned_menus
FROM sys_role r
LEFT JOIN sys_role_menu rm ON r.role_id = rm.role_id
WHERE r.role_id = 105
GROUP BY r.role_id, r.role_name;

-- 4. 显示分配的主要菜单
SELECT 
    m.menu_name,
    m.menu_type,
    m.parent_id
FROM sys_role_menu rm
JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE rm.role_id = 105
AND m.parent_id = 0
ORDER BY m.order_num;