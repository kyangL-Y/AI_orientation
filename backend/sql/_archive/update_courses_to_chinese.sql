-- 将英文课程名称更新为中文
-- 根据您现有的8个课程进行匹配更新

-- 查看现有课程
SELECT course_id, title FROM train_course ORDER BY course_id;

-- 更新为中文名称和描述（根据实际course_id调整）
UPDATE train_course SET 
  title = '前台接待服务培训',
  description = '学习标准的前台接待服务流程，掌握专业的客户服务技能'
WHERE title = 'Front Desk Service Training';

UPDATE train_course SET 
  title = '餐饮服务培训',
  description = '学习专业的餐饮服务礼仪和操作流程，提升服务质量'
WHERE title = 'Dining Service Training';

UPDATE train_course SET 
  title = 'OTA运营管理培训',
  description = '学习OTA平台运营管理，掌握订单处理和客户评价管理技能'
WHERE title = 'OTA Management Training';

UPDATE train_course SET 
  title = '客房服务培训',
  description = '掌握客房服务流程和标准，提升客房清洁与服务质量'
WHERE title = 'Room Service Training';

UPDATE train_course SET 
  title = '客户服务技巧',
  description = '提升客户沟通和服务技巧，学习如何处理客户投诉和需求'
WHERE title = 'Customer Service Skills';

UPDATE train_course SET 
  title = '酒店管理基础',
  description = '学习酒店管理的基础知识，包括运营管理和团队协作'
WHERE title = 'Hotel Management Basics';

UPDATE train_course SET 
  title = '团队协作培训',
  description = '提升团队协作能力和沟通技巧，打造高效团队'
WHERE title = 'Team Collaboration Training';

UPDATE train_course SET 
  title = '销售技巧培训',
  description = '学习酒店销售技巧，掌握客户开发和商务谈判能力'
WHERE title = 'Sales Skills Training';

-- 查看更新后的结果
SELECT course_id, title, description FROM train_course ORDER BY course_id;

