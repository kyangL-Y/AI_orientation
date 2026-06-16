-- 为 train_answer_attempt 表添加 quiz_attempt_id 字段，用于关联考试记录
-- 执行时间: 2026-02-05

USE hotel_training;

-- 添加字段
ALTER TABLE train_answer_attempt 
ADD COLUMN quiz_attempt_id BIGINT(20) NULL COMMENT '考试记录ID，关联train_quiz_attempt表' AFTER id;

-- 添加索引以提高查询性能
ALTER TABLE train_answer_attempt 
ADD INDEX idx_quiz_attempt_id (quiz_attempt_id);

-- 验证字段添加成功
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_COMMENT 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_answer_attempt' 
  AND COLUMN_NAME = 'quiz_attempt_id';
