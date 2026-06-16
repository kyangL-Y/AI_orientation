-- 插入带有实际图片URL的课程数据
-- 使用一些通用的课程相关图片URL

-- 先清空现有数据（可选）
-- DELETE FROM train_course;

-- 插入课程数据，包含封面图片URL
INSERT INTO train_course (title, description, cover, duration, status, create_time) VALUES
('前台接待服务标准流程', '学习前台接待的标准化服务流程，包括客户接待、信息登记、问题解答等核心技能', 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=300&h=200&fit=crop', 120, 0, NOW()),
('前台操作标准化培训', '掌握前台接待的标准操作流程，包括入住登记、退房结算、客户服务等规范操作', 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=300&h=200&fit=crop', 180, 0, NOW()),
('餐饮服务礼仪与标准', '学习餐饮服务的专业礼仪和标准操作流程，包括点餐服务、上菜规范、结账流程等', 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=300&h=200&fit=crop', 150, 0, NOW()),
('OTA运营管理培训', '学习OTA平台运营管理，包括订单处理、价格管理、客户评价回复等核心技能', 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=300&h=200&fit=crop', 120, 0, NOW()),
('客房清洁标准流程', '学习客房清洁的标准化操作流程，包括清洁顺序、质量标准、时间控制等', 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=300&h=200&fit=crop', 120, 0, NOW()),
('客户服务沟通技巧', '提升与客户沟通的专业技巧，学习如何处理客户投诉、提供优质服务体验', 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=300&h=200&fit=crop', 90, 0, NOW()),
('酒店管理基础', '学习酒店管理的基础知识，包括人员管理、成本控制、服务质量提升等', 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=300&h=200&fit=crop', 180, 0, NOW()),
('团队协作与沟通', '提升团队协作能力，学习有效的沟通技巧和团队管理方法', 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=300&h=200&fit=crop', 120, 0, NOW()),
('酒店销售技巧', '学习酒店销售的专业技巧，包括客户开发、价格谈判、合同签订等', 'https://images.unsplash.com/photo-1551434678-e076c223a692?w=300&h=200&fit=crop', 150, 0, NOW()),
('应急处理与安全培训', '学习酒店应急处理流程，掌握安全防范知识和应急响应技能', 'https://images.unsplash.com/photo-1581578731548-c6a0c3f2fcc8?w=300&h=200&fit=crop', 90, 0, NOW());

-- 查看插入结果
SELECT course_id, title, cover, duration, status FROM train_course ORDER BY course_id;
