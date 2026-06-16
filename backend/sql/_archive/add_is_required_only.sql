-- 只添加is_required字段（path_id已存在）

USE `hotel_training`;

-- 添加is_required字段（如果不存在）
ALTER TABLE `learning_plans` 
ADD COLUMN `is_required` tinyint(1) DEFAULT 0 COMMENT '是否必修：1=必修，0=选修' AFTER `path_id`;

