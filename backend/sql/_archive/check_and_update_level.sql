-- 检查并更新课程层级
-- 用于验证 level 字段是否存在，并为课程设置不同的层级

USE hotel_training;

-- 1. 检查 level 字段是否存在
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training'
  AND TABLE_NAME = 'course_category'
  AND COLUMN_NAME = 'level';

-- 2. 查看当前所有课程的层级分布
SELECT 
    level,
    COUNT(*) as course_count
FROM course_category
GROUP BY level
ORDER BY 
    CASE level
        WHEN 'basic' THEN 1
        WHEN 'advance' THEN 2
        WHEN 'expert' THEN 3
        ELSE 4
    END;

-- 3. 查看前10条课程的层级信息
SELECT 
    course_category_id,
    main_title,
    third_level_c,
    level,
    CASE 
        WHEN level = 'basic' THEN '基础'
        WHEN level = 'advance' THEN '进阶'
        WHEN level = 'expert' THEN '高级'
        ELSE '未设置'
    END as level_name
FROM course_category
ORDER BY course_category_id
LIMIT 10;

-- 4. 为课程设置不同层级的示例（根据实际需求修改）
-- 注意：请根据实际业务需求修改课程ID

-- 示例：将前20%的课程设置为基础（如果还没有设置）
-- UPDATE course_category 
-- SET level = 'basic' 
-- WHERE level IS NULL 
-- LIMIT (SELECT COUNT(*) * 0.2 FROM course_category);

-- 示例：将特定课程设置为进阶（请修改课程ID）
-- UPDATE course_category 
-- SET level = 'advance' 
-- WHERE course_category_id IN (10, 11, 12, 13, 14);

-- 示例：将特定课程设置为高级（请修改课程ID）
-- UPDATE course_category 
-- SET level = 'expert' 
-- WHERE course_category_id IN (20, 21, 22, 23, 24);

-- 5. 验证更新结果
-- SELECT 
--     level,
--     COUNT(*) as course_count
-- FROM course_category
-- GROUP BY level;

