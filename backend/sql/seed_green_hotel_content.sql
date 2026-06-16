-- 绿色饭店模块种子数据（课程 + 知识文章）
-- 说明：
-- 1) 幂等脚本，可重复执行
-- 2) 知识文章状态为 published，发布范围为 platform，前台“绿色饭店”模块可直接检索到

SET NAMES utf8mb4;

-- ----------------------------
-- A. 绿色饭店课程补充数据
-- ----------------------------

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`, `remark`)
SELECT
  '绿色饭店培训', '绿色运营基础', '标准认知', '绿色饭店基础认知与评定标准详解', NULL, 'basic',
  '绿色饭店政策背景、评定维度、实施路径', 1010, 1, '000000', 'admin', '绿色饭店种子课程'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '绿色饭店基础认知与评定标准详解'
);

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`, `remark`)
SELECT
  '绿色饭店培训', '低碳运营实践', '客房管理', '客房节能降耗与布草循环管理', NULL, 'advance',
  '客房水电管理、布草洗涤频率、耗材替代方案', 1011, 1, '000000', 'admin', '绿色饭店种子课程'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '客房节能降耗与布草循环管理'
);

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`, `remark`)
SELECT
  '绿色饭店培训', '绿色供应链', '采购管理', '绿色采购准入与供应商协同实务', NULL, 'advance',
  '环保认证标准、供应商评估、采购追溯机制', 1012, 1, '000000', 'admin', '绿色饭店种子课程'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '绿色采购准入与供应商协同实务'
);

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`, `remark`)
SELECT
  '绿色饭店培训', '餐饮减废', '餐饮管理', '餐饮节能与厨余减废管理', NULL, 'expert',
  '厨房设备节能、食材损耗控制、厨余分类和资源化', 1013, 1, '000000', 'admin', '绿色饭店种子课程'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '餐饮节能与厨余减废管理'
);

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`, `remark`)
SELECT
  '绿色饭店培训', '环保运营', '垃圾分类', '垃圾分类与循环利用落地实操', NULL, 'basic',
  '分类标准、回收流程、前后台协同执行机制', 1014, 1, '000000', 'admin', '绿色饭店种子课程'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '垃圾分类与循环利用落地实操'
);

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`, `remark`)
SELECT
  '绿色饭店培训', '服务提升', '前厅管理', '绿色前厅服务与住客沟通话术', NULL, 'basic',
  '绿色服务引导、住客沟通、节能倡导场景话术', 1015, 1, '000000', 'admin', '绿色饭店种子课程'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '绿色前厅服务与住客沟通话术'
);

-- ----------------------------
-- B. 绿色饭店知识文章种子数据
-- ----------------------------

INSERT INTO `train_knowledge_article`
(`title`, `content`, `cover_image`, `author_id`, `author_name`, `dept_id`, `dept_name`, `tenant_id`, `publish_scope`, `status`,
 `view_count`, `like_count`, `favorite_count`, `comment_count`, `is_top`, `top_time`, `create_time`, `update_time`, `del_flag`)
SELECT
  '绿色饭店基础认知：评定标准与实施路线',
  '<h3>一、绿色饭店是什么</h3><p>绿色饭店是以节能、低碳、环保和可持续服务为核心的运营体系。</p><h3>二、评定重点</h3><ul><li>能源与水资源管理</li><li>绿色采购和供应链</li><li>垃圾分类与循环利用</li><li>住客绿色体验</li></ul><h3>三、落地建议</h3><p>先建制度，再做培训，最后以月度指标进行复盘。</p>',
  NULL, 1, '平台运营中心', NULL, '培训中心', '000000', 'platform', 'published',
  0, 0, 0, 0, 1, NOW(), NOW(), NOW(), '0'
WHERE NOT EXISTS (
  SELECT 1 FROM train_knowledge_article WHERE title = '绿色饭店基础认知：评定标准与实施路线' AND del_flag = '0'
);

INSERT INTO `train_knowledge_article`
(`title`, `content`, `cover_image`, `author_id`, `author_name`, `dept_id`, `dept_name`, `tenant_id`, `publish_scope`, `status`,
 `view_count`, `like_count`, `favorite_count`, `comment_count`, `is_top`, `top_time`, `create_time`, `update_time`, `del_flag`)
SELECT
  '节能降耗清单：客房与公区水电管理',
  '<h3>客房节能</h3><p>控制空调温度、优化布草更换频率、采用节水龙头与智能照明。</p><h3>公区节能</h3><p>电梯分时段运行、走廊照明分区控制、设备巡检制度化。</p><h3>建议指标</h3><p>按月跟踪单房能耗与单房用水。</p>',
  NULL, 1, '平台运营中心', NULL, '培训中心', '000000', 'platform', 'published',
  0, 0, 0, 0, 0, NULL, NOW(), NOW(), '0'
