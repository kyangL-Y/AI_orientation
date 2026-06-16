-- 测试考试记录功能
USE hotel_training;

-- 1. 检查表结构
SELECT '========== 1. 表结构检查 ==========' AS step;
SHOW CREATE TABLE train_quiz_attempt;

-- 2. 查看所有记录
SELECT '========== 2. 所有考试记录 ==========' AS step;
SELECT * FROM train_quiz_attempt ORDER BY submitted_at DESC LIMIT 20;

-- 3. 查看用户100的记录
SELECT '========== 3. 用户100的记录 ==========' AS step;
SELECT 
    attempt_id,
    user_id,
    exam_id,
    attempt_type,
    score,
    is_passed,
    question_count,
    correct_count,
    duration,
    submitted_at,
    create_time
FROM train_quiz_attempt 
WHERE user_id = 100 
ORDER BY submitted_at DESC;

-- 4. 统计信息
SELECT '========== 4. 统计信息 ==========' AS step;
SELECT 
    COUNT(*) AS total_count,
    COUNT(CASE WHEN user_id = 100 THEN 1 END) AS user_100_count,
    COUNT(CASE WHEN attempt_type = 'practice' THEN 1 END) AS practice_count,
    COUNT(CASE WHEN attempt_type = 'exam' THEN 1 END) AS exam_count
FROM train_quiz_attempt;

-- 5. 手动插入一条测试记录（用于验证）
SELECT '========== 5. 插入测试记录 ==========' AS step;
INSERT INTO train_quiz_attempt (
    user_id, 
    exam_id, 
    attempt_type, 
    score, 
    is_passed, 
    question_count, 
    correct_count, 
    duration, 
    submitted_at
) VALUES (
    100,
    NULL,
    'practice',
    85,
    1,
    20,
    17,
    1200,
    NOW()
);

SELECT '✅ 测试记录已插入' AS message;

-- 6. 再次查看用户100的记录
SELECT '========== 6. 插入后的记录 ==========' AS step;
SELECT 
    attempt_id,
    user_id,
    attempt_type,
    score,
    is_passed,
    question_count,
    correct_count,
    submitted_at
FROM train_quiz_attempt 
WHERE user_id = 100 
ORDER BY submitted_at DESC 
LIMIT 5;
