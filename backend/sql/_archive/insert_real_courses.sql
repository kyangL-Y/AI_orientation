-- 插入真实的课程数据
INSERT INTO train_course (title, description, cover_image_url, duration, status, create_by, create_time, remark) VALUES
-- 前台相关课程
('前台接待服务标准流程', '学习前台接待的标准化服务流程，包括客户接待、信息登记、问题解答等核心技能，提升服务质量。', 'https://example.com/front-desk-service.jpg', 120, '0', 'admin', NOW(), '前台基础培训课程'),
('前台操作标准化培训', '掌握前台接待的标准操作流程，包括入住登记、退房结算、客户服务等规范操作。', 'https://example.com/front-desk-operations.jpg', 180, '0', 'admin', NOW(), '前台操作规范培训'),
('客户服务沟通技巧', '提升与客户沟通的专业技巧，学习如何处理客户投诉、提供优质服务体验。', 'https://example.com/customer-service.jpg', 90, '0', 'admin', NOW(), '客户服务技能提升'),

-- 餐饮相关课程
('餐饮服务礼仪与标准', '学习餐饮服务的专业礼仪和标准操作流程，包括点餐服务、上菜规范、结账流程等。', 'https://example.com/dining-service.jpg', 150, '0', 'admin', NOW(), '餐饮服务培训'),
('食品安全与卫生管理', '掌握食品安全知识，学习食品储存、加工、服务过程中的卫生管理要求。', 'https://example.com/food-safety.jpg', 120, '0', 'admin', NOW(), '食品安全培训'),
('酒水知识与服务', '学习各类酒水知识，掌握酒水服务技巧和推荐话术，提升餐饮服务质量。', 'https://example.com/beverage-service.jpg', 100, '0', 'admin', NOW(), '酒水服务培训'),

-- 客房相关课程
('客房清洁标准流程', '学习客房清洁的标准化操作流程，包括清洁顺序、质量标准、时间控制等。', 'https://example.com/room-cleaning.jpg', 120, '0', 'admin', NOW(), '客房清洁培训'),
('客房服务技能培训', '掌握客房服务的专业技能，包括客房整理、物品补充、客户需求响应等。', 'https://example.com/room-service.jpg', 90, '0', 'admin', NOW(), '客房服务培训'),
('客房设备维护保养', '学习客房设备的日常维护和保养知识，确保设备正常运行。', 'https://example.com/room-maintenance.jpg', 60, '0', 'admin', NOW(), '设备维护培训'),

-- OTA运营相关课程
('OTA运营管理培训', '学习OTA平台运营管理，包括订单处理、价格管理、客户评价回复等核心技能。', 'https://example.com/ota-management.jpg', 120, '0', 'admin', NOW(), 'OTA运营培训'),
('在线营销策略', '掌握酒店在线营销策略，学习如何提升酒店在OTA平台的排名和销量。', 'https://example.com/online-marketing.jpg', 150, '0', 'admin', NOW(), '在线营销培训'),
('客户评价管理', '学习如何有效管理客户评价，提升酒店在线声誉和客户满意度。', 'https://example.com/review-management.jpg', 90, '0', 'admin', NOW(), '评价管理培训'),

-- 管理相关课程
('酒店管理基础', '学习酒店管理的基础知识，包括人员管理、成本控制、服务质量提升等。', 'https://example.com/hotel-management.jpg', 180, '0', 'admin', NOW(), '管理基础培训'),
('团队协作与沟通', '提升团队协作能力，学习有效的沟通技巧和团队管理方法。', 'https://example.com/team-collaboration.jpg', 120, '0', 'admin', NOW(), '团队协作培训'),
('应急处理与安全培训', '学习酒店应急处理流程，掌握安全防范知识和应急响应技能。', 'https://example.com/emergency-safety.jpg', 90, '0', 'admin', NOW(), '安全应急培训'),

-- 销售相关课程
('酒店销售技巧', '学习酒店销售的专业技巧，包括客户开发、价格谈判、合同签订等。', 'https://example.com/hotel-sales.jpg', 150, '0', 'admin', NOW(), '销售技能培训'),
('会议服务销售', '掌握会议服务的销售技巧，学习如何开发企业客户和会议市场。', 'https://example.com/meeting-sales.jpg', 120, '0', 'admin', NOW(), '会议销售培训'),
('客户关系维护', '学习如何维护客户关系，提升客户忠诚度和复购率。', 'https://example.com/customer-relationship.jpg', 100, '0', 'admin', NOW(), '客户关系培训'),

-- 财务相关课程
('酒店财务管理基础', '学习酒店财务管理的基础知识，包括成本核算、预算管理、财务分析等。', 'https://example.com/hotel-finance.jpg', 180, '0', 'admin', NOW(), '财务管理培训'),
('收银操作规范', '掌握收银操作的标准流程，学习现金管理、刷卡操作、账务核对等。', 'https://example.com/cashier-operations.jpg', 90, '0', 'admin', NOW(), '收银操作培训'),
('成本控制与优化', '学习酒店成本控制方法，掌握成本分析和优化策略。', 'https://example.com/cost-control.jpg', 120, '0', 'admin', NOW(), '成本控制培训'),

-- 技术相关课程
('酒店管理系统操作', '学习酒店管理系统的操作技能，包括预订管理、房态管理、客户信息管理等。', 'https://example.com/hotel-system.jpg', 120, '0', 'admin', NOW(), '系统操作培训'),
('网络营销工具使用', '掌握各种网络营销工具的使用方法，提升酒店在线营销效果。', 'https://example.com/digital-marketing.jpg', 100, '0', 'admin', NOW(), '网络营销培训'),
('数据分析与报表', '学习酒店数据分析方法，掌握各类报表的制作和分析技能。', 'https://example.com/data-analysis.jpg', 90, '0', 'admin', NOW(), '数据分析培训');
