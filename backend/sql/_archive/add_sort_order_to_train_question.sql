-- 为 train_question 表添加排序字段和公司ID字段
ALTER TABLE `train_question` ADD COLUMN `company_id` bigint(20) DEFAULT NULL COMMENT '集团ID' AFTER `id`;
ALTER TABLE `train_question` ADD COLUMN `sort_order` int(11) DEFAULT 0 COMMENT '排序号（数字越小越靠前）' AFTER `difficulty`;

-- 添加索引以提高排序查询性能
ALTER TABLE `train_question` ADD INDEX `idx_company_id` (`company_id`);
ALTER TABLE `train_question` ADD INDEX `idx_sort_order` (`sort_order`);

-- 更新现有数据的排序号，按照ID顺序设置
UPDATE `train_question` SET `sort_order` = `id` WHERE `sort_order` = 0;

-- 设置默认公司ID（根据实际情况调整）
UPDATE `train_question` SET `company_id` = 100 WHERE `company_id` IS NULL;
