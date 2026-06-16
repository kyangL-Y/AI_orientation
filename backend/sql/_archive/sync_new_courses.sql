-- 统一课程数据：使用新的英文课程
-- 建议先备份数据！

-- 1. 备份现有课程数据
CREATE TABLE IF NOT EXISTS train_course_backup_20251024 AS 
SELECT * FROM train_course;

-- 2. 查看现有课程数量
SELECT COUNT(*) AS '现有课程总数' FROM train_course;
SELECT '最近创建的课程（2025-10-15之后）：' AS info;
SELECT course_id, title, create_time FROM train_course 
WHERE create_time >= '2025-10-15' 
ORDER BY create_time DESC;

-- 3. 如果要删除旧课程，只保留新课程（2025-10-15创建的）
-- DELETE FROM train_course WHERE create_time < '2025-10-15';

-- 4. 查看删除后的结果
-- SELECT course_id, title, description, duration, create_time FROM train_course ORDER BY course_id;

-- 注意：执行删除前请确认备份！

