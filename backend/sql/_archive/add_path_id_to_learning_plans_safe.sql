-- 为learning_plans表安全添加path_id和is_required字段
-- 如果字段已存在则跳过，不会报错

USE `hotel_training`;

-- 检查并添加path_id字段
SET @exist_path_id = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'learning_plans' 
    AND COLUMN_NAME = 'path_id'
);

SET @sql_path_id = IF(@exist_path_id = 0,
    'ALTER TABLE `learning_plans` ADD COLUMN `path_id` bigint(20) NULL COMMENT ''所属学习路径ID'' AFTER `plan_id`',
    'SELECT ''path_id字段已存在，跳过'' AS message'
);

PREPARE stmt FROM @sql_path_id;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加is_required字段
SET @exist_is_required = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'learning_plans' 
    AND COLUMN_NAME = 'is_required'
);

SET @sql_is_required = IF(@exist_is_required = 0,
    'ALTER TABLE `learning_plans` ADD COLUMN `is_required` tinyint(1) DEFAULT 0 COMMENT ''是否必修：1=必修，0=选修'' AFTER `path_id`',
    'SELECT ''is_required字段已存在，跳过'' AS message'
);

PREPARE stmt FROM @sql_is_required;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加索引
SET @exist_index = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'learning_plans' 
    AND INDEX_NAME = 'idx_path_id'
);

SET @sql_index = IF(@exist_index = 0,
    'ALTER TABLE `learning_plans` ADD INDEX `idx_path_id` (`path_id`)',
    'SELECT ''idx_path_id索引已存在，跳过'' AS message'
);

PREPARE stmt FROM @sql_index;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '字段检查完成！' AS message;

