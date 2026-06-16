-- 查看最近生成的报告
USE hotel_training;

SELECT 
    r.report_id,
    r.user_id,
    r.period_type,
    r.period_start,
    r.period_end,
    r.total_score,
    r.dimension_scores,
    r.auxiliary_data,
    r.dept_rank,
    r.total_in_dept,
    r.tenant_id,
    r.create_time
FROM train_learning_report r
ORDER BY r.create_time DESC
LIMIT 5;

-- 查看AI建议
SELECT 
    s.suggestion_id,
    s.report_id,
    s.suggestion_type,
    s.target_dimension,
    s.suggestion_content,
    s.create_time
FROM train_ai_suggestion s
ORDER BY s.create_time DESC
LIMIT 10;
