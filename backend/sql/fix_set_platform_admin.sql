-- 设置李海静为平台管理员
-- 将 admin_level 从 5 改为 0，使其拥有超级管理员权限

-- 1. 查看当前状态
SELECT user_id, user_name, admin_level, can_access_admin, status 
FROM sys_user 
WHERE user_id = 102;

-- 2. 更新李海静为平台管理员
UPDATE sys_user 
SET admin_level = 0,
    can_access_admin = 1
WHERE user_id = 102;

-- 3. 验证更新结果
SELECT user_id, user_name, admin_level, can_access_admin, status 
FROM sys_user 
WHERE user_id = 102;

-- 4. 显示所有平台管理员（admin_level = 0）
SELECT user_id, user_name, admin_level, can_access_admin, status 
FROM sys_user 
WHERE admin_level = 0
ORDER BY user_id;
