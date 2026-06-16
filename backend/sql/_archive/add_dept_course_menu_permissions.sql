-- 部门培训课程菜单权限配置
-- 华智酒店员工培训系统

-- 1. 查找培训中心菜单ID（父菜单）
SET @train_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' AND parent_id = 0 LIMIT 1);

-- 如果培训中心菜单不存在，先创建
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, icon, create_by, create_time, remark)
SELECT '培训中心', 0, 5, 'train', NULL, 1, 0, 'M', '0', '0', 'education', 'admin', NOW(), '培训中心目录'
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE menu_name = '培训中心' AND parent_id = 0);

SET @train_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' AND parent_id = 0 LIMIT 1);

-- 2. 添加部门培训课程菜单（如果不存在）
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '部门培训课程', @train_menu_id, 2, 'deptCourse', 'train/deptCourse/index', 1, 0, 'C', '0', '0', 'train:deptCourse:list', 'peoples', 'admin', NOW(), '部门培训课程管理'
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE menu_name = '部门培训课程' AND path = 'deptCourse');

-- 获取部门培训课程菜单ID
SET @dept_course_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '部门培训课程' AND path = 'deptCourse' LIMIT 1);

-- 3. 添加部门培训课程权限按钮
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT * FROM (
    SELECT '部门培训课程查询' as menu_name, @dept_course_menu_id as parent_id, 1 as order_num, '' as path, '' as component, 1 as is_frame, 0 as is_cache, 'F' as menu_type, '0' as visible, '0' as status, 'train:deptCourse:query' as perms, '#' as icon, 'admin' as create_by, NOW() as create_time, '' as remark UNION ALL
    SELECT '部门培训课程新增', @dept_course_menu_id, 2, '', '', 1, 0, 'F', '0', '0', 'train:deptCourse:add', '#', 'admin', NOW(), '' UNION ALL
    SELECT '部门培训课程修改', @dept_course_menu_id, 3, '', '', 1, 0, 'F', '0', '0', 'train:deptCourse:edit', '#', 'admin', NOW(), '' UNION ALL
    SELECT '部门培训课程删除', @dept_course_menu_id, 4, '', '', 1, 0, 'F', '0', '0', 'train:deptCourse:remove', '#', 'admin', NOW(), ''
) t
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms IN ('train:deptCourse:query', 'train:deptCourse:add', 'train:deptCourse:edit', 'train:deptCourse:remove'));

-- 4. 为超级管理员角色分配权限（role_id = 1）
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu 
WHERE perms IN ('train:deptCourse:list', 'train:deptCourse:query', 'train:deptCourse:add', 'train:deptCourse:edit', 'train:deptCourse:remove')
AND NOT EXISTS (
    SELECT 1 FROM sys_role_menu rm 
    WHERE rm.role_id = 1 AND rm.menu_id = sys_menu.menu_id
);

-- 5. 验证添加结果
SELECT '=== 部门培训课程菜单权限配置完成 ===' AS status;
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    path AS '路由地址',
    perms AS '权限标识',
    CASE menu_type 
        WHEN 'M' THEN '目录'
        WHEN 'C' THEN '菜单'
        WHEN 'F' THEN '按钮'
        ELSE menu_type
    END AS '菜单类型'
FROM sys_menu 
WHERE menu_name LIKE '%部门培训课程%' OR perms LIKE 'train:deptCourse:%'
ORDER BY menu_id;

