-- 修复评分模型缺失问题

-- 1. 检查当前是否有评分模型
SELECT 
    model_id,
    model_name,
    is_default,
    status,
    tenant_id,
    create_time
FROM train_scoring_model
ORDER BY is_default DESC, create_time DESC;

-- 2. 如果没有评分模型，插入一个默认的
-- 注意：需要根据实际的租户ID修改 tenant_id
INSERT INTO train_scoring_model (
    model_name,
    description,
    dimension_config,
    is_default,
    status,
    tenant_id,
    create_by,
    create_time
)
SELECT 
    '默认评分模型',
    '系统默认的学习评分模型',
    '{
        "dimensions": [
            {"name": "学习时长", "weight": 30, "code": "learning_time"},
            {"name": "课程完成度", "weight": 25, "code": "course_completion"},
            {"name": "考试成绩", "weight": 25, "code": "exam_score"},
            {"name": "学习频率", "weight": 20, "code": "learning_frequency"}
        ]
    }',
    1,
    '1',
    'T001',
    'admin',
    NOW()
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM train_scoring_model WHERE tenant_id = 'T001'
);

-- 3. 确保有默认模型（如果有多个，设置第一个为默认）
UPDATE train_scoring_model 
SET is_default = 0 
WHERE tenant_id = 'T001';

UPDATE train_scoring_model 
SET is_default = 1 
WHERE model_id = (
    SELECT model_id FROM (
        SELECT model_id FROM train_scoring_model 
        WHERE tenant_id = 'T001' AND status = '1'
        ORDER BY create_time ASC 
        LIMIT 1
    ) AS tmp
);

-- 4. 验证修复结果
SELECT 
    '评分模型检查' as check_item,
    COUNT(*) as total_count,
    SUM(CASE WHEN is_default = 1 THEN 1 ELSE 0 END) as default_count,
    SUM(CASE WHEN status = '1' THEN 1 ELSE 0 END) as enabled_count
FROM train_scoring_model
WHERE tenant_id = 'T001';

-- 5. 显示当前的默认模型
SELECT 
    model_id,
    model_name,
    description,
    is_default,
    status,
    create_time
FROM train_scoring_model
WHERE tenant_id = 'T001' AND is_default = 1;
