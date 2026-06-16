-- ========================================
-- 诊断和修复考试记录问题的完整脚本
-- 数据库：hotel_training
-- ========================================

USE hotel_training;

-- ========================================
-- 第一步：检查表是否存在
-- ========================================
SELECT '========== 第一步：检查表是否存在 ==========' AS step;

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ train_quiz_attempt 表存在'
        ELSE '❌ train_quiz_attempt 表不存在，需要创建'
    END AS table_status
FROM information_schema.tables 
WHERE table_schema = 'hotel_training' 
AND table_name = 'train_quiz_attempt';

-- ========================================
-- 第二步：如果表不存在，创建表
-- ========================================
SELECT '========== 第二步：创建表（如果不存在）==========' AS step;

CREATE TABLE IF NOT EXISTS `train_quiz_attempt` (
  `attempt_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '考试尝试ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `exam_id` BIGINT(20) DEFAULT NULL COMMENT '考试ID（如果是正式考试）',
  `attempt_type` VARCHAR(20) DEFAULT 'practice' COMMENT '答题类型：exam=考试，practice=测验',
  `score` INT DEFAULT 0 COMMENT '考试总分',
  `submitted_at` DATETIME DEFAULT NULL COMMENT '提交时间',
  `is_passed` TINYINT(1) DEFAULT 0 COMMENT '是否通过（0未通过 1通过）',
  `duration` INT DEFAULT 0 COMMENT '考试总用时（秒）',
  `question_count` INT DEFAULT 0 COMMENT '题目总数',
  `correct_count` INT DEFAULT 0 COMMENT '答对题目数',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`attempt_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_exam_id` (`exam_id`),
  KEY `idx_submitted_at` (`submitted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考试答题记录表';

-- ========================================
-- 第三步：检查并添加缺失的字段
-- ========================================
SELECT '========== 第三步：检查并添加缺失字段 ==========' AS step;

-- 检查 attempt_type 字段
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'attempt_type');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `attempt_type` VARCHAR(20) DEFAULT ''practice'' COMMENT ''答题类型：exam=考试，practice=测验'' AFTER `exam_id`',
    'SELECT ''✅ attempt_type 字段已存在'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查 question_count 字段
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'question_count');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `question_count` INT DEFAULT 0 COMMENT ''题目总数'' AFTER `duration`',
    'SELECT ''✅ question_count 字段已存在'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查 correct_count 字段
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'correct_count');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `correct_count` INT DEFAULT 0 COMMENT ''答对题目数'' AFTER `question_count`',
    'SELECT ''✅ correct_count 字段已存在'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查主键字段名
SET @id_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'id');

SET @attempt_id_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'attempt_id');

SET @sql = IF(@id_exists > 0 AND @attempt_id_exists = 0,
    'ALTER TABLE `train_quiz_attempt` CHANGE COLUMN `id` `attempt_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT ''考试尝试ID''',
    'SELECT ''✅ attempt_id 字段正确'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================
-- 第四步：显示当前表结构
-- ========================================
SELECT '========== 第四步：当前表结构 ==========' AS step;
DESCRIBE train_quiz_attempt;

-- ========================================
-- 第五步：检查用户 100 的数据
-- ========================================
SELECT '========== 第五步：检查用户 100 的考试记录 ==========' AS step;

SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN attempt_type = 'exam' THEN 1 ELSE 0 END) AS exam_count,
    SUM(CASE WHEN attempt_type = 'practice' THEN 1 ELSE 0 END) AS practice_count,
    ROUND(AVG(score), 2) AS avg_score
FROM train_quiz_attempt 
WHERE user_id = 100;

-- ========================================
-- 第六步：显示最近的记录
-- ========================================
SELECT '========== 第六步：最近的考试记录 ==========' AS step;

SELECT 
    attempt_id,
    user_id,
    exam_id,
    attempt_type,
    score,
    is_passed,
    question_count,
    correct_count,
    duration,
    submitted_at
FROM train_quiz_attempt 
WHERE user_id = 100 
ORDER BY submitted_at DESC 
LIMIT 10;

-- ========================================
-- 完成提示
-- ========================================
SELECT '========================================' AS '';
SELECT '✅ 数据库诊断和修复完成！' AS message;
SELECT '========================================' AS '';
SELECT '请检查上面的输出：' AS '';
SELECT '1. 表结构是否包含所有必需字段' AS '';
SELECT '2. 用户 100 是否有考试记录' AS '';
SELECT '3. 如果没有记录，请重新做一次测验' AS '';
SELECT '4. 如果有记录但前端不显示，请重启后端服务' AS '';
