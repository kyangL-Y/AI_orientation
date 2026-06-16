-- ================================================
-- 学习能力测评系统 - 菜单数据插入脚本
-- 在主库 hz-vue 中执行
-- ================================================

USE `hz-vue`;

-- 查找培训管理菜单ID（假设已存在）
-- 如果不存在，需要先创建父菜单
SET @parent_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训管理' LIMIT 1);

-- 如果培训管理菜单不存在，使用0作为父ID（顶级菜单）
SET @parent_id = IFNULL(@parent_id, 0);

-- ================================================
-- 1. 学习测评主菜单
-- ================================================
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES ('学习测评', @parent_id, 10, 'assessment', NULL, NULL, NULL, 1, 0, 'M', '0', '0', NULL, 'chart', 'admin', NOW(), '学习能力测评管理');

SET @assessment_menu_id = LAST_INSERT_ID();

-- ================================================
-- 2. 评分模型管理
-- ================================================
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES ('评分模型', @assessment_menu_id, 1, 'model', 'train/assessment/model/index', NULL, NULL, 1, 0, 'C', '0', '0', 'train:assessment:model:list', 'edit', 'admin', NOW(), '评分模型管理');

SET @model_menu_id = LAST_INSERT_ID();

-- 评分模型按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES 
('模型查询', @model_menu_id, 1, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:model:query', '#', 'admin', NOW(), NULL),
('模型新增', @model_menu_id, 2, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:model:add', '#', 'admin', NOW(), NULL),
('模型修改', @model_menu_id, 3, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:model:edit', '#', 'admin', NOW(), NULL),
('模型删除', @model_menu_id, 4, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:model:remove', '#', 'admin', NOW(), NULL);

-- ================================================
-- 3. 学习报告管理
-- ================================================
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES ('学习报告', @assessment_menu_id, 2, 'report', 'train/assessment/report/index', NULL, NULL, 1, 0, 'C', '0', '0', 'train:assessment:report:list', 'documentation', 'admin', NOW(), '学习报告管理');

SET @report_menu_id = LAST_INSERT_ID();

-- 学习报告按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES 
('报告查询', @report_menu_id, 1, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:report:query', '#', 'admin', NOW(), NULL),
('报告生成', @report_menu_id, 2, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:report:generate', '#', 'admin', NOW(), NULL),
('报告导出', @report_menu_id, 3, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:report:export', '#', 'admin', NOW(), NULL);

-- ================================================
-- 4. 部门统计
-- ================================================
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES ('部门统计', @assessment_menu_id, 3, 'statistics', 'train/assessment/statistics/index', NULL, NULL, 1, 0, 'C', '0', '0', 'train:assessment:statistics:list', 'peoples', 'admin', NOW(), '部门学习统计');

SET @stats_menu_id = LAST_INSERT_ID();

-- 部门统计按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES 
('统计查询', @stats_menu_id, 1, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:statistics:query', '#', 'admin', NOW(), NULL),
('统计导出', @stats_menu_id, 2, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:statistics:export', '#', 'admin', NOW(), NULL);

-- ================================================
-- 5. 报告配置
-- ================================================
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES ('报告配置', @assessment_menu_id, 4, 'config', 'train/assessment/config/index', NULL, NULL, 1, 0, 'C', '0', '0', 'train:assessment:config:list', 'system', 'admin', NOW(), '报告生成配置');

SET @config_menu_id = LAST_INSERT_ID();

-- 报告配置按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
VALUES 
('配置查询', @config_menu_id, 1, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:config:query', '#', 'admin', NOW(), NULL),
('配置修改', @config_menu_id, 2, '', NULL, NULL, NULL, 1, 0, 'F', '0', '0', 'train:assessment:config:edit', '#', 'admin', NOW(), NULL);

