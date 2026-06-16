-- 检查报告是否生成成功
USE hotel_training;

SELECT '========== 检查最近生成的报告 ==========' AS '';

SELECT 
    report_id,
    user_id,
    period_type,
    total_score,
    create_time,
    CASE 
        WHEN ai_suggestion IS NOT NULL THEN '✓ 有AI建议'
        ELSE '✗ 无AI建议'
    END as ai_status
FROM train_learning_report
ORDER BY create_time DESC
LIMIT 5;

SELECT '========== 检查用户ID=100的报告 ==========' AS '';

SELECT 
    report_id,
    period_type,
    total_score,
    dimension_scores,
    auxiliary_data,
    create_time
FROM train_learning_report
WHERE user_id = 100
ORDER BY create_time DESC
LIMIT 3;

SELECT '========== 检查评分模型配置 ==========' AS '';

SELECT 
    m.model_id,
    m.model_name,
    m.is_default,
    COUNT(d.dimension_id) as dimension_count,
    SUM(d.weight) as total_weight
FROM train_score_model m
LEFT JOIN train_score_dimension d ON m.model_id = d.model_id
WHERE m.status = '1'
GROUP BY m.model_id, m.model_name, m.is_default;
