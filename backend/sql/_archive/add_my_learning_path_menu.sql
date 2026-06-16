-- =====================================================
-- 添加"我的学习路径"菜单
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
-- 1. 检查现有菜单
-- =====================================================
SELECT '=== 检查现有学习路径相关菜单 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识'
FROM sys_menu 
WHERE menu_id = 2018 OR menu_name LIKE '%学习路径%'
ORDER BY menu_id;

-- =====================================================
-- 2. 查找培训中心菜单ID（父菜单）
-- =====================================================
SET @trainParentId = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' OR path = 'train' LIMIT 1);
SET @trainParentId = IFNULL(@trainParentId, 2000);

SELECT CONCAT('培训中心菜单ID: ', @trainParentId) AS '父菜单信息';

-- =====================================================
-- 3. 检查"我的学习路径"菜单是否已存在
-- =====================================================
SET @myPathsMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '我的学习路径' LIMIT 1);

-- =====================================================
-- 4. 添加"我的学习路径"菜单（如果不存在）
-- =====================================================
INSERT INTO sys_menu 
    (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT 
    '我的学习路径', 
    @trainParentId, 
    7,  -- 排序号，放在学习路径管理之后
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
    SELECT 1 FROM sys_menu WHERE menu_name = '我的学习路径'
);

-- =====================================================
-- 5. 获取刚插入的菜单ID（如果不存在的话）
-- =====================================================
SET @newMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '我的学习路径' LIMIT 1);

-- =====================================================
-- 6. 为超级管理员角色分配"我的学习路径"权限
-- =====================================================
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, @newMenuId
WHERE NOT EXISTS (
    SELECT 1 FROM sys_role_menu WHERE role_id = 1 AND menu_id = @newMenuId
);

-- =====================================================
-- 7. 验证添加结果
-- =====================================================
SELECT '=== 添加后的菜单信息 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识',
    CASE menu_type 
        WHEN 'M' THEN '目录'
        WHEN 'C' THEN '菜单'
        WHEN 'F' THEN '按钮'
        ELSE menu_type
    END AS '菜单类型',
    visible AS '是否显示',
    status AS '状态'
FROM sys_menu 
WHERE menu_name = '我的学习路径';

-- =====================================================
-- 8. 验证权限分配
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
WHERE rm.menu_id = @newMenuId;

SELECT '=========================================' AS '分隔符';
SELECT CONCAT('✅ "我的学习路径"菜单添加完成！菜单ID: ', @newMenuId) AS '消息';
SELECT '=========================================' AS '分隔符';

