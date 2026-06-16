-- 修复排行榜：批量更新所有用户的统计数据
-- 执行时间: 2026-02-05
-- 问题: user_statistics 表为空,导致排行榜不显示任何记录

USE hz-vue;

-- 1. 获取所有有答题记录的用户并更新统计
-- 注意: train_answer_attempt 在 hotel_training 库,需要跨库查询

-- 清空现有统计数据(如果需要重新计算)
-- TRUNCATE TABLE user_statistics;

-- 批量插入/更新所有用户的总统计
INSERT INTO user_statistics (user_id, stat_type, total_questions, correct_answers, accuracy_rate, total_time_spent, avg_time_per_question, last_activity_time, create_time, update_time)
SELECT 
    user_id,
    'total' as stat_type,
    COUNT(*) as total_questions,
    SUM(is_correct) as correct_answers,
    ROUND(AVG(is_correct) * 100, 2) as accuracy_rate,
    SUM(duration) as total_time_spent,
    ROUND(AVG(duration), 2) as avg_time_per_question,
    MAX(submit_time) as last_activity_time,
    NOW() as create_time,
    NOW() as update_time
FROM hotel_training.train_answer_attempt
WHERE submit_time IS NOT NULL
GROUP BY user_id
ON DUPLICATE KEY UPDATE
    total_questions = VALUES(total_questions),
    correct_answers = VALUES(correct_answers),
    accuracy_rate = VALUES(accuracy_rate),
    total_time_spent = VALUES(total_time_spent),
    avg_time_per_question = VALUES(avg_time_per_question),
    last_activity_time = VALUES(last_activity_time),
    update_time = NOW();

-- 批量插入/更新所有用户的考试统计
INSERT INTO user_statistics (user_id, stat_type, total_questions, correct_answers, accuracy_rate, last_activity_time, create_time, update_time)
SELECT 
    user_id,
    'exam' as stat_type,
    COUNT(*) as total_questions,
    SUM(is_correct) as correct_answers,
    ROUND(AVG(is_correct) * 100, 2) as accuracy_rate,
    MAX(submit_time) as last_activity_time,
    NOW() as create_time,
    NOW() as update_time
FROM hotel_training.train_answer_attempt
WHERE submit_time IS NOT NULL AND answer_type = 'exam'
GROUP BY user_id
ON DUPLICATE KEY UPDATE
    total_questions = VALUES(total_questions),
    correct_answers = VALUES(correct_answers),
    accuracy_rate = VALUES(accuracy_rate),
    last_activity_time = VALUES(last_activity_time),
    update_time = NOW();

-- 批量插入/更新所有用户的练习统计
INSERT INTO user_statistics (user_id, stat_type, total_questions, correct_answers, accuracy_rate, last_activity_time, create_time, update_time)
SELECT 
    user_id,
    'practice' as stat_type,
    COUNT(*) as total_questions,
    SUM(is_correct) as correct_answers,
    ROUND(AVG(is_correct) * 100, 2) as accuracy_rate,
    MAX(submit_time) as last_activity_time,
    NOW() as create_time,
    NOW() as update_time
FROM hotel_training.train_answer_attempt
WHERE submit_time IS NOT NULL AND answer_type = 'practice'
GROUP BY user_id
ON DUPLICATE KEY UPDATE
    total_questions = VALUES(total_questions),
    correct_answers = VALUES(correct_answers),
    accuracy_rate = VALUES(accuracy_rate),
    last_activity_time = VALUES(last_activity_time),
    update_time = NOW();

-- 查询更新结果
SELECT 
    stat_type,
    COUNT(*) as user_count,
    SUM(total_questions) as total_questions,
    AVG(accuracy_rate) as avg_accuracy
FROM user_statistics
GROUP BY stat_type;

SELECT '排行榜统计数据已更新完成!' as message;
