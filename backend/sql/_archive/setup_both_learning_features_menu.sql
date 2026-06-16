-- =====================================================
-- 设置学习计划和学习路径两个功能的菜单配置
-- =====================================================
-- 服务器: bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com
-- 端口: 27608
-- 数据库: hz-vue
-- =====================================================
-- 重要：请先连接到 bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608
-- 然后选择 hz-vue 数据库后执行此脚本
-- =====================================================

USE `hz-vue`;

-- =====================================================
-- 1. 查找培训中心菜单ID（父菜单）
-- =====================================================
SET @trainParentId = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' OR path = 'train' LIMIT 1);
SET @trainParentId = IFNULL(@trainParentId, 2000);

SELECT CONCAT('培训中心菜单ID: ', @trainParentId) AS '父菜单信息';

-- =====================================================
-- 2. 检查当前菜单配置
-- =====================================================
SELECT '=== 当前学习计划和路径相关菜单 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识',
    order_num AS '排序'
FROM sys_menu 
WHERE menu_name LIKE '%学习计划%' 
   OR menu_name LIKE '%学习路径%'
   OR path LIKE '%learningPlan%' 
   OR path LIKE '%learningPath%'
   OR component LIKE '%learningPlan%' 
   OR component LIKE '%learningPath%'
ORDER BY parent_id, order_num, menu_id;

-- =====================================================
-- 3. 确保"学习计划管理"菜单存在（如果不存在则创建）
-- =====================================================
INSERT INTO sys_menu 
    (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT 
    '学习计划管理', 
    @trainParentId, 
    5,  -- 排序号
    'learningPlan', 
    'train/learningPlan/index', 
    1,  -- is_frame
    0,  -- is_cache
    'C', -- 菜单类型：C-菜单
    '0', -- visible：0-显示
    '0', -- status：0-正常
    'train:plans:list', -- 权限标识
    'guide', -- 图标
    'admin', -- 创建者
    sysdate(), -- 创建时间
    '学习计划管理菜单'
WHERE NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE menu_name = '学习计划管理' OR (path = 'learningPlan' AND component = 'train/learningPlan/index')
);

-- =====================================================
-- 4. 确保"我的学习计划"菜单存在（如果不存在则创建）
-- =====================================================
INSERT INTO sys_menu 
    (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT 
    '我的学习计划', 
    @trainParentId, 
    6,  -- 排序号
    'myPlans', 
    'train/learningPlan/myPlans', 
    1,  -- is_frame
    0,  -- is_cache
    'C', -- 菜单类型：C-菜单
    '0', -- visible：0-显示
    '0', -- status：0-正常
    'train:plans:my', -- 权限标识
    'user', -- 图标
    'admin', -- 创建者
    sysdate(), -- 创建时间
    '我的学习计划菜单'
WHERE NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE menu_name = '我的学习计划' OR (path = 'myPlans' AND component = 'train/learningPlan/myPlans')
);

-- =====================================================
-- 5. 确保"学习路径管理"菜单存在（如果不存在则创建）
-- =====================================================
INSERT INTO sys_menu 
    (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT 
    '学习路径管理', 
    @trainParentId, 
    7,  -- 排序号
    'learningPath', 
    'train/learningPath/index', 
    1,  -- is_frame
    0,  -- is_cache
    'C', -- 菜单类型：C-菜单
    '0', -- visible：0-显示
    '0', -- status：0-正常
    'train:path:list', -- 权限标识
    'tree', -- 图标
    'admin', -- 创建者
    sysdate(), -- 创建时间
    '学习路径管理菜单'
WHERE NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE menu_name = '学习路径管理' OR (path = 'learningPath' AND component = 'train/learningPath/index')
);

-- =====================================================
-- 6. 确保"我的学习路径"菜单存在（如果不存在则创建）
-- =====================================================
INSERT INTO sys_menu 
    (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT 
    '我的学习路径', 
    @trainParentId, 
    8,  -- 排序号
    'myPaths', 
    'train/learningPath/myPaths', 
    1,  -- is_frame
    0,  -- is_cache
    'C', -- 菜单类型：C-菜单
    '0', -- visible：0-显示
    '0', -- status：0-正常
    'train:path:my', -- 权限标识
    'list', -- 图标
    'admin', -- 创建者
    sysdate(), -- 创建时间
    '我的学习路径菜单'
WHERE NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE menu_name = '我的学习路径' OR (path = 'myPaths' AND component = 'train/learningPath/myPaths')
);

-- =====================================================
-- 7. 为超级管理员角色分配所有菜单权限
-- =====================================================
-- 获取菜单ID
SET @planManageMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '学习计划管理' LIMIT 1);
SET @myPlansMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '我的学习计划' LIMIT 1);
SET @pathManageMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '学习路径管理' LIMIT 1);
SET @myPathsMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '我的学习路径' LIMIT 1);

-- 为超级管理员角色分配权限（如果不存在）
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, @planManageMenuId
WHERE NOT EXISTS (
    SELECT 1 FROM sys_role_menu WHERE role_id = 1 AND menu_id = @planManageMenuId
);

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, @myPlansMenuId
WHERE NOT EXISTS (
    SELECT 1 FROM sys_role_menu WHERE role_id = 1 AND menu_id = @myPlansMenuId
);

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, @pathManageMenuId
WHERE NOT EXISTS (
    SELECT 1 FROM sys_role_menu WHERE role_id = 1 AND menu_id = @pathManageMenuId
);

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, @myPathsMenuId
WHERE NOT EXISTS (
    SELECT 1 FROM sys_role_menu WHERE role_id = 1 AND menu_id = @myPathsMenuId
);

-- =====================================================
-- 8. 验证最终菜单配置
-- =====================================================
SELECT '=== 最终菜单配置 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识',
    order_num AS '排序',
    CASE menu_type 
        WHEN 'M' THEN '目录'
        WHEN 'C' THEN '菜单'
        WHEN 'F' THEN '按钮'
        ELSE menu_type
    END AS '菜单类型',
    visible AS '是否显示',
    status AS '状态'
FROM sys_menu 
WHERE menu_name IN ('学习计划管理', '我的学习计划', '学习路径管理', '我的学习路径')
   OR menu_id IN (@planManageMenuId, @myPlansMenuId, @pathManageMenuId, @myPathsMenuId)
ORDER BY order_num, menu_id;

-- =====================================================
-- 9. 验证权限分配
-- =====================================================
SELECT '=== 权限分配结果 ===' AS section;
SELECT 
    rm.role_id AS '角色ID',
    r.role_name AS '角色名称',
    rm.menu_id AS '菜单ID',
    m.menu_name AS '菜单名称'
FROM sys_role_menu rm
LEFT JOIN sys_role r ON rm.role_id = r.role_id
LEFT JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE rm.menu_id IN (@planManageMenuId, @myPlansMenuId, @pathManageMenuId, @myPathsMenuId)
ORDER BY rm.role_id, m.menu_name;

SELECT '=========================================' AS '分隔符';
SELECT '✅ 学习计划和学习路径菜单配置完成！' AS '消息';
SELECT '=========================================' AS '分隔符';

