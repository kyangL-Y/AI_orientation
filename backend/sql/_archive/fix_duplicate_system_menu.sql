-- 修复重复的"系统管理"菜单问题
-- 执行前请备份数据库！

-- 步骤1: 查看当前"系统管理"菜单情况
SELECT menu_id, menu_name, parent_id, path, component, order_num, status
FROM sys_menu 
WHERE menu_name = '系统管理' 
ORDER BY menu_id;

-- 步骤2: 查看用户管理菜单情况
SELECT menu_id, menu_name, parent_id, path, component, visible, status
FROM sys_menu 
WHERE menu_name = '用户管理';

-- 步骤3: 找出要保留的"系统管理"菜单（优先保留parent_id=0的，如果没有则保留ID最小的）
SET @keep_menu_id = (
    SELECT menu_id 
    FROM sys_menu 
    WHERE menu_name = '系统管理' 
    ORDER BY 
        CASE WHEN parent_id = 0 THEN 0 ELSE 1 END,
        menu_id ASC
    LIMIT 1
);

-- 步骤4: 将其他"系统管理"菜单的子菜单迁移到保留的菜单下
UPDATE sys_menu 
SET parent_id = @keep_menu_id
WHERE parent_id IN (
    SELECT menu_id 
    FROM (SELECT menu_id FROM sys_menu WHERE menu_name = '系统管理' AND menu_id != @keep_menu_id) AS temp
);

-- 步骤5: 删除重复的"系统管理"菜单（保留的那个除外）
DELETE FROM sys_menu 
WHERE menu_name = '系统管理' 
AND menu_id != @keep_menu_id;

-- 步骤6: 确保用户管理菜单存在且路径正确
-- 如果用户管理菜单不存在，创建它
INSERT INTO sys_menu (
    menu_name, parent_id, order_num, path, component, 
    query, route_name, is_frame, is_cache, menu_type, 
    visible, status, perms, icon, create_by, create_time, remark
)
SELECT 
    '用户管理', 
    @keep_menu_id,
    1, 
    '/system/user', 
    'system/user/index',
    '', 
    'User', 
    1, 
    0, 
    'C', 
    '0', 
    '0', 
    'system:user:list', 
    'user', 
    'admin', 
    NOW(), 
    '用户管理菜单'
WHERE NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE menu_name = '用户管理'
);

-- 如果用户管理菜单存在但路径错误，更新它
UPDATE sys_menu 
SET 
    path = '/system/user',
    component = 'system/user/index',
    parent_id = @keep_menu_id,
    visible = '0',
    status = '0'
WHERE menu_name = '用户管理' 
AND (path != '/system/user' OR component != 'system/user/index' OR parent_id != @keep_menu_id);

-- 步骤7: 验证修复结果
SELECT '修复后的"系统管理"菜单:' as info;
SELECT menu_id, menu_name, parent_id, path, component, order_num, status
FROM sys_menu 
WHERE menu_name = '系统管理';

SELECT '修复后的用户管理菜单:' as info;
SELECT menu_id, menu_name, parent_id, path, component, visible, status
FROM sys_menu 
WHERE menu_name = '用户管理';

