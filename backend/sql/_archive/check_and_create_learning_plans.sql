-- =====================================================
-- 检查并创建learning_plans表(带path_id字段)
-- =====================================================

USE hotel_training;

-- =====================================================
-- 第一步: 检查表是否存在
-- =====================================================
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ learning_plans表已存在'
        ELSE '❌ learning_plans表不存在，需要创建'
    END AS 检查结果,
    COUNT(*) AS 表数量
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'hotel_training' 
AND TABLE_NAME = 'learning_plans';

-- =====================================================
-- 第二步: 如果表不存在,创建表(包含path_id字段)
-- =====================================================

-- 学习计划主表
CREATE TABLE IF NOT EXISTS `learning_plans` (
  `plan_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '计划ID',
  `path_id` bigint(20) DEFAULT NULL COMMENT '所属学习路径ID',
  `title` varchar(100) NOT NULL COMMENT '计划标题',
  `description` text COMMENT '计划描述',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `assigned_to` bigint(20) DEFAULT NULL COMMENT '分配给用户ID',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT '计划状态',
  `start_date` date NOT NULL COMMENT '开始日期',
  `end_date` date NOT NULL COMMENT '结束日期',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`plan_id`),
  KEY `idx_path_id` (`path_id`),
  KEY `idx_assigned_to` (`assigned_to`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习计划主表';

-- 计划任务项表
CREATE TABLE IF NOT EXISTS `plan_items` (
  `item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '任务项ID',
  `plan_id` bigint(20) NOT NULL COMMENT '计划ID',
  `content_type` varchar(20) NOT NULL COMMENT '内容类型',
  `content_id` bigint(20) DEFAULT NULL COMMENT '内容ID',
  `title` varchar(100) NOT NULL COMMENT '任务标题',
  `due_date` date DEFAULT NULL COMMENT '截止日期',
  `status` varchar(20) DEFAULT 'pending' COMMENT '任务状态',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序号',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`item_id`),
  KEY `idx_plan_id` (`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='计划任务项表';

-- 任务完成记录表
CREATE TABLE IF NOT EXISTS `plan_item_completions` (
  `completion_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '完成记录ID',
  `item_id` bigint(20) NOT NULL COMMENT '任务项ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `completed_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '完成时间',
  `score` decimal(5,2) DEFAULT NULL COMMENT '得分',
  `feedback` text COMMENT '反馈信息',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`completion_id`),
  UNIQUE KEY `uk_item_user` (`item_id`, `user_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务完成记录表';

-- =====================================================
-- 第三步: 如果表已存在但没有path_id字段,添加它
-- =====================================================
-- 注意: 如果报错"Duplicate column name"说明字段已存在,可忽略
ALTER TABLE `learning_plans` 
ADD COLUMN `path_id` bigint(20) DEFAULT NULL COMMENT '所属学习路径ID' AFTER `plan_id`;

-- 添加索引
ALTER TABLE `learning_plans` 
ADD INDEX `idx_path_id` (`path_id`);

-- =====================================================
-- 执行完成
-- =====================================================
SELECT '✅ learning_plans表及相关表已就绪!' AS 执行结果;
SELECT COUNT(*) AS 学习计划表数量 FROM learning_plans;

