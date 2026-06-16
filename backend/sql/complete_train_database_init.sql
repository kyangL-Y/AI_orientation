-- 完整的培训模块数据库表结构
-- 请先删除原有的 train_question 表，然后执行此脚本

-- 1. 删除原有表（如果存在）
DROP TABLE IF EXISTS `train_question`;
DROP TABLE IF EXISTS `train_question_assign`;
DROP TABLE IF EXISTS `train_users_ref`;

-- 2. 创建新的 train_question 表（与您的实体类完全匹配）
CREATE TABLE `train_question` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '题目ID',
  `hotel_code` varchar(10) DEFAULT NULL COMMENT '酒店代码',
  `category` varchar(50) DEFAULT NULL COMMENT '题目分类',
  `dept_id` int(11) DEFAULT NULL COMMENT '部门ID',
  `question_type` varchar(20) DEFAULT NULL COMMENT '题目类型(单选题/多选题/判断题/简答题/填空题)',
  `question_text` text NOT NULL COMMENT '题目内容',
  `option_a` varchar(500) DEFAULT NULL COMMENT '选项A',
  `option_b` varchar(500) DEFAULT NULL COMMENT '选项B',
  `option_c` varchar(500) DEFAULT NULL COMMENT '选项C',
  `option_d` varchar(500) DEFAULT NULL COMMENT '选项D',
  `correct_answer` varchar(255) DEFAULT NULL COMMENT '正确答案',
  `difficulty` varchar(10) DEFAULT '中等' COMMENT '题目难度(简单/中等/困难)',
  `status` tinyint(1) DEFAULT '0' COMMENT '状态(0启用 1禁用)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_hotel_code` (`hotel_code`),
  KEY `idx_category` (`category`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_question_type` (`question_type`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COMMENT='培训题目表';

-- 3. 创建题目权限分配表
CREATE TABLE `train_question_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user/dept/role',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_question_id` (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-题目权限分配';

-- 4. 创建用户信息快照表
CREATE TABLE `train_users_ref` (
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `user_name` varchar(64) NOT NULL COMMENT '用户账号',
  `nick_name` varchar(128) DEFAULT NULL COMMENT '用户昵称',
  `dept_id` bigint(20) DEFAULT NULL COMMENT '部门ID',
  `role_ids` varchar(500) DEFAULT NULL COMMENT '角色ID列表，逗号分隔',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-用户信息快照';

-- 5. 插入示例数据
INSERT INTO `train_question` (`id`, `hotel_code`, `category`, `dept_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_answer`, `difficulty`, `status`, `create_time`) VALUES
(1, 'ZYHY', 'OTA运营', 1, '单选题', 'OTA订单确认后，应在多少分钟内确认？', '5分钟', '10分钟', '15分钟', '30分钟', 'A', '简单', 0, '2025-09-17 08:56:01'),
(2, 'COMMON', '前台操作', 2, '判断题', '客人退房时必须清理房间', NULL, NULL, NULL, NULL, '错误', '中等', 0, '2025-09-17 08:56:01'),
(3, 'HZJD', '客饮服务', 4, '多选题', '以下哪些属于客饮服务项目？', '做美颜茶', '上架招牌茶', '唯汇客人点餐', '主动添水', 'A,B,D', '中等', 0, '2025-09-17 08:56:01'),
(4, 'COMMON', '服务标准', 3, '简答题', '请简述酒店前台接待客人的基本流程和注意事项。', NULL, NULL, NULL, NULL, '微笑迎客、询问需求、办理入住、介绍设施、祝住愉快', '中等', 0, '2025-09-17 08:56:01'),
(5, 'ZYHY', '操作规范', 2, '填空题', '酒店客房清洁标准要求卫生间应保持____，床单更换频率为____。', NULL, NULL, NULL, NULL, '干净整洁;每日更换', '简单', 0, '2025-09-17 08:56:01');

-- 6. 插入用户信息快照（请根据实际用户信息调整）
INSERT INTO `train_users_ref` (`user_id`, `user_name`, `nick_name`, `dept_id`, `role_ids`) VALUES
(1, 'admin', '管理员', 103, '1'),
(2, 'ry', '若依', 105, '2');

-- 7. 为管理员用户分配题目权限
INSERT INTO `train_question_assign` (`question_id`, `target_type`, `target_id`, `create_by`) VALUES
(1, 'user', 1, 'admin'),
(2, 'user', 1, 'admin'),
(3, 'user', 1, 'admin'),
(4, 'user', 1, 'admin'),
(5, 'user', 1, 'admin');

-- 8. 考试表
CREATE TABLE `train_exam` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '考试ID',
  `name` varchar(200) NOT NULL COMMENT '考试名称',
  `status` varchar(20) DEFAULT 'draft' COMMENT '状态(draft:未发布, published:已发布)',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试表';

-- 9. 考试权限分配表
CREATE TABLE `train_exam_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `exam_id` bigint(20) NOT NULL COMMENT '考试ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user/dept/tenant/company',
  `target_id` varchar(64) NOT NULL COMMENT '目标ID（用户/部门/租户等）',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_exam_id` (`exam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-考试权限分配';

-- 10. 学习权限分配表
CREATE TABLE `train_study_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `study_id` bigint(20) NOT NULL COMMENT '学习ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型(user,dept,hotel,company)',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_study_id` (`study_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习权限分配表';

-- 11. 测评表
CREATE TABLE `train_assessment` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '测评ID',
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

-- 插入示例数据
INSERT INTO `train_exam` (`name`, `status`, `start_time`, `end_time`, `create_by`) VALUES
('酒店服务综合考试', 'published', '2025-09-20 09:00:00', '2025-09-20 11:00:00', 'admin'),
('前台操作技能考试', 'draft', '2025-09-25 14:00:00', '2025-09-25 16:00:00', 'admin'),
('期末考试', 'published', '2025-10-15 14:00:00', '2025-10-15 16:00:00', 'admin'),
('学习路径结业考试', 'published', '2025-10-20 14:00:00', '2025-10-20 16:00:00', 'admin');

INSERT INTO `train_assessment` (`name`, `scale`, `status`, `create_by`) VALUES
('服务意识测评', '服务意识', 'published', 'admin'),
('沟通能力评估', '沟通能力', 'draft', 'admin');
