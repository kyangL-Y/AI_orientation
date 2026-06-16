-- =====================================================
-- 建立积分系统脚本
-- =====================================================
-- 数据库: hotel_training
-- =====================================================

USE hotel_training;

-- 1. 创建用户积分表
CREATE TABLE IF NOT EXISTS `train_user_points` (
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `total_points` int(11) NOT NULL DEFAULT '0' COMMENT '总积分',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户积分表';

-- 2. 创建用户积分日志表
CREATE TABLE IF NOT EXISTS `train_user_points_log` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `points_change` int(11) NOT NULL COMMENT '积分变动',
  `reason` varchar(255) DEFAULT NULL COMMENT '变动原因',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`log_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户积分日志表';

-- 3. 初始化积分（基于历史答题记录）
-- 规则：每个正确答案 10 分
INSERT INTO `train_user_points` (`user_id`, `total_points`, `create_time`, `update_time`)
SELECT 
    user_id, 
    SUM(CASE WHEN is_correct = 1 THEN 10 ELSE 0 END) as total_points,
    NOW(),
    NOW()
FROM `train_answer_attempt`
GROUP BY user_id
ON DUPLICATE KEY UPDATE total_points = VALUES(total_points);

-- 4. 初始化日志（记录初始迁移）
INSERT INTO `train_user_points_log` (`user_id`, `points_change`, `reason`, `create_time`)
SELECT 
    user_id, 
    SUM(CASE WHEN is_correct = 1 THEN 10 ELSE 0 END) as points_change,
    '系统初始化：基于历史答题记录迁移积分',
    NOW()
FROM `train_answer_attempt`
GROUP BY user_id
HAVING points_change > 0;

SELECT '积分系统建立完成！' as message;
