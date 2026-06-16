-- =============================================
-- 学习测评系统诊断脚本
-- 执行库：hotel_training
-- =============================================

USE hotel_training;

SELECT '========== 1. 检查表结构 ==========' AS step;

-- 检查 train_learning_report 表结构
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_COMMENT
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report'
ORDER BY ORDINAL_POSITION;

SELECT '========== 2. 检查评分模型 ==========' AS step;

-- 检查评分模型数据
SELECT 
    model_id,
    model_name,
    status,
    is_default,
    tenant_id
FROM train_score_model
ORDER BY model_id;

SELECT '========== 3. 检查评分维度 ==========' AS step;

-- 检查评分维度数据
SELECT 
    d.dimension_id,
    d.model_id,
    m.model_name,
    d.dimension_code,
    d.dimension_name,
    d.weight
FROM train_score_dimension d
LEFT JOIN train_score_model m ON d.model_id = m.model_id
ORDER BY d.model_id, d.sort_order;

SELECT '========== 4. 检查部门规则 ==========' AS step;

-- 检查部门规则配置
SELECT 
    dr.id,
    dr.dept_id,
    dr.model_id,
    m.model_name,
    dr.tenant_id
FROM train_dept_rule dr
LEFT JOIN train_score_model m ON dr.model_id = m.model_id
ORDER BY dr.dept_id;

SELECT '========== 5. 检查现有报告 ==========' AS step;

-- 检查现有报告数据
SELECT 
    report_id,
    user_id,
    model_id,
    period_type,
    period_start,
    period_end,
    total_score,
    tenant_id,
    create_time
FROM train_learning_report
ORDER BY create_time DESC
LIMIT 10;

SELECT '========== 6. 检查用户学习数据 ==========' AS step;

-- 检查是否有学习数据（课程进度）
SELECT 
    COUNT(*) AS course_progress_count,
    COUNT(DISTINCT user_id) AS user_count
FROM train_course_progress;

-- 检查是否有答题数据
SELECT 
    COUNT(*) AS answer_attempt_count,
    COUNT(DISTINCT user_id) AS user_count
FROM train_answer_attempt;

-- 检查是否有考试数据
SELECT 
    COUNT(*) AS exam_record_count,
    COUNT(DISTINCT user_id) AS user_count
FROM train_exam_record;

SELECT '========== 7. 诊断结果 ==========' AS step;

-- 汇总诊断结果
SELECT 
    '评分模型数量' AS item,
    COUNT(*) AS count
FROM train_score_model
UNION ALL
SELECT 
    '评分维度数量' AS item,
    COUNT(*) AS count
FROM train_score_dimension
UNION ALL
SELECT 
    '部门规则数量' AS item,
    COUNT(*) AS count
FROM train_dept_rule
UNION ALL
SELECT 
    '现有报告数量' AS item,
    COUNT(*) AS count
FROM train_learning_report
UNION ALL
SELECT 
    '学习进度记录' AS item,
    COUNT(*) AS count
FROM train_course_progress
UNION ALL
SELECT 
    '答题记录' AS item,
    COUNT(*) AS count
FROM train_answer_attempt
UNION ALL
SELECT 
    '考试记录' AS item,
    COUNT(*) AS count
FROM train_exam_record;

SELECT '========== 诊断完成 ==========' AS step;
