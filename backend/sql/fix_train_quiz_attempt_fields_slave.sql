-- 为从库 hotel_training 的 train_quiz_attempt 表添加 duration_seconds 字段
-- 执行时间: 2026-02-05
-- 目的: 修复考试记录保存失败的问题（Unknown column 'duration_seconds'）
-- 状态: ✅ 已执行完成

USE hotel_training;

-- 添加 duration_seconds 字段（如果不存在）
-- 注意：MySQL 不支持 IF NOT EXISTS，需要先检查
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_quiz_attempt' 
  AND COLUMN_NAME = 'duration_seconds';

-- 如果字段不存在，则添加
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_quiz_attempt ADD COLUMN duration_seconds INT NULL COMMENT ''答题时长(秒)'' AFTER submitted_at',
    'SELECT ''字段 duration_seconds 已存在'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证字段是否添加成功
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_quiz_attempt'
  AND COLUMN_NAME = 'duration_seconds';

SELECT '✅ duration_seconds 字段添加完成' AS result;
