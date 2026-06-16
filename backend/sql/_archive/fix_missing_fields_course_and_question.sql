-- 修复缺失字段
-- 日期: 2026-01-17
-- 说明: 添加 course_category.cover_image 和 train_question.explanation 字段

USE hotel_training;

-- 1. 添加 course_category 表的 cover_image 字段
ALTER TABLE course_category 
ADD COLUMN cover_image VARCHAR(500) NULL COMMENT '封面图片URL' AFTER third_level_c;

-- 2. 添加 train_question 表的 explanation 字段
ALTER TABLE train_question 
ADD COLUMN explanation TEXT NULL COMMENT '答案解析' AFTER correct_answer;

-- 验证
SELECT 'cover_image 和 explanation 字段添加成功' AS result;
