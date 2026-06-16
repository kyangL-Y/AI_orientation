-- 验证表结构并强制刷新MySQL查询缓存
-- 在hotel_training数据库上执行

USE `hotel_training`;

-- 1. 查看完整的表结构
DESCRIBE `learning_plans`;

-- 2. 检查path_id和is_required字段详细信息
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training'
AND TABLE_NAME = 'learning_plans'
AND COLUMN_NAME IN ('path_id', 'is_required')
ORDER BY ORDINAL_POSITION;

-- 3. 尝试执行一个简单的UPDATE测试（更新path_id为NULL不会改变数据）
-- 这个操作可以验证字段确实存在
UPDATE `learning_plans` 
SET `path_id` = `path_id` 
WHERE `plan_id` = (SELECT MIN(`plan_id`) FROM (SELECT `plan_id` FROM `learning_plans` LIMIT 1) AS t)
LIMIT 1;

-- 4. 刷新表缓存（如果支持）
FLUSH TABLES `learning_plans`;

-- 5. 再次验证字段
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'learning_plans'
AND COLUMN_NAME IN ('path_id', 'is_required');


