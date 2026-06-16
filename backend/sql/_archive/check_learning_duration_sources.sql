-- =============================================
-- 检查学习时长数据来源
-- =============================================

-- 1. 检查课程学习进度表（train_user_course_progress）
SELECT '1. 课程学习进度表' as source_table;
SELECT 
    user_id,
    COUNT(*) as course_count,
    SUM(CASE WHEN status = 2 THEN 1 ELSE 0 END) as completed_courses,
    MIN(started_at) as first_start,
    MAX(last_learn_time) as last_learn,
    TIMESTAMPDIFF(MINUTE, MIN(started_at), MAX(last_learn_time)) as total_minutes_span
FROM train_user_course_progress
WHERE user_id = 2  -- 替换为实际用户ID
GROUP BY user_id;

-- 2. 检查视频学习进度表（train_video_progress）
SELECT '2. 视频学习进度表' as source_table;
SHOW TABLES LIKE 'train_video_progress';
-- 如果表存在，查询数据
-- SELECT user_id, SUM(watch_duration) as total_watch_minutes, COUNT(*) as video_count
-- FROM train_video_progress
-- WHERE user_id = 2
-- GROUP BY user_id;

-- 3. 检查答题记录表（train_answer_attempt）- 可以估算学习时长
SELECT '3. 答题记录表（估算时长）' as source_table;
SELECT 
    user_id,
    COUNT(*) as total_questions,
    COUNT(*) * 1 as estimated_minutes,  -- 每题按1分钟估算
    MIN(attempt_time) as first_attempt,
    MAX(attempt_time) as last_attempt,
    TIMESTAMPDIFF(MINUTE, MIN(attempt_time), MAX(attempt_time)) as time_span_minutes
FROM train_answer_attempt
WHERE user_id = 2  -- 替换为实际用户ID
GROUP BY user_id;

-- 4. 检查考试记录表（train_quiz_attempt）- 有duration字段
SELECT '4. 考试记录表（实际用时）' as source_table;
SELECT 
    user_id,
    COUNT(*) as exam_count,
    SUM(duration) as total_seconds,
    ROUND(SUM(duration) / 60, 2) as total_minutes,
    AVG(duration) as avg_seconds_per_exam
FROM train_quiz_attempt
WHERE user_id = 2  -- 替换为实际用户ID
GROUP BY user_id;

-- 5. 检查知识文章浏览记录（如果有）
SELECT '5. 知识文章表（浏览次数）' as source_table;
SELECT 
    COUNT(*) as total_articles,
    SUM(view_count) as total_views
FROM train_knowledge_article
WHERE del_flag = '0' AND status = 'published';

-- 6. 检查是否有学习时长记录表
SELECT '6. 检查所有相关表' as source_table;
SHOW TABLES LIKE 'train_%';

-- 7. 综合建议：计算学习时长的最佳方案
SELECT '7. 建议的学习时长计算方案' as recommendation;
SELECT 
    '方案1: 课程学习时长 = 课程进度表的时间跨度' as method_1,
    '方案2: 视频学习时长 = 视频进度表的watch_duration总和' as method_2,
    '方案3: 答题学习时长 = 答题数量 × 1分钟（估算）' as method_3,
    '方案4: 考试用时 = 考试记录表的duration总和' as method_4,
    '方案5: 综合时长 = 课程时长 + 视频时长 + 答题时长 + 考试用时' as method_5;

-- 8. 检查train_progress表（如果存在）
SELECT '8. 检查train_progress表' as source_table;
SHOW TABLES LIKE 'train_progress';
-- SELECT * FROM train_progress WHERE user_id = 2 LIMIT 5;

-- 9. 检查是否有学习日志表
SELECT '9. 检查学习日志表' as source_table;
SHOW TABLES LIKE '%log%';
SHOW TABLES LIKE '%record%';
