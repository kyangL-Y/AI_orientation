USE `hz-vue`;

-- 2.3 记录初始积分日志（可选，用于核对）
INSERT INTO train_user_points_log (user_id, points_change, reason, create_time)
SELECT 
    user_id, 
    SUM(CASE WHEN is_correct = 1 THEN 10 ELSE 0 END),
    '系统初始化：同步历史答题积分',
    NOW()
FROM hotel_training.train_answer_attempt
GROUP BY user_id
ON DUPLICATE KEY UPDATE 
    points_change = VALUES(points_change),
    create_time = NOW();
