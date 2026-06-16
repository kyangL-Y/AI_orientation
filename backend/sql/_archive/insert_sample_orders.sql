USE `hz-vue`;

-- 插入示例兑换记录 (Assuming user_id=1 is Admin or a valid user)
-- 如果不知道具体ID，可以使用子查询或者假设几个常见ID
-- 这里假设 user_id = 1 (Admin) 和 user_id = 100 (Common User if exists)

INSERT INTO train_shop_order (user_id, item_id, item_name, points_spent, status, create_time)
VALUES 
(1, 1, '精美笔记本', 500, '1', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(1, 3, '星巴克中杯券', 800, '1', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(1, 2, '定制保温杯', 1200, '1', DATE_SUB(NOW(), INTERVAL 10 DAY));

-- 也可以给其他用户加一点，如果存在的话
-- INSERT INTO train_shop_order (user_id, item_id, item_name, points_spent, status, create_time)
-- SELECT user_id, 4, '无线静音鼠标', 1500, '0', NOW() FROM sys_user WHERE user_id > 1 LIMIT 1;
