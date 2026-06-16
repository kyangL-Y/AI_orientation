-- 诊断Token认证问题

-- 1. 检查Redis中是否有login_token_key
SELECT 'Checking Redis keys...' as step;

-- 2. 检查用户刘涛是否存在
SELECT 
    user_id,
    user_name,
    nick_name,
    dept_id,
    status,
    del_flag,
    tenant_id
FROM sys_user 
WHERE user_name = '刘涛' OR nick_name = '刘涛';

-- 3. 检查该用户的部门信息
SELECT 
    u.user_id,
    u.user_name,
    u.dept_id,
    d.dept_name,
    d.status as dept_status
FROM sys_user u
LEFT JOIN sys_dept d ON u.dept_id = d.dept_id
WHERE u.user_name = '刘涛' OR u.nick_name = '刘涛';

-- 4. 检查该用户是否有学习记录
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT course_id) as courses_count
FROM train_user_course_progress
WHERE user_id = (SELECT user_id FROM sys_user WHERE user_name = '刘涛' LIMIT 1);

-- 5. 检查该用户是否有考试记录
SELECT 
    COUNT(*) as total_attempts
FROM train_quiz_attempt
WHERE user_id = (SELECT user_id FROM sys_user WHERE user_name = '刘涛' LIMIT 1);

-- Token解析说明
-- JWT Token: eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiLliJjmtIsiLCJsb2dpbl91c2VyX2tleSI6IjkzYzhlY2E2LWIxNzctNGFiMy05MTcyLTk5ZTkxM2Y5ZjAzZiJ9.9SV7t2gmAVPV_fqEU3amG8uP92bKYklIYQgZaSykpIfJEXS1tvkxYe55cw2OnjqH6BYXUfWOn9CxX5PgFomLzQ
-- 
-- Base64解码后的payload部分:
-- {"sub":"刘涛","login_user_key":"93c8eca6-b177-4ab3-9172-99e913f9f03f"}
-- 
-- 这意味着:
-- - 用户名: 刘涛
-- - Redis Key应该是: login_tokens:93c8eca6-b177-4ab3-9172-99e913f9f03f
-- 
-- 需要在Redis中执行:
-- GET login_tokens:93c8eca6-b177-4ab3-9172-99e913f9f03f
-- 
-- 如果返回null，说明token已过期或被清除，需要重新登录
