-- ========================================
-- 诊断用户轩亚蕊为什么没有任何记录
-- ========================================

-- 1. 确认用户基本信息
SELECT '=== 1. 用户基本信息 ===' as step;
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
WHERE user_name = '轩亚蕊';

-- 2. 检查用户部门信息
SELECT '=== 2. 用户部门信息 ===' as step;
SELECT 
    u.user_id,
    u.user_name,
    u.dept_id,
    d.dept_name,
    d.parent_id,
    pd.dept_name as parent_dept_name,
    d.status as dept_status
FROM sys_user u
LEFT JOIN sys_dept d ON u.dept_id = d.dept_id
LEFT JOIN sys_dept pd ON d.parent_id = pd.dept_id
WHERE u.user_name = '轩亚蕊';

-- 3. 检查是否有课程分配记录
SELECT '=== 3. 课程分配记录 ===' as step;
SELECT COUNT(*) as assign_count 
FROM train_study_assign 
WHERE user_id = 159;

SELECT * FROM train_study_assign WHERE user_id = 159 LIMIT 5;

-- 4. 检查学习进度记录
SELECT '=== 4. 学习进度记录 ===' as step;
SELECT COUNT(*) as learning_count 
FROM train_user_learning_progress 
WHERE user_id = 159;

SELECT * FROM train_user_learning_progress WHERE user_id = 159 LIMIT 5;

-- 5. 检查考试记录
SELECT '=== 5. 考试记录 ===' as step;
SELECT COUNT(*) as exam_count 
FROM train_quiz_attempt 
WHERE user_id = 159;

SELECT * FROM train_quiz_attempt WHERE user_id = 159 LIMIT 5;

-- 6. 检查答题记录
SELECT '=== 6. 答题记录 ===' as step;
SELECT COUNT(*) as answer_count 
FROM train_answer_attempt_record 
WHERE user_id = 159;

-- 7. 检查积分记录
SELECT '=== 7. 积分记录 ===' as step;
SELECT COUNT(*) as points_count 
FROM train_points_log 
WHERE user_id = 159;

-- 8. 检查登录日志
SELECT '=== 8. 登录日志 ===' as step;
SELECT 
    login_name,
    ipaddr,
    login_location,
    status,
    msg,
    login_time
FROM sys_logininfor
WHERE login_name = '轩亚蕊' OR login_name = '15839428717'
ORDER BY login_time DESC
LIMIT 10;

-- 9. 检查操作日志
SELECT '=== 9. 操作日志 ===' as step;
SELECT COUNT(*) as oper_count
FROM sys_oper_log
WHERE oper_name = '轩亚蕊';

SELECT 
    title,
    business_type,
    method,
    oper_time
FROM sys_oper_log
WHERE oper_name = '轩亚蕊'
ORDER BY oper_time DESC
LIMIT 10;

-- 10. 检查该部门下其他用户的记录情况
SELECT '=== 10. 同部门其他用户记录情况 ===' as step;
SELECT 
    u.user_id,
    u.user_name,
    COUNT(DISTINCT ulp.course_id) as learning_courses,
    COUNT(DISTINCT qa.exam_id) as exam_attempts,
    COUNT(DISTINCT pl.points_log_id) as points_records
FROM sys_user u
LEFT JOIN train_user_learning_progress ulp ON u.user_id = ulp.user_id
LEFT JOIN train_quiz_attempt qa ON u.user_id = qa.user_id
LEFT JOIN train_points_log pl ON u.user_id = pl.user_id
WHERE u.dept_id = 215
GROUP BY u.user_id, u.user_name
ORDER BY learning_courses DESC, exam_attempts DESC
LIMIT 10;

-- 11. 检查是否有可用的课程
SELECT '=== 11. 系统中可用的课程 ===' as step;
SELECT COUNT(*) as total_courses
FROM train_course
WHERE status = '0' AND del_flag = '0';

-- 12. 检查该租户下的课程
SELECT '=== 12. 该租户的课程 ===' as step;
SELECT 
    course_id,
    course_name,
    status,
    create_time
FROM train_course
WHERE tenant_id = (SELECT tenant_id FROM sys_user WHERE user_id = 159)
  AND status = '0' 
  AND del_flag = '0'
ORDER BY create_time DESC
LIMIT 10;

-- 13. 检查用户角色权限
SELECT '=== 13. 用户角色权限 ===' as step;
SELECT 
    r.role_id,
    r.role_name,
    r.role_key,
    r.status
FROM sys_user_role ur
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE ur.user_id = 159;

-- 14. 检查是否有学习计划分配
SELECT '=== 14. 学习计划分配 ===' as step;
SELECT COUNT(*) as plan_count
FROM train_learning_plan_user
WHERE user_id = 159;

-- 15. 检查最近创建的类似用户
SELECT '=== 15. 最近创建的类似用户对比 ===' as step;
SELECT 
    u.user_id,
    u.user_name,
    u.create_time,
    COUNT(DISTINCT ulp.course_id) as courses,
    COUNT(DISTINCT qa.exam_id) as exams
FROM sys_user u
LEFT JOIN train_user_learning_progress ulp ON u.user_id = ulp.user_id
LEFT JOIN train_quiz_attempt qa ON u.user_id = qa.user_id
WHERE u.create_time >= '2026-01-20'
GROUP BY u.user_id, u.user_name, u.create_time
ORDER BY u.create_time DESC
LIMIT 15;
