-- 诊断用户轩亚蕊等人为什么没有记录

-- 1. 查找用户轩亚蕊的基本信息
SELECT 
    user_id,
    user_name,
    phonenumber,
    dept_id,
    status,
    del_flag,
    create_time,
    tenant_id
FROM sys_user
WHERE user_name LIKE '%轩亚蕊%' OR phonenumber LIKE '%轩亚蕊%';

-- 2. 查找所有可能相关的用户（模糊匹配）
SELECT 
    user_id,
    user_name,
    phonenumber,
    dept_id,
    status,
    del_flag,
    create_time,
    tenant_id
FROM sys_user
WHERE user_name LIKE '%轩%' OR user_name LIKE '%亚%' OR user_name LIKE '%蕊%'
ORDER BY create_time DESC
LIMIT 20;

-- 3. 检查最近创建的用户
SELECT 
    user_id,
    user_name,
    phonenumber,
    dept_id,
    status,
    del_flag,
    create_time,
    tenant_id
FROM sys_user
ORDER BY create_time DESC
LIMIT 30;

-- 4. 检查是否有学习记录（如果找到用户ID）
-- 先查询用户ID范围
SET @user_ids = (SELECT GROUP_CONCAT(user_id) FROM sys_user WHERE user_name LIKE '%轩%' OR user_name LIKE '%亚%' OR user_name LIKE '%蕊%');

-- 检查课程学习记录
SELECT 
    ulp.user_id,
    u.user_name,
    ulp.course_id,
    c.course_name,
    ulp.progress,
    ulp.status,
    ulp.start_time,
    ulp.complete_time
FROM train_user_learning_progress ulp
LEFT JOIN sys_user u ON ulp.user_id = u.user_id
LEFT JOIN train_course c ON ulp.course_id = c.course_id
WHERE ulp.user_id IN (SELECT user_id FROM sys_user WHERE user_name LIKE '%轩%' OR user_name LIKE '%亚%' OR user_name LIKE '%蕊%')
ORDER BY ulp.start_time DESC;

-- 5. 检查考试记录
SELECT 
    qa.user_id,
    u.user_name,
    qa.exam_id,
    qa.score,
    qa.status,
    qa.start_time,
    qa.submit_time
FROM train_quiz_attempt qa
LEFT JOIN sys_user u ON qa.user_id = u.user_id
WHERE qa.user_id IN (SELECT user_id FROM sys_user WHERE user_name LIKE '%轩%' OR user_name LIKE '%亚%' OR user_name LIKE '%蕊%')
ORDER BY qa.start_time DESC;

-- 6. 检查答题记录
SELECT 
    aar.user_id,
    u.user_name,
    aar.question_id,
    aar.is_correct,
    aar.answer_time
FROM train_answer_attempt_record aar
LEFT JOIN sys_user u ON aar.user_id = u.user_id
WHERE aar.user_id IN (SELECT user_id FROM sys_user WHERE user_name LIKE '%轩%' OR user_name LIKE '%亚%' OR user_name LIKE '%蕊%')
ORDER BY aar.answer_time DESC
LIMIT 50;

-- 7. 检查积分记录
SELECT 
    pl.user_id,
    u.user_name,
    pl.points,
    pl.reason,
    pl.create_time
FROM train_points_log pl
LEFT JOIN sys_user u ON pl.user_id = u.user_id
WHERE pl.user_id IN (SELECT user_id FROM sys_user WHERE user_name LIKE '%轩%' OR user_name LIKE '%亚%' OR user_name LIKE '%蕊%')
ORDER BY pl.create_time DESC;

-- 8. 检查用户是否被分配了课程
SELECT 
    sa.user_id,
    u.user_name,
    sa.course_id,
    c.course_name,
    sa.assign_time,
    sa.status
FROM train_study_assign sa
LEFT JOIN sys_user u ON sa.user_id = u.user_id
LEFT JOIN train_course c ON sa.course_id = c.course_id
WHERE sa.user_id IN (SELECT user_id FROM sys_user WHERE user_name LIKE '%轩%' OR user_name LIKE '%亚%' OR user_name LIKE '%蕊%')
ORDER BY sa.assign_time DESC;

-- 9. 检查用户部门信息
SELECT 
    u.user_id,
    u.user_name,
    u.dept_id,
    d.dept_name,
    d.parent_id,
    pd.dept_name as parent_dept_name
FROM sys_user u
LEFT JOIN sys_dept d ON u.dept_id = d.dept_id
LEFT JOIN sys_dept pd ON d.parent_id = pd.dept_id
WHERE u.user_name LIKE '%轩%' OR u.user_name LIKE '%亚%' OR u.user_name LIKE '%蕊%';

-- 10. 检查是否有登录日志
SELECT 
    login_name,
    ipaddr,
    login_location,
    browser,
    os,
    status,
    msg,
    login_time
FROM sys_logininfor
WHERE login_name LIKE '%轩%' OR login_name LIKE '%亚%' OR login_name LIKE '%蕊%'
ORDER BY login_time DESC
LIMIT 20;
