-- 学习统计相关查询和视图
-- 用于统计学习时长、答题时长和正确率

-- 0. 清理已存在的对象（避免重复创建错误）
-- 删除已存在的存储过程
DROP PROCEDURE IF EXISTS GetLearningTrend;
DROP PROCEDURE IF EXISTS GetLearningAchievements;

-- 删除已存在的函数
DROP FUNCTION IF EXISTS GetUserLearningStats;

-- 删除已存在的触发器
DROP TRIGGER IF EXISTS tr_update_learning_stats_after_answer;

-- 删除已存在的视图
DROP VIEW IF EXISTS v_comprehensive_learning_stats;
DROP VIEW IF EXISTS v_answer_statistics;
DROP VIEW IF EXISTS v_learning_duration_stats;

-- 删除已存在的索引
DROP INDEX IF EXISTS idx_answer_attempt_user_time ON train_answer_attempt;
DROP INDEX IF EXISTS idx_answer_attempt_user_correct ON train_answer_attempt;
DROP INDEX IF EXISTS idx_answer_attempt_time ON train_answer_attempt;

-- 1. 创建学习时长统计视图
CREATE OR REPLACE VIEW v_learning_duration_stats AS
SELECT 
    u.user_id,
    u.user_name,
    u.nick_name,
    u.avatar,
    -- 总学习时长（小时）
    COALESCE(SUM(
        CASE 
            WHEN qa.attempt_time IS NOT NULL THEN 
                TIMESTAMPDIFF(MINUTE, qa.attempt_time, qa.attempt_time + INTERVAL qa.duration SECOND) / 60.0
            ELSE 0 
        END
    ), 0) AS total_study_hours,
    -- 本月学习时长
    COALESCE(SUM(
        CASE 
            WHEN qa.attempt_time >= DATE_FORMAT(NOW(), '%Y-%m-01') THEN 
                TIMESTAMPDIFF(MINUTE, qa.attempt_time, qa.attempt_time + INTERVAL qa.duration SECOND) / 60.0
            ELSE 0 
        END
    ), 0) AS monthly_study_hours,
    -- 本周学习时长
    COALESCE(SUM(
        CASE 
            WHEN qa.attempt_time >= DATE_SUB(NOW(), INTERVAL WEEKDAY(NOW()) DAY) THEN 
                TIMESTAMPDIFF(MINUTE, qa.attempt_time, qa.attempt_time + INTERVAL qa.duration SECOND) / 60.0
            ELSE 0 
        END
    ), 0) AS weekly_study_hours,
    -- 今日学习时长
    COALESCE(SUM(
        CASE 
            WHEN DATE(qa.attempt_time) = CURDATE() THEN 
                TIMESTAMPDIFF(MINUTE, qa.attempt_time, qa.attempt_time + INTERVAL qa.duration SECOND) / 60.0
            ELSE 0 
        END
    ), 0) AS daily_study_hours,
    -- 最后学习时间
    MAX(qa.attempt_time) AS last_study_time
FROM sys_user u
LEFT JOIN train_answer_attempt qa ON u.user_id = qa.user_id
WHERE u.del_flag = '0'
GROUP BY u.user_id, u.user_name, u.nick_name, u.avatar;

