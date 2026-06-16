-- Use the database
USE `hz-vue`;

-- 1. Find Parent Menu (Try '培训管理' first, then '培训中心')
SET @parent_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训管理' AND parent_id = 0 LIMIT 1);
SET @parent_id = IFNULL(@parent_id, (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' AND parent_id = 0 LIMIT 1));

-- If still null, create '培训管理'
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '培训管理', 0, 10, 'train', 'Layout', 1, 0, 'M', '0', '0', '', 'education', 'admin', NOW(), '', NULL, '培训管理目录'
WHERE @parent_id IS NULL;

-- Get the parent ID again
SET @parent_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训管理' AND parent_id = 0 LIMIT 1);
SET @parent_id = IFNULL(@parent_id, (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' AND parent_id = 0 LIMIT 1));


-- =====================================================
-- 2. Points Management (积分管理)
-- =====================================================
DELETE FROM sys_menu WHERE menu_name = '积分管理' AND parent_id = @parent_id;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('积分管理', @parent_id, 20, 'points', 'train/points/index', 1, 0, 'C', '0', '0', 'train:points:list', 'star', 'admin', NOW(), '', NULL, '积分管理菜单');

-- Add buttons for Points Management
SET @points_menu_id = LAST_INSERT_ID();
DELETE FROM sys_menu WHERE parent_id = @points_menu_id; -- Clean up buttons if any (though we just inserted parent, safe to skip)

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES
('积分查询', @points_menu_id, 1, '#', '', 1, 0, 'F', '0', '0', 'train:points:list', '#', 'admin', NOW(), '', NULL, ''),
('积分调整', @points_menu_id, 2, '#', '', 1, 0, 'F', '0', '0', 'train:points:add', '#', 'admin', NOW(), '', NULL, '');


-- =====================================================
-- 3. Points Mall Management (积分商城)
-- =====================================================
-- Find existing '积分商城'
SET @mall_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '积分商城' AND parent_id = @parent_id LIMIT 1);

-- If not exists, create it
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
SELECT '积分商城', @parent_id, 30, 'shop', 'ParentView', 1, 0, 'M', '0', '0', '', 'shopping', 'admin', NOW(), '', NULL, '积分商城目录'
WHERE @mall_menu_id IS NULL;

SET @mall_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '积分商城' AND parent_id = @parent_id LIMIT 1);

-- 3.1 Item Management (商品管理)
DELETE FROM sys_menu WHERE menu_name = '商品管理' AND parent_id = @mall_menu_id;
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('商品管理', @mall_menu_id, 1, 'item', 'train/shop/item/index', 1, 0, 'C', '0', '0', 'train:shop:list', 'list', 'admin', NOW(), '', NULL, '商品管理菜单');

SET @item_menu_id = LAST_INSERT_ID();
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES
('商品查询', @item_menu_id, 1, '#', '', 1, 0, 'F', '0', '0', 'train:shop:query', '#', 'admin', NOW(), '', NULL, ''),
('商品新增', @item_menu_id, 2, '#', '', 1, 0, 'F', '0', '0', 'train:shop:add', '#', 'admin', NOW(), '', NULL, ''),
('商品修改', @item_menu_id, 3, '#', '', 1, 0, 'F', '0', '0', 'train:shop:edit', '#', 'admin', NOW(), '', NULL, ''),
('商品删除', @item_menu_id, 4, '#', '', 1, 0, 'F', '0', '0', 'train:shop:remove', '#', 'admin', NOW(), '', NULL, '');


-- 3.2 Order Management (兑换订单)
DELETE FROM sys_menu WHERE menu_name = '兑换订单' AND parent_id = @mall_menu_id;
DELETE FROM sys_menu WHERE menu_name = '订单管理' AND parent_id = @mall_menu_id;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('兑换订单', @mall_menu_id, 2, 'order', 'train/shop/order/index', 1, 0, 'C', '0', '0', 'train:shop:order:list', 'form', 'admin', NOW(), '', NULL, '订单管理菜单');

SET @order_menu_id = LAST_INSERT_ID();
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES
('订单查询', @order_menu_id, 1, '#', '', 1, 0, 'F', '0', '0', 'train:shop:order:list', '#', 'admin', NOW(), '', NULL, ''),
('订单处理', @order_menu_id, 2, '#', '', 1, 0, 'F', '0', '0', 'train:shop:order:edit', '#', 'admin', NOW(), '', NULL, '');

-- =====================================================
-- 4. Grant Permissions to Admin Role (ID 1)
-- =====================================================
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE menu_name IN ('积分管理', '商品管理', '兑换订单', '积分查询', '积分调整', '商品查询', '商品新增', '商品修改', '商品删除', '订单查询', '订单处理')
AND menu_id NOT IN (SELECT menu_id FROM sys_role_menu WHERE role_id = 1);

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE menu_name IN ('培训管理', '积分商城', '培训中心')
AND menu_id NOT IN (SELECT menu_id FROM sys_role_menu WHERE role_id = 1);
