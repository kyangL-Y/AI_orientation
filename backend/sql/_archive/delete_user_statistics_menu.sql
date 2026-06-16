-- 删除"用户统计管理"菜单项（与排行榜管理重复）
-- 在主库 hz-vue 执行

-- 先查看要删除的菜单
SELECT menu_id, menu_name, parent_id, order_num, path, component 
FROM sys_menu 
WHERE menu_name = '用户统计管理' OR path = 'userStatistics';

-- 删除菜单
DELETE FROM sys_menu WHERE menu_name = '用户统计管理';

-- 如果按路径删除
DELETE FROM sys_menu WHERE path = 'userStatistics';

-- 验证删除结果
SELECT menu_id, menu_name, parent_id, path 
FROM sys_menu 
WHERE parent_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' LIMIT 1)
ORDER BY order_num;
