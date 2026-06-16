-- ================================================
-- 恢复为5个维度配置（各20%）
-- 在从库 hotel_training 中执行
-- ================================================

USE hotel_training;

-- 1. 删除当前维度配置
DELETE FROM train_score_dimension WHERE model_id = 1;

-- 2. 插入5个维度配置（各20%权重）
INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, min_value, max_value, sort_order)
VALUES 
(1, 'learning_duration', '学习时长', 20, '周期内总学习时长(分钟)，基准值：周60分钟/月240分钟/季720分钟', 0, 100, 1),
(1, 'quiz_count', '刷题数量', 20, '周期内完成题目数，基准值：周20题/月80题/季240题', 0, 100, 2),
(1, 'accuracy_rate', '答题正确率', 20, '正确数/总答题数×100，直接使用百分比', 0, 100, 3),
(1, 'completion_rate', '模块完成率', 20, '已完成模块/分配模块×100，直接使用百分比', 0, 100, 4),
(1, 'assessment_score', '测评得分', 20, '周期内考试平均分，直接使用分数', 0, 100, 5);

-- 3. 更新模型描述
UPDATE train_score_model 
SET description = '适用于所有岗位的通用学习能力评估模型，包含学习时长、刷题数量、答题正确率、模块完成率、测评得分五个维度，各占20%权重'
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
