-- 诊断"独家"平台课程数据问题
-- 执行此脚本查看数据库中的课程数据

-- 1. 查看所有平台的课程数量
SELECT platform, COUNT(*) as count 
FROM course_category 
GROUP BY platform;

-- 2. 查看"独家"平台的课程（如果platform字段有值）
SELECT course_category_id, platform, main_title, main_s, specific_category, third_level_c, level
FROM course_category 
WHERE platform = '独家'
LIMIT 10;

-- 3. 查看main_title为"进阶课程"的数据（可能是独家课程）
SELECT course_category_id, platform, main_title, main_s, specific_category, third_level_c, level
FROM course_category 
WHERE main_title = '进阶课程'
LIMIT 10;

-- 4. 查看所有不同的main_title值
SELECT DISTINCT main_title, platform, COUNT(*) as count
FROM course_category
GROUP BY main_title, platform
ORDER BY count DESC;

-- 5. 查看platform字段为空或NULL的记录
SELECT course_category_id, platform, main_title, main_s, specific_category, third_level_c
FROM course_category 
WHERE platform IS NULL OR platform = ''
LIMIT 20;

-- 6. 如果"进阶课程"的platform字段为空，更新为"独家"
-- UPDATE course_category 
-- SET platform = '独家' 
-- WHERE main_title = '进阶课程' AND (platform IS NULL OR platform = '');

-- 7. 查看表结构
DESCRIBE course_category;
