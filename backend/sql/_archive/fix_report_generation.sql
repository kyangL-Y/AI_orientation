-- ================================================
-- 诊断和修复学习报告生成问题
-- 执行此脚本前请确保已连接到正确的数据库 (hotel_training)
-- ================================================

-- 1. 检查评分模型
SELECT '========== 1. 检查评分模型 ==========' AS step;
SELECT model_id, model_name, is_default, status, tenant_id 
FROM train_score_model;

-- 2. 检查评分维度
SELECT '========== 2. 检查评分维度 ==========' AS step;
SELECT d.dimension_id, d.model_id, d.dimension_code, d.dimension_name, d.weight, d.sort_order
FROM train_score_dimension d
ORDER BY d.model_id, d.sort_order;

-- 3. 检查维度权重总和
SELECT '========== 3. 检查维度权重总和 ==========' AS step;
SELECT 
    m.model_id,
    m.model_name,
    m.is_default,
    COUNT(d.dimension_id) AS dimension_count,
    COALESCE(SUM(d.weight), 0) AS total_weight,
    CASE 
        WHEN COALESCE(SUM(d.weight), 0) = 100 THEN '✓ 权重正确'
        WHEN COALESCE(SUM(d.weight), 0) = 0 THEN '✗ 无维度数据'
        ELSE CONCAT('✗ 权重不正确 (', COALESCE(SUM(d.weight), 0), ')')
    END AS check_result
FROM train_score_model m
LEFT JOIN train_score_dimension d ON m.model_id = d.model_id
GROUP BY m.model_id, m.model_name, m.is_default;

-- 4. 获取默认模型ID
SET @model_id = (SELECT model_id FROM train_score_model WHERE is_default = '1' AND status = '1' LIMIT 1);
SELECT CONCAT('默认模型ID: ', IFNULL(@model_id, '未找到')) AS info;

-- 5. 如果没有默认模型，创建一个
SELECT '========== 5. 创建默认模型（如果不存在）==========' AS step;
INSERT INTO train_score_model (model_name, description, tenant_id, status, is_default, create_by, create_time)
SELECT '标准评分规则', 
       '适用于所有部门的标准评分规则', 
       'T001', 
       '1', 
       '1', 
       'admin',
       NOW()
WHERE NOT EXISTS (SELECT 1 FROM train_score_model WHERE is_default = '1' AND status = '1');

-- 重新获取模型ID
SET @model_id = (SELECT model_id FROM train_score_model WHERE is_default = '1' AND status = '1' LIMIT 1);
SELECT CONCAT('当前默认模型ID: ', IFNULL(@model_id, '未找到')) AS info;

-- 6. 删除现有维度（如果权重不正确）
SELECT '========== 6. 修复维度数据 ==========' AS step;
DELETE FROM train_score_dimension WHERE model_id = @model_id;

-- 7. 重新创建维度（确保权重总和为100）
INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
VALUES 
    (@model_id, 'accuracy_rate', '答题正确率', 33, '用户答题的正确率', 1),
    (@model_id, 'completion_rate', '模块完成率', 33, '学习模块的完成比例', 2),
    (@model_id, 'assessment_score', '测评得分', 34, '考试测评的平均得分', 3);

-- 8. 验证修复结果
SELECT '========== 8. 验证修复结果 ==========' AS step;
SELECT 
    m.model_id,
    m.model_name,
    m.is_default,
    m.status,
    COUNT(d.dimension_id) AS dimension_count,
    SUM(d.weight) AS total_weight,
    CASE 
        WHEN SUM(d.weight) = 100 THEN '✓ 修复成功'
        ELSE '✗ 修复失败'
    END AS check_result
FROM train_score_model m
LEFT JOIN train_score_dimension d ON m.model_id = d.model_id
WHERE m.is_default = '1' AND m.status = '1'
GROUP BY m.model_id, m.model_name, m.is_default, m.status;

-- 9. 显示最终维度配置
SELECT '========== 9. 最终维度配置 ==========' AS step;
SELECT d.dimension_id, d.model_id, d.dimension_code, d.dimension_name, d.weight, d.sort_order
FROM train_score_dimension d
WHERE d.model_id = @model_id
ORDER BY d.sort_order;

SELECT '========== 修复完成 ==========' AS step;
