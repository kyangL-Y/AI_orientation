-- 检查用户菜单API返回的数据
-- 模拟后端getRouters接口的查询逻辑
-- 执行时间: 2026-01-27

USE `hz-vue`;

-- 1. 查询用户的所有菜单（模拟getRouters接口）
SELECT DISTINCT
    m.menu_id,
    m.menu_name,
    m.parent_id,
    m.path,
    m.component,
    m.visible,
    m.status,
    m.perms,
    m.menu_type,
    m.icon,
    m.order_num
FROM sys_menu m
LEFT JOIN sys_role_menu rm ON m.menu_id = rm.menu_id
LEFT JOIN sys_user_role ur ON rm.role_id = ur.role_id
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE ur.user_id = 2  -- 用户15666666666的user_id
  AND m.menu_type IN ('M', 'C')  -- 只查询目录和菜单
  AND m.status = '0'  -- 只查询启用的菜单
  AND r.status = '0'  -- 只查询启用的角色
ORDER BY m.parent_id, m.order_num;

-- 2. 检查顶级菜单（parent_id = 0）
SELECT 
    m.menu_id,
    m.menu_name,
    m.path,
    m.component,
    m.visible,
    m.status,
    m.menu_type,
    '顶级菜单' as description
FROM sys_menu m
LEFT JOIN sys_role_menu rm ON m.menu_id = rm.menu_id
LEFT JOIN sys_user_role ur ON rm.role_id = ur.role_id
WHERE ur.user_id = 2
  AND m.parent_id = 0
  AND m.menu_type = 'M'
  AND m.status = '0'
  AND m.visible = '0'  -- 显示状态
ORDER BY m.order_num;

-- 3. 检查是否有visible=1（隐藏）的顶级菜单
SELECT 
    COUNT(*) as hidden_top_menu_count,
    '隐藏的顶级菜单数量' as description
FROM sys_menu m
LEFT JOIN sys_role_menu rm ON m.menu_id = rm.menu_id
LEFT JOIN sys_user_role ur ON rm.role_id = ur.role_id
WHERE ur.user_id = 2
  AND m.parent_id = 0
  AND m.menu_type = 'M'
  AND m.status = '0'
  AND m.visible = '1';

-- 4. 检查用户的权限字符串（perms）
SELECT 
    m.menu_id,
    m.menu_name,
    m.perms,
    '权限字符串' as description
FROM sys_menu m
LEFT JOIN sys_role_menu rm ON m.menu_id = rm.menu_id
LEFT JOIN sys_user_role ur ON rm.role_id = ur.role_id
WHERE ur.user_id = 2
  AND m.perms IS NOT NULL
  AND m.perms != ''
  AND m.status = '0'
LIMIT 20;

-- 5. 检查用户是否是admin
SELECT 
    user_id,
    user_name,
    phonenumber,
    CASE 
        WHEN user_id = 1 THEN 'YES'
        ELSE 'NO'
    END as is_admin,
    '是否超级管理员' as description
FROM sys_user
WHERE user_id = 2;
