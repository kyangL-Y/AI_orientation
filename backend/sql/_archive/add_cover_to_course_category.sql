-- 为 course_category 表添加封面图片字段
-- 用于支持课程封面图片上传和显示

USE hotel_training;

-- 1. 添加封面字段
ALTER TABLE course_category 
ADD COLUMN cover_image VARCHAR(500) NULL COMMENT '课程封面图片URL' AFTER third_level_c;

-- 2. 添加索引（可选，如果需要按封面筛选）
-- ALTER TABLE course_category ADD INDEX idx_cover_image (cover_image);

-- 3. 查看修改后的表结构
DESCRIBE course_category;

-- 4. 查看前5条记录
SELECT 
    course_category_id,
    main_title,
    third_level_c,
    cover_image,
    created_time
FROM course_category 
ORDER BY course_category_id 
LIMIT 5;

-- 5. 更新示例：为某个课程添加封面图片
-- UPDATE course_category 
-- SET cover_image = 'https://example.com/images/course1.jpg' 
-- WHERE course_category_id = 1;

-- 说明：
-- 1. cover_image 字段用于存储封面图片的URL或相对路径
-- 2. 字段长度500足够存储完整的URL
-- 3. NULL 表示可以为空，旧数据不受影响
-- 4. 添加在 third_level_c 之后，方便查询和显示

