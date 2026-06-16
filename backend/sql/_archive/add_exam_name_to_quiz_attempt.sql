-- 为 train_quiz_attempt 表添加 exam_name 字段
-- 这样就不需要 JOIN train_exam 表了

USE hotel_training;

-- 检查字段是否存在，如果不存在则添加
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_quiz_attempt' 
  AND COLUMN_NAME = 'exam_name';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_quiz_attempt ADD COLUMN exam_name VARCHAR(255) DEFAULT NULL COMMENT ''考试名称'' AFTER exam_id',
    'SELECT ''字段 exam_name 已存在'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 查看表结构
DESC train_quiz_attempt;

-- 查看现有数据
SELECT attempt_id, user_id, exam_id, exam_name, attempt_type, score, submitted_at 
FROM train_quiz_attempt 
ORDER BY submitted_at DESC 
LIMIT 10;
