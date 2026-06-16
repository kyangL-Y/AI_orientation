-- 在远程数据库 hotel_training 上添加字段
-- 服务器: bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608
-- 数据库: hotel_training
-- 用户名: root
-- 密码: 使用环境变量或安全凭据管理，不要写入脚本

USE `hotel_training`;

-- 1. 添加path_id字段（使用动态SQL，如果已存在则跳过）
SET @exist_path_id = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'learning_plans' 
    AND COLUMN_NAME = 'path_id'
);

SET @sql_path = IF(@exist_path_id = 0,
    'ALTER TABLE `learning_plans` ADD COLUMN `path_id` bigint(20) NULL COMMENT ''所属学习路径ID'' AFTER `plan_id`',
    'SELECT ''path_id字段已存在，跳过'' AS message'
);

PREPARE stmt FROM @sql_path;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 添加is_required字段（使用动态SQL，如果已存在则跳过）
SET @exist_is_required = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
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

-- 3. 添加索引（使用动态SQL，如果已存在则跳过）
SET @exist_index = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
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

-- 4. 验证字段是否添加成功
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

