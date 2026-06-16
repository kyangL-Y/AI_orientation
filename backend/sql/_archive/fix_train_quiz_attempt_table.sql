-- 修复 hotel_training 数据库中的 train_quiz_attempt 表结构
-- 使其与代码中的实体类匹配

USE hotel_training;

-- 1. 检查并添加 attempt_type 字段
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'attempt_type');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `attempt_type` VARCHAR(20) DEFAULT ''practice'' COMMENT ''答题类型：exam=考试，practice=测验'' AFTER `exam_id`',
    'SELECT ''attempt_type already exists'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 检查并添加 question_count 字段
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'question_count');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `question_count` INT DEFAULT 0 COMMENT ''题目总数'' AFTER `duration`',
    'SELECT ''question_count already exists'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 检查并添加 correct_count 字段
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'correct_count');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `train_quiz_attempt` ADD COLUMN `correct_count` INT DEFAULT 0 COMMENT ''答对题目数'' AFTER `question_count`',
    'SELECT ''correct_count already exists'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. 检查主键字段名，如果是 id 则需要重命名为 attempt_id
-- 先检查是否存在 id 字段
SET @id_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'id');

SET @attempt_id_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'train_quiz_attempt' 
    AND COLUMN_NAME = 'attempt_id');

-- 如果存在 id 但不存在 attempt_id，则重命名
SET @sql = IF(@id_exists > 0 AND @attempt_id_exists = 0,
    'ALTER TABLE `train_quiz_attempt` CHANGE COLUMN `id` `attempt_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT ''考试尝试ID''',
    'SELECT ''attempt_id already exists or id does not exist'' as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. 显示当前表结构
DESCRIBE train_quiz_attempt;

SELECT '✅ 表结构修复完成！请检查上面的表结构是否包含以下字段：' AS message;
SELECT '   - attempt_id (主键)' AS message;
SELECT '   - attempt_type (考试类型)' AS message;
SELECT '   - question_count (题目总数)' AS message;
SELECT '   - correct_count (答对题目数)' AS message;

