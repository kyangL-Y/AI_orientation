-- 插入示例课程数据（包含封面照片）
-- 用于测试课程管理功能

-- 清空现有数据（可选）
-- DELETE FROM train_course;

-- 插入示例课程数据
INSERT INTO train_course (title, description, cover, duration, status, sort_order, create_time, update_time) VALUES
('前台接待服务标准流程', 
 '学习酒店前台接待的标准操作流程，包括客人入住登记、信息查询、退房结算等服务规范。掌握专业的客户服务技巧，提升酒店形象和客户满意度。',
 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=200&fit=crop&crop=center',
 180, 1, 1, NOW(), NOW()),

('客房清洁与布置标准', 
 '掌握酒店客房的清洁标准、布草更换规范和客房物品摆放要求，提升客房服务质量。学习高效的清洁流程和品质控制方法。',
 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=400&h=200&fit=crop&crop=center',
 240, 1, 2, NOW(), NOW()),

('餐饮服务礼仪与标准', 
 '学习酒店餐饮服务的基本礼仪，包括餐桌布置、点餐服务、酒水服务和顾客需求处理。培养专业的餐饮服务意识和技能。',
 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=200&fit=crop&crop=center',
 210, 1, 3, NOW(), NOW()),

('客户投诉处理与应对', 
 '掌握处理客户投诉的技巧和方法，学习如何有效解决客户问题，提升客户满意度。培养危机处理和客户关系维护能力。',
 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&h=200&fit=crop&crop=center',
 150, 1, 4, NOW(), NOW()),

('酒店安全与应急处理', 
 '学习酒店安全管理知识和各类突发事件的应急处理流程，保障客人和员工安全。掌握消防安全、紧急疏散等关键技能。',
 'https://images.unsplash.com/photo-1581578731548-c6a0c3f2fcc8?w=400&h=200&fit=crop&crop=center',
 180, 1, 5, NOW(), NOW()),

('酒店营销与客户关系管理', 
 '了解酒店营销的基本策略和客户关系管理方法，提升客户忠诚度和复购率。学习数字化营销和客户数据分析技巧。',
 'https://images.unsplash.com/photo-1551434678-e076c223a692?w=400&h=200&fit=crop&crop=center',
 240, 1, 6, NOW(), NOW()),

('高级客户服务技巧', 
 '深入学习高端客户服务的专业技巧，提升VIP客户的服务体验和满意度。掌握个性化服务和客户关系维护的高级方法。',
 'https://images.unsplash.com/photo-1556742111-a301076d9d18?w=400&h=200&fit=crop&crop=center',
 180, 1, 7, NOW(), NOW()),

('酒店数字化管理系统操作', 
 '掌握酒店常用数字化管理系统的操作方法，提高工作效率和管理水平。学习PMS系统、CRM系统等核心工具的使用。',
 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&h=200&fit=crop&crop=center',
 300, 1, 8, NOW(), NOW()),

('OTA平台运营管理', 
 '学习在线旅游代理平台（OTA）的运营管理，包括订单处理、价格策略、客户评价管理等核心业务技能。',
 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&h=200&fit=crop&crop=center',
 120, 1, 9, NOW(), NOW()),

('团队协作与沟通技巧', 
 '提升团队协作能力和沟通技巧，学习有效的团队管理方法和跨部门协作技能，营造良好的工作氛围。',
 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400&h=200&fit=crop&crop=center',
 120, 1, 10, NOW(), NOW());

-- 查询插入结果
SELECT course_id, title, cover, duration, status, create_time 
FROM train_course 
ORDER BY sort_order;
