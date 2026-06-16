-- 添加 publish_scope 字段到知识文章表
-- 执行时间: 2026-01-31
-- 说明: 恢复 publish_scope 字段以支持全平台文章发布功能

USE hotel_training;

-- 添加 publish_scope 字段
ALTER TABLE train_knowledge_article
ADD COLUMN publish_scope VARCHAR(20) DEFAULT 'tenant'
COMMENT '发布范围: platform-全平台/tenant-本租户'
AFTER tenant_id;

-- 为现有数据设置默认值
UPDATE train_knowledge_article
SET publish_scope = CASE
    WHEN tenant_id = '000000' THEN 'platform'
    ELSE 'tenant'
END
WHERE publish_scope IS NULL;

-- 验证字段已添加
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_training'
  AND TABLE_NAME = 'train_knowledge_article'
  AND COLUMN_NAME = 'publish_scope';

SELECT '字段添加完成！' AS status;
