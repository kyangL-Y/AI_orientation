-- 完整的培训系统数据库初始化脚本
-- 包含所有表结构和测试数据

-- 1. 创建题库表
CREATE TABLE IF NOT EXISTS `train_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '题目ID',
  `company_id` bigint(20) DEFAULT NULL COMMENT '集团ID',
  `hotel_code` varchar(10) DEFAULT NULL COMMENT '酒店代码',
  `category` varchar(50) DEFAULT NULL COMMENT '题目分类',
  `dept_id` bigint(20) DEFAULT NULL COMMENT '部门ID',
  `question_type` varchar(20) DEFAULT NULL COMMENT '题目类型(单选题/多选题/判断题/简答题/填空题)',
  `question_text` text NOT NULL COMMENT '题目内容',
  `option_a` varchar(500) DEFAULT NULL COMMENT '选项A',
  `option_b` varchar(500) DEFAULT NULL COMMENT '选项B',
  `option_c` varchar(500) DEFAULT NULL COMMENT '选项C',
  `option_d` varchar(500) DEFAULT NULL COMMENT '选项D',
  `correct_answer` varchar(255) DEFAULT NULL COMMENT '正确答案',
  `difficulty` varchar(10) DEFAULT '中等' COMMENT '题目难度(简单/中等/困难)',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序号（数字越小越靠前）',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态(0禁用 1启用)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_company_id` (`company_id`),
  KEY `idx_hotel_code` (`hotel_code`),
  KEY `idx_category` (`category`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_question_type` (`question_type`),
  KEY `idx_sort_order` (`sort_order`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训题目表';

-- 2. 创建题目权限分配表
CREATE TABLE IF NOT EXISTS `train_question_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user-用户，dept-部门，role-角色，hotel-酒店',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_question_id` (`question_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训题目权限分配表';

-- 3. 创建考试表
CREATE TABLE IF NOT EXISTS `train_exam` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '考试ID',
  `name` varchar(100) NOT NULL COMMENT '考试名称',
  `exam_type` varchar(20) DEFAULT 'final_exam' COMMENT '考试类型',
  `status` varchar(20) DEFAULT 'draft' COMMENT '状态：draft-草稿，published-已发布，ended-已结束',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`),
  KEY `idx_status` (`status`),
  KEY `idx_create_time` (`create_time`),
  KEY `idx_exam_type` (`exam_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试表';

-- 4. 创建考试权限分配表
CREATE TABLE IF NOT EXISTS `train_exam_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `exam_id` bigint(20) NOT NULL COMMENT '考试ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user-用户，dept-部门，tenant-租户，company-全公司',
  `target_id` varchar(64) NOT NULL COMMENT '目标ID（用户/部门/租户等）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_exam_id` (`exam_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试权限分配表';

-- 5. 创建测评表
CREATE TABLE IF NOT EXISTS `train_assessment` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '测评ID',
  `name` varchar(200) NOT NULL COMMENT '测评名称',
  `scale` varchar(100) DEFAULT NULL COMMENT '量表类型',
  `status` varchar(20) DEFAULT 'draft' COMMENT '状态(draft:未发布, published:已发布)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训测评表';

-- 6. 创建测评权限分配表
CREATE TABLE IF NOT EXISTS `train_assessment_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `assessment_id` bigint(20) NOT NULL COMMENT '测评ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user-用户，dept-部门，role-角色，hotel-酒店',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_assessment_id` (`assessment_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测评权限分配表';

-- 7. 创建认证表
CREATE TABLE IF NOT EXISTS `train_certification` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '认证ID',
  `name` varchar(200) NOT NULL COMMENT '认证名称',
  `description` varchar(500) DEFAULT NULL COMMENT '认证描述',
  `level` varchar(50) DEFAULT NULL COMMENT '认证等级',
  `status` varchar(20) DEFAULT 'draft' COMMENT '状态(draft:未发布, published:已发布)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训认证表';

-- 8. 创建认证权限分配表
CREATE TABLE IF NOT EXISTS `train_certification_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `certification_id` bigint(20) NOT NULL COMMENT '认证ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user-用户，dept-部门，role-角色，hotel-酒店',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_certification_id` (`certification_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='认证权限分配表';

-- 9. 创建奖励表
CREATE TABLE IF NOT EXISTS `train_reward` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '奖励ID',
  `name` varchar(200) NOT NULL COMMENT '奖励名称',
  `type` varchar(50) DEFAULT NULL COMMENT '奖励类型',
  `points` int(11) DEFAULT 0 COMMENT '积分',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态(active:有效, inactive:无效)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训奖励表';

-- 10. 创建奖励权限分配表
CREATE TABLE IF NOT EXISTS `train_reward_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `reward_id` bigint(20) NOT NULL COMMENT '奖励ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user-用户，dept-部门，role-角色，hotel-酒店',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_reward_id` (`reward_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='奖励权限分配表';

-- 11. 创建排名表
CREATE TABLE IF NOT EXISTS `train_ranking` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '排名ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `user_name` varchar(100) NOT NULL COMMENT '用户名',
  `score` int(11) DEFAULT 0 COMMENT '总分',
  `rank_type` varchar(50) DEFAULT 'overall' COMMENT '排名类型',
  `period` varchar(20) DEFAULT 'monthly' COMMENT '统计周期',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_rank_type` (`rank_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训排名表';

-- 12. 创建排名权限分配表
CREATE TABLE IF NOT EXISTS `train_ranking_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `ranking_id` bigint(20) NOT NULL COMMENT '排名ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user-用户，dept-部门，role-角色，hotel-酒店',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_ranking_id` (`ranking_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='排名权限分配表';

-- 插入测试数据

-- 插入题库数据
INSERT INTO `train_question` (`company_id`, `hotel_code`, `category`, `dept_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_answer`, `difficulty`, `sort_order`, `status`, `create_by`) VALUES
(1, 'ZYHY', 'OTA运营', 1, '单选题', 'OTA订单确认后，应在多少分钟内确认？', '5分钟', '10分钟', '15分钟', '30分钟', 'A', '简单', 1, 1, 'admin'),
(1, 'COMMON', '前台操作', 2, '判断题', '客人退房时必须清理房间', NULL, NULL, NULL, NULL, '错误', '中等', 2, 1, 'admin'),
(1, 'ZYHY', '客房服务', 3, '单选题', '客房清洁的标准流程是什么？', '先清洁卫生间', '先整理床铺', '先清理垃圾', '先开窗通风', 'D', '中等', 3, 1, 'admin'),
(1, 'COMMON', '餐饮服务', 4, '多选题', '餐厅服务的基本要求包括哪些？', '微笑服务', '及时响应', '专业推荐', '快速结账', 'A,B,C', '简单', 4, 1, 'admin'),
(1, 'ZYHY', '安全管理', 5, '单选题', '酒店消防安全检查的频率是？', '每日一次', '每周一次', '每月一次', '每季度一次', 'C', '困难', 5, 1, 'admin');

-- 插入考试数据
INSERT INTO `train_exam` (`name`, `exam_type`, `status`, `start_time`, `end_time`, `create_by`, `remark`) VALUES
('酒店服务综合考试', 'monthly_exam', 'published', '2025-09-20 09:00:00', '2025-09-20 11:00:00', 'admin', '用于评估员工的服务技能水平'),
('前台操作技能考试', 'monthly_exam', 'draft', '2025-09-25 14:00:00', '2025-09-25 16:00:00', 'admin', '测试前台员工的操作技能'),
('客房服务标准考试', 'monthly_exam', 'draft', '2025-10-01 10:00:00', '2025-10-01 12:00:00', 'admin', '客房服务标准化培训考试'),
('餐饮服务技能考试', 'monthly_exam', 'published', '2025-10-05 15:00:00', '2025-10-05 17:00:00', 'admin', '餐饮服务技能评估考试'),
('期末考试', 'final_exam', 'published', '2025-10-15 14:00:00', '2025-10-15 16:00:00', 'admin', '期末综合能力考试'),
('学习路径结业考试', 'graduation_exam', 'published', '2025-10-20 14:00:00', '2025-10-20 16:00:00', 'admin', '学习路径结业考核');

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
INSERT INTO `train_question_assign` (`question_id`, `target_type`, `target_id`, `create_by`) VALUES
(1, 'dept', 1, 'admin'),
(2, 'dept', 2, 'admin'),
(3, 'dept', 3, 'admin'),
(4, 'dept', 4, 'admin'),
(5, 'dept', 5, 'admin');

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

-- 完成初始化
SELECT '培训系统数据库初始化完成！' as message;
