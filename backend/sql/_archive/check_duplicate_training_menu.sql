-- 检查是否有重复的培训中心菜单
SELECT menu_id, menu_name, parent_id, order_num, path, create_time 
FROM sys_menu 
WHERE menu_name LIKE '%培训%' OR menu_name = '培训中心'
ORDER BY menu_id;

-- 删除可能重复的培训中心菜单（如果有的话）
-- 保留menu_id=2000的培训中心，删除其他重复的
-- DELETE FROM sys_menu WHERE menu_name = '培训中心' AND menu_id != 2000;

-- 查看所有一级菜单
SELECT menu_id, menu_name, parent_id, order_num, path 
FROM sys_menu 
WHERE parent_id = 0 
ORDER BY order_num;