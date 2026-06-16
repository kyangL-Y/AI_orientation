-- 为题库统计菜单分配权限
-- 解决访问 /train/questions/statistics 时的404问题

-- 为普通角色(role_id=2)分配权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (2, 2405);

-- 为集团管理员(role_id=100)分配权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (100, 2405);

-- 为公司管理员(role_id=101)分配权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (101, 2405);

-- 验证权限分配
SELECT r.role_id, r.role_name, m.menu_id, m.menu_name
FROM sys_role r
INNER JOIN sys_role_menu rm ON r.role_id = rm.role_id
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE m.menu_id = 2405
ORDER BY r.role_id;
