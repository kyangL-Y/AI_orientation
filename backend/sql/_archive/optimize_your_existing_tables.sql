-- 基于现有表结构优化答题记录系统
-- 优化 train_quiz_attempt 和 train_answer_attempt 表

-- ==============================================
-- 1. 优化 train_quiz_attempt 表（整场考试成绩表）
-- ==============================================

-- 添加缺失的字段（如果不存在）
-- 检查并添加 attempt_type 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND COLUMN_NAME = 'attempt_type') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `attempt_type` ENUM(''exam'',''practice'') NOT NULL DEFAULT ''practice'' COMMENT ''答题类型：exam=考试，practice=刷题'' AFTER `exam_id`',
    'SELECT ''attempt_type column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 session_name 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND COLUMN_NAME = 'session_name') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `session_name` VARCHAR(255) DEFAULT NULL COMMENT ''会话名称'' AFTER `attempt_type`',
    'SELECT ''session_name column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 start_time 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND COLUMN_NAME = 'start_time') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `start_time` DATETIME DEFAULT NULL COMMENT ''开始时间'' AFTER `session_name`',
    'SELECT ''start_time column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 end_time 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND COLUMN_NAME = 'end_time') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `end_time` DATETIME DEFAULT NULL COMMENT ''结束时间'' AFTER `start_time`',
    'SELECT ''end_time column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 status 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND COLUMN_NAME = 'status') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `status` ENUM(''in_progress'',''completed'',''abandoned'') NOT NULL DEFAULT ''in_progress'' COMMENT ''状态'' AFTER `end_time`',
    'SELECT ''status column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 ip_address 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND COLUMN_NAME = 'ip_address') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `ip_address` VARCHAR(45) DEFAULT NULL COMMENT ''IP地址'' AFTER `status`',
    'SELECT ''ip_address column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 user_agent 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND COLUMN_NAME = 'user_agent') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `user_agent` TEXT DEFAULT NULL COMMENT ''用户代理'' AFTER `ip_address`',
    'SELECT ''user_agent column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加索引优化查询性能（如果不存在）
-- 检查并添加 idx_user_id 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND INDEX_NAME = 'idx_user_id') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD INDEX `idx_user_id` (`user_id`)',
    'SELECT ''idx_user_id index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_exam_id 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND INDEX_NAME = 'idx_exam_id') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD INDEX `idx_exam_id` (`exam_id`)',
    'SELECT ''idx_exam_id index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_attempt_type 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND INDEX_NAME = 'idx_attempt_type') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD INDEX `idx_attempt_type` (`attempt_type`)',
    'SELECT ''idx_attempt_type index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_status 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND INDEX_NAME = 'idx_status') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD INDEX `idx_status` (`status`)',
    'SELECT ''idx_status index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_start_time 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND INDEX_NAME = 'idx_start_time') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD INDEX `idx_start_time` (`start_time`)',
    'SELECT ''idx_start_time index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_user_type_time 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_quiz_attempt' 
     AND INDEX_NAME = 'idx_user_type_time') = 0,
    'ALTER TABLE `train_quiz_attempt` ADD INDEX `idx_user_type_time` (`user_id`, `attempt_type`, `start_time`)',
    'SELECT ''idx_user_type_time index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==============================================
-- 2. 优化 train_answer_attempt 表（用户答题尝试记录表）
-- ==============================================

