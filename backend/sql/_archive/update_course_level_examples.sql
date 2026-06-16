-- 为课程设置学习层级的示例SQL
-- 根据实际需求修改课程ID和层级

USE hotel_training;

-- 示例1：将所有课程设置为基础层级（如果还没有设置）
-- UPDATE course_category SET level = 'basic' WHERE level IS NULL;

-- 示例2：将特定课程设置为进阶层级
-- UPDATE course_category SET level = 'advance' WHERE course_category_id IN (4,5,6,7,8);

-- 示例3：将特定课程设置为高级层级
-- UPDATE course_category SET level = 'expert' WHERE course_category_id IN (9,10,11,12,13);

-- 示例4：根据课程名称设置层级（示例）
-- UPDATE course_category SET level = 'advance' WHERE third_level_c LIKE '%高级%' OR third_level_c LIKE '%进阶%';
-- UPDATE course_category SET level = 'expert' WHERE third_level_c LIKE '%专家%' OR third_level_c LIKE '%精通%';

-- 示例5：查看各层级的课程数量
SELECT 
    level,
    COUNT(*) as course_count
FROM course_category
GROUP BY level;

-- 示例6：查看所有课程的层级分布
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
ORDER BY 
    CASE level
        WHEN 'basic' THEN 1
        WHEN 'advance' THEN 2
        WHEN 'expert' THEN 3
        ELSE 4
    END,
    course_category_id;

