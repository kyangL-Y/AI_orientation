-- =====================================================
-- 付费墙和会员权限系统数据库表
-- 创建时间: 2026-01-14
-- =====================================================

-- 1. 会员等级表
DROP TABLE IF EXISTS `train_membership_level`;
CREATE TABLE `train_membership_level` (
  `level_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '等级ID',
  `level_name` varchar(50) NOT NULL COMMENT '等级名称',
  `level_code` varchar(20) NOT NULL COMMENT '等级代码(free/basic/premium/vip)',
  `level_order` int(11) NOT NULL DEFAULT 0 COMMENT '排序(数值越大等级越高)',
  `price` decimal(10,2) DEFAULT 0.00 COMMENT '价格(元/月)',
  `annual_price` decimal(10,2) DEFAULT 0.00 COMMENT '年费价格',
  `duration_days` int(11) DEFAULT 30 COMMENT '默认有效期(天)',
  `features` text COMMENT '功能权限(JSON格式)',
  `description` varchar(500) DEFAULT NULL COMMENT '等级描述',
  `icon` varchar(100) DEFAULT NULL COMMENT '等级图标',
  `color` varchar(20) DEFAULT NULL COMMENT '等级颜色',
  `status` char(1) DEFAULT '0' COMMENT '状态(0正常1停用)',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`level_id`),
  UNIQUE KEY `uk_level_code` (`level_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会员等级表';

-- 初始化会员等级数据
INSERT INTO `train_membership_level` (`level_name`, `level_code`, `level_order`, `price`, `annual_price`, `duration_days`, `features`, `description`, `icon`, `color`) VALUES
('免费版', 'free', 0, 0.00, 0.00, 0, '{"maxCourses": 5, "maxExams": 3, "aiChat": false, "downloadPdf": false, "certificate": false, "prioritySupport": false}', '基础学习功能，适合体验用户', 'fa-user', '#9CA3AF'),
('基础版', 'basic', 1, 29.00, 299.00, 30, '{"maxCourses": 50, "maxExams": 20, "aiChat": true, "downloadPdf": false, "certificate": false, "prioritySupport": false}', '解锁更多课程和AI助手', 'fa-star', '#3B82F6'),
('高级版', 'premium', 2, 59.00, 599.00, 30, '{"maxCourses": -1, "maxExams": -1, "aiChat": true, "downloadPdf": true, "certificate": true, "prioritySupport": false}', '无限课程和考试，支持证书下载', 'fa-crown', '#F59E0B'),
('VIP版', 'vip', 3, 99.00, 999.00, 30, '{"maxCourses": -1, "maxExams": -1, "aiChat": true, "downloadPdf": true, "certificate": true, "prioritySupport": true}', '全部功能，专属客服支持', 'fa-gem', '#8B5CF6');

-- 2. 用户会员表
DROP TABLE IF EXISTS `train_user_membership`;
CREATE TABLE `train_user_membership` (
  `membership_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '会员记录ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `level_id` bigint(20) NOT NULL COMMENT '等级ID',
  `level_code` varchar(20) NOT NULL COMMENT '等级代码',
  `start_time` datetime NOT NULL COMMENT '开始时间',
  `end_time` datetime NOT NULL COMMENT '结束时间',
  `is_active` char(1) DEFAULT '1' COMMENT '是否激活(0否1是)',
  `is_auto_renew` char(1) DEFAULT '0' COMMENT '是否自动续费(0否1是)',
  `payment_id` varchar(64) DEFAULT NULL COMMENT '支付订单号',
  `source` varchar(20) DEFAULT 'purchase' COMMENT '来源(purchase购买/gift赠送/trial试用)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`membership_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_level_id` (`level_id`),
  KEY `idx_end_time` (`end_time`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户会员表';

-- 3. 付费内容表
DROP TABLE IF EXISTS `train_paid_content`;
CREATE TABLE `train_paid_content` (
  `content_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '内容ID',
  `content_type` varchar(20) NOT NULL COMMENT '内容类型(course/exam/path/article)',
  `content_ref_id` bigint(20) NOT NULL COMMENT '内容关联ID',
  `content_name` varchar(200) DEFAULT NULL COMMENT '内容名称',
  `required_level` varchar(20) NOT NULL DEFAULT 'basic' COMMENT '所需最低等级',
  `price` decimal(10,2) DEFAULT NULL COMMENT '单独购买价格',
  `points_required` int(11) DEFAULT NULL COMMENT '所需积分(可用积分兑换)',
  `is_free_trial` char(1) DEFAULT '0' COMMENT '是否支持免费试用(0否1是)',
  `trial_duration` int(11) DEFAULT 0 COMMENT '试用时长(分钟)',
  `status` char(1) DEFAULT '0' COMMENT '状态(0正常1停用)',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`content_id`),
  UNIQUE KEY `uk_content` (`content_type`, `content_ref_id`),
  KEY `idx_required_level` (`required_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='付费内容表';

-- 4. 用户购买记录表
DROP TABLE IF EXISTS `train_user_purchase`;
CREATE TABLE `train_user_purchase` (
  `purchase_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '购买记录ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `order_no` varchar(64) NOT NULL COMMENT '订单号',
  `purchase_type` varchar(20) NOT NULL COMMENT '购买类型(membership会员/single单品)',
  `content_type` varchar(20) DEFAULT NULL COMMENT '内容类型',
  `content_ref_id` bigint(20) DEFAULT NULL COMMENT '内容关联ID',
  `level_code` varchar(20) DEFAULT NULL COMMENT '会员等级代码(会员购买时)',
  `duration_days` int(11) DEFAULT NULL COMMENT '购买时长(天)',
  `original_amount` decimal(10,2) NOT NULL COMMENT '原价',
  `discount_amount` decimal(10,2) DEFAULT 0.00 COMMENT '优惠金额',
  `actual_amount` decimal(10,2) NOT NULL COMMENT '实付金额',
  `points_used` int(11) DEFAULT 0 COMMENT '使用积分',
  `coupon_id` bigint(20) DEFAULT NULL COMMENT '优惠券ID',
  `payment_method` varchar(20) DEFAULT NULL COMMENT '支付方式(wechat/alipay/points)',
  `payment_status` varchar(20) DEFAULT 'pending' COMMENT '支付状态(pending/paid/failed/refunded)',
  `payment_time` datetime DEFAULT NULL COMMENT '支付时间',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`purchase_id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_payment_status` (`payment_status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户购买记录表';

-- 5. 用户内容访问权限表（单品购买后的访问权限）
DROP TABLE IF EXISTS `train_user_content_access`;
CREATE TABLE `train_user_content_access` (
  `access_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '访问权限ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `content_type` varchar(20) NOT NULL COMMENT '内容类型',
  `content_ref_id` bigint(20) NOT NULL COMMENT '内容关联ID',
  `purchase_id` bigint(20) DEFAULT NULL COMMENT '购买记录ID',
  `start_time` datetime NOT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间(NULL表示永久)',
  `is_active` char(1) DEFAULT '1' COMMENT '是否激活',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`access_id`),
  UNIQUE KEY `uk_user_content` (`user_id`, `content_type`, `content_ref_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_end_time` (`end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户内容访问权限表';

-- 6. 添加菜单
INSERT INTO `sys_menu` (`menu_name`, `parent_id`, `order_num`, `path`, `component`, `query`, `route_name`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`)
VALUES 
('会员管理', 0, 10, 'membership', NULL, NULL, NULL, 1, 0, 'M', '0', '0', '', 'peoples', 'admin', NOW(), '', NULL, '会员管理目录'),
('会员等级', (SELECT menu_id FROM (SELECT menu_id FROM sys_menu WHERE menu_name = '会员管理' LIMIT 1) AS t), 1, 'level', 'train/membership/level/index', NULL, NULL, 1, 0, 'C', '0', '0', 'train:membership:level:list', 'star', 'admin', NOW(), '', NULL, '会员等级菜单'),
('用户会员', (SELECT menu_id FROM (SELECT menu_id FROM sys_menu WHERE menu_name = '会员管理' LIMIT 1) AS t), 2, 'user', 'train/membership/user/index', NULL, NULL, 1, 0, 'C', '0', '0', 'train:membership:user:list', 'user', 'admin', NOW(), '', NULL, '用户会员菜单'),
('付费内容', (SELECT menu_id FROM (SELECT menu_id FROM sys_menu WHERE menu_name = '会员管理' LIMIT 1) AS t), 3, 'content', 'train/membership/content/index', NULL, NULL, 1, 0, 'C', '0', '0', 'train:membership:content:list', 'documentation', 'admin', NOW(), '', NULL, '付费内容菜单'),
('购买记录', (SELECT menu_id FROM (SELECT menu_id FROM sys_menu WHERE menu_name = '会员管理' LIMIT 1) AS t), 4, 'purchase', 'train/membership/purchase/index', NULL, NULL, 1, 0, 'C', '0', '0', 'train:membership:purchase:list', 'money', 'admin', NOW(), '', NULL, '购买记录菜单');

-- 查看创建的表
SELECT TABLE_NAME, TABLE_COMMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME LIKE 'train_%membership%' OR TABLE_NAME LIKE 'train_%paid%' OR TABLE_NAME LIKE 'train_%purchase%' OR TABLE_NAME LIKE 'train_%access%';
