-- 删除后台"学习管理"菜单项
-- 执行数据库：hz-vue (主库)

-- 1. 先查看要删除的菜单
SELECT menu_id, menu_name, parent_id, path, component 
FROM sys_menu 
WHERE menu_name = '学习管理' OR path = 'study';

-- 2. 删除"学习管理"菜单（包括其子菜单会自动删除，如果有的话）
DELETE FROM sys_menu 
WHERE menu_name = '学习管理' AND path = 'study';

-- 3. 验证删除结果
SELECT menu_id, menu_name, parent_id, path 
FROM sys_menu 
WHERE menu_name = '学习管理';

-- 应该返回空结果，表示删除成功

