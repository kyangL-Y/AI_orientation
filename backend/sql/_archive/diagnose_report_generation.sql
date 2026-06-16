-- 诊断报告生成失败的原因
USE hotel_training;

SELECT '========== 1. 检查评分模型是否存在 ==========' AS '';

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('✓ 有评分模型: ', COUNT(*), ' 个')
        ELSE '✗ 没有评分模型！'
    END AS check_result
FROM train_score_model 
WHERE status = '1';

-- 显示所有评分模型
SELECT model_id, model_name, is_default, status, tenant_id
FROM train_score_model;

SELECT '========== 2. 检查是否有默认评分模型 ==========' AS '';

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('✓ 有默认模型: ', model_name)
        ELSE '✗ 没有默认模型！这是问题所在！'
    END AS check_result
FROM train_score_model 
WHERE is_default = '1' AND status = '1'
LIMIT 1;

SELECT '========== 3. 检查评分维度配置 ==========' AS '';

-- 检查每个模型的维度配置
SELECT 
    m.model_id,
    m.model_name,
    COUNT(d.dimension_id) as dimension_count,
    SUM(d.weight) as total_weight,
    CASE 
        WHEN COUNT(d.dimension_id) = 3 AND SUM(d.weight) = 100 THEN '✓ 配置正确'
        WHEN COUNT(d.dimension_id) != 3 THEN CONCAT('✗ 维度数量错误: ', COUNT(d.dimension_id))
        WHEN SUM(d.weight) != 100 THEN CONCAT('✗ 权重错误: ', SUM(d.weight), '%')
        ELSE '✗ 配置错误'
    END as check_result
FROM train_score_model m
LEFT JOIN train_score_dimension d ON m.model_id = d.model_id
WHERE m.status = '1'
GROUP BY m.model_id, m.model_name;

SELECT '========== 4. 检查用户学习数据（用户ID=100） ==========' AS '';

-- 检查课程进度
SELECT 
    CONCAT('课程进度记录: ', COUNT(*)) as info
FROM train_course_progress 
WHERE user_id = 100;

-- 检查答题记录
SELECT 
    CONCAT('答题记录: ', COUNT(*)) as info
FROM train_answer_attempt 
WHERE user_id = 100;

-- 检查考试记录
SELECT 
    CONCAT('考试记录: ', COUNT(*)) as info
FROM train_exam_record 
WHERE user_id = 100;

SELECT '========== 5. 检查最近7天的学习活动 ==========' AS '';

SELECT 
    '最近7天' as period,
    COUNT(DISTINCT user_id) as active_users,
    COUNT(*) as total_records
FROM train_course_progress
WHERE create_time >= DATE_SUB(NOW(), INTERVAL 7 DAY);

SELECT '========== 诊断完成 ==========' AS '';

SELECT '如果没有默认评分模型，需要执行 insert_learning_assessment_data.sql' AS suggestion;
