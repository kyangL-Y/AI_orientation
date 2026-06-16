-- 培训中心模块菜单权限配置
-- 培训中心一级菜单
INSERT INTO sys_menu VALUES('2000', '培训中心', '0', '5', 'train', null, '', '', 1, 0, 'M', '0', '0', '', 'education', 'admin', sysdate(), '', null, '培训中心目录');

-- 培训中心二级菜单
INSERT INTO sys_menu VALUES('2001', '刷题管理', '2000', '1', 'exercises', 'train/exercises/exercises', '', '', 1, 0, 'C', '0', '0', 'train:exercises:list', 'edit', 'admin', sysdate(), '', null, '刷题管理菜单');
INSERT INTO sys_menu VALUES('2002', '考试管理', '2000', '2', 'exam', 'train/exam/exam', '', '', 1, 0, 'C', '0', '0', 'train:exam:list', 'form', 'admin', sysdate(), '', null, '考试管理菜单');
INSERT INTO sys_menu VALUES('2003', '测评管理', '2000', '3', 'assessment', 'train/assessment/assessment', '', '', 1, 0, 'C', '0', '0', 'train:assessment:list', 'skill', 'admin', sysdate(), '', null, '测评管理菜单');
INSERT INTO sys_menu VALUES('2004', '能力等级认证', '2000', '4', 'certification', 'train/certification/certification', '', '', 1, 0, 'C', '0', '0', 'train:certification:list', 'star', 'admin', sysdate(), '', null, '能力等级认证菜单');
INSERT INTO sys_menu VALUES('2005', '奖励机制', '2000', '5', 'awards', 'train/awards/awards', '', '', 1, 0, 'C', '0', '0', 'train:awards:list', 'money', 'admin', sysdate(), '', null, '奖励机制菜单');
INSERT INTO sys_menu VALUES('2006', '排名查看', '2000', '6', 'ranking', 'train/ranking/ranking', '', '', 1, 0, 'C', '0', '0', 'train:ranking:list', 'chart', 'admin', sysdate(), '', null, '排名查看菜单');

