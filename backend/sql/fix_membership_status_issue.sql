-- 修复会员状态显示问题
-- 问题：有些用户的结束时间还没到，但显示为"已过期"

-- 1. 先查看问题数据
SELECT 
    membership_id,
    user_id,
    level_code,
    start_time,
    end_time,
    is_active,
    NOW() as now_time,
    DATEDIFF(end_time, NOW()) as days_remaining
FROM train_user_membership
WHERE end_time > NOW()
AND is_active = '0'
ORDER BY end_time DESC;

-- 2. 修复：将未到期但is_active=0的会员状态改为1
UPDATE train_user_membership
SET is_active = '1',
    update_time = NOW()
WHERE end_time > NOW()  -- 结束时间还没到
AND is_active = '0';    -- 但is_active被设置为0

-- 3. 验证修复结果
SELECT 
    COUNT(*) as fixed_count
FROM train_user_membership
WHERE end_time > NOW()
AND is_active = '1';
