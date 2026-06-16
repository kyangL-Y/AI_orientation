-- 添加部门规则配置菜单
USE hz-vue;

-- 插入部门规则配置菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('部门规则配置', 2317, 2, 'deptRule', 'train/assessment/deptRule/index', 1, 0, 'C', '0', '0', 'train:assessment:deptRule:query', 'tree', 'admin', NOW(), '', NULL, '部门评分规则配置');

-- 获取刚插入的菜单ID
SET @menu_id = LAST_INSERT_ID();

-- 插入按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time)
VALUES 
('部门规则查询', @menu_id, 1, '#', '', 1, 0, 'F', '0', '0', 'train:assessment:deptRule:query', '#', 'admin', NOW()),
('部门规则编辑', @menu_id, 2, '#', '', 1, 0, 'F', '0', '0', 'train:assessment:deptRule:edit', '#', 'admin', NOW());

SELECT '部门规则配置菜单添加成功' AS result;
