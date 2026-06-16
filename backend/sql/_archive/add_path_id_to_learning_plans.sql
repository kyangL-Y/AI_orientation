-- 为learning_plans表添加path_id和is_required字段
-- 用于关联学习路径和标识必修/选修

USE `hotel_training`;

-- 添加path_id字段（如果不存在）
-- 注意：如果字段已存在会报错，可以忽略
ALTER TABLE `learning_plans` 
ADD COLUMN `path_id` bigint(20) NULL COMMENT '所属学习路径ID' AFTER `plan_id`;

-- 添加is_required字段（如果不存在）
ALTER TABLE `learning_plans` 
ADD COLUMN `is_required` tinyint(1) DEFAULT 0 COMMENT '是否必修：1=必修，0=选修' AFTER `path_id`;

-- 添加索引以优化查询性能（如果不存在会报错，可以忽略）
ALTER TABLE `learning_plans` 
ADD INDEX `idx_path_id` (`path_id`);

