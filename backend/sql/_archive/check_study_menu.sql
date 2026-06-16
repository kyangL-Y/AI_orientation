-- 检查"学习管理"菜单是否存在
-- 执行数据库：hz-vue (主库)

-- 查看所有包含"学习"的菜单
SELECT menu_id, menu_name, parent_id, path, component, order_num, visible, status
FROM sys_menu 
WHERE menu_name LIKE '%学习%'
ORDER BY menu_id;

-- 查看培训中心下的所有菜单
SELECT menu_id, menu_name, parent_id, path, component, order_num, visible, status
FROM sys_menu 
WHERE parent_id IN (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心')
ORDER BY order_num;

