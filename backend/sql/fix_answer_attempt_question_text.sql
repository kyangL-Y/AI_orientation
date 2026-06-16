-- 修复 train_answer_attempt 表中 question_text 为空的记录
-- 从 train_question 和 dept_training_question 表回填题目信息

-- 1. 从 train_question 表回填
UPDATE train_answer_attempt taa
INNER JOIN train_question tq ON taa.question_id = tq.id
SET 
    taa.question_text = tq.question_text,
    taa.question_type = COALESCE(taa.question_type, tq.question_type),
    taa.option_a = COALESCE(taa.option_a, tq.option_a),
    taa.option_b = COALESCE(taa.option_b, tq.option_b),
    taa.option_c = COALESCE(taa.option_c, tq.option_c),
    taa.option_d = COALESCE(taa.option_d, tq.option_d),
    taa.correct_answer = COALESCE(taa.correct_answer, tq.correct_answer),
    taa.explanation = COALESCE(taa.explanation, tq.explanation)
WHERE taa.question_text IS NULL OR taa.question_text = '';

-- 2. 从 dept_training_question 表回填（针对部门培训题目）
UPDATE train_answer_attempt taa
INNER JOIN dept_training_question dtq ON taa.question_id = dtq.id
SET 
    taa.question_text = dtq.question_text,
    taa.question_type = COALESCE(taa.question_type, dtq.question_type),
    taa.option_a = COALESCE(taa.option_a, dtq.option_a),
    taa.option_b = COALESCE(taa.option_b, dtq.option_b),
    taa.option_c = COALESCE(taa.option_c, dtq.option_c),
    taa.option_d = COALESCE(taa.option_d, dtq.option_d),
    taa.correct_answer = COALESCE(taa.correct_answer, dtq.correct_answer),
    taa.explanation = COALESCE(taa.explanation, dtq.explanation)
WHERE taa.question_text IS NULL OR taa.question_text = '';

-- 3. 查看修复结果
SELECT 
    COUNT(*) as total_records,
    COUNT(question_text) as has_text,
    COUNT(*) - COUNT(question_text) as still_null
FROM train_answer_attempt;
