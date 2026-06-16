-- 修改智囊阁表结构：删除tenant_id字段
-- 执行数据库：hotel_training（从库）

-- 1. 删除train_knowledge_article表的tenant_id字段
ALTER TABLE `train_knowledge_article` 
DROP COLUMN `tenant_id`,
DROP INDEX `idx_tenant_status`;

-- 2. 添加新的索引（只按status）
ALTER TABLE `train_knowledge_article` 
ADD INDEX `idx_status` (`status`);
