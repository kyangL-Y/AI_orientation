-- 修复平台管理员的会员管理权限问题
-- 执行时间: 2026-02-04

-- ========== 第一步：诊断问题 ==========

-- 1. 查看会员管理相关菜单
SELECT '========== 会员管理菜单 ==========' as step;
SELECT 
    menu_id,
    menu_name,
    parent_id,
    perms,
    visible,
    status,
    CASE 
        WHEN visible = '1' THEN '隐藏'
        WHEN visible = '0' THEN '显示'
        ELSE '未知'
    END as visible_status,
    CASE 
        WHEN status = '1' THEN '停用'
        WHEN status = '0' THEN '正常'
        ELSE '未知'
    END as menu_status
FROM sys_menu
WHERE menu_name LIKE '%会员%'
   OR perms LIKE '%membership%'
ORDER BY menu_id;

-- 2. 查看平台管理员角色
SELECT '========== 平台管理员角色 ==========' as step;
SELECT 
    role_id,
    role_name,
    role_key,
    is_platform_admin,
    status
FROM sys_role
WHERE is_platform_admin = 1
   OR role_key LIKE '%platform%'
   OR role_name LIKE '%平台%';

-- 3. 查看平台管理员用户
SELECT '========== 平台管理员用户 ==========' as step;
SELECT 
    u.user_id,
    u.user_name,
    u.is_platform_admin,
    GROUP_CONCAT(r.role_name) as roles,
    GROUP_CONCAT(r.role_id) as role_ids
FROM sys_user u
LEFT JOIN sys_user_role ur ON u.user_id = ur.user_id
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE u.is_platform_admin = 1
GROUP BY u.user_id, u.user_name, u.is_platform_admin;

-- ========== 第二步：修复权限 ==========

-- 4. 确保会员管理菜单存在且可见
-- 如果菜单不存在，需要先创建（这里假设菜单ID为某个值，需要根据实际情况调整）

-- 5. 为平台管理员角色分配会员管理权限
-- 获取平台管理员角色ID和会员管理菜单ID
SET @platform_admin_role_id = (SELECT role_id FROM sys_role WHERE is_platform_admin = 1 LIMIT 1);
SET @membership_menu_id = (SELECT menu_id FROM sys_menu WHERE perms = 'train:membership:list' LIMIT 1);

-- 如果找到了角色和菜单，且还没有分配权限，则分配
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT @platform_admin_role_id, menu_id
FROM sys_menu
WHERE (menu_name LIKE '%会员%' OR perms LIKE '%membership%')
  AND @platform_admin_role_id IS NOT NULL
  AND menu_id NOT IN (
    SELECT menu_id FROM sys_role_menu WHERE role_id = @platform_admin_role_id
  );

-- 6. 验证修复结果
SELECT '========== 修复后的权限分配 ==========' as step;
SELECT 
    r.role_id,
    r.role_name,
    m.menu_id,
    m.menu_name,
    m.perms
FROM sys_role r
INNER JOIN sys_role_menu rm ON r.role_id = rm.role_id
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE r.is_platform_admin = 1
  AND (m.menu_name LIKE '%会员%' OR m.perms LIKE '%membership%')
ORDER BY r.role_id, m.menu_id;

-- 7. 如果会员管理菜单被隐藏或停用，启用它
UPDATE sys_menu
SET visible = '0',
    status = '0',
    update_time = NOW()
WHERE (menu_name LIKE '%会员%' OR perms LIKE '%membership%')
  AND (visible = '1' OR status = '1');

SELECT '========== 修复完成 ==========' as step;
SELECT 
    CONCAT('已为平台管理员角色分配 ', COUNT(*), ' 个会员管理相关菜单权限') as result
FROM sys_role_menu rm
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
INNER JOIN sys_role r ON rm.role_id = r.role_id
WHERE r.is_platform_admin = 1
  AND (m.menu_name LIKE '%会员%' OR m.perms LIKE '%membership%');
