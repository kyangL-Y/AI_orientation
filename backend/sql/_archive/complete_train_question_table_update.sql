-- 完整的题库表结构更新脚本
-- 添加缺失的字段并设置默认值

-- 1. 添加公司ID字段
ALTER TABLE `train_question` ADD COLUMN `company_id` bigint(20) DEFAULT NULL COMMENT '集团ID' AFTER `id`;

-- 2. 添加排序字段
ALTER TABLE `train_question` ADD COLUMN `sort_order` int(11) DEFAULT 0 COMMENT '排序号（数字越小越靠前）' AFTER `difficulty`;

-- 3. 添加索引以提高查询性能
ALTER TABLE `train_question` ADD INDEX `idx_company_id` (`company_id`);
ALTER TABLE `train_question` ADD INDEX `idx_sort_order` (`sort_order`);
ALTER TABLE `train_question` ADD INDEX `idx_hotel_code` (`hotel_code`);
ALTER TABLE `train_question` ADD INDEX `idx_dept_id` (`dept_id`);
ALTER TABLE `train_question` ADD INDEX `idx_question_type` (`question_type`);
ALTER TABLE `train_question` ADD INDEX `idx_difficulty` (`difficulty`);
ALTER TABLE `train_question` ADD INDEX `idx_status` (`status`);

-- 4. 更新现有数据
-- 设置默认公司ID（华智集团）
UPDATE `train_question` SET `company_id` = 100 WHERE `company_id` IS NULL;

-- 设置默认排序号（按照ID顺序）
UPDATE `train_question` SET `sort_order` = `id` WHERE `sort_order` = 0;

-- 5. 验证数据更新
SELECT 
    COUNT(*) as total_questions,
    COUNT(CASE WHEN company_id IS NOT NULL THEN 1 END) as with_company_id,
    COUNT(CASE WHEN sort_order > 0 THEN 1 END) as with_sort_order
FROM `train_question`;

-- 6. 显示更新后的表结构
DESCRIBE `train_question`;


