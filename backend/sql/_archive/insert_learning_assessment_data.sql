-- ================================================
-- 学习能力测评系统 - 默认数据插入脚本
-- 在从库 hotel_training 中执行
-- ================================================

USE hotel_training;

-- ================================================
-- 1. 插入默认评分模型
-- ================================================
INSERT INTO train_score_model (model_name, model_code, description, applicable_positions, tenant_id, status, create_by)
VALUES ('通用学习能力评分模型', 'DEFAULT_MODEL', '适用于所有岗位的通用学习能力评估模型，包含学习时长、刷题数量、答题正确率、模块完成率、测评得分五个维度', '["全部岗位"]', 'T001', '1', 'admin');

-- 获取刚插入的模型ID
SET @model_id = LAST_INSERT_ID();

-- ================================================
-- 2. 插入默认评分维度（5个维度各20%权重）
-- ================================================
INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, min_value, max_value, sort_order)
VALUES 
(@model_id, 'learning_duration', '学习时长', 20, '周期内总学习时长(分钟)，基准值：周60分钟/月240分钟/季720分钟', 0, 100, 1),
(@model_id, 'quiz_count', '刷题数量', 20, '周期内完成题目数，基准值：周20题/月80题/季240题', 0, 100, 2),
(@model_id, 'accuracy_rate', '答题正确率', 20, '正确数/总答题数×100，直接使用百分比', 0, 100, 3),
(@model_id, 'completion_rate', '模块完成率', 20, '已完成模块/分配模块×100，直接使用百分比', 0, 100, 4),
(@model_id, 'assessment_score', '测评得分', 20, '周期内考试平均分，直接使用分数', 0, 100, 5);

-- ================================================
-- 3. 插入默认报告配置
-- ================================================
INSERT INTO train_report_config (tenant_id, model_id, period_type, is_enabled, notify_employee, cron_expression)
VALUES 
('T001', @model_id, 'weekly', '1', '1', '0 0 1 ? * MON'),      -- 每周一凌晨1点
('T001', @model_id, 'monthly', '1', '1', '0 0 2 1 * ?'),       -- 每月1日凌晨2点
('T001', @model_id, 'quarterly', '1', '1', '0 0 3 1 1,4,7,10 ?'); -- 每季度首月1日凌晨3点