-- 2. 创建答题统计视图
CREATE OR REPLACE VIEW v_answer_statistics AS
SELECT 
    u.user_id,
    u.user_name,
    u.nick_name,
    u.avatar,
    -- 总答题数
    COUNT(qa.attempt_id) AS total_questions,
    -- 正确答题数
    SUM(CASE WHEN qa.is_correct = 1 THEN 1 ELSE 0 END) AS correct_answers,
    -- 错误答题数
    SUM(CASE WHEN qa.is_correct = 0 THEN 1 ELSE 0 END) AS wrong_answers,
    -- 正确率
    CASE 
        WHEN COUNT(qa.attempt_id) > 0 THEN 
            ROUND(SUM(CASE WHEN qa.is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(qa.attempt_id), 2)
        ELSE 0 
    END AS accuracy_rate,
    -- 平均答题时长（秒）
    ROUND(AVG(qa.duration), 2) AS avg_answer_duration,
    -- 总答题时长（秒）
    SUM(qa.duration) AS total_answer_duration,
    -- 本月答题数
    SUM(CASE WHEN qa.attempt_time >= DATE_FORMAT(NOW(), '%Y-%m-01') THEN 1 ELSE 0 END) AS monthly_questions,
    -- 本周答题数
    SUM(CASE WHEN qa.attempt_time >= DATE_SUB(NOW(), INTERVAL WEEKDAY(NOW()) DAY) THEN 1 ELSE 0 END) AS weekly_questions,
    -- 今日答题数
    SUM(CASE WHEN DATE(qa.attempt_time) = CURDATE() THEN 1 ELSE 0 END) AS daily_questions,
    -- 最后答题时间
    MAX(qa.attempt_time) AS last_answer_time
FROM sys_user u
LEFT JOIN train_answer_attempt qa ON u.user_id = qa.user_id
WHERE u.del_flag = '0'
GROUP BY u.user_id, u.user_name, u.nick_name, u.avatar;

-- 3. 创建综合学习统计视图
CREATE OR REPLACE VIEW v_comprehensive_learning_stats AS
SELECT 
    ds.user_id,
    ds.user_name,
    ds.nick_name,
    ds.avatar,
    -- 学习时长统计
    ds.total_study_hours,
    ds.monthly_study_hours,
    ds.weekly_study_hours,
    ds.daily_study_hours,
    ds.last_study_time,
    -- 答题统计
    as_stats.total_questions,
    as_stats.correct_answers,
    as_stats.wrong_answers,
    as_stats.accuracy_rate,
    as_stats.avg_answer_duration,
    as_stats.total_answer_duration,
    as_stats.monthly_questions,
    as_stats.weekly_questions,
    as_stats.daily_questions,
    as_stats.last_answer_time,
    -- 计算学习活跃度
    CASE 
        WHEN ds.daily_study_hours > 2 THEN '优秀'
        WHEN ds.daily_study_hours > 1 THEN '良好'
        WHEN ds.daily_study_hours > 0.5 THEN '一般'
        ELSE '待提升'
    END AS learning_activity_level,
    -- 计算学习连续性（连续学习天数）
    (
        SELECT COUNT(DISTINCT DATE(attempt_time))
        FROM train_answer_attempt 
        WHERE user_id = ds.user_id 
        AND attempt_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    ) AS consecutive_days,
    -- 计算学习排名（基于总学习时长）
    (
        SELECT COUNT(*) + 1
        FROM v_learning_duration_stats ds2
        WHERE ds2.total_study_hours > ds.total_study_hours
    ) AS study_ranking
FROM v_learning_duration_stats ds
LEFT JOIN v_answer_statistics as_stats ON ds.user_id = as_stats.user_id;

-- 4. 创建学习趋势统计存储过程
DELIMITER //
CREATE PROCEDURE GetLearningTrend(
    IN p_user_id BIGINT,
    IN p_period VARCHAR(20) -- 'daily', 'weekly', 'monthly'
)
BEGIN
    DECLARE start_date DATE;
    DECLARE end_date DATE;
    
    -- 根据周期设置日期范围
    CASE p_period
        WHEN 'daily' THEN
            SET start_date = DATE_SUB(CURDATE(), INTERVAL 30 DAY);
            SET end_date = CURDATE();
        WHEN 'weekly' THEN
            SET start_date = DATE_SUB(CURDATE(), INTERVAL 12 WEEK);
            SET end_date = CURDATE();
        WHEN 'monthly' THEN
            SET start_date = DATE_SUB(CURDATE(), INTERVAL 12 MONTH);
            SET end_date = CURDATE();
    END CASE;
    
    -- 返回学习趋势数据
    SELECT 
        CASE p_period
            WHEN 'daily' THEN DATE(qa.attempt_time)
            WHEN 'weekly' THEN DATE(DATE_SUB(qa.attempt_time, INTERVAL WEEKDAY(qa.attempt_time) DAY))
            WHEN 'monthly' THEN DATE_FORMAT(qa.attempt_time, '%Y-%m-01')
        END AS period_date,
        COUNT(qa.attempt_id) AS question_count,
        SUM(CASE WHEN qa.is_correct = 1 THEN 1 ELSE 0 END) AS correct_count,
        ROUND(AVG(CASE WHEN qa.is_correct = 1 THEN 1 ELSE 0 END) * 100, 2) AS accuracy_rate,
        ROUND(SUM(qa.duration) / 60.0, 2) AS study_minutes,
        ROUND(AVG(qa.duration), 2) AS avg_duration
    FROM train_answer_attempt qa
    WHERE qa.user_id = p_user_id
    AND qa.attempt_time >= start_date
    AND qa.attempt_time <= end_date
    GROUP BY period_date
    ORDER BY period_date;
END //
DELIMITER ;

-- 5. 创建学习成就统计存储过程
DELIMITER //
CREATE PROCEDURE GetLearningAchievements(IN p_user_id BIGINT)
BEGIN
    DECLARE total_questions INT DEFAULT 0;
    DECLARE total_correct INT DEFAULT 0;
    DECLARE total_hours DECIMAL(10,2) DEFAULT 0;
    DECLARE consecutive_days INT DEFAULT 0;
    DECLARE max_accuracy DECIMAL(5,2) DEFAULT 0;
    
    -- 获取基础统计数据
    SELECT 
        COUNT(*),
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END),
        ROUND(SUM(duration) / 3600.0, 2)
    INTO total_questions, total_correct, total_hours
    FROM train_answer_attempt 
    WHERE user_id = p_user_id;
    
    -- 计算连续学习天数
    SELECT COUNT(DISTINCT DATE(attempt_time))
    INTO consecutive_days
    FROM train_answer_attempt 
    WHERE user_id = p_user_id 
    AND attempt_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    
    -- 计算最高正确率
    SELECT MAX(accuracy_rate)
    INTO max_accuracy
    FROM v_answer_statistics
    WHERE user_id = p_user_id;
    
    -- 返回成就数据
    SELECT 
        p_user_id AS user_id,
        total_questions,
        total_correct,
        total_hours,
        consecutive_days,
        max_accuracy,
        -- 成就判断
        CASE WHEN total_questions >= 100 THEN 1 ELSE 0 END AS achievement_100_questions,
        CASE WHEN total_questions >= 500 THEN 1 ELSE 0 END AS achievement_500_questions,
        CASE WHEN total_questions >= 1000 THEN 1 ELSE 0 END AS achievement_1000_questions,
        CASE WHEN total_hours >= 10 THEN 1 ELSE 0 END AS achievement_10_hours,
        CASE WHEN total_hours >= 50 THEN 1 ELSE 0 END AS achievement_50_hours,
        CASE WHEN total_hours >= 100 THEN 1 ELSE 0 END AS achievement_100_hours,
        CASE WHEN consecutive_days >= 7 THEN 1 ELSE 0 END AS achievement_7_days,
        CASE WHEN consecutive_days >= 30 THEN 1 ELSE 0 END AS achievement_30_days,
        CASE WHEN max_accuracy >= 90 THEN 1 ELSE 0 END AS achievement_90_accuracy,
        CASE WHEN max_accuracy >= 95 THEN 1 ELSE 0 END AS achievement_95_accuracy
    FROM DUAL;
