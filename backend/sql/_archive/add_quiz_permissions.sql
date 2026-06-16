-- 添加考试提交相关权限
-- 考试提交菜单权限
INSERT INTO sys_menu VALUES('2160', '考试提交', '2002', '6', '', '', '', '', 1, 0, 'F', '0', '0', 'train:quiz:add', '#', 'admin', sysdate(), '', null, '考试提交权限');

-- 为超级管理员角色分配考试提交权限
INSERT INTO sys_role_menu VALUES ('1', '2160');

-- 为普通角色分配考试提交权限
INSERT INTO sys_role_menu VALUES ('2', '2160');

-- 如果还有其他角色，也可以添加
-- INSERT INTO sys_role_menu VALUES ('3', '2160'); -- 假设角色ID为3
