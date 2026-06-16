-- 验证用户权限配置
-- 检查当前登录用户是否有部门培训课程的编辑权限

-- 1. 查看所有部门培训课程相关的权限
SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    perms AS '权限标识',
    CASE menu_type 
        WHEN 'M' THEN '目录'
        WHEN 'C' THEN '菜单'
        WHEN 'F' THEN '按钮'
        ELSE menu_type
    END AS '菜单类型'
FROM sys_menu 
WHERE perms LIKE 'train:deptCourse:%' OR menu_name LIKE '%部门培训课程%'
ORDER BY menu_id;

-- 2. 查看超级管理员角色(role_id=1)是否有这些权限
SELECT 
    rm.role_id AS '角色ID',
    r.role_name AS '角色名称',
    rm.menu_id AS '菜单ID',
    m.menu_name AS '菜单名称',
    m.perms AS '权限标识'
FROM sys_role_menu rm
INNER JOIN sys_role r ON rm.role_id = r.role_id
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE m.perms LIKE 'train:deptCourse:%'
ORDER BY rm.role_id, rm.menu_id;

-- 3. 查看所有用户及其角色和权限（用于排查具体用户）
SELECT 
    u.user_id AS '用户ID',
    u.user_name AS '用户名',
    r.role_id AS '角色ID',
    r.role_name AS '角色名称',
    m.perms AS '权限标识',
    m.menu_name AS '菜单名称'
FROM sys_user u
INNER JOIN sys_user_role ur ON u.user_id = ur.user_id
INNER JOIN sys_role r ON ur.role_id = r.role_id
INNER JOIN sys_role_menu rm ON r.role_id = rm.role_id
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE m.perms = 'train:deptCourse:edit'
ORDER BY u.user_id;

-- 4. 如果上面的查询没有结果，说明用户没有权限，需要为角色分配权限
-- 执行以下SQL为超级管理员角色分配权限（如果还没有分配）
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu 
WHERE perms IN ('train:deptCourse:list', 'train:deptCourse:query', 'train:deptCourse:add', 'train:deptCourse:edit', 'train:deptCourse:remove')
AND NOT EXISTS (
    SELECT 1 FROM sys_role_menu rm 
    WHERE rm.role_id = 1 AND rm.menu_id = sys_menu.menu_id
);

-- 5. 验证结果
SELECT '=== 权限验证完成 ===' AS status;
SELECT 
    COUNT(*) AS '已分配的权限数量'
FROM sys_role_menu rm
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE rm.role_id = 1 AND m.perms LIKE 'train:deptCourse:%';

