-- =============================================
-- 学习测评系统默认数据（V2版本 - 简化版）
-- 执行库：hotel_training（从库）
-- =============================================

-- 插入默认评分规则（3个维度）
-- 注意：这只是示例数据，管理员可以自己创建规则并设置权重
INSERT INTO train_score_model (model_name, description, tenant_id, status, is_default, create_by) 
VALUES ('标准评分规则', '适用于所有部门的标准评分规则（示例）', 'T001', '1', '1', 'admin');

-- 获取刚插入的规则ID
SET @model_id = LAST_INSERT_ID();

-- 插入3个评分维度（权重：33%、33%、34%，管理员可自行调整）
INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order) VALUES
(@model_id, 'accuracy_rate', '答题正确率', 33, '正确数/总答题数×100', 1),
(@model_id, 'completion_rate', '模块完成率', 33, '已完成模块/分配模块×100', 2),
(@model_id, 'assessment_score', '测评得分', 34, '周期内考试平均分', 3);

-- 说明：
-- 1. 辅助数据（学习时长、刷题数量）不在维度表中，直接在报告中记录
-- 2. 管理员可以在管理端创建新的评分规则，自定义各维度的权重
-- 3. 权重总和必须等于100%
