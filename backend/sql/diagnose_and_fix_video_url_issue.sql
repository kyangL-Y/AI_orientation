-- 诊断并修复部门课程视频URL问题
-- 问题：视频已上传到COS，但数据库video_url字段为空

USE hotel_training;

-- 1. 查看当前video_url为空但COS中有视频的课程
SELECT 
    course_id,
    course_name,
    dept_type,
    video_url,
    updated_time
FROM dept_training_course
WHERE (video_url IS NULL OR video_url = '')
ORDER BY updated_time DESC
LIMIT 20;

-- 2. 检查最近更新的课程（可能是刚上传视频的）
SELECT 
    course_id,
    course_name,
    dept_type,
    video_url,
    updated_by,
    updated_time
FROM dept_training_course
WHERE updated_time >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY updated_time DESC;

-- 3. 统计video_url状态
SELECT 
    CASE 
        WHEN video_url IS NULL THEN '未设置(NULL)'
        WHEN video_url = '' THEN '空字符串'
        ELSE '已设置'
    END AS video_url_status,
    COUNT(*) AS count
FROM dept_training_course
GROUP BY video_url_status;
