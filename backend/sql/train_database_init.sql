-- 培训模块数据库表结构
-- 建议在数据库中执行此脚本

-- 1. 题库表
CREATE TABLE IF NOT EXISTS `train_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `title` varchar(500) NOT NULL COMMENT '题目',
  `category` varchar(100) DEFAULT NULL COMMENT '分类',
  `difficulty` varchar(50) DEFAULT NULL COMMENT '难度',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(64) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-题库';

-- 2. 题目权限分配表
CREATE TABLE IF NOT EXISTS `train_question_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user/dept/role',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_question_id` (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-题目权限分配';

-- 3. 考试表
CREATE TABLE IF NOT EXISTS `train_exam` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(200) NOT NULL COMMENT '考试名称',
  `status` varchar(20) DEFAULT 'draft' COMMENT '状态',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `create_by` varchar(64) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(64) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `remark` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-考试管理';

-- 4. 考试权限分配表  
CREATE TABLE IF NOT EXISTS `train_exam_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `exam_id` bigint(20) NOT NULL COMMENT '考试ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user/dept/tenant/company',
  `target_id` varchar(64) NOT NULL COMMENT '目标ID（用户/部门/租户等）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_exam_id` (`exam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-考试权限分配';

-- 5. 学习权限分配表
CREATE TABLE IF NOT EXISTS `train_study_assign` (
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

-- 6. 用户快照表
CREATE TABLE IF NOT EXISTS `train_users_ref` (
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `user_name` varchar(64) NOT NULL COMMENT '用户账号',
  `nick_name` varchar(128) DEFAULT NULL COMMENT '用户昵称',
  `dept_id` bigint(20) DEFAULT NULL COMMENT '部门ID',
  `role_ids` varchar(500) DEFAULT NULL COMMENT '角色ID列表，逗号分隔',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-用户信息快照';

-- 7. 部门快照表
CREATE TABLE IF NOT EXISTS `train_depts_ref` (
  `dept_id` bigint(20) NOT NULL COMMENT '部门ID',
  `dept_name` varchar(64) NOT NULL COMMENT '部门名称',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`dept_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-部门信息快照';

-- 8. 角色快照表
CREATE TABLE IF NOT EXISTS `train_roles_ref` (
  `role_id` bigint(20) NOT NULL COMMENT '角色ID',
  `role_name` varchar(64) NOT NULL COMMENT '角色名称',
  `role_key` varchar(100) NOT NULL COMMENT '角色权限字符串',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-角色信息快照';

-- 插入测试数据
INSERT INTO train_question (title, category, difficulty, create_by, create_time) VALUES
('酒店前厅服务的基本要求是什么？', '前厅', 'easy', 'admin', NOW()),
('客房清洁的标准流程包括哪些步骤？', '客房', 'medium', 'admin', NOW()),
('餐厅服务中如何处理客人投诉？', '餐饮', 'hard', 'admin', NOW());
