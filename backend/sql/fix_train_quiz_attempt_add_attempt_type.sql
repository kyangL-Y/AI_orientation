-- 修复 train_quiz_attempt 表缺少 attempt_type 字段的问题
-- 日期: 2026-01-23

USE `hz-vue`;

-- 检查字段是否存在
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hz-vue' 
  AND TABLE_NAME = 'train_quiz_attempt' 
  AND COLUMN_NAME = 'attempt_type';

-- 如果字段不存在，则添加
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_quiz_attempt ADD COLUMN attempt_type VARCHAR(20) DEFAULT ''practice'' COMMENT ''答题类型：practice-练习，exam-考试'' AFTER exam_id',
    'SELECT ''字段 attempt_type 已存在'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证字段是否添加成功
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hz-vue' 
  AND TABLE_NAME = 'train_quiz_attempt' 
  AND COLUMN_NAME = 'attempt_type';
