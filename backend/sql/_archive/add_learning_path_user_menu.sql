-- =====================================================
-- 添加学习路径相关用户端菜单
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
WHERE menu_id = 2018 OR menu_name LIKE '%学习路径%' OR menu_name LIKE '%学习计划%'
ORDER BY menu_id;

-- =====================================================
-- 2. 查找可用的菜单ID（从2100开始）
-- =====================================================
SELECT '=== 查找可用菜单ID ===' AS section;
SELECT 
    MAX(menu_id) AS '当前最大菜单ID',
    MAX(menu_id) + 1 AS '建议下一个菜单ID'
FROM sys_menu;

-- =====================================================
-- 3. 添加"我的学习路径"菜单（如果不存在）
-- =====================================================
SET @myPathsMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '我的学习路径' LIMIT 1);
SET @trainParentId = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' OR path = 'train' LIMIT 1);

-- 如果培训中心菜单不存在，使用2000作为默认值
SET @trainParentId = IFNULL(@trainParentId, 2000);

SET @addMyPaths = IF(@myPathsMenuId IS NULL,
    CONCAT('INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark) VALUES (\'我的学习路径\', ', @trainParentId, ', 6, \'myPaths\', \'train/learningPath/myPaths\', 1, 0, \'C\', \'0\', \'0\', \'train:path:my\', \'list\', \'admin\', sysdate(), \'我的学习路径菜单\')'),
    CONCAT('SELECT \'我的学习路径菜单已存在，menu_id=\', ', @myPathsMenuId, ' AS message')
);

PREPARE stmt FROM @addMyPaths;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================
-- 4. 确保"我的学习计划"菜单存在（如果不存在则添加）
-- =====================================================
SET @myPlansMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '我的学习计划' LIMIT 1);

SET @addMyPlans = IF(@myPlansMenuId IS NULL,
    CONCAT('INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark) VALUES (\'我的学习计划\', ', @trainParentId, ', 5, \'myPlans\', \'train/learningPlan/myPlans\', 1, 0, \'C\', \'0\', \'0\', \'train:plans:my\', \'user\', \'admin\', sysdate(), \'我的学习计划菜单\')'),
    CONCAT('SELECT \'我的学习计划菜单已存在，menu_id=\', ', @myPlansMenuId, ' AS message')
);

PREPARE stmt2 FROM @addMyPlans;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- =====================================================
-- 5. 为学习路径管理添加"分配"按钮权限（如果不存在）
-- =====================================================
SET @assignButtonId = (SELECT menu_id FROM sys_menu WHERE perms = 'train:path:assign' LIMIT 1);
SET @pathMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '学习路径管理' AND parent_id = @trainParentId LIMIT 1);

SET @pathMenuId = IFNULL(@pathMenuId, 2018);

SET @addAssignButton = IF(@assignButtonId IS NULL,
    CONCAT('INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark) VALUES (\'路径分配\', ', @pathMenuId, ', 7, \'\', \'\', 1, 0, \'F\', \'0\', \'0\', \'train:path:assign\', \'#\', \'admin\', sysdate(), \'学习路径分配权限\')'),
    CONCAT('SELECT \'分配按钮权限已存在，menu_id=\', ', @assignButtonId, ' AS message')
);

PREPARE stmt3 FROM @addAssignButton;
EXECUTE stmt3;
DEALLOCATE PREPARE stmt3;

-- =====================================================
-- 6. 验证添加结果
-- =====================================================
SELECT '=== 添加后的菜单列表 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识',
    menu_type AS '菜单类型'
FROM sys_menu 
WHERE menu_name IN ('我的学习路径', '我的学习计划', '学习路径管理', '路径分配')
   OR (parent_id = @pathMenuId AND perms = 'train:path:assign')
ORDER BY parent_id, order_num, menu_id;

-- =====================================================
-- 7. 检查学习路径管理菜单的子菜单
-- =====================================================
SELECT '=== 学习路径管理菜单及其子菜单 ===' AS section;
SELECT 
    m1.menu_id AS '菜单ID',
    m1.menu_name AS '菜单名称',
    m1.parent_id AS '父菜单ID',
    m1.path AS '路由地址',
    m1.component AS '组件路径',
    m1.perms AS '权限标识',
    CASE m1.menu_type 
        WHEN 'M' THEN '目录'
        WHEN 'C' THEN '菜单'
        WHEN 'F' THEN '按钮'
        ELSE m1.menu_type
    END AS '菜单类型'
FROM sys_menu m1
WHERE m1.menu_id = @pathMenuId 
   OR m1.parent_id = @pathMenuId
ORDER BY m1.order_num, m1.menu_id;

SELECT '=========================================' AS '分隔符';
SELECT '✅ 菜单添加完成！' AS '消息';
SELECT '=========================================' AS '分隔符';

