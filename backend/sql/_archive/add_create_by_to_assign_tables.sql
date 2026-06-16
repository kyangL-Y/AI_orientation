-- 在酒店培训系统从库(hotel_training)中执行以下SQL语句

-- 为题目授权表添加创建者字段
ALTER TABLE `train_question_assign` 
ADD COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者' AFTER `created_at`;

-- 为考试授权表添加创建者字段
ALTER TABLE `train_exam_assign` 
ADD COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者' AFTER `created_at`;

-- 验证学习授权表结构(已包含create_by字段)
-- ALTER TABLE `train_study_assign` 
-- ADD COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者' AFTER `create_time`;