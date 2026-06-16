-- ================================================
-- 更新评分模型为3维度配置
-- 在从库 hotel_training 中执行
-- ================================================

USE hotel_training;

-- 1. 删除旧的维度配置
DELETE FROM train_score_dimension WHERE model_id = 1;

-- 2. 插入新的3维度配置
INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, min_value, max_value, sort_order)
VALUES 
(1, 'accuracy_rate', '答题正确率', 33, '正确数/总答题数×100，直接使用百分比', 0, 100, 1),
(1, 'completion_rate', '模块完成率', 33, '已完成模块/分配模块×100，直接使用百分比', 0, 100, 2),
(1, 'assessment_score', '测评得分', 34, '周期内考试平均分，直接使用分数', 0, 100, 3);

-- 3. 更新模型描述
UPDATE train_score_model 
SET description = '适用于所有岗位的通用学习能力评估模型，包含答题正确率(33%)、模块完成率(33%)、测评得分(34%)三个维度。学习时长和刷题数量作为辅助数据不参与评分。'
WHERE model_id = 1;

-- 4. 验证配置
SELECT '========== 验证评分维度配置 ==========' AS '';
SELECT 
    dimension_code,
    dimension_name,
    weight,
    calc_formula
FROM train_score_dimension 
WHERE model_id = 1
ORDER BY sort_order;

SELECT '========== 验证权重总和 ==========' AS '';
SELECT 
    SUM(weight) as total_weight,
    CASE 
        WHEN SUM(weight) = 100 THEN '✓ 权重配置正确'
        ELSE '✗ 权重配置错误'
    END as check_result
FROM train_score_dimension 
WHERE model_id = 1;
