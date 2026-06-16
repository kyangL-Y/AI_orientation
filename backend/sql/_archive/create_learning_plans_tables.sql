-- =====================================================
-- 学习计划模块数据库表结构
-- 华智酒店员工培训系统 - 学习计划模块
-- =====================================================
-- 服务器: bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com
-- 端口: 27608
-- 数据库: hotel_training
-- =====================================================
-- 重要：请先连接到 bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608
-- 然后选择 hotel_training 数据库后执行此脚本
-- =====================================================

USE hotel_training;

-- 1. 学习计划主表
CREATE TABLE IF NOT EXISTS `learning_plans` (
  `plan_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '计划ID',
  `title` varchar(100) NOT NULL COMMENT '计划标题',
  `description` text COMMENT '计划描述',
  `created_by` bigint(20) NOT NULL COMMENT '创建人ID',
  `assigned_to` bigint(20) NOT NULL COMMENT '分配给用户ID',
  `status` enum('draft','active','completed','cancelled') NOT NULL DEFAULT 'active' COMMENT '计划状态',
  `start_date` date NOT NULL COMMENT '开始日期',
  `end_date` date NOT NULL COMMENT '结束日期',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`plan_id`),
  KEY `idx_assigned_to` (`assigned_to`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_status` (`status`),
  KEY `idx_date_range` (`start_date`, `end_date`),
  CONSTRAINT `fk_learning_plans_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_user` (`user_id`),
  CONSTRAINT `fk_learning_plans_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `sys_user` (`user_id`),
  CONSTRAINT `chk_learning_plans_end_date` CHECK (`end_date` > `start_date`),
  CONSTRAINT `chk_learning_plans_title` CHECK (LENGTH(`title`) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习计划主表';

-- 2. 计划任务项表
CREATE TABLE IF NOT EXISTS `plan_items` (
  `item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '任务项ID',
  `plan_id` bigint(20) NOT NULL COMMENT '计划ID',
  `content_type` enum('course','quiz','task') NOT NULL COMMENT '内容类型',
  `content_id` bigint(20) NOT NULL COMMENT '内容ID（课程ID、考试ID等）',
  `title` varchar(100) NOT NULL COMMENT '任务标题',
  `due_date` date NOT NULL COMMENT '截止日期',
  `status` enum('pending','in_progress','completed','overdue') NOT NULL DEFAULT 'pending' COMMENT '任务状态',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序号',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`item_id`),
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_content` (`content_type`, `content_id`),
  KEY `idx_due_date` (`due_date`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_plan_items_plan_id` FOREIGN KEY (`plan_id`) REFERENCES `learning_plans` (`plan_id`) ON DELETE CASCADE,
  CONSTRAINT `chk_plan_items_title` CHECK (LENGTH(`title`) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计划任务项表';

-- 3. 任务完成记录表
CREATE TABLE IF NOT EXISTS `plan_item_completions` (
  `completion_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '完成记录ID',
  `item_id` bigint(20) NOT NULL COMMENT '任务项ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `completed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '完成时间',
  `score` decimal(5,2) DEFAULT NULL COMMENT '得分（可选）',
  `feedback` text COMMENT '反馈信息（可选）',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`completion_id`),
  UNIQUE KEY `uk_item_user_completion` (`item_id`, `user_id`) COMMENT '防止重复完成',
  KEY `idx_user_id` (`user_id`),
  KEY `idx_completed_at` (`completed_at`),
  CONSTRAINT `fk_completions_item_id` FOREIGN KEY (`item_id`) REFERENCES `plan_items` (`item_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_completions_user_id` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务完成记录表';

-- 添加索引优化查询性能
CREATE INDEX `idx_learning_plans_composite` ON `learning_plans` (`assigned_to`, `status`, `start_date`);
CREATE INDEX `idx_plan_items_composite` ON `plan_items` (`plan_id`, `status`, `due_date`);

-- 插入示例数据（可选）
INSERT INTO `learning_plans` (`title`, `description`, `created_by`, `assigned_to`, `status`, `start_date`, `end_date`, `create_by`) VALUES
('新员工入职培训', '新员工必须完成的入职培训计划', 1, 2, 'active', '2025-01-15', '2025-01-30', 'admin'),
('安全规范培训', '酒店安全操作规范培训', 1, 3, 'active', '2025-01-20', '2025-02-05', 'admin'),
('学习路径结业考试', '学习路径内的结业考试安排', 1, 2, 'active', '2025-02-01', '2025-02-10', 'admin');

INSERT INTO `plan_items` (`plan_id`, `content_type`, `content_id`, `title`, `due_date`, `status`, `create_by`) VALUES
(1, 'course', 101, '酒店文化介绍', '2025-01-18', 'pending', 'admin'),
(1, 'quiz', 201, '入职考试', '2025-01-25', 'pending', 'admin'),
(1, 'task', 301, '部门实习', '2025-01-30', 'pending', 'admin'),
(2, 'course', 102, '消防安全知识', '2025-01-25', 'pending', 'admin'),
(2, 'quiz', 202, '安全规范考试', '2025-02-05', 'pending', 'admin'),
(3, 'quiz', IFNULL((SELECT id FROM train_exam WHERE name = '学习路径结业考试' ORDER BY id DESC LIMIT 1), 0), '结业考试', '2025-02-10', 'pending', 'admin');
