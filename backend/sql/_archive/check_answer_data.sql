-- 检查答题数据是否存在

-- 1. 检查 train_answer_attempt 表是否有数据
SELECT COUNT(*) as total_records FROM train_answer_attempt;

-- 2. 检查每个用户的答题记录
SELECT user_id, COUNT(*) as attempt_count, 
       MIN(attempt_time) as first_attempt, 
       MAX(attempt_time) as last_attempt
FROM train_answer_attempt
GROUP BY user_id
ORDER BY attempt_count DESC
LIMIT 10;

-- 3. 检查是否有 duration 字段数据
SELECT user_id, 
       COUNT(*) as total_attempts,
       SUM(COALESCE(duration, 0)) as total_duration,
       AVG(COALESCE(duration, 0)) as avg_duration
FROM train_answer_attempt
GROUP BY user_id
LIMIT 10;

-- 4. 检查用户表和部门信息
SELECT u.user_id, u.user_name, u.nick_name, u.dept_id, d.dept_name
FROM sys_user u
LEFT JOIN sys_dept d ON u.dept_id = d.dept_id
WHERE u.del_flag = '0'
LIMIT 10;

-- 5. 检查学习报告表
SELECT * FROM train_learning_report ORDER BY create_time DESC LIMIT 5;

-- 6. 检查某个用户的详细答题数据
SELECT * FROM train_answer_attempt 
WHERE user_id = (SELECT user_id FROM train_answer_attempt LIMIT 1)
ORDER BY attempt_time DESC
LIMIT 10;
