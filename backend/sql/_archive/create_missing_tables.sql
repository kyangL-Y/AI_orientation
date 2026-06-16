-- 创建缺失的培训模块表
-- 只创建不存在的表，不影响现有数据

-- 创建考试表（如果不存在）
CREATE TABLE IF NOT EXISTS `train_exam` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '考试ID',
  `name` varchar(100) NOT NULL COMMENT '考试名称',
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
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试表';

-- 创建考试权限分配表
CREATE TABLE IF NOT EXISTS `train_exam_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `exam_id` bigint(20) NOT NULL COMMENT '考试ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user-用户，dept-部门，role-角色，hotel-酒店',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_exam_id` (`exam_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试权限分配表';

-- 创建考试-题目关联表（如果不存在）
CREATE TABLE IF NOT EXISTS `train_exam_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `exam_id` bigint(20) NOT NULL COMMENT '考试ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序',
  `score` int(11) DEFAULT 1 COMMENT '分值',
  PRIMARY KEY (`id`),
  KEY `idx_exam_id` (`exam_id`),
  KEY `idx_question_id` (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训考试-题目关联表';

-- 创建测评表（如果不存在）
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

-- 创建测评权限分配表
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

-- 创建认证表（如果不存在）
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

-- 创建认证权限分配表
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

-- 创建奖励表（如果不存在）
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

-- 创建奖励权限分配表
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

-- 创建排名表（如果不存在）
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

-- 创建排名权限分配表
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

-- 完成表创建
SELECT '缺失的表创建完成！' as message;
