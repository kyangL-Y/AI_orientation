-- =====================================================
-- 更新菜单名称：将"学习计划"改为"学习路径"
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
-- 1. 检查当前菜单配置
-- =====================================================
SELECT '=== 更新前的菜单配置 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识'
FROM sys_menu 
WHERE menu_name LIKE '%学习计划%' OR menu_name LIKE '%学习路径%'
   OR path LIKE '%learningPlan%' OR path LIKE '%learningPath%'
   OR component LIKE '%learningPlan%' OR component LIKE '%learningPath%'
ORDER BY menu_id;

-- =====================================================
-- 2. 更新"学习计划管理"为"学习路径管理"
-- =====================================================
UPDATE sys_menu 
SET menu_name = '学习路径管理',
    path = 'learningPath',
    component = 'train/learningPath/index'
WHERE menu_name = '学习计划管理' 
   OR (path = 'learningPlan' AND component LIKE '%learningPlan%');

-- =====================================================
-- 3. 更新"我的学习计划"为"我的学习路径"（如果存在）
-- =====================================================
UPDATE sys_menu 
SET menu_name = '我的学习路径',
    path = 'myPaths',
    component = 'train/learningPath/myPaths'
WHERE menu_name = '我的学习计划'
   OR (path = 'myPlans' AND component LIKE '%learningPlan%myPlans%');

-- =====================================================
-- 4. 更新路径为 learningPath 但名称还是学习计划的菜单
-- =====================================================
UPDATE sys_menu 
SET menu_name = CASE 
    WHEN menu_name LIKE '%学习计划管理%' THEN '学习路径管理'
    WHEN menu_name LIKE '%我的学习计划%' THEN '我的学习路径'
    WHEN menu_name = '学习计划' THEN '学习路径'
    ELSE menu_name
END
WHERE path LIKE '%learningPath%' 
   OR component LIKE '%learningPath%';

-- =====================================================
-- 5. 验证更新结果
-- =====================================================
SELECT '=== 更新后的菜单配置 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识'
FROM sys_menu 
WHERE menu_name LIKE '%学习路径%'
   OR path LIKE '%learningPath%'
   OR component LIKE '%learningPath%'
ORDER BY parent_id, order_num, menu_id;

-- =====================================================
-- 6. 检查是否还有"学习计划"相关的菜单（应该已经没有了）
-- =====================================================
SELECT '=== 检查是否还有学习计划相关菜单 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    path AS '路由地址',
    component AS '组件路径'
FROM sys_menu 
WHERE (menu_name LIKE '%学习计划%' AND menu_name NOT LIKE '%学习路径%')
   OR (path LIKE '%learningPlan%' AND path NOT LIKE '%learningPath%')
   OR (component LIKE '%learningPlan%' AND component NOT LIKE '%learningPath%');

SELECT '=========================================' AS '分隔符';
SELECT '✅ 菜单名称更新完成！' AS '消息';
SELECT '=========================================' AS '分隔符';

