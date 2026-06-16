-- 清理重复的排行榜管理菜单
-- 保留新的菜单（ID: 2024），删除旧的菜单（ID: 2006）

-- 1. 先查看两个排行榜管理菜单的详细信息
SELECT 
    menu_id,
    menu_name,
    parent_id,
    order_num,
    path,
    component,
    perms,
    icon,
    create_time
FROM sys_menu 
WHERE menu_name = '排行榜管理' 
ORDER BY menu_id;

-- 2. 删除旧的排行榜管理菜单（ID: 2006）及其相关权限
-- 删除旧的按钮权限
DELETE FROM sys_menu WHERE parent_id = '2006';

-- 删除旧的主菜单
DELETE FROM sys_menu WHERE menu_id = '2006' AND menu_name = '排行榜管理';

-- 3. 删除角色权限中的旧菜单引用
DELETE FROM sys_role_menu WHERE menu_id = '2006';

-- 4. 确认删除结果
SELECT 
    menu_id,
    menu_name,
    parent_id,
    order_num,
    path,
    component,
    perms,
    icon
FROM sys_menu 
WHERE menu_name = '排行榜管理' 
ORDER BY menu_id;

-- 5. 查看培训中心下的所有菜单
SELECT 
    menu_id,
    menu_name,
    parent_id,
    order_num,
    path,
    component,
    perms,
    icon
FROM sys_menu 
WHERE parent_id = '2000' 
ORDER BY order_num, menu_id;
