-- 快速修复数据 - 插入测试数据到三个模块

-- 插入认证数据
INSERT INTO `train_certification` (`employee_name`, `level`, `status`, `cert_time`, `create_by`, `remark`) VALUES
('张三', '高级', 'completed', '2025-09-30 10:00:00', 'admin', '高级员工认证'),
('李四', '中级', 'pending', '2025-09-30 11:00:00', 'admin', '中级员工认证'),
('王五', '初级', 'completed', '2025-09-30 12:00:00', 'admin', '初级员工认证');

-- 插入奖励数据  
INSERT INTO `train_reward` (`name`, `type`, `points`, `status`, `create_by`, `remark`) VALUES
('优秀员工奖励', 'points', 100, '1', 'admin', '月度优秀员工奖励'),
('技能提升奖励', 'points', 50, '1', 'admin', '技能提升奖励'),
('团队协作奖励', 'points', 80, '1', 'admin', '团队协作表现奖励');

-- 插入排名数据
INSERT INTO `train_ranking` (`rank`, `name`, `points`, `avg_score`, `type`, `metric`, `create_by`) VALUES
(1, '张三', 1200, 95.5, 'user', 'points', 'admin'),
(2, '李四', 1100, 92.0, 'user', 'points', 'admin'),
(3, '王五', 1000, 88.5, 'user', 'points', 'admin');