-- 添加缺失的字段（如果不存在）
-- 检查并添加 attempt_id 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND COLUMN_NAME = 'attempt_id') = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `attempt_id` BIGINT(20) DEFAULT NULL COMMENT ''关联的答题会话ID'' AFTER `id`',
    'SELECT ''attempt_id column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 selected_option 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND COLUMN_NAME = 'selected_option') = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `selected_option` VARCHAR(500) NOT NULL DEFAULT '''' COMMENT ''选择的答案'' AFTER `question_id`',
    'SELECT ''selected_option column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 correct_answer 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND COLUMN_NAME = 'correct_answer') = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `correct_answer` VARCHAR(500) DEFAULT NULL COMMENT ''正确答案'' AFTER `selected_option`',
    'SELECT ''correct_answer column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 answer_type 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND COLUMN_NAME = 'answer_type') = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `answer_type` ENUM(''exam'',''practice'') NOT NULL DEFAULT ''practice'' COMMENT ''答题类型'' AFTER `correct_answer`',
    'SELECT ''answer_type column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 confidence_level 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND COLUMN_NAME = 'confidence_level') = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `confidence_level` TINYINT(1) DEFAULT NULL COMMENT ''信心等级：1-5'' AFTER `answer_type`',
    'SELECT ''confidence_level column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 is_flagged 字段
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND COLUMN_NAME = 'is_flagged') = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `is_flagged` TINYINT(1) DEFAULT 0 COMMENT ''是否标记：1=标记，0=未标记'' AFTER `confidence_level`',
    'SELECT ''is_flagged column already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加外键约束（如果不存在）
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND CONSTRAINT_NAME = 'fk_answer_attempt_quiz') = 0,
    'ALTER TABLE `train_answer_attempt` ADD CONSTRAINT `fk_answer_attempt_quiz` FOREIGN KEY (`attempt_id`) REFERENCES `train_quiz_attempt` (`attempt_id`) ON DELETE SET NULL ON UPDATE CASCADE',
    'SELECT ''fk_answer_attempt_quiz constraint already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加索引优化查询性能（如果不存在）
-- 检查并添加 idx_attempt_id 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND INDEX_NAME = 'idx_attempt_id') = 0,
    'ALTER TABLE `train_answer_attempt` ADD INDEX `idx_attempt_id` (`attempt_id`)',
    'SELECT ''idx_attempt_id index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_user_id 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND INDEX_NAME = 'idx_user_id') = 0,
    'ALTER TABLE `train_answer_attempt` ADD INDEX `idx_user_id` (`user_id`)',
    'SELECT ''idx_user_id index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_question_id 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND INDEX_NAME = 'idx_question_id') = 0,
    'ALTER TABLE `train_answer_attempt` ADD INDEX `idx_question_id` (`question_id`)',
    'SELECT ''idx_question_id index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_answer_type 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND INDEX_NAME = 'idx_answer_type') = 0,
    'ALTER TABLE `train_answer_attempt` ADD INDEX `idx_answer_type` (`answer_type`)',
    'SELECT ''idx_answer_type index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_is_correct 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND INDEX_NAME = 'idx_is_correct') = 0,
    'ALTER TABLE `train_answer_attempt` ADD INDEX `idx_is_correct` (`is_correct`)',
    'SELECT ''idx_is_correct index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_attempt_time 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND INDEX_NAME = 'idx_attempt_time') = 0,
    'ALTER TABLE `train_answer_attempt` ADD INDEX `idx_attempt_time` (`attempt_time`)',
    'SELECT ''idx_attempt_time index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_user_type_correct 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND INDEX_NAME = 'idx_user_type_correct') = 0,
    'ALTER TABLE `train_answer_attempt` ADD INDEX `idx_user_type_correct` (`user_id`, `answer_type`, `is_correct`)',
    'SELECT ''idx_user_type_correct index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_user_type_time 索引
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'train_answer_attempt' 
     AND INDEX_NAME = 'idx_user_type_time') = 0,
    'ALTER TABLE `train_answer_attempt` ADD INDEX `idx_user_type_time` (`user_id`, `answer_type`, `attempt_time`)',
    'SELECT ''idx_user_type_time index already exists'' as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==============================================
-- 3. 创建用户统计汇总表（性能优化）
-- ==============================================
CREATE TABLE IF NOT EXISTS `user_statistics` (
  `stat_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '统计ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `stat_type` ENUM('total','exam','practice') NOT NULL DEFAULT 'total' COMMENT '统计类型',
  `total_questions` INT(11) DEFAULT 0 COMMENT '总答题数',
  `correct_answers` INT(11) DEFAULT 0 COMMENT '正确答案数',
  `accuracy_rate` DECIMAL(5,2) DEFAULT 0.00 COMMENT '正确率',
  `total_time_spent` INT(11) DEFAULT 0 COMMENT '总用时（秒）',
  `avg_time_per_question` DECIMAL(8,2) DEFAULT 0.00 COMMENT '平均每题用时（秒）',
  `consecutive_correct` INT(11) DEFAULT 0 COMMENT '连续正确数',
  `max_consecutive_correct` INT(11) DEFAULT 0 COMMENT '最大连续正确数',
  `last_activity_time` DATETIME DEFAULT NULL COMMENT '最后活动时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`stat_id`),
  UNIQUE KEY `uk_user_type` (`user_id`, `stat_type`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_stat_type` (`stat_type`),
  KEY `idx_accuracy_rate` (`accuracy_rate`),
  KEY `idx_total_questions` (`total_questions`),
  CONSTRAINT `fk_user_statistics_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户统计汇总表';

-- ==============================================
-- 4. 创建题目统计表
-- ==============================================
CREATE TABLE IF NOT EXISTS `question_statistics` (
  `stat_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '统计ID',
  `question_id` BIGINT(20) NOT NULL COMMENT '题目ID',
  `total_attempts` INT(11) DEFAULT 0 COMMENT '总答题次数',
  `correct_attempts` INT(11) DEFAULT 0 COMMENT '正确答题次数',
  `accuracy_rate` DECIMAL(5,2) DEFAULT 0.00 COMMENT '正确率',
  `avg_time_spent` DECIMAL(8,2) DEFAULT 0.00 COMMENT '平均答题时间（秒）',
  `difficulty_score` DECIMAL(3,2) DEFAULT 0.00 COMMENT '难度评分（0-1）',
  `last_attempt_time` DATETIME DEFAULT NULL COMMENT '最后答题时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`stat_id`),
  UNIQUE KEY `uk_question_id` (`question_id`),
  KEY `idx_accuracy_rate` (`accuracy_rate`),
  KEY `idx_difficulty_score` (`difficulty_score`),
  KEY `idx_total_attempts` (`total_attempts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='题目统计表';

-- ==============================================
-- 5. 创建排行榜缓存表
-- ==============================================
CREATE TABLE IF NOT EXISTS `ranking_cache` (
  `cache_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '缓存ID',
  `ranking_type` ENUM('total','exam','practice','weekly','monthly') NOT NULL COMMENT '排行榜类型',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `rank_position` INT(11) NOT NULL COMMENT '排名位置',
  `score` DECIMAL(10,2) DEFAULT 0.00 COMMENT '得分',
  `total_questions` INT(11) DEFAULT 0 COMMENT '总答题数',
  `accuracy_rate` DECIMAL(5,2) DEFAULT 0.00 COMMENT '正确率',
  `time_period` VARCHAR(20) DEFAULT NULL COMMENT '时间周期（如：2024-01）',
  `cache_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '缓存时间',
  `expire_time` DATETIME NOT NULL COMMENT '过期时间',
  PRIMARY KEY (`cache_id`),
  KEY `idx_ranking_type` (`ranking_type`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_rank_position` (`rank_position`),
  KEY `idx_time_period` (`time_period`),
  KEY `idx_expire_time` (`expire_time`),
  KEY `idx_type_period_rank` (`ranking_type`, `time_period`, `rank_position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='排行榜缓存表';

-- ==============================================
-- 6. 创建存储过程：更新用户统计
-- ==============================================
-- 删除已存在的存储过程（如果存在）
DROP PROCEDURE IF EXISTS UpdateUserStatistics;

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
    SUM(duration),
    ROUND(AVG(duration), 2)
  INTO v_total_questions, v_correct_answers, v_accuracy_rate, v_total_time, v_avg_time
  FROM train_answer_attempt 
  WHERE user_id = p_user_id;
  
  -- 计算考试统计
  SELECT 
    COUNT(*),
    SUM(is_correct),
    ROUND(AVG(is_correct) * 100, 2)
  INTO v_exam_questions, v_exam_correct, v_exam_accuracy
  FROM train_answer_attempt 
  WHERE user_id = p_user_id AND answer_type = 'exam';
  
  -- 计算刷题统计
  SELECT 
    COUNT(*),
    SUM(is_correct),
    ROUND(AVG(is_correct) * 100, 2)
  INTO v_practice_questions, v_practice_correct, v_practice_accuracy
  FROM train_answer_attempt 
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

-- 创建获取排行榜的存储过程（带排名）
DELIMITER //
CREATE PROCEDURE GetRankingWithPosition(
    IN p_ranking_type VARCHAR(20),
    IN p_limit INT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_rank INT DEFAULT 0;
    
    -- 根据类型选择不同的排行榜
    IF p_ranking_type = 'total' THEN
        SELECT 
            @rank := @rank + 1 as rank_position,
            us.user_id,
            su.user_name,
            su.nick_name,
            us.total_questions,
            us.correct_answers,
            us.accuracy_rate,
            us.total_time_spent,
            us.avg_time_per_question
        FROM user_statistics us
        JOIN sys_user su ON us.user_id = su.user_id
        CROSS JOIN (SELECT @rank := 0) r
        WHERE us.stat_type = 'total' AND us.total_questions > 0
        ORDER BY us.accuracy_rate DESC, us.total_questions DESC
        LIMIT p_limit;
    ELSEIF p_ranking_type = 'exam' THEN
        SELECT 
            @rank := @rank + 1 as rank_position,
            us.user_id,
            su.user_name,
            su.nick_name,
            us.total_questions,
            us.correct_answers,
            us.accuracy_rate
        FROM user_statistics us
        JOIN sys_user su ON us.user_id = su.user_id
        CROSS JOIN (SELECT @rank := 0) r
        WHERE us.stat_type = 'exam' AND us.total_questions > 0
        ORDER BY us.accuracy_rate DESC, us.total_questions DESC
        LIMIT p_limit;
    ELSEIF p_ranking_type = 'practice' THEN
        SELECT 
            @rank := @rank + 1 as rank_position,
            us.user_id,
            su.user_name,
            su.nick_name,
            us.total_questions,
            us.correct_answers,
            us.accuracy_rate
        FROM user_statistics us
        JOIN sys_user su ON us.user_id = su.user_id
        CROSS JOIN (SELECT @rank := 0) r
        WHERE us.stat_type = 'practice' AND us.total_questions > 0
        ORDER BY us.accuracy_rate DESC, us.total_questions DESC
        LIMIT p_limit;
    END IF;
END //
DELIMITER ;

-- ==============================================
-- 7. 创建触发器：自动更新统计
-- ==============================================
-- 删除已存在的触发器（如果存在）
DROP TRIGGER IF EXISTS tr_answer_attempt_after_insert;

DELIMITER //
CREATE TRIGGER tr_answer_attempt_after_insert
AFTER INSERT ON train_answer_attempt
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
    ROUND(AVG(duration), 2)
  FROM train_answer_attempt 
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
-- 8. 创建视图：排行榜查询（兼容老版本MySQL，不使用变量）
-- ==============================================
CREATE OR REPLACE VIEW v_ranking_total AS
SELECT 
  us.user_id,
  su.user_name,
  su.nick_name,
  us.total_questions,
  us.correct_answers,
  us.accuracy_rate,
  us.total_time_spent,
  us.avg_time_per_question
FROM user_statistics us
JOIN sys_user su ON us.user_id = su.user_id
WHERE us.stat_type = 'total' AND us.total_questions > 0
ORDER BY us.accuracy_rate DESC, us.total_questions DESC;

CREATE OR REPLACE VIEW v_ranking_exam AS
SELECT 
  us.user_id,
  su.user_name,
  su.nick_name,
  us.total_questions,
  us.correct_answers,
  us.accuracy_rate
FROM user_statistics us
JOIN sys_user su ON us.user_id = su.user_id
WHERE us.stat_type = 'exam' AND us.total_questions > 0
ORDER BY us.accuracy_rate DESC, us.total_questions DESC;

CREATE OR REPLACE VIEW v_ranking_practice AS
SELECT 
  us.user_id,
  su.user_name,
  su.nick_name,
  us.total_questions,
  us.correct_answers,
  us.accuracy_rate
FROM user_statistics us
JOIN sys_user su ON us.user_id = su.user_id
WHERE us.stat_type = 'practice' AND us.total_questions > 0
ORDER BY us.accuracy_rate DESC, us.total_questions DESC;

-- ==============================================
-- 9. 更新现有数据（如果需要）
-- ==============================================

-- 为现有的 train_quiz_attempt 记录设置默认值
UPDATE train_quiz_attempt 
SET attempt_type = 'exam' 
WHERE exam_id IS NOT NULL;

UPDATE train_quiz_attempt 
SET attempt_type = 'practice' 
WHERE exam_id IS NULL;

-- 为现有的 train_answer_attempt 记录设置默认值
UPDATE train_answer_attempt 
SET answer_type = 'practice' 
WHERE answer_type IS NULL OR answer_type = '';

-- 初始化用户统计数据
INSERT INTO user_statistics (user_id, stat_type, total_questions, correct_answers, accuracy_rate, total_time_spent, avg_time_per_question)
SELECT 
  user_id,
  'total' as stat_type,
  COUNT(*) as total_questions,
  SUM(is_correct) as correct_answers,
  ROUND(AVG(is_correct) * 100, 2) as accuracy_rate,
  SUM(duration) as total_time_spent,
  ROUND(AVG(duration), 2) as avg_time_per_question
FROM train_answer_attempt
GROUP BY user_id
ON DUPLICATE KEY UPDATE
  total_questions = VALUES(total_questions),
  correct_answers = VALUES(correct_answers),
  accuracy_rate = VALUES(accuracy_rate),
  total_time_spent = VALUES(total_time_spent),
  avg_time_per_question = VALUES(avg_time_per_question),
  update_time = CURRENT_TIMESTAMP;

-- ==============================================
-- 10. 验证优化结果
-- ==============================================

-- 查看表结构
DESCRIBE train_quiz_attempt;
DESCRIBE train_answer_attempt;
DESCRIBE user_statistics;

-- 查看索引
SHOW INDEX FROM train_quiz_attempt;
SHOW INDEX FROM train_answer_attempt;

-- 查看外键约束
SELECT 
  CONSTRAINT_NAME,
  TABLE_NAME,
  COLUMN_NAME,
  REFERENCED_TABLE_NAME,
  REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('train_quiz_attempt', 'train_answer_attempt')
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- 测试排行榜查询（使用视图，不带排名）
SELECT * FROM v_ranking_total LIMIT 5;
SELECT * FROM v_ranking_exam LIMIT 5;
SELECT * FROM v_ranking_practice LIMIT 5;

-- 测试排行榜查询（使用存储过程，带排名）
CALL GetRankingWithPosition('total', 10);
CALL GetRankingWithPosition('exam', 10);
CALL GetRankingWithPosition('practice', 10);

-- ==============================================
-- 11. 使用示例
-- ==============================================

-- 创建考试会话
-- INSERT INTO train_quiz_attempt (user_id, exam_id, attempt_type, session_name, start_time) 
-- VALUES (100, 201, 'exam', '2024年第一季度考试', NOW());

-- 记录考试答题
-- INSERT INTO train_answer_attempt (attempt_id, user_id, question_id, selected_option, correct_answer, is_correct, answer_type, duration) 
-- VALUES (1, 100, 1001, 'A', 'A', 1, 'exam', 30);

-- 创建刷题会话
-- INSERT INTO train_quiz_attempt (user_id, exam_id, attempt_type, session_name, start_time) 
-- VALUES (100, NULL, 'practice', '日常刷题练习', NOW());

-- 记录刷题答题
-- INSERT INTO train_answer_attempt (attempt_id, user_id, question_id, selected_option, correct_answer, is_correct, answer_type, duration) 
-- VALUES (2, 100, 1002, 'B', 'A', 0, 'practice', 25);

-- 查询用户答题历史
-- SELECT 
--   taa.id,
--   taa.attempt_time,
--   taa.selected_option,
--   taa.is_correct,
--   taa.answer_type,
--   taa.duration,
--   tq.question_text
-- FROM train_answer_attempt taa
-- JOIN train_question tq ON taa.question_id = tq.question_id
-- WHERE taa.user_id = 100
-- ORDER BY taa.attempt_time DESC;

-- 查询排行榜（前10名）
-- SELECT * FROM v_ranking_total LIMIT 10;

-- 查询用户个人统计
-- SELECT * FROM user_statistics WHERE user_id = 100;
