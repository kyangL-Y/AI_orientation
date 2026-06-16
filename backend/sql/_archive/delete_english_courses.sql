-- 删除英文课程，保留中文课程
-- 执行前请先查看现有数据！

-- ========================================
-- 第一步：查看所有课程数据
-- ========================================
SELECT 
    course_id,
    title,
    description,
    cover,
    duration,
    status,
    create_time
FROM train_course
ORDER BY create_time DESC;

-- ========================================
-- 第二步：查看2025-10-15创建的课程（这些是要删除的英文课程）
-- ========================================
SELECT 
    course_id,
    title,
    create_time
FROM train_course
WHERE create_time >= '2025-10-15'
ORDER BY course_id;

-- ========================================
-- 第三步：备份要删除的课程（重要！）
-- ========================================
CREATE TABLE IF NOT EXISTS train_course_backup_english AS
SELECT * FROM train_course
WHERE create_time >= '2025-10-15';

SELECT COUNT(*) AS '已备份的英文课程数量' FROM train_course_backup_english;

-- ========================================
-- 第四步：删除英文课程
-- ========================================
-- 方法1：按创建日期删除（删除2025-10-15及之后创建的课程）
DELETE FROM train_course
WHERE create_time >= '2025-10-15';

-- 方法2：按课程标题删除（精确删除）
-- DELETE FROM train_course WHERE title = 'Front Desk Service Training';
-- DELETE FROM train_course WHERE title = 'Dining Service Training';
-- DELETE FROM train_course WHERE title = 'OTA Management Training';
-- DELETE FROM train_course WHERE title = 'Room Service Training';
-- DELETE FROM train_course WHERE title = 'Customer Service Skills';
-- DELETE FROM train_course WHERE title = 'Hotel Management Basics';
-- DELETE FROM train_course WHERE title = 'Team Collaboration Training';
-- DELETE FROM train_course WHERE title = 'Sales Skills Training';

-- ========================================
-- 第五步：查看删除后剩余的课程
-- ========================================
SELECT 
    course_id,
    title,
    description,
    create_time
FROM train_course
ORDER BY course_id;

SELECT COUNT(*) AS '剩余课程总数' FROM train_course;

-- ========================================
-- 第六步：如果需要恢复数据，执行以下语句
-- ========================================
-- INSERT INTO train_course SELECT * FROM train_course_backup_english;

-- ========================================
-- 说明
-- ========================================
-- 1. 此脚本会删除2025-10-15及之后创建的英文课程
-- 2. 删除前会自动备份到 train_course_backup_english 表
-- 3. 如果误删，可以从备份表恢复数据
-- 4. 建议先执行查询语句确认数据，再执行删除操作

