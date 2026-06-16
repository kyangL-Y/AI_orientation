-- ============================================
-- 检查和修复"独家"平台课程数据
-- ============================================

USE hotel_training;

-- 1. 查看 course_category 表中所有不同的 platform 值
SELECT '========== 1. 查看所有平台值 ==========' AS step;
SELECT DISTINCT platform, COUNT(*) as count 
FROM course_category 
GROUP BY platform;

-- 2. 查看"独家"平台的课程数据
SELECT '========== 2. 查看独家平台课程 ==========' AS step;
SELECT course_category_id, main_title, main_s, third_level_c, platform, level
FROM course_category 
WHERE platform = '独家'
LIMIT 20;

-- 3. 查看所有课程数据（前20条）
SELECT '========== 3. 查看所有课程数据 ==========' AS step;
SELECT course_category_id, main_title, main_s, third_level_c, platform, level
FROM course_category 
ORDER BY course_category_id
LIMIT 20;

-- 4. 检查是否有 platform 为空或 NULL 的数据
SELECT '========== 4. 检查空平台数据 ==========' AS step;
SELECT course_category_id, main_title, main_s, third_level_c, platform
FROM course_category 
WHERE platform IS NULL OR platform = '';

-- 5. 如果需要，可以将某些课程设置为"独家"平台
-- 例如：将没有平台的课程设置为"独家"
-- UPDATE course_category SET platform = '独家' WHERE platform IS NULL OR platform = '';

-- 6. 或者插入一些测试数据
-- INSERT INTO course_category (main_title, main_s, third_level_c, platform, level, knowledge_points)
-- VALUES 
-- ('独家课程', '酒店管理', '酒店运营基础', '独家', 'basic', '酒店运营的基础知识'),
-- ('独家课程', '酒店管理', '客户服务技巧', '独家', 'advance', '提升客户服务质量的技巧');

SELECT '✅ 检查完成！' AS result;
