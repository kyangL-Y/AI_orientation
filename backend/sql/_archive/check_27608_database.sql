-- 检查27608端口数据库的内容
-- 这个SQL应该在连接到 bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608 后执行

SELECT '=== 连接信息验证 ===' AS section;
SELECT 
    @@hostname AS '服务器名称',
    @@port AS '端口',
    DATABASE() AS '当前数据库',
    NOW() AS '查询时间';

USE `hotel_training`;

SELECT '=== learning_plans 表结构（27608）===' AS section;
DESCRIBE `learning_plans`;

SELECT '=== learning_plans 表所有字段（27608）===' AS section;
SELECT 
    COLUMN_NAME AS '字段名',
    DATA_TYPE AS '数据类型',
    COLUMN_TYPE AS '完整类型',
    IS_NULLABLE AS '允许NULL',
    COLUMN_DEFAULT AS '默认值',
    COLUMN_COMMENT AS '注释'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training'
AND TABLE_NAME = 'learning_plans'
ORDER BY ORDINAL_POSITION;

SELECT '=== 关键字段检查（27608）===' AS section;
SELECT 
    COLUMN_NAME AS '字段名',
    CASE 
        WHEN COLUMN_NAME = 'path_id' THEN '✅ path_id 存在'
        WHEN COLUMN_NAME = 'is_required' THEN '✅ is_required 存在'
        ELSE '其他字段'
    END AS '状态'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training'
AND TABLE_NAME = 'learning_plans'
AND COLUMN_NAME IN ('path_id', 'is_required');

SELECT '=== 数据统计（27608）===' AS section;
SELECT 
    COUNT(*) AS '学习计划总数',
    COUNT(DISTINCT path_id) AS '不同path_id数量'
FROM `learning_plans`;

-- 如果 path_id 字段存在，显示一些示例数据
SELECT '=== 示例数据（如果有path_id字段）===' AS section;
SELECT 
    plan_id,
    path_id,
    is_required,
    title,
    status
FROM `learning_plans`
LIMIT 5;

