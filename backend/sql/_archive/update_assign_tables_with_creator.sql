-- 在酒店培训系统从库(hotel_training)中执行以下SQL语句
-- 确保所有授权表具有一致的结构，包含create_by字段

-- 1. 更新题目授权表
ALTER TABLE `train_question_assign` 
MODIFY COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者';

-- 2. 更新考试授权表
ALTER TABLE `train_exam_assign` 
MODIFY COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者';

-- 3. 更新学习授权表
ALTER TABLE `train_study_assign` 
MODIFY COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者';

-- 4. 更新测评授权表
ALTER TABLE `train_assessment_assign` 
MODIFY COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者';

-- 5. 更新认证授权表
ALTER TABLE `train_certification_assign` 
MODIFY COLUMN `create_by` varchar(64) DEFAULT NULL COMMENT '创建者';

-- 验证所有表结构
-- DESC train_question_assign;
-- DESC train_exam_assign;
-- DESC train_study_assign;
-- DESC train_assessment_assign;
-- DESC train_certification_assign;