-- 修复数据统计菜单权限
-- 为角色 101 添加数据统计权限

INSERT INTO sys_role_menu (role_id, menu_id) VALUES (101, 2312);
