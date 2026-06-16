-- ========================================
-- 诊断答题记录丢失和权限问题
-- ========================================

-- 1. 检查租户T001的课程情况
SELECT '=== 1. 租户T001的课程 ===' as step;
SELECT course_id, course_name, status, create_time
FROM train_course
WHERE tenant_id = 'T001' AND status = '0' AND del_flag = '0'
ORDER BY create_time DESC
LIMIT 10;

-- 2. 检查租户T001的题目情况
SELECT '=== 2. 租户T001的题目 ===' as step;
SELECT COUNT(*) as question_count
FROM train_question
WHERE tenant_id = 'T001' AND del_flag = '0';

-- 3. 检查最近的答题记录（所有用户）
SELECT '=== 3. 最近的答题记录 ===' as step;
SELECT 
    aar.record_id,
    aar.user_id,
    u.user_name,
    aar.question_id,
    aar.is_correct,
    aar.answer_time,
    aar.create_time
FROM train_answer_attempt_record aar
LEFT JOIN sys_user u ON aar.user_id = u.user_id
WHERE aar.create_time >= '2026-01-20'
ORDER BY aar.create_time DESC
LIMIT 20;

-- 4. 检查用户159的所有可能的答题相关表
SELECT '=== 4. 用户159的答题相关记录 ===' as step;
SELECT COUNT(*) as answer_attempt_count FROM train_answer_attempt_record WHERE user_id = 159;
SELECT COUNT(*) as quiz_attempt_count FROM train_quiz_attempt WHERE user_id = 159;
SELECT COUNT(*) as practice_progress_count FROM train_practice_progress WHERE user_id = 159;

-- 5. 检查会员表结构和数据
SELECT '=== 5. 会员系统 ===' as step;
SHOW TABLES LIKE '%membership%';
SHOW TABLES LIKE '%member%';

-- 6. 检查用户会员状态
SELECT '=== 6. 用户会员状态 ===' as step;
SELECT 
    um.user_id,
    u.user_name,
    um.membership_level,
    um.start_date,
    um.end_date,
    um.status,
    um.create_time
FROM train_user_membership um
LEFT JOIN sys_user u ON um.user_id = u.user_id
WHERE um.user_id = 159;

-- 7. 检查所有新注册用户的会员状态
SELECT '=== 7. 新注册用户会员状态 ===' as step;
SELECT 
    u.user_id,
    u.user_name,
    u.create_time as user_create_time,
    um.membership_level,
    um.status as membership_status,
    um.create_time as membership_create_time
FROM sys_user u
LEFT JOIN train_user_membership um ON u.user_id = um.user_id
WHERE u.create_time >= '2026-01-20'
ORDER BY u.create_time DESC
LIMIT 20;

-- 8. 检查会员等级配置
SELECT '=== 8. 会员等级配置 ===' as step;
SELECT * FROM train_membership_level ORDER BY level_order;

-- 9. 检查答题权限配置（可能在配置表中）
SELECT '=== 9. 系统配置 - 答题权限 ===' as step;
SELECT config_id, config_name, config_key, config_value, remark
FROM sys_config
WHERE config_key LIKE '%answer%' 
   OR config_key LIKE '%quiz%'
   OR config_key LIKE '%membership%'
   OR config_key LIKE '%permission%';

-- 10. 检查用户角色权限
SELECT '=== 10. 用户159的角色权限 ===' as step;
SELECT 
    r.role_id,
    r.role_name,
    r.role_key,
    r.status,
    r.remark
FROM sys_user_role ur
LEFT JOIN sys_role r ON ur.role_id = r.role_id
WHERE ur.user_id = 159;

-- 11. 检查角色菜单权限（答题相关）
SELECT '=== 11. 角色的答题菜单权限 ===' as step;
SELECT 
    m.menu_id,
    m.menu_name,
    m.path,
    m.perms,
    m.visible,
    m.status
FROM sys_role_menu rm
LEFT JOIN sys_menu m ON rm.menu_id = m.menu_id
WHERE rm.role_id IN (SELECT role_id FROM sys_user_role WHERE user_id = 159)
  AND (m.menu_name LIKE '%答题%' 
       OR m.menu_name LIKE '%练习%'
       OR m.menu_name LIKE '%考试%'
       OR m.path LIKE '%answer%'
       OR m.path LIKE '%practice%'
       OR m.path LIKE '%quiz%');

-- 12. 检查是否有答题记录但未提交的情况
SELECT '=== 12. 未提交的答题记录 ===' as step;
SELECT 
    qa.attempt_id,
    qa.user_id,
    u.user_name,
    qa.exam_id,
    qa.status,
    qa.start_time,
    qa.submit_time
FROM train_quiz_attempt qa
LEFT JOIN sys_user u ON qa.user_id = u.user_id
WHERE qa.user_id = 159
   OR (qa.create_time >= '2026-01-20' AND qa.status != 'completed');

-- 13. 检查数据库表的触发器和约束
SELECT '=== 13. 答题记录表的约束 ===' as step;
SHOW CREATE TABLE train_answer_attempt_record;

-- 14. 检查是否有数据插入失败的日志
SELECT '=== 14. 操作日志 - 答题相关 ===' as step;
SELECT 
    oper_id,
    title,
    business_type,
    method,
    oper_name,
    status,
    error_msg,
    oper_time
FROM sys_oper_log
WHERE (title LIKE '%答题%' OR title LIKE '%answer%' OR method LIKE '%answer%')
  AND oper_time >= '2026-01-20'
ORDER BY oper_time DESC
LIMIT 20;

-- 15. 检查企业文化答题记录
SELECT '=== 15. 企业文化答题记录 ===' as step;
SELECT COUNT(*) as culture_answer_count
FROM train_answer_attempt_record
WHERE question_id IN (
    SELECT question_id FROM train_question WHERE question_type = 'corporate_culture'
);
