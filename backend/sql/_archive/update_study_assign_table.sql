-- 更新学习授权表结构，添加创建者字段
ALTER TABLE `train_study_assign` 
ADD COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者' AFTER `create_time`;

-- 更新题目授权表结构，添加创建者字段（如果不存在）
ALTER TABLE `train_question_assign` 
ADD COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者' AFTER `created_at`;

-- 更新考试授权表结构，添加创建者字段（如果不存在）
ALTER TABLE `train_exam_assign` 
ADD COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者' AFTER `created_at`;