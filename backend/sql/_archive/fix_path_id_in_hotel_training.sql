-- ============================================
-- 在后端实际使用的数据库上添加 path_id 和 is_required 字段
-- 数据库：hotel_training（从库 SLAVE）
-- 主机：bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608
-- ============================================

USE hotel_training;

-- 检查表是否存在
SELECT 
    TABLE_NAME,
    TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'learning_plans';

-- 显示当前表结构（用于确认）
DESCRIBE learning_plans;

-- 检查 path_id 字段是否存在
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

-- ============================================
-- 添加字段（如果不存在）
-- ============================================

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

-- 显示最终表结构
DESCRIBE learning_plans;

