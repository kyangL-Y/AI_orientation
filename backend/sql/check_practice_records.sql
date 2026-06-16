-- 查看平时测验记录统计
-- 执行时间: 2026-02-04

-- 1. 按类型统计记录数
SELECT 
    attempt_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT user_id) as unique_users,
    ROUND(AVG(score), 2) as avg_score,
    SUM(CASE WHEN is_passed = 1 THEN 1 ELSE 0 END) as passed_count,
    ROUND(SUM(CASE WHEN is_passed = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pass_rate
FROM train_quiz_attempt
GROUP BY attempt_type;

-- 2. 查看最近10条平时测验记录
SELECT 
    attempt_id,
    user_id,
    exam_name,
    score,
    is_passed,
    duration_seconds,
    DATE_FORMAT(submitted_at, '%Y-%m-%d %H:%i:%s') as submitted_time,
    attempt_type
FROM train_quiz_attempt
WHERE attempt_type = 'practice'
ORDER BY submitted_at DESC
LIMIT 10;

-- 3. 按用户统计平时测验情况
SELECT 
    user_id,
    COUNT(*) as attempt_count,
    ROUND(AVG(score), 2) as avg_score,
    MAX(score) as max_score,
    MIN(score) as min_score,
    SUM(CASE WHEN is_passed = 1 THEN 1 ELSE 0 END) as passed_count
FROM train_quiz_attempt
WHERE attempt_type = 'practice'
GROUP BY user_id
ORDER BY attempt_count DESC;
