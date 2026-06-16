-- 只插入测试数据，不创建表
-- 适用于已有表结构但缺少数据的情况

-- 插入考试数据
INSERT INTO `train_exam` (`name`, `status`, `start_time`, `end_time`, `create_by`, `remark`) VALUES
('酒店服务综合考试', 'published', '2025-09-20 09:00:00', '2025-09-20 11:00:00', 'admin', '用于评估员工的服务技能水平'),
('前台操作技能考试', 'draft', '2025-09-25 14:00:00', '2025-09-25 16:00:00', 'admin', '测试前台员工的操作技能'),
('客房服务标准考试', 'draft', '2025-10-01 10:00:00', '2025-10-01 12:00:00', 'admin', '客房服务标准化培训考试'),
('餐饮服务技能考试', 'published', '2025-10-05 15:00:00', '2025-10-05 17:00:00', 'admin', '餐饮服务技能评估考试');

-- 插入测评数据
INSERT INTO `train_assessment` (`name`, `scale`, `status`, `create_by`, `remark`) VALUES
('服务意识测评', '服务意识量表', 'published', 'admin', '评估员工的服务意识和态度'),
('沟通能力评估', '沟通能力量表', 'draft', 'admin', '测试员工的沟通交流能力'),
('团队协作测评', '团队协作量表', 'published', 'admin', '评估员工的团队合作能力'),
('客户满意度测评', '客户满意度量表', 'draft', 'admin', '测试员工对客户需求的理解');

-- 插入认证数据
INSERT INTO `train_certification` (`name`, `description`, `level`, `status`, `create_by`, `remark`) VALUES
('初级服务员认证', '基础服务技能认证', '初级', 'published', 'admin', '新员工基础技能认证'),
('中级主管认证', '管理技能认证', '中级', 'published', 'admin', '主管级别管理能力认证'),
('高级经理认证', '高级管理认证', '高级', 'draft', 'admin', '高级管理人员认证'),
('专业技师认证', '专业技能认证', '专业', 'published', 'admin', '专业技术岗位认证');

-- 插入奖励数据
INSERT INTO `train_reward` (`name`, `type`, `points`, `status`, `create_by`, `remark`) VALUES
('优秀员工奖励', '积分奖励', 100, 'active', 'admin', '月度优秀员工奖励'),
('学习进步奖', '积分奖励', 50, 'active', 'admin', '学习进步奖励'),
('团队贡献奖', '积分奖励', 200, 'active', 'admin', '团队贡献奖励'),
('创新建议奖', '积分奖励', 150, 'active', 'admin', '创新建议奖励');

-- 插入排名数据
INSERT INTO `train_ranking` (`user_id`, `user_name`, `score`, `rank_type`, `period`) VALUES
(1, '张三', 95, '月度排名', '2024-01'),
(2, '李四', 88, '月度排名', '2024-01'),
(3, '王五', 82, '月度排名', '2024-01'),
(4, '赵六', 78, '月度排名', '2024-01'),
(5, '钱七', 75, '月度排名', '2024-01');

-- 插入权限分配数据（示例）
INSERT INTO `train_exam_assign` (`exam_id`, `target_type`, `target_id`, `create_by`) VALUES
(1, 'dept', 1, 'admin'),
(1, 'dept', 2, 'admin'),
(2, 'dept', 3, 'admin'),
(3, 'dept', 4, 'admin'),
(4, 'dept', 5, 'admin');

INSERT INTO `train_assessment_assign` (`assessment_id`, `target_type`, `target_id`, `create_by`) VALUES
(1, 'dept', 1, 'admin'),
(1, 'dept', 2, 'admin'),
(2, 'dept', 3, 'admin'),
(3, 'dept', 4, 'admin'),
(4, 'dept', 5, 'admin');

INSERT INTO `train_certification_assign` (`certification_id`, `target_type`, `target_id`, `create_by`) VALUES
(1, 'dept', 1, 'admin'),
(1, 'dept', 2, 'admin'),
(2, 'dept', 3, 'admin'),
(3, 'dept', 4, 'admin'),
(4, 'dept', 5, 'admin');

INSERT INTO `train_reward_assign` (`reward_id`, `target_type`, `target_id`, `create_by`) VALUES
(1, 'dept', 1, 'admin'),
(1, 'dept', 2, 'admin'),
(2, 'dept', 3, 'admin'),
(3, 'dept', 4, 'admin'),
(4, 'dept', 5, 'admin');

INSERT INTO `train_ranking_assign` (`ranking_id`, `target_type`, `target_id`, `create_by`) VALUES
(1, 'dept', 1, 'admin'),
(1, 'dept', 2, 'admin'),
(2, 'dept', 3, 'admin'),
(3, 'dept', 4, 'admin'),
(4, 'dept', 5, 'admin');

-- 完成数据插入
SELECT '测试数据插入完成！' as message;
