-- 直接执行这个SQL文件

-- 1. 插入认证数据
INSERT INTO train_certification (name, description, level, status, create_by, remark) VALUES
('高级员工认证', '高级员工技能认证', '高级', 'published', 'admin', '高级员工认证');

INSERT INTO train_certification (name, description, level, status, create_by, remark) VALUES
('中级员工认证', '中级员工技能认证', '中级', 'published', 'admin', '中级员工认证');

INSERT INTO train_certification (name, description, level, status, create_by, remark) VALUES
('初级员工认证', '初级员工技能认证', '初级', 'draft', 'admin', '初级员工认证');

-- 2. 插入奖励数据
INSERT INTO train_reward (name, type, points, status, create_by, remark) VALUES
('优秀员工奖励', 'points', 100, 'active', 'admin', '月度优秀员工奖励');

INSERT INTO train_reward (name, type, points, status, create_by, remark) VALUES
('技能提升奖励', 'points', 50, 'active', 'admin', '技能提升奖励');

INSERT INTO train_reward (name, type, points, status, create_by, remark) VALUES
('团队协作奖励', 'points', 80, 'active', 'admin', '团队协作表现奖励');

-- 3. 插入排名数据
INSERT INTO train_ranking (user_id, user_name, score, rank_type, period) VALUES
(1, '张三', 1200, 'overall', 'monthly');

INSERT INTO train_ranking (user_id, user_name, score, rank_type, period) VALUES
(2, '李四', 1100, 'overall', 'monthly');

INSERT INTO train_ranking (user_id, user_name, score, rank_type, period) VALUES
(3, '王五', 1000, 'overall', 'monthly');
