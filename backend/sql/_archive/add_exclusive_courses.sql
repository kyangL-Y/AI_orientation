-- ============================================
-- 检查和添加"独家"平台课程数据
-- ============================================

USE hotel_training;

-- 1. 查看 course_category 表中所有不同的 platform 值
SELECT '========== 1. 查看所有平台值 ==========' AS step;
SELECT DISTINCT platform, COUNT(*) as count 
FROM course_category 
GROUP BY platform;

-- 2. 查看"独家"平台的课程数据
SELECT '========== 2. 查看独家平台课程 ==========' AS step;
SELECT course_category_id, main_title, main_s, third_level_c, platform, level
FROM course_category 
WHERE platform = '独家'
LIMIT 20;

-- 3. 如果没有独家课程，添加一些示例数据
-- 首先检查是否已有独家课程
SET @exclusive_count = (SELECT COUNT(*) FROM course_category WHERE platform = '独家');

SELECT CONCAT('当前独家课程数量: ', @exclusive_count) AS info;

-- 4. 如果没有独家课程，插入示例数据
-- 注意：这里使用 INSERT IGNORE 避免重复插入
INSERT INTO course_category (main_title, main_s, specific_category, third_level_c, platform, level, knowledge_points, sort_order, created_time, updated_time)
SELECT * FROM (
    SELECT '酒店运营管理' as main_title, '运营基础' as main_s, '日常运营' as specific_category, '酒店日常运营流程' as third_level_c, '独家' as platform, 'basic' as level, 
           '<h2>酒店日常运营流程</h2><p>本课程详细介绍酒店日常运营的各个环节，包括前台接待、客房管理、餐饮服务等核心业务流程。</p><h3>学习目标</h3><ul><li>掌握酒店运营的基本流程</li><li>了解各部门协作机制</li><li>提升服务质量和效率</li></ul>' as knowledge_points, 
           1 as sort_order, NOW() as created_time, NOW() as updated_time
    UNION ALL
    SELECT '酒店运营管理', '运营基础', '日常运营', '客房清洁标准与流程', '独家', 'basic', 
           '<h2>客房清洁标准与流程</h2><p>专业的客房清洁标准和操作流程，确保为客人提供舒适整洁的住宿环境。</p><h3>核心内容</h3><ul><li>清洁工具和用品的使用</li><li>标准清洁流程</li><li>质量检查要点</li></ul>', 
           2, NOW(), NOW()
    UNION ALL
    SELECT '酒店运营管理', '服务技巧', '客户服务', '客户投诉处理技巧', '独家', 'advance', 
           '<h2>客户投诉处理技巧</h2><p>学习如何专业、高效地处理客户投诉，将危机转化为提升客户满意度的机会。</p><h3>关键技能</h3><ul><li>倾听与同理心</li><li>问题分析与解决</li><li>补救措施与跟进</li></ul>', 
           3, NOW(), NOW()
    UNION ALL
    SELECT '酒店运营管理', '服务技巧', '客户服务', 'VIP客户接待礼仪', '独家', 'advance', 
           '<h2>VIP客户接待礼仪</h2><p>针对高端客户的专业接待礼仪和服务标准，提升酒店品牌形象。</p><h3>学习要点</h3><ul><li>VIP识别与档案管理</li><li>个性化服务设计</li><li>高端礼仪规范</li></ul>', 
           4, NOW(), NOW()
    UNION ALL
    SELECT '酒店运营管理', '管理进阶', '团队管理', '酒店团队建设与激励', '独家', 'advance', 
           '<h2>酒店团队建设与激励</h2><p>打造高效协作的酒店团队，提升员工满意度和工作效率。</p><h3>管理技能</h3><ul><li>团队文化建设</li><li>激励机制设计</li><li>绩效管理方法</li></ul>', 
           5, NOW(), NOW()
    UNION ALL
    SELECT '酒店运营管理', '管理进阶', '团队管理', '酒店人才培养体系', '独家', 'high', 
           '<h2>酒店人才培养体系</h2><p>建立系统化的人才培养机制，为酒店持续发展储备优秀人才。</p><h3>体系构建</h3><ul><li>培训需求分析</li><li>培养计划制定</li><li>效果评估与改进</li></ul>', 
           6, NOW(), NOW()
    UNION ALL
    SELECT '收益管理', '定价策略', '动态定价', '酒店动态定价策略', '独家', 'advance', 
           '<h2>酒店动态定价策略</h2><p>掌握科学的定价方法，根据市场需求动态调整房价，最大化收益。</p><h3>核心技能</h3><ul><li>市场需求预测</li><li>竞争对手分析</li><li>价格优化模型</li></ul>', 
           7, NOW(), NOW()
    UNION ALL
    SELECT '收益管理', '定价策略', '动态定价', '收益管理数据分析', '独家', 'high', 
           '<h2>收益管理数据分析</h2><p>利用数据分析工具，深入洞察市场趋势，制定精准的收益策略。</p><h3>分析方法</h3><ul><li>历史数据分析</li><li>预测模型应用</li><li>决策支持系统</li></ul>', 
           8, NOW(), NOW()
) AS tmp
WHERE NOT EXISTS (
    SELECT 1 FROM course_category WHERE platform = '独家' AND third_level_c = tmp.third_level_c
);

-- 5. 再次查看独家课程数量
SELECT '========== 5. 插入后独家课程数量 ==========' AS step;
SELECT COUNT(*) as exclusive_course_count FROM course_category WHERE platform = '独家';

-- 6. 显示所有独家课程
SELECT '========== 6. 所有独家课程列表 ==========' AS step;
SELECT course_category_id, main_title, main_s, specific_category, third_level_c, platform, level
FROM course_category 
WHERE platform = '独家'
ORDER BY sort_order;

SELECT '✅ 独家课程数据检查和添加完成！' AS result;
