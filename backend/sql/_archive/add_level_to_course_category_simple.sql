-- 为 course_category 表添加学习层级字段（简化版）
-- 用于支持基础/进阶/高级课程筛选
-- 
-- 使用方法：
-- 1. 如果字段已存在，会报错但可以忽略（字段已存在）
-- 2. 如果字段不存在，会成功添加

USE hotel_training;

-- 添加 level 字段（如果已存在会报错，可以忽略）
ALTER TABLE course_category 
ADD COLUMN level VARCHAR(20) NULL DEFAULT 'basic' 
COMMENT '学习层级：basic-基础,advance-进阶,expert-高级' 
AFTER cover_image;

-- 查看修改后的表结构
DESCRIBE course_category;

-- 查看前5条记录的 level 字段
SELECT 
    course_category_id,
    main_title,
    third_level_c,
    level,
    cover_image
FROM course_category 
ORDER BY course_category_id 
LIMIT 5;

-- 为所有现有课程设置默认层级（如果 level 为 NULL）
UPDATE course_category 
SET level = 'basic' 
WHERE level IS NULL;

-- 说明：
-- 1. level 字段用于区分课程的学习层级：basic(基础)、advance(进阶)、expert(高级)
-- 2. 默认值为 'basic'，确保旧数据有默认值
-- 3. 字段长度20足够存储层级值
-- 4. 添加在 cover_image 之后，保持字段顺序合理

