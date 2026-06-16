-- =============================================
-- 修复 auxiliary_data 字段缺失问题
-- 执行库：hotel_training
-- 说明：添加 auxiliary_data 字段，不影响现有数据
-- =============================================

USE hotel_training;

-- 检查并添加 auxiliary_data 字段
ALTER TABLE train_learning_report 
ADD COLUMN IF NOT EXISTS auxiliary_data JSON COMMENT '辅助数据JSON（学习时长、刷题数量等，不参与评分）' 
AFTER dimension_scores;

-- 为现有数据设置默认值
UPDATE train_learning_report 
SET auxiliary_data = JSON_OBJECT('learning_duration', 0, 'quiz_count', 0)
WHERE auxiliary_data IS NULL;

-- 验证结果
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    COLUMN_COMMENT
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report'
  AND COLUMN_NAME = 'auxiliary_data';

SELECT '修复完成！auxiliary_data 字段已添加' AS message;
