-- 强制添加字段（即使已存在，先删除再添加，确保字段存在）
-- 在hotel_training数据库上执行

USE `hotel_training`;

-- 1. 检查path_id字段是否存在，如果不存在则添加
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'learning_plans' 
    AND COLUMN_NAME = 'path_id'
);

-- 如果不存在，添加path_id字段
SET @sql1 = IF(@col_exists = 0,
    'ALTER TABLE `learning_plans` ADD COLUMN `path_id` bigint(20) NULL COMMENT ''所属学习路径ID'' AFTER `plan_id`',
    'SELECT ''path_id字段已存在'' AS message'
);

PREPARE stmt1 FROM @sql1;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

-- 2. 检查is_required字段是否存在，如果不存在则添加
SET @col_exists2 = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'learning_plans' 
    AND COLUMN_NAME = 'is_required'
);

SET @sql2 = IF(@col_exists2 = 0,
    'ALTER TABLE `learning_plans` ADD COLUMN `is_required` tinyint(1) DEFAULT 0 COMMENT ''是否必修：1=必修，0=选修'' AFTER `path_id`',
    'SELECT ''is_required字段已存在'' AS message'
);

PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- 3. 最终验证：查看表结构
DESCRIBE `learning_plans`;

-- 4. 验证字段是否存在
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


