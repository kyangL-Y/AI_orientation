-- 页面访问记录表（记录用户在系统各页面的停留时长）
-- 设计要点：
-- 1) 用户每次进入页面后产生一条记录，通过前端计时上传
-- 2) 通过 duration 记录停留时长（秒）
-- 3) 通过 page_name 记录页面类型，方便统计不同功能的使用情况
-- 4) 通过 visit_date 字段便于按日统计

CREATE TABLE IF NOT EXISTS `train_page_visit` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `page_name` varchar(100) NOT NULL COMMENT '页面名称',
  `visit_time` datetime NOT NULL COMMENT '访问时间（开始时刻）',
  `visit_date` date GENERATED ALWAYS AS (DATE(visit_time)) STORED COMMENT '访问日期',
  `duration` int(11) NOT NULL DEFAULT 0 COMMENT '停留时长（秒）',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_page_name` (`page_name`),
  KEY `idx_visit_date` (`visit_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='页面访问记录表';
