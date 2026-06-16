-- =====================================================
-- 学习路径功能数据库脚本 (兼容版 - 支持所有MySQL版本)
-- 数据库: hotel_training
-- 执行说明: 直接在Navicat中全选并运行
-- =====================================================

-- 使用数据库
USE hotel_training;

-- =====================================================
-- 1. 创建学习路径主表
-- =====================================================
CREATE TABLE IF NOT EXISTS `learning_paths` (
  `path_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '路径ID',
  `path_name` varchar(200) NOT NULL COMMENT '路径名称',
  `path_description` text COMMENT '路径描述',
  `path_type` varchar(50) DEFAULT 'standard' COMMENT '路径类型',
  `target_role` varchar(100) COMMENT '目标岗位',
  `difficulty_level` varchar(20) DEFAULT 'beginner' COMMENT '难度等级',
  `estimated_duration` int(11) DEFAULT 0 COMMENT '预计时长天数',
  `cover_image` varchar(500) DEFAULT NULL COMMENT '封面图片',
  `status` varchar(20) DEFAULT 'active' COMMENT '路径状态(draft-草稿,active-激活,archived-归档)',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序号',
  `auto_assign_all` tinyint(1) DEFAULT 0 COMMENT '是否自动分配给全员(1-是,0-否)',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_by` bigint(20) COMMENT '更新人',
  `updated_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark` varchar(500) COMMENT '备注',
  PRIMARY KEY (`path_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习路径表';

-- =====================================================
-- 2. 创建学习路径-计划关联表
-- =====================================================
CREATE TABLE IF NOT EXISTS `learning_path_plans` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `path_id` bigint(20) NOT NULL COMMENT '路径ID',
  `plan_id` bigint(20) NOT NULL COMMENT '计划ID',
  `sequence` int(11) DEFAULT 0 COMMENT '顺序',
  `is_required` tinyint(1) DEFAULT 1 COMMENT '是否必修',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_path_id` (`path_id`),
  KEY `idx_plan_id` (`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='路径计划关联表';

-- =====================================================
-- 3. 创建用户学习路径关联表
-- =====================================================
CREATE TABLE IF NOT EXISTS `user_learning_paths` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `path_id` bigint(20) NOT NULL COMMENT '路径ID',
  `assigned_by` bigint(20) COMMENT '分配人',
  `assigned_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '分配时间',
  `start_time` datetime COMMENT '开始时间',
  `complete_time` datetime COMMENT '完成时间',
  `progress` decimal(5,2) DEFAULT 0.00 COMMENT '进度',
  `status` varchar(20) DEFAULT 'assigned' COMMENT '状态',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_path_id` (`path_id`),
  UNIQUE KEY `uk_user_path` (`user_id`, `path_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户路径表';

-- =====================================================
-- 4. 插入示例数据
-- =====================================================
INSERT IGNORE INTO `learning_paths` (`path_id`, `path_name`, `path_description`, `path_type`, `target_role`, `difficulty_level`, `estimated_duration`, `status`, `sort_order`) VALUES
(1, '前台服务专家路径', '针对酒店前台岗位的完整培训路径，从基础到进阶全面提升', 'standard', '前台接待', 'intermediate', 90, 'active', 1),
(2, '营销运营进阶路径', '酒店线上营销和运营管理的系统化培训路径', 'standard', '营销经理', 'advanced', 120, 'active', 2),
(3, '新员工入职路径', '新员工快速熟悉酒店业务的标准化入职培训路径', 'standard', '全员', 'beginner', 30, 'active', 3);

-- =====================================================
-- 5. 检查learning_plans表是否需要添加path_id字段
-- =====================================================
-- 注意: 如果下面的语句报错"Duplicate column name 'path_id'"
-- 说明字段已存在,可以忽略此错误,继续执行后面的语句即可

ALTER TABLE `learning_plans` 
ADD COLUMN `path_id` bigint(20) DEFAULT NULL COMMENT '所属路径ID' AFTER `plan_id`;

-- 添加索引(如果报错说索引已存在,也可以忽略)
ALTER TABLE `learning_plans` 
ADD INDEX `idx_path_id` (`path_id`);

-- =====================================================
-- 执行完成
-- =====================================================
SELECT '✅ 学习路径表结构创建完成!' AS 执行结果;
SELECT COUNT(*) AS 学习路径数量 FROM learning_paths;

