-- 检查learning_plans表是否存在
USE hotel_training;

-- 方法1: 查询information_schema
SELECT 
    TABLE_NAME AS '表名',
    TABLE_COMMENT AS '表注释',
    CREATE_TIME AS '创建时间'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'hotel_training' 
AND TABLE_NAME = 'learning_plans';

-- 方法2: 查看表结构(如果表存在)
SHOW CREATE TABLE learning_plans;

-- 方法3: 查看表字段(如果表存在)
DESC learning_plans;

