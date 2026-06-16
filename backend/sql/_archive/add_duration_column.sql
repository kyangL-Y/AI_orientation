-- 为 train_answer_attempt 表添加 duration 字段
-- 用于记录答题用时（秒）

USE hotel_training;

-- 检查字段是否存在，如果不存在则添加
SET @dbname = DATABASE();
SET @tablename = 'train_answer_attempt';
SET @columnname = 'duration';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' INT(11) NOT NULL DEFAULT 0 COMMENT ''答题用时（秒）'' AFTER is_correct')
));

PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 验证字段是否添加成功
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training'
  AND TABLE_NAME = 'train_answer_attempt'
  AND COLUMN_NAME = 'duration';

SELECT '✅ duration 字段添加完成！' AS status;
