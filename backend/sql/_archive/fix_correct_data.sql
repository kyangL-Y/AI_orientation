-- 正确的数据插入SQL，使用实际存在的字段

-- 插入认证数据（使用正确的字段名）
INSERT INTO `train_certification` (`name`, `description`, `level`, `status`, `create_by`, `remark`) VALUES
('高级员工认证', '高级员工技能认证', '高级', 'published', 'admin', '高级员工认证'),
('中级员工认证', '中级员工技能认证', '中级', 'published', 'admin', '中级员工认证'),
('初级员工认证', '初级员工技能认证', '初级', 'draft', 'admin', '初级员工认证');

-- 插入奖励数据（使用正确的字段名）
INSERT INTO `train_reward` (`name`, `type`, `points`, `status`, `create_by`, `remark`) VALUES
('优秀员工奖励', 'points', 100, 'active', 'admin', '月度优秀员工奖励'),
('技能提升奖励', 'points', 50, 'active', 'admin', '技能提升奖励'),
('团队协作奖励', 'points', 80, 'active', 'admin', '团队协作表现奖励');

-- 插入排名数据（使用正确的字段名）
INSERT INTO `train_ranking` (`rank`, `name`, `points`, `avg_score`, `type`, `metric`, `create_by`) VALUES
(1, '张三', 1200, 95.5, 'user', 'points', 'admin'),
(2, '李四', 1100, 92.0, 'user', 'points', 'admin'),
(3, '王五', 1000, 88.5, 'user', 'points', 'admin');
