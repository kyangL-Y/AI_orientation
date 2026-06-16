-- 测试：手动插入题目详情数据，验证回看功能
-- 执行时间: 2026-02-05

USE hotel_training;

-- 1. 查看最新的考试记录
SELECT attempt_id, user_id, exam_name, question_count 
FROM train_quiz_attempt 
ORDER BY create_time DESC 
LIMIT 1;

-- 2. 手动插入一条测试题目详情（使用最新的 attempt_id）
-- 注意：需要先获取上面查询的 attempt_id 和 user_id

-- 假设最新的 attempt_id = 3, user_id = 123
INSERT INTO train_answer_attempt (
    quiz_attempt_id,
    user_id,
    question_id,
    question_text,
    question_type,
    user_answer,
    correct_answer,
    option_a,
    option_b,
    option_c,
    option_d,
    explanation,
    is_correct,
    attempt_time,
    create_time,
    update_time
) VALUES (
    3,  -- quiz_attempt_id（替换为实际的 attempt_id）
    123,  -- user_id（替换为实际的 user_id）
    1001,  -- question_id
    '测试题目：酒店服务的核心是什么？',  -- question_text
    'single',  -- question_type
    'A',  -- user_answer
    'A',  -- correct_answer
    '客户满意',  -- option_a
    '利润最大化',  -- option_b
    '员工福利',  -- option_c
    '品牌知名度',  -- option_d
    '酒店服务的核心是客户满意度，这是酒店业的基本原则。',  -- explanation
    1,  -- is_correct
    NOW(),  -- attempt_time
    NOW(),  -- create_time
    NOW()   -- update_time
);

-- 3. 验证插入结果
SELECT 
    qa.attempt_id,
    qa.exam_name,
    qa.question_count,
    COUNT(aa.id) as saved_count
FROM train_quiz_attempt qa
LEFT JOIN train_answer_attempt aa ON qa.attempt_id = aa.quiz_attempt_id
WHERE qa.attempt_id = 3  -- 替换为实际的 attempt_id
GROUP BY qa.attempt_id;

-- 4. 查看插入的题目详情
SELECT * FROM train_answer_attempt 
WHERE quiz_attempt_id = 3  -- 替换为实际的 attempt_id
ORDER BY id DESC 
LIMIT 5;
