-- =====================================================
-- 更新后台菜单: 学习路径管理
-- 将"学习计划管理"改为"学习路径管理"
-- =====================================================

USE hz-vue;

-- 1. 查找现有的学习计划管理菜单
SELECT menu_id, menu_name, parent_id, path, component, perms 
FROM sys_menu 
WHERE menu_name LIKE '%学习计划%' OR menu_name LIKE '%learning%plan%'
ORDER BY menu_id;

-- 2. 更新学习计划管理菜单为学习路径管理
-- 假设菜单ID需要根据查询结果调整
UPDATE sys_menu 
SET menu_name = '学习路径管理',
    path = 'learningPath',
    component = 'train/learningPath/index',
    perms = 'train:path:list',
    remark = '学习路径管理菜单'
WHERE menu_name = '学习计划管理';

-- 3. 更新子菜单权限(如果有)
UPDATE sys_menu 
SET perms = REPLACE(perms, 'train:plan:', 'train:path:')
WHERE parent_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '学习路径管理' LIMIT 1);

-- 4. 或者直接插入新的学习路径管理菜单(如果不存在学习计划菜单)
-- 先检查是否存在
SET @menu_exists = (SELECT COUNT(*) FROM sys_menu WHERE menu_name = '学习路径管理');

-- 如果不存在,插入新菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '学习路径管理', 
       (SELECT menu_id FROM sys_menu WHERE menu_name = '培训管理' OR menu_name = '系统工具' LIMIT 1),
       5,
       'learningPath',
       'train/learningPath/index',
       1,
       0,
       'C',
       '0',
       '0',
       'train:path:list',
       'route',
       'admin',
       NOW(),
       '学习路径管理菜单'
WHERE @menu_exists = 0;

-- 5. 查看最终结果
SELECT menu_id, menu_name, parent_id, order_num, path, component, perms, visible, status
FROM sys_menu 
WHERE menu_name LIKE '%学习路径%' OR menu_name LIKE '%学习计划%'
ORDER BY menu_id;

