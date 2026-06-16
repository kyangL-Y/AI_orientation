-- 添加用户答题记录菜单权限
-- 在培训中心下添加用户答题记录菜单

-- 1. 添加用户答题记录主菜单
INSERT INTO sys_menu VALUES('2180', '用户答题记录', '2000', '10', 'attempts', 'train/attempt/index', '', '', 1, 0, 'C', '0', '0', 'train:attempt:list', 'list', 'admin', sysdate(), '', null, '用户答题记录菜单');

-- 2. 添加用户答题记录按钮权限
INSERT INTO sys_menu VALUES('2181', '答题记录查询', '2180', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:attempt:query', '#', 'admin', sysdate(), '', null, '');

-- 3. 为超级管理员角色分配用户答题记录权限
INSERT INTO sys_role_menu VALUES ('1', '2180');
INSERT INTO sys_role_menu VALUES ('1', '2181');

-- 4. 为普通角色分配答题记录查询权限（如果需要）
-- INSERT INTO sys_role_menu VALUES ('2', '2180');
-- INSERT INTO sys_role_menu VALUES ('2', '2181');

