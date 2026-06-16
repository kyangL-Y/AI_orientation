-- 确保path_id和is_required字段存在于learning_plans表
-- 这个SQL应该在后端实际连接的数据库实例上执行
-- 后端连接：bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608/hotel_training

USE `hotel_training`;

-- 查看当前连接的数据库和服务器信息
SELECT 
    DATABASE() AS current_database,
    @@hostname AS server_hostname,
    @@port AS server_port;

-- 查看learning_plans表的当前结构
DESCRIBE `learning_plans`;

-- 检查并添加path_id字段
SET @sql1 = CONCAT(
    'ALTER TABLE `learning_plans` ',
    'ADD COLUMN IF NOT EXISTS `path_id` bigint(20) NULL COMMENT ''所属学习路径ID'' AFTER `plan_id`'
);

-- 由于IF NOT EXISTS可能不支持，使用动态SQL检查
SET @path_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'learning_plans' 
    AND COLUMN_NAME = 'path_id'
);

SET @sql_path = IF(@path_exists = 0,
    'ALTER TABLE `learning_plans` ADD COLUMN `path_id` bigint(20) NULL COMMENT ''所属学习路径ID'' AFTER `plan_id`',
    'SELECT ''path_id字段已存在，无需添加'' AS message'
);

PREPARE stmt FROM @sql_path;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加is_required字段
SET @required_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
    AND TABLE_NAME = 'learning_plans' 
    AND COLUMN_NAME = 'is_required'
);

SET @sql_required = IF(@required_exists = 0,
    'ALTER TABLE `learning_plans` ADD COLUMN `is_required` tinyint(1) DEFAULT 0 COMMENT ''是否必修：1=必修，0=选修'' AFTER `path_id`',
    'SELECT ''is_required字段已存在，无需添加'' AS message'
);

PREPARE stmt FROM @sql_required;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证字段是否都存在
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training'
AND TABLE_NAME = 'learning_plans'
AND COLUMN_NAME IN ('path_id', 'is_required')
ORDER BY ORDINAL_POSITION;

