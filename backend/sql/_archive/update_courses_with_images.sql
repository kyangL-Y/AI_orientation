-- 更新现有课程数据，添加封面图片
-- 为已有的课程添加封面图片URL

UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=300&h=200&fit=crop' WHERE title LIKE '%前台接待%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=300&h=200&fit=crop' WHERE title LIKE '%前台操作%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=300&h=200&fit=crop' WHERE title LIKE '%餐饮服务%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=300&h=200&fit=crop' WHERE title LIKE '%OTA运营%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=300&h=200&fit=crop' WHERE title LIKE '%客房清洁%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=300&h=200&fit=crop' WHERE title LIKE '%客户服务%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=300&h=200&fit=crop' WHERE title LIKE '%酒店管理%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=300&h=200&fit=crop' WHERE title LIKE '%团队协作%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1551434678-e076c223a692?w=300&h=200&fit=crop' WHERE title LIKE '%酒店销售%';
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1581578731548-c6a0c3f2fcc8?w=300&h=200&fit=crop' WHERE title LIKE '%应急处理%';

-- 为没有匹配到的课程设置默认图片
UPDATE train_course SET cover = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=200&fit=crop' WHERE cover IS NULL OR cover = '';

-- 查看更新结果
SELECT course_id, title, cover, duration, status FROM train_course ORDER BY course_id;
