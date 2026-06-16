-- 诊断考试回看功能问题
-- 检查考试记录和题目详情是否正确保存

USE hotel_training;

-- 1. 查看最近的考试记录
SELECT 
    attempt_id,
    user_id,
    exam_id,
    exam_name,
    attempt_type,
    score,
    question_count,
    correct_count,
    duration_seconds,
    submitted_at,
    create_time
FROM train_quiz_attempt
ORDER BY create_time DESC
LIMIT 5;

-- 2. 查看最近的答题详情记录
SELECT 
    id,
    quiz_attempt_id,
    user_id,
    question_id,
    is_correct,
    question_text,
    user_answer,
    correct_answer,
    create_time
FROM train_answer_attempt
ORDER BY create_time DESC
LIMIT 10;

-- 3. 检查是否有关联的题目详情（通过 quiz_attempt_id）
SELECT 
    qa.attempt_id,
    qa.exam_name,
    qa.score,
    COUNT(aa.id) as question_detail_count
FROM train_quiz_attempt qa
LEFT JOIN train_answer_attempt aa ON qa.attempt_id = aa.quiz_attempt_id
WHERE qa.create_time >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY qa.attempt_id
ORDER BY qa.create_time DESC;

-- 4. 查看 train_answer_attempt 表结构，确认 quiz_attempt_id 字段是否存在
SHOW COLUMNS FROM train_answer_attempt LIKE 'quiz_attempt_id';

SELECT '✅ 诊断查询完成' AS result;
