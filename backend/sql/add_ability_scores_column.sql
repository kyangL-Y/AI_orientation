-- 学习报告添加业务能力维度得分字段
-- 用于新的业务能力雷达图展示
-- 维度包括：成本控制、客户服务、团队协作、专业技能、安全合规

ALTER TABLE train_learning_report ADD COLUMN ability_scores TEXT COMMENT '业务能力维度得分JSON' AFTER dimension_scores;

-- 示例数据格式：
-- {
--   "cost_control": 85,
--   "customer_service": 78,
--   "team_collaboration": 92,
--   "professional_skills": 88,
--   "safety_compliance": 75
-- }
