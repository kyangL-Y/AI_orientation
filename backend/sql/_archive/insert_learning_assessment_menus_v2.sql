-- =============================================
-- 学习测评系统菜单数据（V2版本 - 简化版）
-- 执行库：hz-vue（主库）
-- =============================================

-- 1. 一级菜单：学习测评
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('学习测评', 2000, 6, 'assessment', NULL, 1, 0, 'M', '0', '0', NULL, 'chart', 'admin', NOW(), '', NULL, '学习测评菜单');

SET @assessment_menu_id = LAST_INSERT_ID();

-- 2. 二级菜单：评分规则
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('评分规则', @assessment_menu_id, 1, 'model', 'train/assessment/model/index', 1, 0, 'C', '0', '0', 'train:assessment:model:list', 'edit', 'admin', NOW(), '', NULL, '评分规则菜单');

SET @model_menu_id = LAST_INSERT_ID();

-- 评分规则按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES
('评分规则查询', @model_menu_id, 1, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:model:query', '#', 'admin', NOW(), '', NULL, ''),
('评分规则新增', @model_menu_id, 2, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:model:add', '#', 'admin', NOW(), '', NULL, ''),
('评分规则修改', @model_menu_id, 3, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:model:edit', '#', 'admin', NOW(), '', NULL, ''),
('评分规则删除', @model_menu_id, 4, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:model:remove', '#', 'admin', NOW(), '', NULL, '');

-- 3. 二级菜单：部门规则
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('部门规则', @assessment_menu_id, 2, 'dept-rule', 'train/assessment/deptRule/index', 1, 0, 'C', '0', '0', 'train:assessment:deptRule:list', 'tree', 'admin', NOW(), '', NULL, '部门规则配置菜单');

SET @dept_rule_menu_id = LAST_INSERT_ID();

-- 部门规则按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES
('部门规则查询', @dept_rule_menu_id, 1, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:deptRule:query', '#', 'admin', NOW(), '', NULL, ''),
('部门规则配置', @dept_rule_menu_id, 2, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:deptRule:edit', '#', 'admin', NOW(), '', NULL, '');

-- 4. 二级菜单：员工报告
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('员工报告', @assessment_menu_id, 3, 'report', 'train/assessment/report/index', 1, 0, 'C', '0', '0', 'train:assessment:report:list', 'documentation', 'admin', NOW(), '', NULL, '员工报告菜单');

SET @report_menu_id = LAST_INSERT_ID();

-- 员工报告按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES
('报告查询', @report_menu_id, 1, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:report:query', '#', 'admin', NOW(), '', NULL, ''),
('报告详情', @report_menu_id, 2, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:report:detail', '#', 'admin', NOW(), '', NULL, ''),
('报告导出', @report_menu_id, 3, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:report:export', '#', 'admin', NOW(), '', NULL, '');

-- 5. 二级菜单：部门统计
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('部门统计', @assessment_menu_id, 4, 'statistics', 'train/assessment/statistics/index', 1, 0, 'C', '0', '0', 'train:assessment:statistics:list', 'chart', 'admin', NOW(), '', NULL, '部门统计菜单');

SET @statistics_menu_id = LAST_INSERT_ID();

-- 部门统计按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES
('统计查询', @statistics_menu_id, 1, '', NULL, 1, 0, 'F', '0', '0', 'train:assessment:statistics:query', '#', 'admin', NOW(), '', NULL, '');
