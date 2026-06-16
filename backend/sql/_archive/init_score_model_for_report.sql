-- ================================================
-- 初始化评分模型数据（用于学习报告生成）
-- 执行此脚本前请确保已连接到正确的数据库
-- ================================================

-- 1. 检查是否存在评分模型
SELECT '========== 检查现有评分模型 ==========' AS info;
SELECT model_id, model_name, is_default, status, tenant_id 
FROM train_score_model;

-- 2. 检查是否存在默认评分模型
SELECT '========== 检查默认评分模型 ==========' AS info;
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN CONCAT('✓ 存在默认评分模型，model_id=', MAX(model_id))
        ELSE '✗ 不存在默认评分模型，需要创建'
    END AS check_result
FROM train_score_model
WHERE is_default = '1' AND status = '1';

-- 3. 如果不存在评分模型，创建默认模型
-- 注意：请根据实际租户ID修改 tenant_id 值
INSERT INTO train_score_model (model_name, description, tenant_id, status, is_default, create_by, create_time)
SELECT '标准评分规则', 
       '适用于所有部门的标准评分规则，包含答题正确率(33%)、模块完成率(33%)、测评得分(34%)三个维度', 
       'T001', 
       '1', 
       '1', 
       'admin',
       NOW()
WHERE NOT EXISTS (SELECT 1 FROM train_score_model WHERE status = '1');

-- 4. 获取刚创建的模型ID
SET @model_id = (SELECT model_id FROM train_score_model WHERE is_default = '1' AND status = '1' LIMIT 1);

-- 5. 检查是否存在评分维度
SELECT '========== 检查评分维度 ==========' AS info;
SELECT dimension_id, model_id, dimension_code, dimension_name, weight, sort_order
FROM train_score_dimension
WHERE model_id = @model_id;

-- 6. 如果不存在评分维度，创建默认维度
-- 注意：train_score_dimension 表结构为 (dimension_id, model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
SELECT @model_id, 'accuracy_rate', '答题正确率', 33, '用户答题的正确率', 1
WHERE @model_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM train_score_dimension WHERE model_id = @model_id AND dimension_code = 'accuracy_rate');

INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
SELECT @model_id, 'completion_rate', '模块完成率', 33, '学习模块的完成比例', 2
WHERE @model_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM train_score_dimension WHERE model_id = @model_id AND dimension_code = 'completion_rate');

INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
SELECT @model_id, 'assessment_score', '测评得分', 34, '考试测评的平均得分', 3
WHERE @model_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM train_score_dimension WHERE model_id = @model_id AND dimension_code = 'assessment_score');

-- 7. 验证结果
SELECT '========== 验证初始化结果 ==========' AS info;
SELECT 
    m.model_id,
    m.model_name,
    m.is_default,
    m.status,
    COUNT(d.dimension_id) AS dimension_count,
    SUM(d.weight) AS total_weight
FROM train_score_model m
LEFT JOIN train_score_dimension d ON m.model_id = d.model_id
WHERE m.is_default = '1' AND m.status = '1'
GROUP BY m.model_id, m.model_name, m.is_default, m.status;

SELECT '========== 初始化完成 ==========' AS info;
