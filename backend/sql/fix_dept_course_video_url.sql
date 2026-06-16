-- 修复部门课程的video_url字段
-- 将视频文件路径关联到对应的课程

USE hotel_training;

-- 更新前厅部课程的视频路径
UPDATE dept_training_course SET video_url = 'dept_course/前厅1.mp4' WHERE course_id = 78;
UPDATE dept_training_course SET video_url = 'dept_course/前厅2.mp4' WHERE course_id = 79;
UPDATE dept_training_course SET video_url = 'dept_course/前厅3.mp4' WHERE course_id = 80;
UPDATE dept_training_course SET video_url = 'dept_course/前厅4.mp4' WHERE course_id = 81;
UPDATE dept_training_course SET video_url = 'dept_course/前厅5.mp4' WHERE course_id = 82;

-- 验证更新结果
SELECT course_id, course_name, video_url, dept_type 
FROM dept_training_course 
WHERE course_id BETWEEN 78 AND 85
ORDER BY course_id;
