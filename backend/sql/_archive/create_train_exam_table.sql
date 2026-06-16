-- 创建培训考试表
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

-- 插入一些测试数据
INSERT INTO `train_exam` (`name`, `status`, `start_time`, `end_time`, `create_by`, `remark`) VALUES
('酒店服务综合考试', 'published', '2025-09-20 09:00:00', '2025-09-20 11:00:00', 'admin', '用于评估员工的服务技能水平'),
('前台操作技能考试', 'draft', '2025-09-25 14:00:00', '2025-09-25 16:00:00', 'admin', '测试前台员工的操作技能'),
('客房服务标准考试', 'draft', '2025-10-01 10:00:00', '2025-10-01 12:00:00', 'admin', '客房服务标准化培训考试');


