-- 检查 hotel_training 数据库中的考试记录数据
USE hotel_training;

-- 1. 查看表结构
DESCRIBE train_quiz_attempt;

-- 2. 查看所有考试记录
SELECT * FROM train_quiz_attempt ORDER BY submitted_at DESC LIMIT 20;

-- 3. 统计用户 100 的考试记录
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN attempt_type = 'exam' THEN 1 ELSE 0 END) AS exam_count,
    SUM(CASE WHEN attempt_type = 'practice' THEN 1 ELSE 0 END) AS practice_count,
    AVG(score) AS avg_score
FROM train_quiz_attempt 
WHERE user_id = 100;

-- 4. 查看用户 100 的最近 10 条记录
SELECT 
    attempt_id,
    exam_id,
    attempt_type,
    score,
    is_passed,
    question_count,
    correct_count,
    duration_seconds,
    submitted_at
FROM train_quiz_attempt 
WHERE user_id = 100 
ORDER BY submitted_at DESC 
LIMIT 10;
