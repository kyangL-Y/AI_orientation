-- 诊断会员过期问题
-- 检查会员状态和实际过期时间

SELECT 
    user_id,
    level_code,
    start_date,
    end_date,
    status,
    NOW() as current_time,
    CASE 
        WHEN end_date < NOW() THEN '已过期'
        WHEN end_date >= NOW() THEN '有效'
        ELSE '未知'
    END as should_be_status,
    CASE 
        WHEN status = '已过期' AND end_date >= NOW() THEN '❌ 错误：未到期但标记为过期'
        WHEN status != '已过期' AND end_date < NOW() THEN '⚠️ 警告：已过期但未标记'
        ELSE '✅ 正常'
    END as status_check
FROM train_user_membership
WHERE user_id IN (46, 47, 45, 44, 41, 42, 43, 25, 13)
ORDER BY user_id;
