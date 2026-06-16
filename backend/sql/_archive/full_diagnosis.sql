-- 完整诊断报告生成问题
USE hotel_training;

-- 1. 检查报告表是否有数据
SELECT '========== 1. 检查报告表数据 ==========' AS info;
SELECT COUNT(*) as total_reports FROM train_learning_report;
SELECT * FROM train_learning_report ORDER BY create_time DESC LIMIT 3;

-- 2. 检查评分模型
SELECT '========== 2. 检查评分模型 ==========' AS info;
SELECT model_id, model_name, is_default, status, tenant_id FROM train_score_model;

-- 3. 检查评分维度
SELECT '========== 3. 检查评分维度 ==========' AS info;
SELECT 
    m.model_id,
    m.model_name,
    d.dimension_code,
    d.dimension_name,
    d.weight
FROM train_score_model m
LEFT JOIN train_score_dimension d ON m.model_id = d.model_id
WHERE m.status = '1'
ORDER BY m.model_id, d.sort_order;

-- 4. 检查部门规则配置
SELECT '========== 4. 检查部门规则配置 ==========' AS info;
SELECT * FROM train_dept_rule;

-- 5. 检查用户ID=100的学习数据
SELECT '========== 5. 检查用户学习数据 ==========' AS info;
SELECT 
    '课程进度' as data_type,
    COUNT(*) as count,
    MIN(create_time) as earliest,
    MAX(create_time) as latest
FROM train_course_progress 
WHERE user_id = 100
UNION ALL
SELECT 
    '答题记录' as data_type,
    COUNT(*) as count,
    MIN(create_time) as earliest,
    MAX(create_time) as latest
FROM train_answer_attempt 
WHERE user_id = 100
UNION ALL
SELECT 
    '考试记录' as data_type,
    COUNT(*) as count,
    MIN(create_time) as earliest,
    MAX(create_time) as latest
FROM train_exam_record 
WHERE user_id = 100;

-- 6. 检查表结构
SELECT '========== 6. 检查报告表结构 ==========' AS info;
SHOW COLUMNS FROM train_learning_report;
