-- =====================================================
-- 学习路径功能数据库脚本 (简化版 - 适合Navicat直接执行)
-- 数据库: hotel_training
-- 服务器: bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com
-- 端口: 27608
-- =====================================================
-- 重要：请先连接到 bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608
-- 然后选择 hotel_training 数据库后执行此脚本
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
  `path_type` varchar(50) DEFAULT 'standard' COMMENT '路径类型(standard-标准路径,custom-自定义路径)',
  `target_role` varchar(100) COMMENT '目标岗位/角色',
  `difficulty_level` varchar(20) DEFAULT 'beginner' COMMENT '难度等级(beginner-初级,intermediate-中级,advanced-高级)',
  `estimated_duration` int(11) DEFAULT 0 COMMENT '预计学习时长(天)',
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
  `sequence` int(11) DEFAULT 0 COMMENT '在路径中的顺序',
  `is_required` tinyint(1) DEFAULT 1 COMMENT '是否必修(1-必修,0-选修)',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_path_id` (`path_id`),
  KEY `idx_plan_id` (`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习路径-计划关联表';

-- =====================================================
-- 3. 创建用户学习路径关联表
-- =====================================================
CREATE TABLE IF NOT EXISTS `user_learning_paths` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `path_id` bigint(20) NOT NULL COMMENT '路径ID',
  `assigned_by` bigint(20) COMMENT '分配人',
  `assigned_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '分配时间',
  `start_time` datetime COMMENT '开始学习时间',
  `complete_time` datetime COMMENT '完成时间',
  `progress` decimal(5,2) DEFAULT 0.00 COMMENT '学习进度(百分比)',
  `status` varchar(20) DEFAULT 'assigned' COMMENT '状态(assigned-已分配,in_progress-学习中,completed-已完成,expired-已过期)',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_path_id` (`path_id`),
  UNIQUE KEY `uk_user_path` (`user_id`, `path_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户学习路径关联表';

-- =====================================================
-- 4. 修改learning_plans表,添加path_id字段
-- =====================================================
-- 检查并添加path_id字段（如果不存在）
SET @dbname = DATABASE();
SET @tablename = 'learning_plans';
SET @columnname = 'path_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      TABLE_SCHEMA = @dbname
      AND TABLE_NAME = @tablename
      AND COLUMN_NAME = @columnname
  ) > 0,
  'SELECT ''path_id字段已存在'' AS message',
  CONCAT('ALTER TABLE `', @tablename, '` ADD COLUMN `', @columnname, '` bigint(20) DEFAULT NULL COMMENT ''所属学习路径ID'' AFTER `plan_id`')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 添加索引（如果不存在）
SET @indexExists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
                     WHERE TABLE_SCHEMA = DATABASE() 
                     AND TABLE_NAME = 'learning_plans' 
                     AND INDEX_NAME = 'idx_path_id');
SET @addIndex = IF(@indexExists = 0,
    'ALTER TABLE `learning_plans` ADD INDEX `idx_path_id` (`path_id`)',
    'SELECT ''idx_path_id索引已存在'' AS message'
);
PREPARE stmt FROM @addIndex;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================
-- 5. 插入示例数据
-- =====================================================
INSERT IGNORE INTO `learning_paths` (`path_id`, `path_name`, `path_description`, `path_type`, `target_role`, `difficulty_level`, `estimated_duration`, `status`, `sort_order`) VALUES
(1, '前台服务专家路径', '针对酒店前台岗位的完整培训路径，从基础到进阶全面提升', 'standard', '前台接待', 'intermediate', 90, 'active', 1),
(2, '营销运营进阶路径', '酒店线上营销和运营管理的系统化培训路径', 'standard', '营销经理', 'advanced', 120, 'active', 2),
(3, '新员工入职路径', '新员工快速熟悉酒店业务的标准化入职培训路径', 'standard', '全员', 'beginner', 30, 'active', 3);

-- =====================================================
-- 执行完成提示
-- =====================================================
SELECT '学习路径表结构创建完成！' AS message;
SELECT COUNT(*) AS '学习路径数量' FROM learning_paths;

