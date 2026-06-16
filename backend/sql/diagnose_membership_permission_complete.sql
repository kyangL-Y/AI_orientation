-- 完整诊断会员管理权限问题
-- 执行时间: 2026-02-04

-- 1. 查看会员管理相关的所有菜单（包括子菜单）
SELECT 
    menu_id,
    menu_name,
    parent_id,
    perms,
    visible,
    status,
    menu_type
FROM sys_menu
WHERE menu_name LIKE '%会员%'
   OR perms LIKE '%membership%'
ORDER BY parent_id, menu_id;

-- 2. 查看所有角色
SELECT 
    role_id,
    role_name,
    role_key,
    role_sort,
    status,
    data_scope
FROM sys_role
WHERE status = '0'
ORDER BY role_sort;

-- 3. 查看所有用户及其角色
SELECT 
    u.user_id,
    u.user_name,
    u.nick_name,
    u.status,
    GROUP_CONCAT(DISTINCT r.role_id) as role_ids,
    GROUP_CONCAT(DISTINCT r.role_name) as role_names
FROM sys_user u
LEFT JOIN sys_user_role ur ON u.user_id = ur.user_id
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE u.status = '0'
GROUP BY u.user_id, u.user_name, u.nick_name, u.status
ORDER BY u.user_id;

-- 4. 查看每个角色分配的会员管理菜单权限
SELECT 
    r.role_id,
    r.role_name,
    m.menu_id,
    m.menu_name,
    m.perms,
    m.menu_type
FROM sys_role r
LEFT JOIN sys_role_menu rm ON r.role_id = rm.role_id
LEFT JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE (m.menu_name LIKE '%会员%' OR m.perms LIKE '%membership%')
  AND r.status = '0'
ORDER BY r.role_id, m.parent_id, m.menu_id;

-- 5. 检查是否有角色没有分配会员管理权限
SELECT 
    r.role_id,
    r.role_name,
    r.role_key,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM sys_role_menu rm
            INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
            WHERE rm.role_id = r.role_id
              AND (m.menu_name LIKE '%会员%' OR m.perms LIKE '%membership%')
        ) THEN '已分配'
        ELSE '未分配'
    END as has_membership_permission
FROM sys_role r
WHERE r.status = '0'
  AND (r.role_key LIKE '%admin%' OR r.role_name LIKE '%管理员%')
ORDER BY r.role_sort;

-- 6. 查看会员管理菜单的父菜单是否正常
SELECT 
    parent.menu_id as parent_menu_id,
    parent.menu_name as parent_menu_name,
    parent.visible as parent_visible,
    parent.status as parent_status,
    child.menu_id as child_menu_id,
    child.menu_name as child_menu_name,
    child.visible as child_visible,
    child.status as child_status
FROM sys_menu parent
LEFT JOIN sys_menu child ON parent.menu_id = child.parent_id
WHERE parent.menu_name LIKE '%会员%'
   OR child.menu_name LIKE '%会员%'
ORDER BY parent.menu_id, child.menu_id;
