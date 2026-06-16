-- =====================================================
-- 完整的学路径和学习计划系统建表脚本
-- =====================================================
-- 服务器: bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com
-- 端口: 27608
-- 数据库: hotel_training
-- =====================================================
-- 重要：请先连接到 bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608
-- 然后选择 hotel_training 数据库后执行此脚本
-- =====================================================

USE hotel_training;

-- =====================================================
-- 第一步：检查当前连接信息
-- =====================================================
SELECT 
    @@hostname AS '服务器名称',
    @@port AS '端口',
    DATABASE() AS '当前数据库',
    NOW() AS '执行时间'
AS '连接验证';

-- =====================================================
-- 第二步：创建学习计划表（如果不存在）
-- =====================================================
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
  KEY `idx_date_range` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习计划主表';

-- =====================================================
-- 第三步：创建计划任务项表（如果不存在）
-- =====================================================
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
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计划任务项表';

-- =====================================================
-- 第四步：创建任务完成记录表（如果不存在）
-- =====================================================
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
  KEY `idx_completed_at` (`completed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务完成记录表';

-- =====================================================
-- 第五步：创建学习路径主表（如果不存在）
-- =====================================================
CREATE TABLE IF NOT EXISTS `learning_paths` (
  `path_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '路径ID',
  `path_name` varchar(200) NOT NULL COMMENT '路径名称',
  `path_description` text COMMENT '路径描述',
  `path_type` varchar(50) DEFAULT 'standard' COMMENT '路径类型(standard-标准路径,custom-自定义路径)',
  `target_role` varchar(100) COMMENT '目标岗位/角色',
  `difficulty_level` varchar(20) DEFAULT 'beginner' COMMENT '难度等级(beginner-初级,intermediate-中级,advanced-高级)',
  `estimated_duration` int(11) DEFAULT 0 COMMENT '预计学习时长(天)',
  `cover_image` varchar(500) COMMENT '封面图片',
  `status` varchar(20) DEFAULT 'active' COMMENT '路径状态(draft-草稿,active-激活,archived-归档)',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序号',
  `auto_assign_all` tinyint(1) DEFAULT 0 COMMENT '是否自动分配给全员(1-是,0-否)',
  `created_by` bigint(20) COMMENT '创建人',
  `created_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_by` bigint(20) COMMENT '更新人',
  `updated_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark` varchar(500) COMMENT '备注',
  PRIMARY KEY (`path_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习路径表';

-- =====================================================
-- 第六步：创建学习路径-计划关联表（如果不存在）
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
-- 第七步：创建用户学习路径关联表（如果不存在）
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
-- 第八步：为learning_plans表添加path_id字段（如果不存在）
-- =====================================================
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

-- 为path_id字段添加索引（如果不存在）
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
-- 第九步：添加其他必要的索引
-- =====================================================
-- 为learning_plans添加复合索引（如果不存在）
SET @idx1 = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
             WHERE TABLE_SCHEMA = DATABASE() 
             AND TABLE_NAME = 'learning_plans' 
             AND INDEX_NAME = 'idx_learning_plans_composite');
SET @sql1 = IF(@idx1 = 0,
    'CREATE INDEX `idx_learning_plans_composite` ON `learning_plans` (`assigned_to`, `status`, `start_date`)',
    'SELECT ''idx_learning_plans_composite索引已存在'' AS message'
);
PREPARE stmt1 FROM @sql1;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

-- 为plan_items添加复合索引（如果不存在）
SET @idx2 = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
             WHERE TABLE_SCHEMA = DATABASE() 
             AND TABLE_NAME = 'plan_items' 
             AND INDEX_NAME = 'idx_plan_items_composite');
SET @sql2 = IF(@idx2 = 0,
    'CREATE INDEX `idx_plan_items_composite` ON `plan_items` (`plan_id`, `status`, `due_date`)',
    'SELECT ''idx_plan_items_composite索引已存在'' AS message'
);
PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- =====================================================
-- 第十步：验证所有表是否创建成功
-- =====================================================
SELECT '=== 表结构创建完成 ===' AS message;

SELECT 
    TABLE_NAME AS '表名',
    TABLE_ROWS AS '记录数',
    CREATE_TIME AS '创建时间'
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN (
    'learning_plans',
    'plan_items', 
    'plan_item_completions',
    'learning_paths',
    'learning_path_plans',
    'user_learning_paths'
)
ORDER BY TABLE_NAME;

-- =====================================================
-- 第十一步：检查learning_plans表的字段（确认path_id已添加）
-- =====================================================
SELECT 
    COLUMN_NAME AS '字段名',
    DATA_TYPE AS '数据类型',
    IS_NULLABLE AS '允许NULL',
    COLUMN_DEFAULT AS '默认值',
    COLUMN_COMMENT AS '注释'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'learning_plans'
ORDER BY ORDINAL_POSITION;

SELECT '=== 执行完成！===' AS message;

