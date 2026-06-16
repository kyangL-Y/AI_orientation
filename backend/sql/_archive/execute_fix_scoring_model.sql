-- 修复评分模型缺失问题 - 执行脚本
-- 数据库: hotel_training
-- 租户ID: T001

USE hotel_training;

-- 1. 检查当前是否有评分模型
SELECT '=== 步骤1: 检查现有评分模型 ===' as step;
SELECT 
    model_id,
    model_name,
    is_default,
    status,
    tenant_id,
    create_time
FROM train_score_model
WHERE tenant_id = 'T001'
ORDER BY is_default DESC, create_time DESC;

-- 2. 插入默认评分模型（如果不存在）
SELECT '=== 步骤2: 插入默认评分模型 ===' as step;
INSERT INTO train_score_model (
    model_name,
    description,
    dimension_config,
    is_default,
    status,
    tenant_id,
    create_by,
    create_time,
    update_time
)
SELECT 
    '默认评分模型' as model_name,
    '系统默认的学习评分模型，包含学习时长、课程完成度、考试成绩和学习频率四个维度' as description,
    '{"dimensions":[{"name":"学习时长","weight":30,"code":"learning_time","description":"用户在学习平台上的总学习时间"},{"name":"课程完成度","weight":25,"code":"course_completion","description":"已完成课程数量占总课程数的比例"},{"name":"考试成绩","weight":25,"code":"exam_score","description":"考试的平均分数"},{"name":"学习频率","weight":20,"code":"learning_frequency","description":"学习的活跃度和规律性"}]}' as dimension_config,
    1 as is_default,
    '1' as status,
    'T001' as tenant_id,
    'admin' as create_by,
    NOW() as create_time,
    NOW() as update_time
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM train_score_model WHERE tenant_id = 'T001'
);

-- 3. 确保只有一个默认模型
SELECT '=== 步骤3: 设置默认模型 ===' as step;

-- 先取消所有默认标记
UPDATE train_score_model 
SET is_default = 0 
WHERE tenant_id = 'T001';

-- 设置第一个启用的模型为默认
UPDATE train_score_model 
SET is_default = 1 
WHERE tenant_id = 'T001' 
  AND status = '1'
  AND model_id = (
    SELECT model_id FROM (
        SELECT model_id FROM train_score_model 
        WHERE tenant_id = 'T001' AND status = '1'
        ORDER BY create_time ASC 
        LIMIT 1
    ) AS tmp
);

-- 4. 验证修复结果
SELECT '=== 步骤4: 验证修复结果 ===' as step;
SELECT 
    '评分模型统计' as check_item,
    COUNT(*) as total_count,
    SUM(CASE WHEN is_default = 1 THEN 1 ELSE 0 END) as default_count,
    SUM(CASE WHEN status = '1' THEN 1 ELSE 0 END) as enabled_count
FROM train_score_model
WHERE tenant_id = 'T001';

-- 5. 显示当前的默认模型详情
SELECT '=== 步骤5: 当前默认模型 ===' as step;
SELECT 
    model_id,
    model_name,
    description,
    dimension_config,
    is_default,
    status,
    create_time
FROM train_score_model
WHERE tenant_id = 'T001' AND is_default = 1;

SELECT '=== 修复完成 ===' as result;
SELECT '现在用户可以正常生成学习报告了' as message;
