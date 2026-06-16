-- 修复参数设置菜单权限
-- 为角色 100 和 101 添加参数设置相关权限

-- 添加参数设置主菜单权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (100, 106);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (101, 106);

-- 添加参数查询权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (100, 1030);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (101, 1030);

-- 添加参数新增权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (100, 1031);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (101, 1031);

-- 添加参数修改权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (100, 1032);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (101, 1032);

-- 添加参数删除权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (100, 1033);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (101, 1033);

-- 添加参数导出权限
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (100, 1034);
INSERT INTO sys_role_menu (role_id, menu_id) VALUES (101, 1034);
