-- 课程批量导入示例数据
-- 可以使用这些数据作为Excel模板的参考

-- Excel模板列结构：
-- 主标题 | 分类 | 具体分类 | 课程名称 | 知识点 | 课程封面 | 学习层级 | 排序
-- 学习层级可选值：basic(基础)、advance(进阶)、expert(高级)，默认为basic

-- 示例数据：
/*
基础运营	加入携程	关于携程	1.1.1携程集团（Trip.com Group）全面知识总结	携程集团简介、业务模式、发展历程		1
基础运营	加入携程	加盟须知	1.2.1 服务缺陷操作手册	服务标准、缺陷处理流程		2
基础运营	新手开店	基础操作	2.1.1 EBK后台安装指南	EBK安装步骤、账号管理		3
基础运营	日常操作	订单处理	3.1.1 EBK订单功能介绍	订单列表、订单详情、联系客人		4
基础运营	日常操作	房态房价	3.2.1 儿童政策、加床政策介绍	亲子流量、转化率提升		5
*/

-- 批量插入示例（根据Excel数据生成）
INSERT INTO hotel_training.course_category 
(main_title, main_s, specific_category, third_level_c, knowledge_points, cover_image, level, sort_order) 
VALUES
('基础运营', '加入携程', '关于携程', '1.1.1携程集团（Trip.com Group）全面知识总结', '携程集团简介、业务模式、发展历程', NULL, 'basic', 1),
('基础运营', '加入携程', '加盟须知', '1.2.1 服务缺陷操作手册', '服务标准、缺陷处理流程', NULL, 'basic', 2),
('基础运营', '新手开店', '基础操作', '2.1.1 EBK后台安装指南', 'EBK安装步骤、账号管理', NULL, 'basic', 3),
('线上营销', '促销活动', '常规促销', '高级促销策略', '促销活动策划、执行技巧', NULL, 'advance', 10),
('门店运营', '服务设计', '服务提高', '专家级服务管理', '高级服务管理、客户体验优化', NULL, 'expert', 20)
ON DUPLICATE KEY UPDATE
    main_title = VALUES(main_title),
    main_s = VALUES(main_s),
    specific_category = VALUES(specific_category),
    third_level_c = VALUES(third_level_c),
    knowledge_points = VALUES(knowledge_points),
    cover_image = VALUES(cover_image),
    level = VALUES(level),
    sort_order = VALUES(sort_order);

-- 说明：
-- 1. Excel模板应包含以上8列：主标题、分类、具体分类、课程名称、知识点、课程封面、学习层级、排序
-- 2. 课程名称（third_level_c）是必填字段
-- 3. 课程封面（cover_image）可以为空
-- 4. 学习层级（level）可选值：basic(基础)、advance(进阶)、expert(高级)，默认为basic
-- 5. 排序（sort_order）默认为0
-- 6. 导入时会自动设置创建时间和更新时间

