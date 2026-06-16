-- =====================================================
-- 积分商城管理端菜单SQL
-- =====================================================
-- 数据库: hotel_training
-- =====================================================

USE hotel_training;

-- 1. 查找培训管理菜单ID
SET @parent_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训管理' AND parent_id = 0 LIMIT 1);

-- 如果没找到父菜单，这里需要手动处理，或者创建一个父菜单
-- INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
-- VALUES ('培训管理', 0, 1, 'train', NULL, 1, 0, 'M', '0', '0', '', 'education', 'admin', NOW(), '', NULL, '培训管理菜单');
-- SET @parent_id = LAST_INSERT_ID();

-- 2. 创建"积分商城"目录
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('积分商城', @parent_id, 10, 'shop', 'train/shop/index', 1, 0, 'M', '0', '0', '', 'shopping', 'admin', NOW(), '', NULL, '积分商城目录');

SET @shop_menu_id = LAST_INSERT_ID();

-- 3. 创建"商品管理"菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('商品管理', @shop_menu_id, 1, 'item', 'train/shop/item/index', 1, 0, 'C', '0', '0', 'train:shop:list', 'list', 'admin', NOW(), '', NULL, '商品管理菜单');

SET @item_menu_id = LAST_INSERT_ID();

-- 商品管理按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES 
('商品查询', @item_menu_id, 1, '#', '', 1, 0, 'F', '0', '0', 'train:shop:query', '#', 'admin', NOW(), '', NULL, ''),
('商品新增', @item_menu_id, 2, '#', '', 1, 0, 'F', '0', '0', 'train:shop:add', '#', 'admin', NOW(), '', NULL, ''),
('商品修改', @item_menu_id, 3, '#', '', 1, 0, 'F', '0', '0', 'train:shop:edit', '#', 'admin', NOW(), '', NULL, ''),
('商品删除', @item_menu_id, 4, '#', '', 1, 0, 'F', '0', '0', 'train:shop:remove', '#', 'admin', NOW(), '', NULL, '');


-- 4. 创建"订单管理"菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark)
VALUES ('订单管理', @shop_menu_id, 2, 'order', 'train/shop/order/index', 1, 0, 'C', '0', '0', 'train:shop:order:list', 'form', 'admin', NOW(), '', NULL, '订单管理菜单');

SET @order_menu_id = LAST_INSERT_ID();

-- 订单管理按钮权限
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, update_by, update_time, remark) VALUES 
('订单查询', @order_menu_id, 1, '#', '', 1, 0, 'F', '0', '0', 'train:shop:order:list', '#', 'admin', NOW(), '', NULL, ''),
('订单修改', @order_menu_id, 2, '#', '', 1, 0, 'F', '0', '0', 'train:shop:order:edit', '#', 'admin', NOW(), '', NULL, '');

SELECT '积分商城管理菜单已创建！请重新登录管理端查看。' as message;
