-- 检查当前登录用户的权限
-- 用于排查405错误

-- 1. 查看所有用户及其角色（用于确认当前登录用户）
SELECT 
    u.user_id AS '用户ID',
    u.user_name AS '用户名',
    u.status AS '状态',
    r.role_id AS '角色ID',
    r.role_name AS '角色名称',
    r.status AS '角色状态'
FROM sys_user u
LEFT JOIN sys_user_role ur ON u.user_id = ur.user_id
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE u.del_flag = '0'
ORDER BY u.user_id;

-- 2. 检查特定用户（替换USER_ID为实际用户ID）是否有部门培训课程编辑权限
-- 例如：检查用户ID为1的用户
SET @user_id = 1;  -- 请替换为实际登录用户的ID

SELECT 
    u.user_id AS '用户ID',
    u.user_name AS '用户名',
    r.role_id AS '角色ID',
    r.role_name AS '角色名称',
    m.perms AS '权限标识',
    m.menu_name AS '菜单名称',
    CASE 
        WHEN m.perms = 'train:deptCourse:edit' THEN '✅ 有编辑权限'
        ELSE '❌ 无编辑权限'
    END AS '权限状态'
FROM sys_user u
INNER JOIN sys_user_role ur ON u.user_id = ur.user_id
INNER JOIN sys_role r ON ur.role_id = r.role_id
INNER JOIN sys_role_menu rm ON r.role_id = rm.role_id
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE u.user_id = @user_id
  AND m.perms LIKE 'train:deptCourse:%'
ORDER BY m.perms;

-- 3. 如果上面的查询没有返回 train:deptCourse:edit 权限，执行以下SQL为该用户角色分配权限
-- 首先查看该用户有哪些角色
SELECT 
    u.user_id AS '用户ID',
    u.user_name AS '用户名',
    r.role_id AS '角色ID',
    r.role_name AS '角色名称'
FROM sys_user u
INNER JOIN sys_user_role ur ON u.user_id = ur.user_id
INNER JOIN sys_role r ON ur.role_id = r.role_id
WHERE u.user_id = @user_id;

-- 4. 为该用户的所有角色分配部门培训课程权限（如果还没有分配）
-- 注意：请将 @user_id 替换为实际用户ID，或者直接使用角色ID
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT ur.role_id, m.menu_id 
FROM sys_user_role ur
CROSS JOIN sys_menu m
WHERE ur.user_id = @user_id
  AND m.perms IN ('train:deptCourse:list', 'train:deptCourse:query', 'train:deptCourse:add', 'train:deptCourse:edit', 'train:deptCourse:remove')
  AND NOT EXISTS (
      SELECT 1 FROM sys_role_menu rm 
      WHERE rm.role_id = ur.role_id AND rm.menu_id = m.menu_id
  );

-- 5. 验证分配结果
SELECT 
    u.user_id AS '用户ID',
    u.user_name AS '用户名',
    r.role_id AS '角色ID',
    r.role_name AS '角色名称',
    COUNT(DISTINCT m.perms) AS '已分配的权限数量'
FROM sys_user u
INNER JOIN sys_user_role ur ON u.user_id = ur.user_id
INNER JOIN sys_role r ON ur.role_id = r.role_id
INNER JOIN sys_role_menu rm ON r.role_id = rm.role_id
INNER JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE u.user_id = @user_id
  AND m.perms LIKE 'train:deptCourse:%'
GROUP BY u.user_id, u.user_name, r.role_id, r.role_name;

-- 6. 显示所有部门培训课程权限的分配情况
SELECT 
    m.perms AS '权限标识',
    m.menu_name AS '菜单名称',
    COUNT(DISTINCT rm.role_id) AS '已分配的角色数量',
    GROUP_CONCAT(DISTINCT r.role_name SEPARATOR ', ') AS '已分配的角色'
FROM sys_menu m
LEFT JOIN sys_role_menu rm ON m.menu_id = rm.menu_id
LEFT JOIN sys_role r ON rm.role_id = r.role_id
WHERE m.perms LIKE 'train:deptCourse:%'
GROUP BY m.perms, m.menu_name
ORDER BY m.perms;

