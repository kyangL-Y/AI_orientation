-- 会员管理权限最终修复方案
-- 执行时间: 2026-02-04
-- 说明: 确保超级管理员和平台管理员有会员管理的完整权限

-- 1. 确认会员管理菜单状态正常
UPDATE sys_menu
SET visible = '0',
    status = '0',
    update_time = NOW()
WHERE menu_id IN (2336, 2337, 2338, 2339, 2340);

-- 2. 确保超级管理员（role_id=1）有所有会员管理权限
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
VALUES 
(1, 2336),
(1, 2337),
(1, 2338),
(1, 2339),
(1, 2340);

-- 3. 确保平台管理员（role_id=105）有所有会员管理权限
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
VALUES 
(105, 2336),
(105, 2337),
(105, 2338),
(105, 2339),
(105, 2340);

-- 4. 移除其他角色的会员管理权限（如果有的话）
DELETE FROM sys_role_menu 
WHERE menu_id IN (2336, 2337, 2338, 2339, 2340)
  AND role_id NOT IN (1, 105);

-- 5. 验证最终结果
SELECT 
    '=== 会员管理菜单状态 ===' as info;
    
SELECT 
    menu_id,
    menu_name,
    parent_id,
    visible,
    status,
    perms
FROM sys_menu
WHERE menu_id IN (2336, 2337, 2338, 2339, 2340)
ORDER BY parent_id, menu_id;

SELECT 
    '=== 角色权限分配 ===' as info;

SELECT 
    r.role_id,
    r.role_name,
    COUNT(rm.menu_id) as menu_count,
    GROUP_CONCAT(m.menu_name ORDER BY m.menu_id) as menus
FROM sys_role r
INNER JOIN sys_role_menu rm ON r.role_id = rm.role_id
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE m.menu_id IN (2336, 2337, 2338, 2339, 2340)
GROUP BY r.role_id, r.role_name
ORDER BY r.role_id;

SELECT 
    '=== 有权限的用户 ===' as info;

SELECT 
    u.user_id,
    u.user_name,
    u.phonenumber,
    GROUP_CONCAT(DISTINCT r.role_name) as roles
FROM sys_user u
INNER JOIN sys_user_role ur ON u.user_id = ur.user_id
INNER JOIN sys_role r ON ur.role_id = r.role_id
WHERE r.role_id IN (1, 105)
  AND u.status = '0'
GROUP BY u.user_id, u.user_name, u.phonenumber
ORDER BY u.user_id;
