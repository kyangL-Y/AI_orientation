-- 检查learning_plans表结构

USE `hotel_training`;

-- 查看表结构
DESC `learning_plans`;

-- 检查path_id字段是否存在
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training'
AND TABLE_NAME = 'learning_plans'
AND COLUMN_NAME IN ('path_id', 'is_required');


