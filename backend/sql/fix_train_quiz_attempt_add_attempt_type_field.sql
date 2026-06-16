-- 为 train_quiz_attempt 表添加 attempt_type 字段
-- 用于区分考试类型：practice（平时测验）或 exam（正式考试）
-- 执行时间：2026-02-05

USE hotel_training;

-- 检查字段是否已存在
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_quiz_attempt' 
  AND COLUMN_NAME = 'attempt_type';

-- 如果字段不存在，则添加
ALTER TABLE train_quiz_attempt 
ADD COLUMN IF NOT EXISTS attempt_type VARCHAR(20) DEFAULT 'practice' COMMENT '考试类型：practice-平时测验，exam-正式考试' 
AFTER exam_name;

-- 更新现有记录的 attempt_type
-- 如果 exam_id 为 NULL，则为平时测验；否则为正式考试
UPDATE train_quiz_attempt 
SET attempt_type = CASE 
    WHEN exam_id IS NULL THEN 'practice'
    ELSE 'exam'
END
WHERE attempt_type IS NULL OR attempt_type = '';

-- 验证字段是否添加成功
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_quiz_attempt' 
  AND COLUMN_NAME IN ('exam_name', 'attempt_type', 'duration_seconds')
ORDER BY ORDINAL_POSITION;

-- 查看表结构
SHOW CREATE TABLE train_quiz_attempt;

-- 统计各类型的考试记录数
SELECT 
    attempt_type,
    COUNT(*) as count,
    AVG(score) as avg_score
FROM train_quiz_attempt 
GROUP BY attempt_type;
