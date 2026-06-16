-- 修复平台管理员的会员管理权限问题 (修正版)
-- 执行时间: 2026-02-04

-- 1. 查看会员管理相关菜单
SELECT 
    menu_id,
    menu_name,
    parent_id,
    perms,
    visible,
    status
FROM sys_menu
WHERE menu_name LIKE '%会员%'
   OR perms LIKE '%membership%'
ORDER BY menu_id;

-- 2. 查看所有角色（找出管理员角色）
SELECT 
    role_id,
    role_name,
    role_key,
    role_sort,
    status
FROM sys_role
WHERE role_key LIKE '%admin%'
   OR role_name LIKE '%管理员%'
ORDER BY role_sort;

-- 3. 为管理员角色分配会员管理菜单权限
-- 假设角色ID为1是超级管理员，为其分配所有会员管理菜单
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id
FROM sys_menu
WHERE (menu_name LIKE '%会员%' OR perms LIKE '%membership%')
  AND menu_id NOT IN (
    SELECT menu_id FROM sys_role_menu WHERE role_id = 1
  );

-- 4. 如果有其他管理员角色（role_id=2等），也为其分配权限
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 2, menu_id
FROM sys_menu
WHERE (menu_name LIKE '%会员%' OR perms LIKE '%membership%')
  AND menu_id NOT IN (
    SELECT menu_id FROM sys_role_menu WHERE role_id = 2
  )
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_id = 2);

-- 5. 确保会员管理菜单可见且启用
UPDATE sys_menu
SET visible = '0',
    status = '0',
    update_time = NOW()
WHERE (menu_name LIKE '%会员%' OR perms LIKE '%membership%')
  AND (visible = '1' OR status = '1');

-- 6. 验证修复结果
SELECT 
    r.role_id,
    r.role_name,
    COUNT(m.menu_id) as menu_count
FROM sys_role r
INNER JOIN sys_role_menu rm ON r.role_id = rm.role_id
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE (m.menu_name LIKE '%会员%' OR m.perms LIKE '%membership%')
GROUP BY r.role_id, r.role_name
ORDER BY r.role_id;
