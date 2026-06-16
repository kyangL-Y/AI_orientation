-- =====================================================
-- 建立积分商城系统脚本
-- =====================================================
-- 数据库: hotel_training
-- =====================================================

USE hotel_training;

-- 1. 创建商品表
CREATE TABLE IF NOT EXISTS `train_shop_item` (
  `item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '商品ID',
  `item_name` varchar(100) NOT NULL COMMENT '商品名称',
  `description` varchar(500) DEFAULT NULL COMMENT '商品描述',
  `cover_img` varchar(255) DEFAULT NULL COMMENT '封面图片',
  `points_required` int(11) NOT NULL DEFAULT '0' COMMENT '所需积分',
  `stock_quantity` int(11) NOT NULL DEFAULT '0' COMMENT '库存数量',
  `status` char(1) DEFAULT '1' COMMENT '状态（1正常 0停用）',
  `sort_order` int(4) DEFAULT '0' COMMENT '排序号',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='积分商城商品表';

-- 2. 创建订单表
CREATE TABLE IF NOT EXISTS `train_shop_order` (
  `order_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `item_id` bigint(20) NOT NULL COMMENT '商品ID',
  `item_name` varchar(100) NOT NULL COMMENT '商品名称快照',
  `points_spent` int(11) NOT NULL COMMENT '花费积分',
  `status` char(1) DEFAULT '1' COMMENT '状态（1已完成 0待处理）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '兑换时间',
  PRIMARY KEY (`order_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='积分商城兑换记录表';

-- 3. 初始化一些示例商品
INSERT INTO `train_shop_item` (`item_name`, `description`, `cover_img`, `points_required`, `stock_quantity`, `status`, `sort_order`, `create_time`) VALUES
('星巴克咖啡券', '凭此券可兑换任意中杯饮品一杯', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500&q=80', 500, 100, '1', 1, NOW()),
('京东E卡 50元', '京东商城全场通用', 'https://images.unsplash.com/photo-1628527304948-06157ee3c8a6?w=500&q=80', 1000, 50, '1', 2, NOW()),
('豪华午睡枕', '办公室午休神器，记忆棉材质', 'https://images.unsplash.com/photo-1584143990664-92e3532f7a07?w=500&q=80', 800, 30, '1', 3, NOW()),
('带薪休假券 (1小时)', '凭此券可提前1小时下班 (需主管批准)', 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=500&q=80', 2000, 10, '1', 4, NOW()),
('团队下午茶基金', '为团队赢取一次下午茶机会', 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=500&q=80', 5000, 5, '1', 5, NOW()),
('荣誉证书：学习标兵', '获得精美实体证书与奖杯', 'https://images.unsplash.com/photo-1579548122080-c35fd6820ecb?w=500&q=80', 300, 999, '1', 6, NOW());

SELECT '积分商城系统建立完成！' as message;
