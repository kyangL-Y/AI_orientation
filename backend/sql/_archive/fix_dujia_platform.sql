-- 修复课程平台数据
-- 确保所有课程都有正确的 platform 字段值

-- ============================================
-- 第一步：诊断当前数据状态
-- ============================================

-- 1.1 查看所有平台的课程数量
SELECT '当前平台分布' as info;
SELECT IFNULL(platform, '(空)') as platform, COUNT(*) as count 
FROM course_category 
GROUP BY platform;

-- 1.2 查看 main_title 分布
SELECT '主标题分布' as info;
SELECT IFNULL(main_title, '(空)') as main_title, IFNULL(platform, '(空)') as platform, COUNT(*) as count
FROM course_category
GROUP BY main_title, platform
ORDER BY count DESC;

-- 1.3 查看platform为空的记录
SELECT 'platform为空的记录' as info;
SELECT course_category_id, main_title, main_s, specific_category, third_level_c
FROM course_category 
WHERE platform IS NULL OR platform = ''
LIMIT 20;

-- ============================================
-- 第二步：修复数据
-- ============================================

-- 2.1 修复"独家"平台课程（main_title = '进阶课程' 的记录）
UPDATE course_category 
SET platform = '独家' 
WHERE main_title = '进阶课程' AND (platform IS NULL OR platform = '');

-- 2.2 如果有其他需要修复的平台，可以添加类似的UPDATE语句
-- 例如：美团、携程、飞猪等平台的课程
-- UPDATE course_category SET platform = '美团' WHERE main_title LIKE '%美团%' AND (platform IS NULL OR platform = '');
-- UPDATE course_category SET platform = '携程' WHERE main_title LIKE '%携程%' AND (platform IS NULL OR platform = '');
-- UPDATE course_category SET platform = '飞猪' WHERE main_title LIKE '%飞猪%' AND (platform IS NULL OR platform = '');

-- ============================================
-- 第三步：验证修复结果
-- ============================================

-- 3.1 验证修复后的平台分布
SELECT '修复后平台分布' as info;
SELECT IFNULL(platform, '(空)') as platform, COUNT(*) as count 
FROM course_category 
GROUP BY platform;

-- 3.2 查看"独家"平台的课程样例
SELECT '独家平台课程样例' as info;
SELECT course_category_id, platform, main_title, main_s, specific_category, third_level_c, level
FROM course_category 
WHERE platform = '独家'
LIMIT 10;

-- 3.3 确认没有platform为空的记录
SELECT 'platform仍为空的记录数' as info;
SELECT COUNT(*) as empty_platform_count
FROM course_category 
WHERE platform IS NULL OR platform = '';
