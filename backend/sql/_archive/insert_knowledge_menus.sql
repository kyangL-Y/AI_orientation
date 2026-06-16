-- 智囊阁菜单数据
-- 说明：此脚本会自动查询培训中心菜单ID并插入子菜单

-- 1. 智囊阁父菜单（自动获取培训中心菜单ID作为parent_id）
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '智囊阁', menu_id, 7, 'knowledge', NULL, 1, 0, 'M', '0', '0', NULL, 'reading', 'admin', NOW(), 'admin', NOW(), '知识共享平台'
FROM sys_menu WHERE menu_name = '培训中心' LIMIT 1;

-- 获取刚插入的智囊阁菜单ID
SET @knowledge_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '智囊阁' AND parent_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' LIMIT 1) LIMIT 1);

-- 2. 文章审核菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '文章审核', @knowledge_menu_id, 1, 'review', 'train/knowledge/review', 1, 0, 'C', '0', '0', 'train:knowledge:review', 'edit', 'admin', NOW(), 'admin', NOW(), '审核待发布文章'
WHERE @knowledge_menu_id IS NOT NULL;

-- 获取文章审核菜单ID
SET @review_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '文章审核' AND parent_id = @knowledge_menu_id LIMIT 1);

-- 3. 文章管理菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '文章管理', @knowledge_menu_id, 2, 'manage', 'train/knowledge/manage', 1, 0, 'C', '0', '0', 'train:knowledge:manage', 'list', 'admin', NOW(), 'admin', NOW(), '管理所有文章'
WHERE @knowledge_menu_id IS NOT NULL;

-- 获取文章管理菜单ID
SET @manage_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '文章管理' AND parent_id = @knowledge_menu_id LIMIT 1);

-- 4. 数据统计菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '数据统计', @knowledge_menu_id, 3, 'statistics', 'train/knowledge/statistics', 1, 0, 'C', '0', '0', 'train:knowledge:statistics', 'data-analysis', 'admin', NOW(), 'admin', NOW(), '查看知识共享统计数据'
WHERE @knowledge_menu_id IS NOT NULL;

-- 5. 文章审核按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '审核通过', @review_menu_id, 1, '', NULL, 1, 0, 'F', '0', '0', 'train:knowledge:approve', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE @review_menu_id IS NOT NULL;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '审核拒绝', @review_menu_id, 2, '', NULL, 1, 0, 'F', '0', '0', 'train:knowledge:reject', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE @review_menu_id IS NOT NULL;

-- 6. 文章管理按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '查看文章', @manage_menu_id, 1, '', NULL, 1, 0, 'F', '0', '0', 'train:knowledge:query', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE @manage_menu_id IS NOT NULL;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '删除文章', @manage_menu_id, 2, '', NULL, 1, 0, 'F', '0', '0', 'train:knowledge:remove', '#', 'admin', NOW(), 'admin', NOW(), ''
WHERE @manage_menu_id IS NOT NULL;

-- 说明：
-- 1. 此脚本会自动查询培训中心菜单ID并创建子菜单
-- 2. 如果找不到培训中心菜单，则不会插入任何数据
-- 3. 菜单类型：M=目录，C=菜单，F=按钮
-- 4. visible: '0'=显示，'1'=隐藏
-- 5. status: '0'=正常，'1'=停用
-- 6. is_frame: 1=否（内部链接），0=是（外部链接）
-- 7. is_cache: 0=不缓存，1=缓存
-- 8. 权限标识格式：模块:功能:操作

