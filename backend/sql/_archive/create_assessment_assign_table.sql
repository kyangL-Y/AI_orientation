-- 创建测评分配表
CREATE TABLE IF NOT EXISTS `train_assessment_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `assessment_id` bigint(20) NOT NULL COMMENT '测评ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：hotel-酒店，dept-部门，user-用户',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_assessment_id` (`assessment_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='测评分配表';

-- 创建认证分配表
CREATE TABLE IF NOT EXISTS `train_certification_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `certification_id` bigint(20) NOT NULL COMMENT '认证ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：hotel-酒店，dept-部门，user-用户',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_certification_id` (`certification_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='认证分配表';

-- 创建奖励分配表
CREATE TABLE IF NOT EXISTS `train_reward_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `reward_id` bigint(20) NOT NULL COMMENT '奖励ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：hotel-酒店，dept-部门，user-用户',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_reward_id` (`reward_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='奖励分配表';

-- 创建排名分配表
CREATE TABLE IF NOT EXISTS `train_ranking_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `ranking_id` bigint(20) NOT NULL COMMENT '排名ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：hotel-酒店，dept-部门，user-用户',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_ranking_id` (`ranking_id`),
  KEY `idx_target` (`target_type`, `target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='排名分配表';


