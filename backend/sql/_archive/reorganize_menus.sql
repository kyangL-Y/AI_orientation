USE `hz-vue`;

-- 1. Create new directory menus under 'Training Center' (ID 2000)

-- 题库与练习
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (2400, '题库与练习', 2000, 10, 'questions', 'ParentView', 1, 0, 'M', '0', '0', NULL, 'education', 'admin', NOW(), '', NULL, '');

-- 课程与学习
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (2401, '课程与学习', 2000, 20, 'learning', 'ParentView', 1, 0, 'M', '0', '0', NULL, 'documentation', 'admin', NOW(), '', NULL, '');

-- 考试与考核
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (2402, '考试与考核', 2000, 30, 'assessment', 'ParentView', 1, 0, 'M', '0', '0', NULL, 'edit', 'admin', NOW(), '', NULL, '');

-- 学员统计
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (2403, '学员统计', 2000, 40, 'statistics', 'ParentView', 1, 0, 'M', '0', '0', NULL, 'chart', 'admin', NOW(), '', NULL, '');

-- 积分系统
INSERT INTO sys_menu (menu_id, menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES (2404, '积分系统', 2000, 50, 'points-system', 'ParentView', 1, 0, 'M', '0', '0', NULL, 'money', 'admin', NOW(), '', NULL, '');


-- 2. Move existing menus to new directories

-- Move to 题库与练习 (2400)
UPDATE sys_menu SET parent_id = 2400 WHERE menu_id IN (2001, 2304, 2309);
-- 2001: 刷题管理, 2304: 企业文化题库, 2309: 智囊阁

-- Move to 课程与学习 (2401)
UPDATE sys_menu SET parent_id = 2401 WHERE menu_id IN (2017, 2290, 2018, 2275);
-- 2017: 课程管理, 2290: 部门培训课程, 2018: 学习路径管理, 2275: 学习计划管理

-- Move to 考试与考核 (2402)
UPDATE sys_menu SET parent_id = 2402 WHERE menu_id IN (2002);
-- 2002: 考试管理

-- Move to 学员统计 (2403)
UPDATE sys_menu SET parent_id = 2403 WHERE menu_id IN (2024, 2278, 2180, 2298);
-- 2024: 排行榜管理, 2278: 用户学习时长, 2180: 用户答题记录, 2298: 学习进度

-- Move to 积分系统 (2404)
UPDATE sys_menu SET parent_id = 2404 WHERE menu_id IN (2343, 2346);
-- 2343: 积分管理, 2346: 积分商城
