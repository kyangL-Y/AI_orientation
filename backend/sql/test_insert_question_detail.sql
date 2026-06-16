-- 测试插入题目详情数据
-- 用于验证 train_answer_attempt 表结构是否正确

USE hotel_training;

-- 插入一条测试数据
INSERT INTO train_answer_attempt (
    quiz_attempt_id,
    user_id,
    question_id,
    is_correct,
    attempt_time,
    user_answer,
    question_text,
    question_type,
    option_a,
    option_b,
    option_c,
    option_d,
    correct_answer,
    explanation,
    create_time,
    update_time
) VALUES (
    3,  -- 关联到 attempt_id = 3 的考试记录
    159,  -- 用户ID（请根据实际情况修改）
    1,  -- 题目ID
    1,  -- 是否正确
    NOW(),
    'A',  -- 用户答案
    '测试题目',
    'single',
    '选项A',
    '选项B',
    '选项C',
    '选项D',
    'A',  -- 正确答案
    '这是测试解析',
    NOW(),
    NOW()
);

-- 验证插入是否成功
SELECT 
    id,
    quiz_attempt_id,
    user_id,
    question_id,
    question_text,
    user_answer,
    correct_answer,
    is_correct
FROM train_answer_attempt
WHERE quiz_attempt_id = 3;

-- 查看关联的考试记录
SELECT 
    qa.attempt_id,
    qa.exam_name,
    qa.score,
    COUNT(aa.id) as question_detail_count
FROM train_quiz_attempt qa
LEFT JOIN train_answer_attempt aa ON qa.attempt_id = aa.quiz_attempt_id
WHERE qa.attempt_id = 3
GROUP BY qa.attempt_id;

SELECT '✅ 测试插入完成' AS result;
