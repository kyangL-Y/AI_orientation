-- 修复 train_question 表，添加缺失的字段
USE ry-vue;

-- 添加 company_id 字段
ALTER TABLE train_question ADD COLUMN IF NOT EXISTS company_id bigint(20) DEFAULT NULL COMMENT '集团ID' AFTER id;

-- 添加 sort_order 字段  
ALTER TABLE train_question ADD COLUMN IF NOT EXISTS sort_order int(11) DEFAULT 0 COMMENT '排序号（数字越小越靠前）' AFTER difficulty;

-- 为现有数据设置默认值
UPDATE train_question SET company_id = 100 WHERE company_id IS NULL;
UPDATE train_question SET sort_order = 0 WHERE sort_order IS NULL;

-- 添加索引
ALTER TABLE train_question ADD INDEX IF NOT EXISTS idx_company_id (company_id);
ALTER TABLE train_question ADD INDEX IF NOT EXISTS idx_sort_order (sort_order);


