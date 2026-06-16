-- 插入带有本地图片路径的课程数据
-- 使用本地图片路径，避免网络图片加载问题

-- 先清空现有数据（可选）
-- DELETE FROM train_course;

-- 插入课程数据，包含本地图片路径
INSERT INTO train_course (title, description, cover, duration, status, create_time) VALUES
('前台接待服务标准流程', '学习前台接待的标准化服务流程，包括客户接待、信息登记、问题解答等核心技能', '/static/images/course/front-desk.jpg', 120, 0, NOW()),
('前台操作标准化培训', '掌握前台接待的标准操作流程，包括入住登记、退房结算、客户服务等规范操作', '/static/images/course/front-operations.jpg', 180, 0, NOW()),
('餐饮服务礼仪与标准', '学习餐饮服务的专业礼仪和标准操作流程，包括点餐服务、上菜规范、结账流程等', '/static/images/course/restaurant-service.jpg', 150, 0, NOW()),
('OTA运营管理培训', '学习OTA平台运营管理，包括订单处理、价格管理、客户评价回复等核心技能', '/static/images/course/ota-management.jpg', 120, 0, NOW()),
('客房清洁标准流程', '学习客房清洁的标准化操作流程，包括清洁顺序、质量标准、时间控制等', '/static/images/course/housekeeping.jpg', 120, 0, NOW()),
('客户服务沟通技巧', '提升与客户沟通的专业技巧，学习如何处理客户投诉、提供优质服务体验', '/static/images/course/customer-service.jpg', 90, 0, NOW()),
('酒店管理基础', '学习酒店管理的基础知识，包括人员管理、成本控制、服务质量提升等', '/static/images/course/hotel-management.jpg', 180, 0, NOW()),
('团队协作与沟通', '提升团队协作能力，学习有效的沟通技巧和团队管理方法', '/static/images/course/teamwork.jpg', 120, 0, NOW()),
('酒店销售技巧', '学习酒店销售的专业技巧，包括客户开发、价格谈判、合同签订等', '/static/images/course/sales-skills.jpg', 150, 0, NOW()),
('应急处理与安全培训', '学习酒店应急处理流程，掌握安全防范知识和应急响应技能', '/static/images/course/emergency-safety.jpg', 90, 0, NOW());

-- 查看插入结果
SELECT course_id, title, cover, duration, status FROM train_course ORDER BY course_id;
