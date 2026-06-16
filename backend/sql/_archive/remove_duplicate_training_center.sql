-- 查找并删除重复的培训中心菜单
-- 第一步：查看当前所有的培训中心菜单
SELECT menu_id, menu_name, parent_id, order_num, path, create_time, remark
FROM sys_menu 
WHERE menu_name = '培训中心'
ORDER BY menu_id;

-- 第二步：查看所有一级菜单的排序
SELECT menu_id, menu_name, parent_id, order_num, path, create_time
FROM sys_menu 
WHERE parent_id = 0 
ORDER BY order_num, menu_id;

-- 第三步：删除重复的培训中心菜单
-- 假设我们要保留menu_id=2000的培训中心，删除其他重复的
-- 请根据查询结果确定要删除的具体menu_id

-- 删除重复的培训中心菜单及其相关权限
-- DELETE FROM sys_role_menu WHERE menu_id IN (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' AND menu_id != 2000);
-- DELETE FROM sys_menu WHERE menu_name = '培训中心' AND menu_id != 2000;

-- 第四步：验证删除结果
-- SELECT menu_id, menu_name, parent_id, order_num, path
-- FROM sys_menu 
-- WHERE parent_id = 0 
-- ORDER BY order_num, menu_id;