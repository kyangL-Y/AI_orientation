-- 修正管理员级别定义
-- 区分超级管理员和平台管理员

-- admin_level 定义：
-- 0 = 超级管理员（最高权限，唯一，只有华智 user_id=1）
-- 1 = 平台管理员（次高权限，可多个，如李海静）
-- 5 = 普通管理员（需要角色权限配置）

-- ⚠️ 重要：超级管理员在系统中是唯一的，不应该有多个 admin_level=0 的用户

-- 1. 查看当前状态
SELECT user_id, user_name, admin_level, can_access_admin, status 
FROM sys_user 
WHERE user_id IN (1, 102)
ORDER BY user_id;

-- 2. 设置华智为超级管理员（admin_level = 0）
UPDATE sys_user 
SET admin_level = 0,
    can_access_admin = 1
WHERE user_id = 1;

-- 3. 设置李海静为平台管理员（admin_level = 1）
UPDATE sys_user 
SET admin_level = 1,
    can_access_admin = 1
WHERE user_id = 102;

-- 4. 验证更新结果
SELECT 
    user_id, 
    user_name, 
    admin_level,
    CASE 
        WHEN admin_level = 0 THEN '超级管理员'
        WHEN admin_level = 1 THEN '平台管理员'
        WHEN admin_level = 5 THEN '普通管理员'
        ELSE '未知级别'
    END as level_name,
    can_access_admin, 
    status 
FROM sys_user 
WHERE admin_level IN (0, 1)
ORDER BY admin_level, user_id;
