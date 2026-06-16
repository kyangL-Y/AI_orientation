USE `hz-vue`;

-- 1. 初始化积分商城商品数据
INSERT INTO train_shop_item (item_name, description, cover_img, points_required, stock_quantity, status, sort_order, create_time, create_by)
VALUES 
('精美笔记本', '华智定制商务笔记本，书写流畅，皮质封面', 'https://img14.360buyimg.com/n0/jfs/t1/186067/26/2693/144203/60b05e5dE65893774/8a94665420137578.jpg', 500, 100, '1', 1, NOW(), 'admin'),
('定制保温杯', '316不锈钢，24小时长效保温，智能显温', 'https://img14.360buyimg.com/n0/jfs/t1/157677/22/36733/83002/64a6829cF0298813f/8627883250106967.jpg', 1200, 50, '1', 2, NOW(), 'admin'),
('星巴克中杯券', '电子兑换券，全国通用，即时到账', 'https://img14.360buyimg.com/n0/jfs/t1/204273/19/22967/141026/6262438cE63604324/5045474320242226.jpg', 800, 200, '1', 3, NOW(), 'admin'),
('无线静音鼠标', '人体工学设计，超长续航，办公专用', 'https://img14.360buyimg.com/n0/jfs/t1/94830/30/43460/64413/6544621fF55306368/5645557766255006.jpg', 1500, 30, '1', 4, NOW(), 'admin'),
('午睡记忆枕', '办公室午休神器，慢回弹记忆棉，舒适透气', 'https://img14.360buyimg.com/n0/jfs/t1/192666/12/34265/157209/643f5509F50444646/2422002244222044.jpg', 600, 50, '1', 5, NOW(), 'admin');

-- 2. 同步用户积分（基于答题记录）
-- 逻辑：统计每个用户的答题得分（每题10分），更新或插入到 train_user_points 表
INSERT INTO train_user_points (user_id, total_points, create_time, update_time)
SELECT 
    user_id, 
    SUM(CASE WHEN is_correct = 1 THEN 10 ELSE 0 END) as total_points,
    NOW(),
    NOW()
FROM hotel_training.train_answer_attempt
GROUP BY user_id
ON DUPLICATE KEY UPDATE 
    total_points = VALUES(total_points),
    update_time = NOW();

-- 3. 记录初始积分日志（可选，用于核对）
INSERT INTO train_user_points_log (user_id, points_change, reason, create_time)
SELECT 
    user_id,
    SUM(CASE WHEN is_correct = 1 THEN 10 ELSE 0 END),
    '系统初始化：同步历史答题积分',
    NOW()
FROM hotel_training.train_answer_attempt
GROUP BY user_id;
