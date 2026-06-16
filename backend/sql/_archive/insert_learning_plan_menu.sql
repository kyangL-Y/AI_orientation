-- 学习计划模块菜单权限
-- 华智酒店员工培训系统

-- 1. 学习计划管理菜单（父菜单）
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark) VALUES
('学习计划管理', 2000, 4, 'learningPlan', 'train/learningPlan/index', '', 1, 0, 'C', '0', '0', 'train:plans:list', 'education', 'admin', sysdate(), '学习计划管理菜单');

-- 获取刚插入的菜单ID
SET @learning_plan_menu_id = LAST_INSERT_ID();

-- 2. 学习计划管理子菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark) VALUES
('学习计划查询', @learning_plan_menu_id, 1, '', '', '', 1, 0, 'F', '0', '0', 'train:plans:query', '#', 'admin', sysdate(), ''),
('学习计划新增', @learning_plan_menu_id, 2, '', '', '', 1, 0, 'F', '0', '0', 'train:plans:add', '#', 'admin', sysdate(), ''),
('学习计划修改', @learning_plan_menu_id, 3, '', '', '', 1, 0, 'F', '0', '0', 'train:plans:edit', '#', 'admin', sysdate(), ''),
('学习计划删除', @learning_plan_menu_id, 4, '', '', '', 1, 0, 'F', '0', '0', 'train:plans:remove', '#', 'admin', sysdate(), ''),
('学习计划导出', @learning_plan_menu_id, 5, '', '', '', 1, 0, 'F', '0', '0', 'train:plans:export', '#', 'admin', sysdate(), '');

-- 3. 我的学习计划菜单（学员端）
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark) VALUES
('我的学习计划', 2000, 5, 'myPlans', 'train/learningPlan/myPlans', '', 1, 0, 'C', '0', '0', 'train:plans:list', 'user', 'admin', sysdate(), '我的学习计划菜单');
