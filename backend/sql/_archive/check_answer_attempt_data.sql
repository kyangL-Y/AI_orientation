-- 查看答题记录表（从库 hotel_training）

-- 1. 查看表结构
DESCRIBE train_answer_attempt;

-- 2. 查看答题记录总数
SELECT COUNT(*) AS total_records FROM train_answer_attempt;

-- 3. 查看每个用户的答题统计
SELECT 
    user_id,
    COUNT(*) as total_attempts,
    SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct_count,
    ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as accuracy_rate
FROM train_answer_attempt
GROUP BY user_id
ORDER BY total_attempts DESC
LIMIT 20;

-- 4. 查看最近的答题记录（前10条）
SELECT 
    attempt_id,
    user_id,
    question_id,
    is_correct,
    duration,
    attempt_time
FROM train_answer_attempt
ORDER BY attempt_time DESC
LIMIT 10;

-- 5. 查看有答题记录的用户数
SELECT COUNT(DISTINCT user_id) AS users_with_attempts FROM train_answer_attempt;

