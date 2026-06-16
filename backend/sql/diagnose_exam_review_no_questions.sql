-- 诊断考试回看没有题目详情的问题
-- 执行时间: 2026-02-05

USE hotel_training;

-- 1. 查看最近的考试记录
SELECT 
    attempt_id,
    user_id,
    exam_name,
    score,
    question_count,
    correct_count,
    submitted_at,
    create_time
FROM train_quiz_attempt
ORDER BY create_time DESC
LIMIT 5;

-- 2. 查看最近考试记录的题目详情数量
SELECT 
    qa.attempt_id,
    qa.exam_name,
    qa.question_count as expected_count,
    COUNT(aa.id) as actual_count,
    qa.create_time
FROM train_quiz_attempt qa
LEFT JOIN train_answer_attempt aa ON qa.attempt_id = aa.quiz_attempt_id
WHERE qa.create_time >= DATE_SUB(NOW(), INTERVAL 2 HOUR)
GROUP BY qa.attempt_id
ORDER BY qa.create_time DESC;

-- 3. 检查 train_answer_attempt 表结构
SHOW COLUMNS FROM train_answer_attempt LIKE 'quiz_attempt_id';

-- 4. 查看 train_answer_attempt 表中最近的记录
SELECT 
    id,
    quiz_attempt_id,
    question_id,
    question_text,
    user_answer,
    correct_answer,
    is_correct,
    create_time
FROM train_answer_attempt
ORDER BY create_time DESC
LIMIT 10;

-- 5. 查看是否有 quiz_attempt_id 为 NULL 的记录
SELECT COUNT(*) as null_count
FROM train_answer_attempt
WHERE quiz_attempt_id IS NULL;

-- 6. 查看是否有 quiz_attempt_id 不为 NULL 的记录
SELECT COUNT(*) as not_null_count
FROM train_answer_attempt
WHERE quiz_attempt_id IS NOT NULL;

-- 7. 如果有数据，查看一条完整的题目详情
SELECT *
FROM train_answer_attempt
WHERE quiz_attempt_id IS NOT NULL
ORDER BY create_time DESC
LIMIT 1;
