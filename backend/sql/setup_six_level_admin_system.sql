-- 建立五级管理体系
-- 数字越小，级别越高，权限越大

-- admin_level 定义：
-- 0 = 超级管理员（系统最高权限，唯一）
-- 1 = 平台管理员（平台级管理，可多个）
-- 2 = 集团管理员（集团级管理）
-- 3 = 公司管理员（公司级管理）
-- 4 = 部门管理员（部门级管理）
-- null/999 = 普通用户（无管理权限）

-- 1. 查看当前管理员分布
SELECT 
    admin_level,
    CASE 
        WHEN admin_level = 0 THEN '超级管理员'
        WHEN admin_level = 1 THEN '平台管理员'
        WHEN admin_level = 2 THEN '集团管理员'
        WHEN admin_level = 3 THEN '公司管理员'
        WHEN admin_level = 4 THEN '部门管理员'
        ELSE '未知级别'
    END as level_name,
    COUNT(*) as count
FROM sys_user 
WHERE admin_level IS NOT NULL
GROUP BY admin_level
ORDER BY admin_level;

-- 2. 查看当前所有管理员
SELECT 
    user_id,
    user_name,
    admin_level,
    CASE 
        WHEN admin_level = 0 THEN '超级管理员'
        WHEN admin_level = 1 THEN '平台管理员'
        WHEN admin_level = 2 THEN '集团管理员'
        WHEN admin_level = 3 THEN '公司管理员'
        WHEN admin_level = 4 THEN '部门管理员'
        ELSE '未知级别'
    END as level_name,
    can_access_admin,
    status
FROM sys_user 
WHERE admin_level IN (0, 1, 2, 3, 4)
ORDER BY admin_level, user_id;

-- 3. 示例：设置不同级别的管理员（根据实际需求调整）
-- 注意：只有更高级别的管理员才能设置低级别的管理员

-- 设置集团管理员示例（需要超级管理员或平台管理员操作）
-- UPDATE sys_user SET admin_level = 2, can_access_admin = 1 WHERE user_id = ?;

-- 设置公司管理员示例（需要超级管理员、平台管理员或集团管理员操作）
-- UPDATE sys_user SET admin_level = 3, can_access_admin = 1 WHERE user_id = ?;

-- 设置部门管理员示例（需要超级管理员、平台管理员、集团管理员或公司管理员操作）
-- UPDATE sys_user SET admin_level = 4, can_access_admin = 1 WHERE user_id = ?;
