-- 添加考试成绩管理菜单权限
-- 在培训中心下添加考试成绩管理菜单

-- 1. 添加考试成绩管理主菜单
INSERT INTO sys_menu VALUES('2170', '考试成绩管理', '2000', '3', 'quizAttempt', 'train/quizAttempt/index', '', '', 1, 0, 'C', '0', '0', 'train:quiz:list', 'chart', 'admin', sysdate(), '', null, '考试成绩管理菜单');

-- 2. 添加考试成绩管理按钮权限
INSERT INTO sys_menu VALUES('2171', '考试成绩查询', '2170', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:quiz:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2172', '考试成绩新增', '2170', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:quiz:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2173', '考试成绩修改', '2170', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:quiz:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2174', '考试成绩删除', '2170', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:quiz:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2175', '考试成绩导出', '2170', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:quiz:export', '#', 'admin', sysdate(), '', null, '');

-- 3. 为超级管理员角色分配考试成绩管理权限
INSERT INTO sys_role_menu VALUES ('1', '2170');
INSERT INTO sys_role_menu VALUES ('1', '2171');
INSERT INTO sys_role_menu VALUES ('1', '2172');
INSERT INTO sys_role_menu VALUES ('1', '2173');
INSERT INTO sys_role_menu VALUES ('1', '2174');
INSERT INTO sys_role_menu VALUES ('1', '2175');

-- 4. 为普通角色分配考试成绩查询权限（如果需要）
-- INSERT INTO sys_role_menu VALUES ('2', '2170');
-- INSERT INTO sys_role_menu VALUES ('2', '2171');
