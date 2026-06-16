-- ========================================
-- 为没有会员的用户自动开通15天免费试用
-- ========================================

-- 1. 查看当前没有会员的用户
SELECT 
    u.user_id,
    u.user_name,
    u.phonenumber,
    u.create_time,
    um.membership_id
FROM sys_user u
LEFT JOIN train_user_membership um ON u.user_id = um.user_id
WHERE um.user_id IS NULL
  AND u.user_id > 2
  AND u.del_flag = '0'
  AND u.status = '0'
ORDER BY u.create_time DESC;

-- 2. 为这些用户开通免费试用会员
INSERT INTO train_user_membership (
    user_id, 
    level_id, 
    level_code, 
    start_time, 
    end_time, 
    is_active, 
    source, 
    create_by,
    create_time,
    update_by,
    update_time
)
SELECT 
    u.user_id,
    1,  -- 免费试用版 level_id
    'free',  -- 免费试用版 level_code
    NOW(),
    DATE_ADD(NOW(), INTERVAL 15 DAY),
    '1',  -- 激活状态
    'auto_grant',  -- 自动授予
    'system',
    NOW(),
    'system',
    NOW()
FROM sys_user u
LEFT JOIN train_user_membership um ON u.user_id = um.user_id
WHERE um.user_id IS NULL
  AND u.user_id > 2
  AND u.del_flag = '0'
  AND u.status = '0';

-- 3. 查看执行结果
SELECT 
    u.user_id,
    u.user_name,
    u.phonenumber,
    u.create_time as user_create_time,
    ml.level_name,
    um.level_code,
    um.start_time,
    um.end_time,
    um.is_active,
    DATEDIFF(um.end_time, NOW()) as days_remaining
FROM sys_user u
LEFT JOIN train_user_membership um ON u.user_id = um.user_id
LEFT JOIN train_membership_level ml ON um.level_id = ml.level_id
WHERE u.create_time >= '2026-01-20'
ORDER BY u.create_time DESC;

-- 4. 统计结果
SELECT 
    '总用户数' as item,
    COUNT(*) as count
FROM sys_user
WHERE user_id > 2 AND del_flag = '0' AND status = '0'
UNION ALL
SELECT 
    '有会员用户数' as item,
    COUNT(DISTINCT um.user_id) as count
FROM train_user_membership um
WHERE um.is_active = '1'
UNION ALL
SELECT 
    '无会员用户数' as item,
    COUNT(*) as count
FROM sys_user u
LEFT JOIN train_user_membership um ON u.user_id = um.user_id
WHERE u.user_id > 2 
  AND u.del_flag = '0' 
  AND u.status = '0'
  AND um.user_id IS NULL;
