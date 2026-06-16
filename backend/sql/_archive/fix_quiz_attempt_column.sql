-- ============================================
-- 修复 train_quiz_attempt 表的 attempt_id 列问题
-- 错误：Unknown column 'tqa.attempt_id' in 'field list'
-- ============================================

USE hotel_training;

-- 1. 首先查看当前表结构
SELECT '========== 当前表结构 ==========' AS step;
DESCRIBE train_quiz_attempt;

-- 2. 检查主键列名
SELECT '========== 检查主键列 ==========' AS step;
SELECT COLUMN_NAME, COLUMN_KEY, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
AND TABLE_NAME = 'train_quiz_attempt'
AND COLUMN_KEY = 'PRI';

-- 3. 如果主键是 id，需要重命名为 attempt_id
-- 先检查是否存在 id 字段
SET @id_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'id');

SET @attempt_id_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'attempt_id');

SELECT @id_exists AS id_exists, @attempt_id_exists AS attempt_id_exists;

-- 4. 如果存在 id 但不存在 attempt_id，则重命名
SET @sql = IF(@id_exists > 0 AND @attempt_id_exists = 0,
    'ALTER TABLE `train_quiz_attempt` CHANGE COLUMN `id` `attempt_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT ''考试尝试ID''',
    'SELECT ''✅ attempt_id 列已存在或 id 列不存在'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. 检查并添加 exam_name 字段（如果不存在）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'exam_name');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `exam_name` VARCHAR(255) DEFAULT NULL COMMENT ''考试名称'' AFTER `exam_id`',
    'SELECT ''✅ exam_name 列已存在'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 6. 检查并添加 attempt_type 字段（如果不存在）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'attempt_type');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `attempt_type` VARCHAR(20) DEFAULT ''practice'' COMMENT ''答题类型：exam=考试，practice=测验'' AFTER `exam_name`',
    'SELECT ''✅ attempt_type 列已存在'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 7. 检查并添加 question_count 字段（如果不存在）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'question_count');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `question_count` INT DEFAULT 0 COMMENT ''题目总数'' AFTER `duration`',
    'SELECT ''✅ question_count 列已存在'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 8. 检查并添加 correct_count 字段（如果不存在）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'correct_count');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `correct_count` INT DEFAULT 0 COMMENT ''答对题目数'' AFTER `question_count`',
    'SELECT ''✅ correct_count 列已存在'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 9. 显示修复后的表结构
SELECT '========== 修复后的表结构 ==========' AS step;
DESCRIBE train_quiz_attempt;

-- 10. 验证查询是否正常工作
SELECT '========== 验证查询 ==========' AS step;
SELECT attempt_id, user_id, exam_id, exam_name, attempt_type, score, submitted_at
FROM train_quiz_attempt
ORDER BY submitted_at DESC
LIMIT 5;

SELECT '✅ 修复完成！' AS result;
