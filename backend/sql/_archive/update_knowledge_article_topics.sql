-- 知识文章表添加话题字段
-- 执行数据库: hotel_training (从库)

ALTER TABLE train_knowledge_article 
ADD COLUMN topics VARCHAR(500) DEFAULT NULL COMMENT '文章话题(逗号分隔)' AFTER content;