WHERE NOT EXISTS (
  SELECT 1 FROM train_knowledge_article WHERE title = '节能降耗清单：客房与公区水电管理' AND del_flag = '0'
);

INSERT INTO `train_knowledge_article`
(`title`, `content`, `cover_image`, `author_id`, `author_name`, `dept_id`, `dept_name`, `tenant_id`, `publish_scope`, `status`,
 `view_count`, `like_count`, `favorite_count`, `comment_count`, `is_top`, `top_time`, `create_time`, `update_time`, `del_flag`)
SELECT
  '绿色采购操作手册：供应商准入与台账',
  '<h3>准入标准</h3><p>优先选择具备环保认证、可追溯和合规资质的供应商。</p><h3>采购台账</h3><p>建立“类别-供应商-资质-到期时间”台账，按季度复审。</p><h3>风险控制</h3><p>对高耗能、高污染品类设置替代清单。</p>',
  NULL, 1, '平台运营中心', NULL, '培训中心', '000000', 'platform', 'published',
  0, 0, 0, 0, 0, NULL, NOW(), NOW(), '0'
WHERE NOT EXISTS (
  SELECT 1 FROM train_knowledge_article WHERE title = '绿色采购操作手册：供应商准入与台账' AND del_flag = '0'
);

INSERT INTO `train_knowledge_article`
(`title`, `content`, `cover_image`, `author_id`, `author_name`, `dept_id`, `dept_name`, `tenant_id`, `publish_scope`, `status`,
 `view_count`, `like_count`, `favorite_count`, `comment_count`, `is_top`, `top_time`, `create_time`, `update_time`, `del_flag`)
SELECT
  '低碳客房运营：布草、清洁与耗材优化',
  '<h3>布草管理</h3><p>实施“按需更换”，并通过住客引导减少不必要洗涤。</p><h3>清洁用品</h3><p>采用可降解、低刺激环保清洁剂，减少一次性用品。</p><h3>培训重点</h3><p>前厅与客房要统一话术和执行标准。</p>',
  NULL, 1, '平台运营中心', NULL, '培训中心', '000000', 'platform', 'published',
  0, 0, 0, 0, 0, NULL, NOW(), NOW(), '0'
WHERE NOT EXISTS (
  SELECT 1 FROM train_knowledge_article WHERE title = '低碳客房运营：布草、清洁与耗材优化' AND del_flag = '0'
);

INSERT INTO `train_knowledge_article`
(`title`, `content`, `cover_image`, `author_id`, `author_name`, `dept_id`, `dept_name`, `tenant_id`, `publish_scope`, `status`,
 `view_count`, `like_count`, `favorite_count`, `comment_count`, `is_top`, `top_time`, `create_time`, `update_time`, `del_flag`)
SELECT
  '绿色餐饮与减废：后厨全流程管理',
  '<h3>节能</h3><p>重点管控冷链、烹饪设备和高峰时段能耗。</p><h3>减废</h3><p>从采购、储存、加工到出品全流程减少食材损耗。</p><h3>循环利用</h3><p>做好厨余分类，探索资源化处理路径。</p>',
  NULL, 1, '平台运营中心', NULL, '培训中心', '000000', 'platform', 'published',
  0, 0, 0, 0, 0, NULL, NOW(), NOW(), '0'
WHERE NOT EXISTS (
  SELECT 1 FROM train_knowledge_article WHERE title = '绿色餐饮与减废：后厨全流程管理' AND del_flag = '0'
);

INSERT INTO `train_knowledge_article`
(`title`, `content`, `cover_image`, `author_id`, `author_name`, `dept_id`, `dept_name`, `tenant_id`, `publish_scope`, `status`,
 `view_count`, `like_count`, `favorite_count`, `comment_count`, `is_top`, `top_time`, `create_time`, `update_time`, `del_flag`)
SELECT
  '垃圾分类与循环利用：前后台协同机制',
  '<h3>分类原则</h3><p>明确可回收物、厨余垃圾、有害垃圾与其他垃圾标准。</p><h3>协同机制</h3><p>客房、餐饮、后勤统一流程，减少混投与二次污染。</p><h3>检查建议</h3><p>按班次抽检，问题闭环到岗位。</p>',
  NULL, 1, '平台运营中心', NULL, '培训中心', '000000', 'platform', 'published',
  0, 0, 0, 0, 0, NULL, NOW(), NOW(), '0'
WHERE NOT EXISTS (
  SELECT 1 FROM train_knowledge_article WHERE title = '垃圾分类与循环利用：前后台协同机制' AND del_flag = '0'
);

SELECT COUNT(*) AS green_course_total FROM green_hotel_course WHERE status = 1;
SELECT COUNT(*) AS green_article_total FROM train_knowledge_article WHERE del_flag = '0' AND status = 'published';
