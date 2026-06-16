-- ============================================
-- 在后端实际连接的数据库实例上添加字段
-- 重要：这个 SQL 必须在以下数据库实例上执行：
-- 服务器：bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com
-- 端口：27608
-- 数据库：hotel_training
-- ============================================

USE hotel_training;

-- 显示当前连接信息（用于确认）
SELECT 
    @@hostname AS '当前服务器',
    @@port AS '当前端口',
    DATABASE() AS '当前数据库';

-- 添加 path_id 字段（如果不存在）
SET @sql_path_id = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE `learning_plans` ADD COLUMN `path_id` bigint(20) NULL COMMENT ''所属学习路径ID'' AFTER `plan_id`',
        'SELECT ''path_id 字段已存在，跳过添加'' AS message'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'hotel_training' 
      AND TABLE_NAME = 'learning_plans' 
      AND COLUMN_NAME = 'path_id'
);

PREPARE stmt FROM @sql_path_id;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 is_required 字段（如果不存在）
SET @sql_is_required = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE `learning_plans` ADD COLUMN `is_required` tinyint(1) DEFAULT 0 COMMENT ''是否必学（0=否，1=是）'' AFTER `path_id`',
        'SELECT ''is_required 字段已存在，跳过添加'' AS message'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'hotel_training' 
      AND TABLE_NAME = 'learning_plans' 
      AND COLUMN_NAME = 'is_required'
);

PREPARE stmt FROM @sql_is_required;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证字段是否添加成功
SELECT 
    COLUMN_NAME AS '字段名',
    DATA_TYPE AS '数据类型',
    IS_NULLABLE AS '允许为空',
    COLUMN_DEFAULT AS '默认值',
    COLUMN_COMMENT AS '字段注释'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'learning_plans' 
  AND COLUMN_NAME IN ('path_id', 'is_required')
ORDER BY ORDINAL_POSITION;

-- 显示最终表结构
DESCRIBE learning_plans;

