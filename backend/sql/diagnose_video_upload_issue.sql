-- 诊断部门课程视频上传问题
-- 检查video_url字段在hotel_training数据库中的状态

USE hotel_training;
SELECT 
    'hotel_training数据库' AS database_name,
    course_id,
    course_name,
    dept_type,
    video_url,
    CASE 
        WHEN video_url IS NULL THEN '未设置'
        WHEN video_url = '' THEN '空字符串'
        ELSE '已设置'
    END AS video_url_status,
    created_time,
    updated_time
FROM dept_training_course
ORDER BY course_id;
