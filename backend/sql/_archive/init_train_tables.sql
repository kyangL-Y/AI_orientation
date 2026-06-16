-- 培训模块完整数据库表初始化脚本
-- 执行前请备份现有数据

-- 1. 表
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

-- 2. 考试管理表
CREATE TABLE IF NOT EXISTS `train_exam` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '考试ID',
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

-- 3. 能力等级认证表
CREATE TABLE IF NOT EXISTS `train_certification` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '认证ID',
  `employee_name` varchar(100) NOT NULL COMMENT '员工姓名',
  `level` varchar(50) NOT NULL COMMENT '等级',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态(pending:待审核, approved:通过, rejected:拒绝)',
  `cert_time` datetime DEFAULT NULL COMMENT '认证时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训认证表';

-- 4. 奖励机制表
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

-- 5. 排名管理表
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

-- 6. 权限分配表（通用）
CREATE TABLE IF NOT EXISTS `train_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `resource_type` varchar(50) NOT NULL COMMENT '资源类型(question,exam,assessment,certification,reward)',
  `resource_id` bigint(20) NOT NULL COMMENT '资源ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型(user,dept,role,company)',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_resource` (`resource_type`, `resource_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训权限分配表';

-- 插入示例数据
INSERT INTO `train_assessment` (`name`, `scale`, `status`, `create_by`) VALUES
('服务意识测评', '服务意识', 'published', 'admin'),
('沟通能力评估', '沟通能力', 'draft', 'admin');

INSERT INTO `train_exam` (`name`, `status`, `start_time`, `end_time`, `create_by`) VALUES
('酒店服务综合考试', 'published', '2025-09-20 09:00:00', '2025-09-20 11:00:00', 'admin'),
('前台操作技能考试', 'draft', '2025-09-25 14:00:00', '2025-09-25 16:00:00', 'admin');

INSERT INTO `train_certification` (`employee_name`, `level`, `status`, `create_by`) VALUES
('张三', '初级服务员', 'approved', 'admin'),
('李四', '中级服务员', 'pending', 'admin');

INSERT INTO `train_reward` (`name`, `type`, `points`, `status`, `create_by`) VALUES
('优秀员工奖', '月度奖励', 100, 'active', 'admin'),
('进步奖', '成长奖励', 50, 'active', 'admin');

INSERT INTO `train_ranking` (`user_id`, `user_name`, `score`, `rank_type`) VALUES
(1, 'admin', 95, 'overall'),
(2, 'ry', 88, 'overall');