-- 检查评分模型和部门规则配置

-- 1. 检查用户刘洋的部门信息
SELECT 
    u.user_id,
    u.user_name,
    u.nick_name,
    u.dept_id,
    d.dept_name,
    d.parent_id,
    d.ancestors
FROM sys_user u
LEFT JOIN sys_dept d ON u.dept_id = d.dept_id
WHERE u.user_name = '刘洋' OR u.nick_name = '刘洋';

-- 2. 检查是否有评分模型
SELECT * FROM train_scoring_model ORDER BY create_time DESC;

-- 3. 检查部门评分规则配置
SELECT 
    dr.*,
    d.dept_name,
    sm.model_name
FROM train_dept_scoring_rule dr
LEFT JOIN sys_dept d ON dr.dept_id = d.dept_id
LEFT JOIN train_scoring_model sm ON dr.model_id = sm.model_id
ORDER BY dr.create_time DESC;

-- 4. 检查产品部的评分规则
SELECT 
    dr.*,
    d.dept_name,
    sm.model_name
FROM train_dept_scoring_rule dr
LEFT JOIN sys_dept d ON dr.dept_id = d.dept_id
LEFT JOIN train_scoring_model sm ON dr.model_id = sm.model_id
WHERE d.dept_name LIKE '%产品%'
ORDER BY dr.create_time DESC;

-- 5. 检查是否有默认评分规则（dept_id为NULL或0）
SELECT 
    dr.*,
    sm.model_name
FROM train_dept_scoring_rule dr
LEFT JOIN train_scoring_model sm ON dr.model_id = sm.model_id
WHERE dr.dept_id IS NULL OR dr.dept_id = 0
ORDER BY dr.create_time DESC;
