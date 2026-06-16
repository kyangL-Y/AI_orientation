-- ============================================
-- 检查当前数据库连接信息
-- 用于确认是否连接到后端实际使用的数据库
-- ============================================

-- 1. 检查当前连接的服务器和端口
SELECT 
    @@hostname AS '当前服务器主机名',
    @@port AS '当前端口',
    DATABASE() AS '当前使用的数据库',
    USER() AS '当前用户',
    CONNECTION_ID() AS '连接ID';

-- 2. 检查服务器版本和配置
SELECT 
    VERSION() AS 'MySQL版本',
    @@version_comment AS '版本注释';

-- 3. 确认后端应该连接的配置（参考）
-- 后端配置应该是：
-- 主库：bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608/hz-vue
-- 从库：bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608/hotel_training

-- 4. 检查 hotel_training 数据库是否存在
SELECT 
    SCHEMA_NAME AS '数据库名称',
    DEFAULT_CHARACTER_SET_NAME AS '字符集',
    DEFAULT_COLLATION_NAME AS '排序规则'
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME = 'hotel_training';

-- 5. 检查 learning_plans 表是否存在
SELECT 
    TABLE_SCHEMA AS '数据库名',
    TABLE_NAME AS '表名',
    TABLE_TYPE AS '表类型',
    ENGINE AS '存储引擎'
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'learning_plans';

-- 6. 检查 learning_plans 表中的字段（重点检查 path_id 和 is_required）
SELECT 
    COLUMN_NAME AS '字段名',
    DATA_TYPE AS '数据类型',
    IS_NULLABLE AS '允许为空',
    COLUMN_DEFAULT AS '默认值',
    COLUMN_COMMENT AS '字段注释',
    ORDINAL_POSITION AS '位置'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'learning_plans'
ORDER BY ORDINAL_POSITION;

-- 7. 特别检查 path_id 和 is_required 字段是否存在
SELECT 
    CASE 
        WHEN COUNT(CASE WHEN COLUMN_NAME = 'path_id' THEN 1 END) > 0 
        THEN '✅ path_id 字段存在' 
        ELSE '❌ path_id 字段不存在' 
    END AS 'path_id状态',
    CASE 
        WHEN COUNT(CASE WHEN COLUMN_NAME = 'is_required' THEN 1 END) > 0 
        THEN '✅ is_required 字段存在' 
        ELSE '❌ is_required 字段不存在' 
    END AS 'is_required状态'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'learning_plans'
  AND COLUMN_NAME IN ('path_id', 'is_required');

-- 8. 显示完整的表结构（DESCRIBE）
USE hotel_training;
DESCRIBE learning_plans;

