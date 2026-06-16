-- =====================================================
-- 将"学习计划管理"菜单更新为"学习路径管理"
-- =====================================================

USE `hz-vue`;

-- 1. 更新主菜单(menu_id: 2018)
UPDATE sys_menu 
SET menu_name = '学习路径管理',
    path = 'learningPath',
    component = 'train/learningPath/index'
WHERE menu_id = 2018;

-- 2. 更新子菜单的权限标识(将 trainplans 改为 path)
UPDATE sys_menu SET perms = 'train:path:query' WHERE menu_id = 2019;  -- 查询
UPDATE sys_menu SET perms = 'train:path:add' WHERE menu_id = 2020;    -- 新增
UPDATE sys_menu SET perms = 'train:path:edit' WHERE menu_id = 2021;   -- 修改
UPDATE sys_menu SET perms = 'train:path:remove' WHERE menu_id = 2022; -- 删除
UPDATE sys_menu SET perms = 'train:path:export' WHERE menu_id = 2023; -- 导出

-- 3. 更新主菜单的权限标识
UPDATE sys_menu SET perms = 'train:path:list' WHERE menu_id = 2018;

-- 4. 查看更新结果
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识'
FROM sys_menu 
WHERE menu_id IN (2018, 2019, 2020, 2021, 2022, 2023)
ORDER BY menu_id;

-- 执行完成提示
SELECT '✅ 菜单已更新为"学习路径管理"' AS 结果;