-- 刷题管理按钮权限
INSERT INTO sys_menu VALUES('2100', '题目查询', '2001', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exercises:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2101', '题目新增', '2001', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exercises:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2102', '题目修改', '2001', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exercises:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2103', '题目删除', '2001', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exercises:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2104', '题目授权', '2001', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exercises:assign', '#', 'admin', sysdate(), '', null, '');

-- 考试管理按钮权限
INSERT INTO sys_menu VALUES('2110', '考试查询', '2002', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exam:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2111', '考试新增', '2002', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exam:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2112', '考试修改', '2002', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exam:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2113', '考试删除', '2002', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exam:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2114', '考试授权', '2002', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exam:assign', '#', 'admin', sysdate(), '', null, '');

-- 测评管理按钮权限
INSERT INTO sys_menu VALUES('2120', '测评查询', '2003', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:assessment:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2121', '测评新增', '2003', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:assessment:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2122', '测评修改', '2003', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:assessment:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2123', '测评删除', '2003', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:assessment:remove', '#', 'admin', sysdate(), '', null, '');

-- 其他模块按钮权限
INSERT INTO sys_menu VALUES('2130', '认证查询', '2004', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:certification:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2131', '认证新增', '2004', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:certification:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2132', '认证修改', '2004', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:certification:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2133', '认证删除', '2004', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:certification:remove', '#', 'admin', sysdate(), '', null, '');

INSERT INTO sys_menu VALUES('2140', '奖励查询', '2005', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:awards:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2141', '奖励新增', '2005', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:awards:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2142', '奖励修改', '2005', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:awards:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2143', '奖励删除', '2005', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:awards:remove', '#', 'admin', sysdate(), '', null, '');

INSERT INTO sys_menu VALUES('2150', '排名查询', '2006', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:query', '#', 'admin', sysdate(), '', null, '');

-- 超级管理员角色权限分配
INSERT INTO sys_role_menu VALUES ('1', '2000');
INSERT INTO sys_role_menu VALUES ('1', '2001');
INSERT INTO sys_role_menu VALUES ('1', '2002');
INSERT INTO sys_role_menu VALUES ('1', '2003');
INSERT INTO sys_role_menu VALUES ('1', '2004');
INSERT INTO sys_role_menu VALUES ('1', '2005');
INSERT INTO sys_role_menu VALUES ('1', '2006');
INSERT INTO sys_role_menu VALUES ('1', '2100');
INSERT INTO sys_role_menu VALUES ('1', '2101');
INSERT INTO sys_role_menu VALUES ('1', '2102');
INSERT INTO sys_role_menu VALUES ('1', '2103');
INSERT INTO sys_role_menu VALUES ('1', '2104');
INSERT INTO sys_role_menu VALUES ('1', '2110');
INSERT INTO sys_role_menu VALUES ('1', '2111');
INSERT INTO sys_role_menu VALUES ('1', '2112');
INSERT INTO sys_role_menu VALUES ('1', '2113');
INSERT INTO sys_role_menu VALUES ('1', '2114');
INSERT INTO sys_role_menu VALUES ('1', '2120');
INSERT INTO sys_role_menu VALUES ('1', '2121');
INSERT INTO sys_role_menu VALUES ('1', '2122');
INSERT INTO sys_role_menu VALUES ('1', '2123');
INSERT INTO sys_role_menu VALUES ('1', '2130');
INSERT INTO sys_role_menu VALUES ('1', '2131');
INSERT INTO sys_role_menu VALUES ('1', '2132');
INSERT INTO sys_role_menu VALUES ('1', '2133');
INSERT INTO sys_role_menu VALUES ('1', '2140');
INSERT INTO sys_role_menu VALUES ('1', '2141');
INSERT INTO sys_role_menu VALUES ('1', '2142');
INSERT INTO sys_role_menu VALUES ('1', '2143');
INSERT INTO sys_role_menu VALUES ('1', '2150');

-- 普通角色权限分配
INSERT INTO sys_role_menu VALUES ('2', '2000');
INSERT INTO sys_role_menu VALUES ('2', '2001');
INSERT INTO sys_role_menu VALUES ('2', '2002');
INSERT INTO sys_role_menu VALUES ('2', '2003');
INSERT INTO sys_role_menu VALUES ('2', '2004');
INSERT INTO sys_role_menu VALUES ('2', '2005');
INSERT INTO sys_role_menu VALUES ('2', '2006');
INSERT INTO sys_role_menu VALUES ('2', '2100');
INSERT INTO sys_role_menu VALUES ('2', '2101');
INSERT INTO sys_role_menu VALUES ('2', '2102');
INSERT INTO sys_role_menu VALUES ('2', '2103');
INSERT INTO sys_role_menu VALUES ('2', '2104');
INSERT INTO sys_role_menu VALUES ('2', '2110');
INSERT INTO sys_role_menu VALUES ('2', '2111');
INSERT INTO sys_role_menu VALUES ('2', '2112');
INSERT INTO sys_role_menu VALUES ('2', '2113');
INSERT INTO sys_role_menu VALUES ('2', '2114');
INSERT INTO sys_role_menu VALUES ('2', '2120');
INSERT INTO sys_role_menu VALUES ('2', '2121');
INSERT INTO sys_role_menu VALUES ('2', '2122');
INSERT INTO sys_role_menu VALUES ('2', '2123');
INSERT INTO sys_role_menu VALUES ('2', '2130');
INSERT INTO sys_role_menu VALUES ('2', '2131');
INSERT INTO sys_role_menu VALUES ('2', '2132');
INSERT INTO sys_role_menu VALUES ('2', '2133');
INSERT INTO sys_role_menu VALUES ('2', '2140');
INSERT INTO sys_role_menu VALUES ('2', '2141');
INSERT INTO sys_role_menu VALUES ('2', '2142');
INSERT INTO sys_role_menu VALUES ('2', '2143');
INSERT INTO sys_role_menu VALUES ('2', '2150');
