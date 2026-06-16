-- =====================================================
-- 建表前检查脚本
-- =====================================================
-- 服务器: bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com
-- 端口: 27608
-- 数据库: hotel_training
-- =====================================================
-- 重要：请先连接到 bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608
-- 然后选择 hotel_training 数据库后执行此脚本
-- =====================================================

USE hotel_training;

-- 1. 检查连接信息
SELECT '=== 连接信息 ===' AS section;
SELECT 
    @@hostname AS '服务器名称',
    @@port AS '端口',
    DATABASE() AS '当前数据库',
    NOW() AS '查询时间';

-- 2. 检查哪些表已存在
SELECT '=== 已存在的表 ===' AS section;
SELECT 
    TABLE_NAME AS '表名',
    TABLE_ROWS AS '记录数',
    CREATE_TIME AS '创建时间'
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN (
    'learning_plans',
    'plan_items', 
    'plan_item_completions',
    'learning_paths',
    'learning_path_plans',
    'user_learning_paths'
)
ORDER BY TABLE_NAME;

-- 3. 检查learning_plans表的字段（重点）
SELECT '=== learning_plans表字段 ===' AS section;
SELECT 
    COLUMN_NAME AS '字段名',
    DATA_TYPE AS '数据类型',
    IS_NULLABLE AS '允许NULL',
    COLUMN_DEFAULT AS '默认值',
    COLUMN_COMMENT AS '注释'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'learning_plans'
ORDER BY ORDINAL_POSITION;

-- 4. 检查path_id字段是否存在
SELECT '=== path_id字段检查 ===' AS section;
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ path_id 字段已存在'
        ELSE '❌ path_id 字段不存在，需要添加'
    END AS 'path_id状态',
    COUNT(*) AS '字段数量'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'learning_plans'
AND COLUMN_NAME = 'path_id';

-- 5. 检查is_required字段是否存在（这个不应该在learning_plans表中）
SELECT '=== is_required字段检查（应该在learning_path_plans表中）===' AS section;
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '⚠️ is_required 在learning_plans表中存在（这是错误的，应该在关联表中）'
        ELSE '✅ learning_plans表中没有is_required字段（正确）'
    END AS 'is_required状态',
    COUNT(*) AS '字段数量'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'learning_plans'
AND COLUMN_NAME = 'is_required';

-- 6. 检查learning_path_plans关联表是否存在
SELECT '=== learning_path_plans关联表检查 ===' AS section;
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ learning_path_plans 表已存在'
        ELSE '❌ learning_path_plans 表不存在，需要创建'
    END AS '表状态',
    COUNT(*) AS '表数量'
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'learning_path_plans';

-- 7. 如果关联表存在，检查is_required字段
SELECT '=== learning_path_plans表的is_required字段检查 ===' AS section;
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ is_required 字段在关联表中存在（正确）'
        ELSE '❌ is_required 字段在关联表中不存在，需要添加'
    END AS 'is_required状态',
    COUNT(*) AS '字段数量'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'learning_path_plans'
AND COLUMN_NAME = 'is_required';

SELECT '=== 检查完成！请查看上面的结果 ===' AS message;

