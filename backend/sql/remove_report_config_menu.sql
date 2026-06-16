-- ================================================
-- 删除报告配置菜单及其子菜单
-- 原因: 报告配置功能未实现，只是前端空壳
-- 保留学习报告菜单，因为用户端在使用
-- ================================================

-- 1. 查看当前报告相关菜单
SELECT menu_id, menu_name, parent_id, path, component, visible
FROM sys_menu 
WHERE menu_name LIKE '%报告%'
ORDER BY menu_id;

-- 2. 删除报告配置菜单（menu_id=2330）
DELETE FROM sys_menu WHERE menu_id = 2330;

-- 3. 验证删除结果
SELECT menu_id, menu_name, parent_id, path, component, visible
FROM sys_menu 
WHERE menu_name LIKE '%报告%'
ORDER BY menu_id;

-- 说明:
-- - 删除了"报告配置"菜单（未实现的功能）
-- - 保留了"学习报告"菜单及其子菜单（用户端正在使用）
