-- =====================================================
-- 学习报告表添加唯一约束，防止并发生成重复报告
-- 执行时间：2026-03-05
-- 问题描述：checkReportExists 后 insertReport 存在并发窗口
-- =====================================================

-- 1. 先检查是否已存在该索引
SELECT COUNT(*) AS index_exists
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'train_learning_report'
  AND INDEX_NAME = 'uk_user_period';

-- 2. 添加唯一约束（如果不存在）
-- 约束条件：用户ID + 周期类型 + 周期结束日期 + 评分模型ID + 租户ID
-- 注意：包含 tenant_id 以支持多租户环境下的数据隔离
ALTER TABLE train_learning_report
ADD UNIQUE INDEX uk_user_period (user_id, period_type, period_end, model_id, tenant_id);

-- 3. 如果上面的命令因已存在索引而失败，可以先删除再创建
-- DROP INDEX uk_user_period ON train_learning_report;
-- ALTER TABLE train_learning_report
-- ADD UNIQUE INDEX uk_user_period (user_id, period_type, period_end, model_id, tenant_id);

-- 4. 验证索引是否成功创建
SHOW INDEX FROM train_learning_report WHERE Key_name = 'uk_user_period';

-- 5. 查看表结构确认
DESC train_learning_report;
