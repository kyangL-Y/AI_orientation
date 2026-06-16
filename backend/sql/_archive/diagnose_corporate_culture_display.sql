-- 诊断企业文化题库显示问题

-- 1. 检查数据总数
SELECT '数据总数' as check_item, COUNT(*) as result FROM corporate_culture_question;

-- 2. 检查租户分布
SELECT '租户分布' as check_item, tenant_id, COUNT(*) as count 
FROM corporate_culture_question 
GROUP BY tenant_id;

-- 3. 检查状态分布
SELECT '状态分布' as check_item, status, COUNT(*) as count 
FROM corporate_culture_question 
GROUP BY status;

-- 4. 检查分类分布
SELECT '分类分布' as check_item, category, COUNT(*) as count 
FROM corporate_culture_question 
WHERE tenant_id = 'T001' AND status = '0'
GROUP BY category;

-- 5. 查看前5条数据
SELECT '前5条数据' as check_item, id, tenant_id, category, question_type, 
       LEFT(question_text, 50) as question_preview, status
FROM corporate_culture_question 
LIMIT 5;

-- 6. 检查当前用户的租户ID
SELECT '当前用户租户' as check_item, user_id, user_name, tenant_id 
FROM hz-vue.sys_user 
WHERE user_id = 100;
