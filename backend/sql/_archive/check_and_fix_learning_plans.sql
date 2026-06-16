-- 检查学习计划表中path_id为NULL的记录
SELECT 
    plan_id,
    path_id,
    title,
    status,
    create_time
FROM hotel_training.learning_plans
WHERE path_id IS NULL
ORDER BY create_time DESC;

-- 如果发现有path_id为NULL的记录，需要手动修复或删除
-- 删除path_id为NULL的记录（注意：请先备份！）
-- DELETE FROM hotel_training.learning_plans WHERE path_id IS NULL;

-- 检查最近新增的学习计划
SELECT 
    plan_id,
    path_id,
    title,
    status,
    create_time
FROM hotel_training.learning_plans
ORDER BY create_time DESC
LIMIT 10;

-- 检查某个路径下的学习计划（替换为实际的path_id）
-- SELECT * FROM hotel_training.learning_plans WHERE path_id = 1;

