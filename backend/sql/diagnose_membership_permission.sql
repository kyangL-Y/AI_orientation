-- 诊断平台管理员的会员管理权限问题

-- 1. 查看会员管理相关的菜单
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

-- 2. 查看平台管理员角色（假设角色ID为某个特定值，需要先确认）
SELECT 
    role_id,
    role_name,
    role_key,
    role_sort,
    status,
    is_platform_admin
FROM sys_role
WHERE is_platform_admin = 1
   OR role_key LIKE '%platform%'
   OR role_name LIKE '%平台%';

-- 3. 查看当前登录用户的角色
-- 需要知道用户ID，这里假设查看所有平台管理员
SELECT 
    u.user_id,
    u.user_name,
    u.is_platform_admin,
    GROUP_CONCAT(r.role_name) as roles
FROM sys_user u
LEFT JOIN sys_user_role ur ON u.user_id = ur.user_id
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE u.is_platform_admin = 1
GROUP BY u.user_id, u.user_name, u.is_platform_admin;

-- 4. 查看平台管理员角色的菜单权限
SELECT 
    r.role_id,
    r.role_name,
    m.menu_id,
    m.menu_name,
    m.perms
FROM sys_role r
LEFT JOIN sys_role_menu rm ON r.role_id = rm.role_id
LEFT JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE r.is_platform_admin = 1
  AND (m.menu_name LIKE '%会员%' OR m.perms LIKE '%membership%')
ORDER BY r.role_id, m.menu_id;
