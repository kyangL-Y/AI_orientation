-- 检查排行榜相关数据

-- 1. 检查 train_answer_attempt 表是否存在数据
USE hotel_training;

SELECT COUNT(*) as '答题记录总数' FROM train_answer_attempt;

-- 2. 检查每个用户的答题统计
SELECT 
    user_id as '用户ID',
    COUNT(*) as '答题数',
    SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as '正确数',
    ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as '正确率%',
    SUM(duration) as '总用时秒',
    ROUND(AVG(duration), 2) as '平均用时秒'
FROM train_answer_attempt
GROUP BY user_id
ORDER BY user_id;

-- 3. 查看最近的10条答题记录
SELECT 
    id,
    user_id,
    question_id,
    is_correct,
    attempt_time,
    duration,
    create_time
FROM train_answer_attempt
ORDER BY create_time DESC
LIMIT 10;

-- 4. 检查 sys_user 表中的用户
USE `hz-vue`;
SELECT user_id, user_name, nick_name FROM sys_user WHERE user_id > 2 AND del_flag = '0' LIMIT 10;

