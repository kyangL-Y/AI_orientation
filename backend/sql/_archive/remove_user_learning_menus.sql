-- =====================================================
-- 删除用户端菜单："我的学习计划"和"我的学习路径"
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
-- 1. 检查要删除的菜单
-- =====================================================
SELECT '=== 要删除的菜单 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识'
FROM sys_menu 
WHERE menu_name IN ('我的学习计划', '我的学习路径')
   OR (path = 'myPlans' AND component LIKE '%learningPlan%myPlans%')
   OR (path = 'myPaths' AND component LIKE '%learningPath%myPaths%');

-- =====================================================
-- 2. 获取要删除的菜单ID
-- =====================================================
SET @myPlansMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '我的学习计划' LIMIT 1);
SET @myPathsMenuId = (SELECT menu_id FROM sys_menu WHERE menu_name = '我的学习路径' LIMIT 1);

SELECT CONCAT('我的学习计划菜单ID: ', IFNULL(@myPlansMenuId, '不存在')) AS '菜单信息';
SELECT CONCAT('我的学习路径菜单ID: ', IFNULL(@myPathsMenuId, '不存在')) AS '菜单信息';

-- =====================================================
-- 3. 删除角色菜单关联（先删除关联，避免外键约束）
-- =====================================================
DELETE FROM sys_role_menu 
WHERE menu_id = @myPlansMenuId OR menu_id = @myPathsMenuId;

SELECT CONCAT('已删除角色菜单关联，影响行数: ', ROW_COUNT()) AS '删除结果';

-- =====================================================
-- 4. 删除菜单项
-- =====================================================
DELETE FROM sys_menu 
WHERE menu_name = '我的学习计划' 
   OR menu_name = '我的学习路径'
   OR (path = 'myPlans' AND component LIKE '%learningPlan%myPlans%')
   OR (path = 'myPaths' AND component LIKE '%learningPath%myPaths%');

SELECT CONCAT('已删除菜单项，影响行数: ', ROW_COUNT()) AS '删除结果';

-- =====================================================
-- 5. 验证删除结果
-- =====================================================
SELECT '=== 删除后的菜单列表 ===' AS section;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识'
FROM sys_menu 
WHERE menu_name LIKE '%学习计划%' 
   OR menu_name LIKE '%学习路径%'
   OR path LIKE '%learningPlan%' 
   OR path LIKE '%learningPath%'
ORDER BY parent_id, order_num, menu_id;

-- =====================================================
-- 6. 检查是否还有残留的关联数据
-- =====================================================
SELECT '=== 检查残留的角色菜单关联 ===' AS section;
SELECT 
    rm.role_id AS '角色ID',
    r.role_name AS '角色名称',
    rm.menu_id AS '菜单ID',
    '菜单已被删除' AS '菜单名称'
FROM sys_role_menu rm
LEFT JOIN sys_role r ON rm.role_id = r.role_id
WHERE rm.menu_id = @myPlansMenuId OR rm.menu_id = @myPathsMenuId;

-- 如果有残留关联，也删除掉
DELETE rm FROM sys_role_menu rm
WHERE (rm.menu_id = @myPlansMenuId OR rm.menu_id = @myPathsMenuId)
  AND NOT EXISTS (SELECT 1 FROM sys_menu m WHERE m.menu_id = rm.menu_id);

SELECT '=========================================' AS '分隔符';
SELECT '✅ 菜单删除完成！' AS '消息';
SELECT '保留的菜单：' AS '说明';
SELECT '  - 学习计划管理' AS '菜单1';
SELECT '  - 学习路径管理' AS '菜单2';
SELECT '已删除的菜单：' AS '说明';
SELECT '  - 我的学习计划' AS '已删除1';
SELECT '  - 我的学习路径' AS '已删除2';
SELECT '=========================================' AS '分隔符';

