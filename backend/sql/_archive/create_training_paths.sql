-- 创建岗位培训路径表
CREATE TABLE IF NOT EXISTS `train_training_path` (
  `path_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '路径ID',
  `path_name` varchar(100) NOT NULL COMMENT '路径名称',
  `path_description` text COMMENT '路径描述',
  `target_position` varchar(100) NOT NULL COMMENT '目标岗位',
  `difficulty_level` tinyint(1) DEFAULT 1 COMMENT '难度等级(1-初级,2-中级,3-高级)',
  `estimated_duration` int(11) DEFAULT 0 COMMENT '预计学习时长(小时)',
  `course_count` int(11) DEFAULT 0 COMMENT '课程数量',
  `cover_image` varchar(255) DEFAULT NULL COMMENT '封面图片',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态(0-停用,1-启用)',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`path_id`),
  KEY `idx_target_position` (`target_position`),
  KEY `idx_difficulty_level` (`difficulty_level`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='岗位培训路径表';

-- 创建路径课程关联表
CREATE TABLE IF NOT EXISTS `train_path_course` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `path_id` bigint(20) NOT NULL COMMENT '路径ID',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序',
  `is_required` tinyint(1) DEFAULT 1 COMMENT '是否必修(0-选修,1-必修)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_path_course` (`path_id`, `course_id`),
  KEY `idx_path_id` (`path_id`),
  KEY `idx_course_id` (`course_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='路径课程关联表';

-- 创建用户学习路径表
CREATE TABLE IF NOT EXISTS `train_user_path` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `path_id` bigint(20) NOT NULL COMMENT '路径ID',
  `status` tinyint(1) DEFAULT 0 COMMENT '状态(0-未开始,1-进行中,2-已完成)',
  `progress_percent` decimal(5,2) DEFAULT 0.00 COMMENT '完成进度百分比',
  `started_at` datetime DEFAULT NULL COMMENT '开始时间',
  `completed_at` datetime DEFAULT NULL COMMENT '完成时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_path` (`user_id`, `path_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_path_id` (`path_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户学习路径表';

-- 插入示例数据
INSERT INTO `train_training_path` (`path_name`, `path_description`, `target_position`, `difficulty_level`, `estimated_duration`, `course_count`, `cover_image`, `status`, `sort_order`, `create_by`) VALUES
('前台接待专员', '从入门到精通的前台服务技能，包括客户接待、预订管理、投诉处理等核心技能', '前台接待专员', 1, 24, 8, '/images/paths/front-desk.jpg', 1, 1, 'admin'),
('客房服务主管', '客房服务与管理进阶技能，涵盖团队管理、质量控制、成本控制等管理技能', '客房服务主管', 2, 18, 6, '/images/paths/housekeeping.jpg', 1, 2, 'admin'),
('餐饮服务经理', '餐饮服务与运营管理技能，包括菜单设计、成本控制、团队培训等', '餐饮服务经理', 2, 30, 10, '/images/paths/food-service.jpg', 1, 3, 'admin'),
('酒店销售总监', '酒店销售与市场推广技能，涵盖客户开发、合同谈判、市场分析等', '酒店销售总监', 3, 36, 12, '/images/paths/sales.jpg', 1, 4, 'admin'),
('酒店总经理', '酒店全面运营管理技能，包括战略规划、财务管理、人力资源等', '酒店总经理', 3, 48, 15, '/images/paths/general-manager.jpg', 1, 5, 'admin');
