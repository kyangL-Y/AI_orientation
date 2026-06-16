-- 诊断课程78的视频加载问题
-- 查看课程信息和视频路径

USE hz-vue;

-- 1. 查看课程基本信息
SELECT '=== 课程基本信息 ===' AS info;
SELECT id, title, video_url, video_path, cover_image, create_time
FROM course_category 
WHERE id = 78;

-- 2. 查看最近导入的几个课程
SELECT '=== 最近导入的课程 ===' AS info;
SELECT id, title, video_url, video_path, cover_image, create_time
FROM course_category 
WHERE id >= 78 AND id <= 85
ORDER BY id;

-- 3. 查看能正常播放的课程示例
SELECT '=== 能正常播放的课程示例 ===' AS info;
SELECT id, title, video_url, video_path, cover_image
FROM course_category 
WHERE id < 78 AND video_url IS NOT NULL
LIMIT 5;

-- 4. 检查课程是否有关联的题目
SELECT '=== 课程78的题目数量 ===' AS info;
SELECT COUNT(*) as question_count
FROM train_question
WHERE course_id = 78;

-- 5. 查看所有课程表
SELECT '=== 数据库中的课程相关表 ===' AS info;
SHOW TABLES LIKE '%course%';
