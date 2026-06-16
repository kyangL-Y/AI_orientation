-- 查看和管理中文课程数据
-- 用于确认数据库中是否有前端显示的中文课程

-- ========================================
-- 查看所有课程数据（按创建时间排序）
-- ========================================
SELECT 
    course_id,
    title,
    description,
    cover,
    duration,
    status,
    create_time,
    update_time
FROM train_course
ORDER BY create_time ASC;

-- ========================================
-- 统计课程数量
-- ========================================
SELECT 
    COUNT(*) AS '课程总数',
    COUNT(CASE WHEN status = 0 THEN 1 END) AS '启用状态',
    COUNT(CASE WHEN status = 1 THEN 1 END) AS '禁用状态'
FROM train_course;

-- ========================================
-- 查看课程标题列表（便于确认）
-- ========================================
SELECT course_id, title FROM train_course ORDER BY course_id;

-- ========================================
-- 按标题关键字搜索课程
-- ========================================
-- 搜索包含"携程"的课程
SELECT * FROM train_course WHERE title LIKE '%携程%';

-- 搜索包含"酒店"的课程
SELECT * FROM train_course WHERE title LIKE '%酒店%';

-- 搜索包含"前台"的课程
SELECT * FROM train_course WHERE title LIKE '%前台%';

-- 搜索包含"服务"的课程
SELECT * FROM train_course WHERE title LIKE '%服务%';

-- ========================================
-- 如果需要导入中文课程数据，请参考以下模板
-- ========================================
/*
-- 示例：插入中文课程数据
INSERT INTO train_course (title, description, cover, duration, status, create_time) VALUES
('1.1.1携程集团(Trip.com Group)全面知识', '学习携程集团的组织架构、业务模式、发展历程等全面知识', 'https://example.com/cover1.jpg', 120, 0, NOW()),
('3.1.1酒店泳拳门生整饰', '学习酒店游泳池和健身房的管理维护标准', 'https://example.com/cover2.jpg', 90, 0, NOW()),
('1.1.1国内酒店促销工具图谱', '掌握国内酒店常用的促销工具和营销策略', 'https://example.com/cover3.jpg', 150, 0, NOW());

-- 更多课程请根据实际情况添加...
*/

-- ========================================
-- 查看课程与用户学习进度的关联
-- ========================================
SELECT 
    c.course_id,
    c.title AS '课程名称',
    COUNT(DISTINCT p.user_id) AS '学习人数',
    AVG(p.progress) AS '平均进度'
FROM train_course c
LEFT JOIN train_user_course_progress p ON c.course_id = p.course_id
GROUP BY c.course_id, c.title
ORDER BY COUNT(DISTINCT p.user_id) DESC;

-- ========================================
-- 查看课程是否有封面图片
-- ========================================
SELECT 
    course_id,
    title,
    CASE 
        WHEN cover IS NULL OR cover = '' THEN '无封面'
        ELSE '有封面'
    END AS '封面状态',
    cover
FROM train_course
ORDER BY course_id;

