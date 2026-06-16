-- 诊断报告生成问题
USE hotel_training;

SELECT '========== 1. 检查评分模型 ==========' AS '';

-- 查看所有评分模型
SELECT model_id, model_name, is_default, status, tenant_id
FROM train_score_model;

-- 检查是否有默认模型
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('✓ 有默认模型: ', GROUP_CONCAT(model_name))
        ELSE '✗ 没有默认模型！'
    END AS check_result
FROM train_score_model 
WHERE is_default = '1' AND status = '1';

SELECT '========== 2. 检查评分维度 ==========' AS '';

-- 查看评分维度配置
SELECT d.model_id, m.model_name, d.dimension_code, d.dimension_name, d.weight
FROM train_score_dimension d
LEFT JOIN train_score_model m ON d.model_id = m.model_id
ORDER BY d.model_id, d.sort_order;

-- 检查权重总和
SELECT 
    model_id,
    SUM(weight) as total_weight,
    CASE 
        WHEN SUM(weight) = 100 THEN '✓ 权重正确'
        ELSE CONCAT('✗ 权重错误: ', SUM(weight), '%')
    END as check_result
FROM train_score_dimension
GROUP BY model_id;

SELECT '========== 3. 检查部门规则 ==========' AS '';

-- 查看部门规则配置
SELECT * FROM train_dept_rule LIMIT 10;

SELECT CONCAT('部门规则数量: ', COUNT(*)) as info FROM train_dept_rule;

SELECT '========== 4. 检查现有报告 ==========' AS '';

-- 查看最近的报告
SELECT 
    report_id,
    user_id,
    model_id,
    period_type,
    total_score,
    CASE 
        WHEN auxiliary_data IS NULL THEN '✗ auxiliary_data为空'
        ELSE '✓ auxiliary_data有值'
    END as aux_check,
    CASE 
        WHEN ai_suggestion IS NULL THEN '✗ ai_suggestion为空'
        ELSE '✓ ai_suggestion有值'
    END as ai_check,
    create_time
FROM train_learning_report
ORDER BY create_time DESC
LIMIT 5;

SELECT CONCAT('报告总数: ', COUNT(*)) as info FROM train_learning_report;

SELECT '========== 5. 检查用户学习数据 ==========' AS '';

-- 检查是否有学习数据（随机取一个用户）
SET @test_user_id = (SELECT user_id FROM train_course_progress LIMIT 1);

SELECT CONCAT('测试用户ID: ', IFNULL(@test_user_id, '无')) as info;

-- 检查该用户的学习进度
SELECT 
    CONCAT('课程进度记录: ', COUNT(*)) as info
FROM train_course_progress 
WHERE user_id = @test_user_id;

-- 检查该用户的答题记录
SELECT 
    CONCAT('答题记录: ', COUNT(*)) as info
FROM train_answer_attempt 
WHERE user_id = @test_user_id;

-- 检查该用户的考试记录
SELECT 
    CONCAT('考试记录: ', COUNT(*)) as info
FROM train_exam_record 
WHERE user_id = @test_user_id;

SELECT '========== 6. 测试评分计算所需的数据 ==========' AS '';

-- 检查最近7天是否有学习活动
SELECT 
    '最近7天学习活动' as data_type,
    COUNT(DISTINCT user_id) as user_count,
    COUNT(*) as record_count
FROM train_course_progress
WHERE create_time >= DATE_SUB(NOW(), INTERVAL 7 DAY);

SELECT 
    '最近7天答题活动' as data_type,
    COUNT(DISTINCT user_id) as user_count,
    COUNT(*) as record_count
FROM train_answer_attempt
WHERE create_time >= DATE_SUB(NOW(), INTERVAL 7 DAY);

SELECT 
    '最近7天考试活动' as data_type,
    COUNT(DISTINCT user_id) as user_count,
    COUNT(*) as record_count
FROM train_exam_record
WHERE create_time >= DATE_SUB(NOW(), INTERVAL 7 DAY);

SELECT '========== 诊断完成 ==========' AS '';