END //
DELIMITER ;

-- 6. 创建实时统计更新触发器（需要先确保user_statistics表存在）
-- 注意：这个触发器需要user_statistics表存在才能正常工作
-- 如果表不存在，请先执行optimize_your_existing_tables.sql脚本
DELIMITER //
CREATE TRIGGER tr_update_learning_stats_after_answer
AFTER INSERT ON train_answer_attempt
FOR EACH ROW
BEGIN
    -- 检查user_statistics表是否存在
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'user_statistics') THEN
        -- 更新用户统计表
        INSERT INTO user_statistics (
            user_id, 
            stat_type, 
            total_questions, 
            correct_answers, 
            accuracy_rate, 
            total_time_spent, 
            last_activity_time,
            update_time
        ) VALUES (
            NEW.user_id,
            'total',
            1,
            CASE WHEN NEW.is_correct = 1 THEN 1 ELSE 0 END,
            CASE WHEN NEW.is_correct = 1 THEN 100.0 ELSE 0.0 END,
            NEW.duration,
            NEW.attempt_time,
            NOW()
        ) ON DUPLICATE KEY UPDATE
            total_questions = total_questions + 1,
            correct_answers = correct_answers + (CASE WHEN NEW.is_correct = 1 THEN 1 ELSE 0 END),
            accuracy_rate = ROUND((correct_answers + (CASE WHEN NEW.is_correct = 1 THEN 1 ELSE 0 END)) * 100.0 / (total_questions + 1), 2),
            total_time_spent = total_time_spent + NEW.duration,
            last_activity_time = NEW.attempt_time,
            update_time = NOW();
    END IF;
