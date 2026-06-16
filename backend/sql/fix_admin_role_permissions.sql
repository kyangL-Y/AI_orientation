-- 修复超级管理员权限问题
-- 问题：只有 user_id=1 的用户才被识别为超级管理员，其他拥有 admin 角色的用户没有完整权限
-- 解决方案：确保所有 admin 角色用户都能访问所有菜单

-- 1. 检查当前 admin 角色的菜单权限
SELECT COUNT(*) as menu_count FROM sys_role_menu WHERE role_id = 1;

-- 2. 获取所有菜单ID
SELECT GROUP_CONCAT(menu_id) as all_menu_ids FROM sys_menu WHERE status = '0';

-- 3. 清空 admin 角色的菜单权限（准备重新分配）
DELETE FROM sys_role_menu WHERE role_id = 1;

-- 4. 给 admin 角色分配所有菜单权限
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE status = '0';

-- 5. 验证权限分配
SELECT 
    r.role_id,
    r.role_name,
    r.role_key,
    COUNT(rm.menu_id) as assigned_menus,
    (SELECT COUNT(*) FROM sys_menu WHERE status = '0') as total_menus
FROM sys_role r
LEFT JOIN sys_role_menu rm ON r.role_id = rm.role_id
WHERE r.role_id = 1
GROUP BY r.role_id, r.role_name, r.role_key;

-- 6. 显示所有拥有 admin 角色的用户
SELECT 
    u.user_id,
    u.user_name,
    u.status,
    r.role_name,
    r.role_key
FROM sys_user u
INNER JOIN sys_user_role ur ON u.user_id = ur.user_id
INNER JOIN sys_role r ON ur.role_id = r.role_id
WHERE r.role_key = 'admin'
ORDER BY u.user_id;
