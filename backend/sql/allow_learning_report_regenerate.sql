-- =====================================================
-- 允许学习报告同周期重复生成
-- 执行时间：2026-03-06
-- 说明：移除 train_learning_report 的同周期唯一索引，允许保留多份报告
-- =====================================================

-- 1. 检查唯一索引是否存在
SELECT COUNT(*) AS index_exists
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'train_learning_report'
  AND INDEX_NAME = 'uk_user_period';

-- 2. 若存在唯一索引，则删除
ALTER TABLE train_learning_report
DROP INDEX uk_user_period;

-- 3. 验证索引是否已删除
SHOW INDEX FROM train_learning_report WHERE Key_name = 'uk_user_period';