END //
DELIMITER ;

-- 7. 创建学习统计查询函数（修复聚合函数问题）
DELIMITER //
CREATE FUNCTION GetUserLearningStats(p_user_id BIGINT, p_stat_type VARCHAR(20))
RETURNS JSON
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    DECLARE done INT DEFAULT FALSE;
    DECLARE trend_data JSON DEFAULT JSON_ARRAY();
    DECLARE trend_cursor CURSOR FOR 
        SELECT 
            DATE(attempt_time) as date,
            COUNT(*) as questions,
            SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct,
            ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as accuracy,
            ROUND(SUM(duration) / 60.0, 2) as duration
        FROM train_answer_attempt
        WHERE user_id = p_user_id
        AND attempt_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY DATE(attempt_time)
        ORDER BY DATE(attempt_time);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    CASE p_stat_type
        WHEN 'overview' THEN
            SELECT JSON_OBJECT(
                'total_questions', total_questions,
                'correct_answers', correct_answers,
                'accuracy_rate', accuracy_rate,
                'total_study_hours', total_study_hours,
                'study_ranking', study_ranking,
                'learning_activity_level', learning_activity_level
            ) INTO result
            FROM v_comprehensive_learning_stats
            WHERE user_id = p_user_id;
            
        WHEN 'trend' THEN
            -- 使用游标处理趋势数据
            OPEN trend_cursor;
            read_loop: LOOP
                FETCH trend_cursor INTO @date, @questions, @correct, @accuracy, @duration;
                IF done THEN
                    LEAVE read_loop;
                END IF;
                SET trend_data = JSON_ARRAY_APPEND(trend_data, '$', JSON_OBJECT(
                    'date', @date,
                    'questions', @questions,
                    'correct', @correct,
                    'accuracy', @accuracy,
                    'duration', @duration
                ));
            END LOOP;
            CLOSE trend_cursor;
            SET result = trend_data;
            
        WHEN 'achievements' THEN
            -- 调用存储过程获取成就数据
            SET result = JSON_OBJECT('status', 'success', 'message', 'Use CALL GetLearningAchievements() instead');
    END CASE;
    
    RETURN COALESCE(result, JSON_OBJECT('error', 'No data found'));
END //
DELIMITER ;

-- 8. 创建索引优化查询性能
CREATE INDEX idx_answer_attempt_user_time ON train_answer_attempt(user_id, attempt_time);
CREATE INDEX idx_answer_attempt_user_correct ON train_answer_attempt(user_id, is_correct);
CREATE INDEX idx_answer_attempt_time ON train_answer_attempt(attempt_time);

-- 9. 简化的查询语句（避免函数中的聚合函数问题）
-- 获取用户学习统计概览
SELECT * FROM v_comprehensive_learning_stats WHERE user_id = 1;

-- 获取学习趋势数据
CALL GetLearningTrend(1, 'daily');

-- 获取学习成就
CALL GetLearningAchievements(1);

-- 简化的趋势数据查询（替代函数）
SELECT 
    DATE(attempt_time) as date,
    COUNT(*) as questions,
    SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct,
    ROUND(SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as accuracy,
    ROUND(SUM(duration) / 60.0, 2) as duration_minutes
FROM train_answer_attempt
WHERE user_id = 1
AND attempt_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(attempt_time)
ORDER BY DATE(attempt_time);

-- 获取学习时长分布
SELECT 
    'video' as type,
    '视频学习' as name,
    ROUND(SUM(CASE WHEN duration > 0 THEN duration ELSE 0 END) / 3600.0, 2) as hours,
    '#3B82F6' as color
FROM train_answer_attempt
WHERE user_id = 1
AND attempt_type = 'video'

UNION ALL

SELECT 
    'practice' as type,
    '在线练习' as name,
    ROUND(SUM(CASE WHEN duration > 0 THEN duration ELSE 0 END) / 3600.0, 2) as hours,
    '#10B981' as color
FROM train_answer_attempt
WHERE user_id = 1
AND attempt_type = 'practice'

UNION ALL

SELECT 
    'exam' as type,
    '考试答题' as name,
    ROUND(SUM(CASE WHEN duration > 0 THEN duration ELSE 0 END) / 3600.0, 2) as hours,
    '#F59E0B' as color
FROM train_answer_attempt
WHERE user_id = 1
AND attempt_type = 'exam';
