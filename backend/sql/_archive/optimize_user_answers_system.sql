-- 优化用户答题记录系统
-- 支持考试和刷题的统一管理，实现灵活的排行榜功能

-- ==============================================
-- 1. 创建答题会话表 (quiz_attempts)
-- ==============================================
CREATE TABLE IF NOT EXISTS `quiz_attempts` (
  `attempt_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '答题会话ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `exam_id` bigint(20) DEFAULT NULL COMMENT '考试ID（刷题时为NULL）',
  `attempt_type` enum('exam','practice') NOT NULL DEFAULT 'practice' COMMENT '答题类型：exam=考试，practice=刷题',
  `session_name` varchar(255) DEFAULT NULL COMMENT '会话名称（如：2024年第一季度考试）',
  `start_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `total_questions` int(11) DEFAULT 0 COMMENT '总题数',
  `answered_questions` int(11) DEFAULT 0 COMMENT '已答题数',
  `correct_answers` int(11) DEFAULT 0 COMMENT '正确答案数',
  `score` decimal(5,2) DEFAULT 0.00 COMMENT '得分',
  `status` enum('in_progress','completed','abandoned') NOT NULL DEFAULT 'in_progress' COMMENT '状态',
  `time_spent` int(11) DEFAULT 0 COMMENT '用时（秒）',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'IP地址',
  `user_agent` text DEFAULT NULL COMMENT '用户代理',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`attempt_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_exam_id` (`exam_id`),
  KEY `idx_attempt_type` (`attempt_type`),
  KEY `idx_status` (`status`),
  KEY `idx_start_time` (`start_time`),
  KEY `idx_user_type_time` (`user_id`, `attempt_type`, `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='答题会话表';

-- ==============================================
-- 2. 创建用户答题记录表 (user_answers)
-- ==============================================
CREATE TABLE IF NOT EXISTS `user_answers` (
  `answer_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '答题记录ID',
  `attempt_id` bigint(20) NOT NULL COMMENT '答题会话ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `selected_option` varchar(500) NOT NULL COMMENT '选择的答案（支持多选）',
  `correct_answer` varchar(500) DEFAULT NULL COMMENT '正确答案',
  `is_correct` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否正确：1=正确，0=错误',
  `answer_type` enum('exam','practice') NOT NULL DEFAULT 'practice' COMMENT '答题类型',
  `time_spent` int(11) DEFAULT 0 COMMENT '单题用时（秒）',
  `confidence_level` tinyint(1) DEFAULT NULL COMMENT '信心等级：1-5',
  `is_flagged` tinyint(1) DEFAULT 0 COMMENT '是否标记：1=标记，0=未标记',
  `answered_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '答题时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`answer_id`),
  UNIQUE KEY `uk_attempt_question` (`attempt_id`, `question_id`),
  KEY `idx_attempt_id` (`attempt_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_question_id` (`question_id`),
  KEY `idx_answer_type` (`answer_type`),
  KEY `idx_is_correct` (`is_correct`),
  KEY `idx_answered_at` (`answered_at`),
  KEY `idx_user_type_correct` (`user_id`, `answer_type`, `is_correct`),
  KEY `idx_user_type_time` (`user_id`, `answer_type`, `answered_at`),
  CONSTRAINT `fk_user_answers_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `quiz_attempts` (`attempt_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户答题记录表';

-- ==============================================
-- 3. 创建用户统计汇总表 (user_statistics)
-- ==============================================
CREATE TABLE IF NOT EXISTS `user_statistics` (
  `stat_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '统计ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `stat_type` enum('total','exam','practice') NOT NULL DEFAULT 'total' COMMENT '统计类型',
  `total_questions` int(11) DEFAULT 0 COMMENT '总答题数',
  `correct_answers` int(11) DEFAULT 0 COMMENT '正确答案数',
  `accuracy_rate` decimal(5,2) DEFAULT 0.00 COMMENT '正确率',
  `total_time_spent` int(11) DEFAULT 0 COMMENT '总用时（秒）',
  `avg_time_per_question` decimal(8,2) DEFAULT 0.00 COMMENT '平均每题用时（秒）',
  `consecutive_correct` int(11) DEFAULT 0 COMMENT '连续正确数',
  `max_consecutive_correct` int(11) DEFAULT 0 COMMENT '最大连续正确数',
  `last_activity_time` datetime DEFAULT NULL COMMENT '最后活动时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`stat_id`),
  UNIQUE KEY `uk_user_type` (`user_id`, `stat_type`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_stat_type` (`stat_type`),
  KEY `idx_accuracy_rate` (`accuracy_rate`),
  KEY `idx_total_questions` (`total_questions`),
  CONSTRAINT `fk_user_statistics_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户统计汇总表';

-- ==============================================
-- 4. 创建题目统计表 (question_statistics)
-- ==============================================
CREATE TABLE IF NOT EXISTS `question_statistics` (
  `stat_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '统计ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `total_attempts` int(11) DEFAULT 0 COMMENT '总答题次数',
  `correct_attempts` int(11) DEFAULT 0 COMMENT '正确答题次数',
  `accuracy_rate` decimal(5,2) DEFAULT 0.00 COMMENT '正确率',
  `avg_time_spent` decimal(8,2) DEFAULT 0.00 COMMENT '平均答题时间（秒）',
  `difficulty_score` decimal(3,2) DEFAULT 0.00 COMMENT '难度评分（0-1）',
  `last_attempt_time` datetime DEFAULT NULL COMMENT '最后答题时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`stat_id`),
  UNIQUE KEY `uk_question_id` (`question_id`),
  KEY `idx_accuracy_rate` (`accuracy_rate`),
  KEY `idx_difficulty_score` (`difficulty_score`),
  KEY `idx_total_attempts` (`total_attempts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='题目统计表';

-- ==============================================
-- 5. 创建排行榜缓存表 (ranking_cache)
-- ==============================================
CREATE TABLE IF NOT EXISTS `ranking_cache` (
  `cache_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '缓存ID',
  `ranking_type` enum('total','exam','practice','weekly','monthly') NOT NULL COMMENT '排行榜类型',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `rank_position` int(11) NOT NULL COMMENT '排名位置',
  `score` decimal(10,2) DEFAULT 0.00 COMMENT '得分',
  `total_questions` int(11) DEFAULT 0 COMMENT '总答题数',
  `accuracy_rate` decimal(5,2) DEFAULT 0.00 COMMENT '正确率',
  `time_period` varchar(20) DEFAULT NULL COMMENT '时间周期（如：2024-01）',
  `cache_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '缓存时间',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  PRIMARY KEY (`cache_id`),
  KEY `idx_ranking_type` (`ranking_type`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_rank_position` (`rank_position`),
  KEY `idx_time_period` (`time_period`),
  KEY `idx_expire_time` (`expire_time`),
  KEY `idx_type_period_rank` (`ranking_type`, `time_period`, `rank_position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='排行榜缓存表';

-- ==============================================
-- 6. 插入示例数据
-- ==============================================

-- 插入示例答题会话
INSERT INTO `quiz_attempts` (`user_id`, `exam_id`, `attempt_type`, `session_name`, `total_questions`, `answered_questions`, `correct_answers`, `score`, `status`, `time_spent`) VALUES
(1, NULL, 'practice', '日常刷题练习', 10, 10, 8, 80.00, 'completed', 300),
(1, 201, 'exam', '2024年第一季度考试', 20, 20, 16, 80.00, 'completed', 1200),
(2, NULL, 'practice', '前台服务练习', 15, 15, 12, 80.00, 'completed', 450),
(2, 202, 'exam', '客房服务考试', 25, 25, 20, 80.00, 'completed', 1500);

-- 插入示例答题记录
INSERT INTO `user_answers` (`attempt_id`, `user_id`, `question_id`, `selected_option`, `correct_answer`, `is_correct`, `answer_type`, `time_spent`) VALUES
(1, 1, 1001, 'A', 'A', 1, 'practice', 30),
(1, 1, 1002, 'B', 'A', 0, 'practice', 25),
(1, 1, 1003, 'C', 'C', 1, 'practice', 35),
(2, 1, 2001, 'A', 'A', 1, 'exam', 60),
(2, 1, 2002, 'B', 'B', 1, 'exam', 45),
(3, 2, 1001, 'A', 'A', 1, 'practice', 28),
(3, 2, 1002, 'A', 'A', 1, 'practice', 32);

-- 插入示例统计数据
INSERT INTO `user_statistics` (`user_id`, `stat_type`, `total_questions`, `correct_answers`, `accuracy_rate`, `total_time_spent`, `avg_time_per_question`, `consecutive_correct`, `max_consecutive_correct`) VALUES
(1, 'total', 30, 24, 80.00, 1500, 50.00, 3, 5),
(1, 'exam', 20, 16, 80.00, 1200, 60.00, 2, 4),
(1, 'practice', 10, 8, 80.00, 300, 30.00, 3, 5),
(2, 'total', 40, 32, 80.00, 1950, 48.75, 4, 6),
(2, 'exam', 25, 20, 80.00, 1500, 60.00, 3, 5),
(2, 'practice', 15, 12, 80.00, 450, 30.00, 4, 6);

-- ==============================================
-- 7. 创建存储过程：更新用户统计
-- ==============================================
DELIMITER //
CREATE PROCEDURE UpdateUserStatistics(IN p_user_id BIGINT)
BEGIN
  DECLARE v_total_questions INT DEFAULT 0;
  DECLARE v_correct_answers INT DEFAULT 0;
  DECLARE v_accuracy_rate DECIMAL(5,2) DEFAULT 0.00;
  DECLARE v_total_time INT DEFAULT 0;
  DECLARE v_avg_time DECIMAL(8,2) DEFAULT 0.00;
  DECLARE v_exam_questions INT DEFAULT 0;
  DECLARE v_exam_correct INT DEFAULT 0;
  DECLARE v_exam_accuracy DECIMAL(5,2) DEFAULT 0.00;
  DECLARE v_practice_questions INT DEFAULT 0;
  DECLARE v_practice_correct INT DEFAULT 0;
  DECLARE v_practice_accuracy DECIMAL(5,2) DEFAULT 0.00;
  
  -- 计算总统计
  SELECT 
    COUNT(*),
    SUM(is_correct),
    ROUND(AVG(is_correct) * 100, 2),
    SUM(time_spent),
    ROUND(AVG(time_spent), 2)
  INTO v_total_questions, v_correct_answers, v_accuracy_rate, v_total_time, v_avg_time
  FROM user_answers 
  WHERE user_id = p_user_id;
  
  -- 计算考试统计
  SELECT 
    COUNT(*),
    SUM(is_correct),
    ROUND(AVG(is_correct) * 100, 2)
  INTO v_exam_questions, v_exam_correct, v_exam_accuracy
  FROM user_answers 
  WHERE user_id = p_user_id AND answer_type = 'exam';
  
  -- 计算刷题统计
  SELECT 
    COUNT(*),
    SUM(is_correct),
    ROUND(AVG(is_correct) * 100, 2)
  INTO v_practice_questions, v_practice_correct, v_practice_accuracy
  FROM user_answers 
  WHERE user_id = p_user_id AND answer_type = 'practice';
  
  -- 更新总统计
  INSERT INTO user_statistics (user_id, stat_type, total_questions, correct_answers, accuracy_rate, total_time_spent, avg_time_per_question)
  VALUES (p_user_id, 'total', v_total_questions, v_correct_answers, v_accuracy_rate, v_total_time, v_avg_time)
  ON DUPLICATE KEY UPDATE
    total_questions = v_total_questions,
    correct_answers = v_correct_answers,
    accuracy_rate = v_accuracy_rate,
    total_time_spent = v_total_time,
    avg_time_per_question = v_avg_time,
    update_time = CURRENT_TIMESTAMP;
  
  -- 更新考试统计
  INSERT INTO user_statistics (user_id, stat_type, total_questions, correct_answers, accuracy_rate)
  VALUES (p_user_id, 'exam', v_exam_questions, v_exam_correct, v_exam_accuracy)
  ON DUPLICATE KEY UPDATE
    total_questions = v_exam_questions,
    correct_answers = v_exam_correct,
    accuracy_rate = v_exam_accuracy,
    update_time = CURRENT_TIMESTAMP;
  
  -- 更新刷题统计
  INSERT INTO user_statistics (user_id, stat_type, total_questions, correct_answers, accuracy_rate)
  VALUES (p_user_id, 'practice', v_practice_questions, v_practice_correct, v_practice_accuracy)
  ON DUPLICATE KEY UPDATE
    total_questions = v_practice_questions,
    correct_answers = v_practice_correct,
    accuracy_rate = v_practice_accuracy,
    update_time = CURRENT_TIMESTAMP;
END //
DELIMITER ;

-- ==============================================
-- 8. 创建触发器：自动更新统计
-- ==============================================
DELIMITER //
CREATE TRIGGER tr_user_answers_after_insert
AFTER INSERT ON user_answers
FOR EACH ROW
BEGIN
  -- 更新用户统计
  CALL UpdateUserStatistics(NEW.user_id);
  
  -- 更新题目统计
  INSERT INTO question_statistics (question_id, total_attempts, correct_attempts, accuracy_rate, avg_time_spent)
  SELECT 
    NEW.question_id,
    COUNT(*),
    SUM(is_correct),
    ROUND(AVG(is_correct) * 100, 2),
    ROUND(AVG(time_spent), 2)
  FROM user_answers 
  WHERE question_id = NEW.question_id
  ON DUPLICATE KEY UPDATE
    total_attempts = VALUES(total_attempts),
    correct_attempts = VALUES(correct_attempts),
    accuracy_rate = VALUES(accuracy_rate),
    avg_time_spent = VALUES(avg_time_spent),
    last_attempt_time = CURRENT_TIMESTAMP,
    update_time = CURRENT_TIMESTAMP;
END //
DELIMITER ;

-- ==============================================
-- 9. 创建视图：排行榜查询
-- ==============================================
CREATE VIEW v_ranking_total AS
SELECT 
  us.user_id,
  su.user_name,
  su.nick_name,
  us.total_questions,
  us.correct_answers,
  us.accuracy_rate,
  us.total_time_spent,
  us.avg_time_per_question,
  ROW_NUMBER() OVER (ORDER BY us.accuracy_rate DESC, us.total_questions DESC) as rank_position
FROM user_statistics us
JOIN sys_user su ON us.user_id = su.user_id
WHERE us.stat_type = 'total' AND us.total_questions > 0
ORDER BY us.accuracy_rate DESC, us.total_questions DESC;

CREATE VIEW v_ranking_exam AS
SELECT 
  us.user_id,
  su.user_name,
  su.nick_name,
  us.total_questions,
  us.correct_answers,
  us.accuracy_rate,
  ROW_NUMBER() OVER (ORDER BY us.accuracy_rate DESC, us.total_questions DESC) as rank_position
FROM user_statistics us
JOIN sys_user su ON us.user_id = su.user_id
WHERE us.stat_type = 'exam' AND us.total_questions > 0
ORDER BY us.accuracy_rate DESC, us.total_questions DESC;

CREATE VIEW v_ranking_practice AS
SELECT 
  us.user_id,
  su.user_name,
  su.nick_name,
  us.total_questions,
  us.correct_answers,
  us.accuracy_rate,
  ROW_NUMBER() OVER (ORDER BY us.accuracy_rate DESC, us.total_questions DESC) as rank_position
FROM user_statistics us
JOIN sys_user su ON us.user_id = su.user_id
WHERE us.stat_type = 'practice' AND us.total_questions > 0
ORDER BY us.accuracy_rate DESC, us.total_questions DESC;

-- ==============================================
-- 10. 常用查询示例
-- ==============================================

-- 查询用户答题历史
-- SELECT 
--   ua.answer_id,
--   ua.answered_at,
--   ua.selected_option,
--   ua.is_correct,
--   ua.answer_type,
--   ua.time_spent,
--   q.question_text
-- FROM user_answers ua
-- JOIN questions q ON ua.question_id = q.question_id
-- WHERE ua.user_id = 1
-- ORDER BY ua.answered_at DESC;

-- 查询排行榜（前10名）
-- SELECT * FROM v_ranking_total LIMIT 10;

-- 查询用户个人统计
-- SELECT * FROM user_statistics WHERE user_id = 1;

-- 查询题目难度分析
-- SELECT 
--   q.question_id,
--   q.question_text,
--   qs.accuracy_rate,
--   qs.difficulty_score,
--   qs.total_attempts
-- FROM questions q
-- JOIN question_statistics qs ON q.question_id = qs.question_id
-- ORDER BY qs.difficulty_score DESC;

-- 查询用户答题趋势
-- SELECT 
--   DATE(answered_at) as answer_date,
--   COUNT(*) as daily_questions,
--   AVG(is_correct) as daily_accuracy
-- FROM user_answers 
-- WHERE user_id = 1 
--   AND answered_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
-- GROUP BY DATE(answered_at)
-- ORDER BY answer_date DESC;
