-- 只添加 ai_suggestion 字段
USE hotel_training;

-- 添加 ai_suggestion 字段
ALTER TABLE train_learning_report 
ADD COLUMN ai_suggestion JSON COMMENT 'AI学习建议JSON' 
AFTER auxiliary_data;

-- 验证
SELECT 'ai_suggestion 字段添加完成！' AS message;

SHOW COLUMNS FROM train_learning_report LIKE '%suggestion%';
