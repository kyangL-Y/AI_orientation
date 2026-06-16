-- =====================================================
-- 更新会员等级以匹配定价计划
-- 执行时间: 2026-01-15
-- =====================================================

-- 更新会员等级数据，与 PRICING_PLAN.md 保持一致
-- 等级: free(免费) < light(轻量版) < standard(标准版) < flagship(旗舰版) < enterprise(企业版)

-- 先清空旧数据
TRUNCATE TABLE `train_membership_level`;

-- 插入新的会员等级
INSERT INTO `train_membership_level` (`level_name`, `level_code`, `level_order`, `price`, `annual_price`, `duration_days`, `features`, `description`, `icon`, `color`) VALUES
('免费版', 'free', 0, 0.00, 0.00, 15, 
 '{"dailyQuestions": 10, "dailyPractice": 5, "aiChat": 5, "videoPreview": 30, "learningDashboard": "basic", "corporateCulture": false, "knowledgeSharing": false, "multiStore": false, "apiAccess": false, "privateDeployment": false}', 
 '15天全功能试用，含10个学习账号', 'fa-user', '#9CA3AF'),

('轻量版', 'light', 1, 166.67, 2000.00, 365, 
 '{"dailyQuestions": -1, "dailyPractice": -1, "aiChat": -1, "videoPreview": -1, "learningDashboard": "basic", "corporateCulture": false, "knowledgeSharing": false, "multiStore": false, "apiAccess": false, "privateDeployment": false}', 
 '适用≤50间房酒店，岗位培训+智能题库+AI教练', 'fa-star', '#3B82F6'),

('标准版', 'standard', 2, 416.67, 5000.00, 365, 
 '{"dailyQuestions": -1, "dailyPractice": -1, "aiChat": -1, "videoPreview": -1, "learningDashboard": "full", "corporateCulture": true, "knowledgeSharing": true, "multiStore": false, "apiAccess": false, "privateDeployment": false}', 
 '适用51-200间房酒店，完整数据看板+企业文化定制+知识共享', 'fa-crown', '#F59E0B'),

('旗舰版', 'flagship', 3, 833.33, 10000.00, 365, 
 '{"dailyQuestions": -1, "dailyPractice": -1, "aiChat": -1, "videoPreview": -1, "learningDashboard": "fullWithPrediction", "corporateCulture": true, "knowledgeSharing": true, "multiStore": true, "apiAccess": true, "privateDeployment": false}', 
 '适用200+间房酒店，集团化管理+API接口+专属客户经理', 'fa-gem', '#8B5CF6'),

('企业版', 'enterprise', 4, 0.00, 0.00, 365, 
 '{"dailyQuestions": -1, "dailyPractice": -1, "aiChat": -1, "videoPreview": -1, "learningDashboard": "custom", "corporateCulture": true, "knowledgeSharing": true, "multiStore": true, "apiAccess": true, "privateDeployment": true}', 
 '集团/多品牌定制，私有化部署+内容深度定制', 'fa-building', '#DC2626');

-- 更新现有用户会员记录中的 level_code (如果有旧数据)
UPDATE `train_user_membership` SET `level_code` = 'light' WHERE `level_code` = 'basic';
UPDATE `train_user_membership` SET `level_code` = 'standard' WHERE `level_code` = 'premium';

-- 验证更新结果
SELECT level_id, level_name, level_code, level_order, annual_price, description FROM train_membership_level ORDER BY level_order;
