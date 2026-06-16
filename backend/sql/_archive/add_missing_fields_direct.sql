-- 直接添加缺失的字段（如果已存在会报错但不影响）
USE hotel_training;

-- 添加 auxiliary_data 字段
ALTER TABLE train_learning_report 
ADD COLUMN auxiliary_data JSON COMMENT '辅助数据JSON（学习时长、刷题数量等，不参与评分）' 
AFTER raw_data;

-- 添加 ai_suggestion 字段
ALTER TABLE train_learning_report 
ADD COLUMN ai_suggestion JSON COMMENT 'AI学习建议JSON' 
AFTER auxiliary_data;

-- 为现有数据设置默认值
UPDATE train_learning_report 
SET auxiliary_data = JSON_OBJECT('learning_duration', 0, 'quiz_count', 0)
WHERE auxiliary_data IS NULL;

-- 验证
SELECT '字段添加完成，验证结果：' AS message;

SHOW COLUMNS FROM train_learning_report LIKE '%suggestion%';
SHOW COLUMNS FROM train_learning_report LIKE '%auxiliary%';

SELECT '如果上面显示了字段信息，说明添加成功！' AS message;
