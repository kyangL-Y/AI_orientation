-- 检查学习数据情况

-- 1. 检查 train_answer_attempt 表结构
DESCRIBE train_answer_attempt;

-- 2. 检查是否有 duration 字段的数据
SELECT user_id, COUNT(*) as attempt_count, SUM(COALESCE(duration, 0)) as total_duration
FROM train_answer_attempt
GROUP BY user_id
LIMIT 10;

-- 3. 检查 train_practice_progress 表
DESCRIBE train_practice_progress;

-- 4. 检查练习进度数据
SELECT * FROM train_practice_progress LIMIT 10;

-- 5. 检查 train_quiz_attempt 表
DESCRIBE train_quiz_attempt;

-- 6. 检查考试记录
SELECT * FROM train_quiz_attempt LIMIT 10;

-- 7. 检查用户的答题记录
SELECT user_id, attempt_time, is_correct, duration, module_id
FROM train_answer_attempt
ORDER BY attempt_time DESC
LIMIT 20;

-- 8. 检查是否有视频学习记录表
SHOW TABLES LIKE '%learn%';
SHOW TABLES LIKE '%video%';
SHOW TABLES LIKE '%course%';
