-- 诊断企业文化题库问题
-- 请在从库执行此脚本

-- 1. 检查表是否存在
SELECT 
    TABLE_NAME, 
    TABLE_ROWS, 
    CREATE_TIME, 
    UPDATE_TIME
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'corporate_culture_question';

-- 2. 检查表结构
DESCRIBE corporate_culture_question;

-- 3. 检查数据总数
SELECT COUNT(*) as total_count FROM corporate_culture_question;

-- 4. 检查租户ID为T001的数据
SELECT COUNT(*) as t001_count 
FROM corporate_culture_question 
WHERE tenant_id = 'T001';

-- 5. 检查状态为0（正常）的数据
SELECT COUNT(*) as active_count 
FROM corporate_culture_question 
WHERE tenant_id = 'T001' AND status = '0';

-- 6. 查看所有租户ID
SELECT DISTINCT tenant_id, COUNT(*) as count 
FROM corporate_culture_question 
GROUP BY tenant_id;

-- 7. 查看T001的分类统计（这是接口实际执行的SQL）
SELECT category as name, COUNT(*) as count
FROM corporate_culture_question
WHERE tenant_id = 'T001' AND status = '0'
GROUP BY category
ORDER BY count DESC;

-- 8. 查看前5条数据样例
SELECT id, tenant_id, category, question_type, question_text, status
FROM corporate_culture_question
WHERE tenant_id = 'T001'
LIMIT 5;

-- 9. 检查是否有status为NULL的数据
SELECT COUNT(*) as null_status_count
FROM corporate_culture_question
WHERE tenant_id = 'T001' AND status IS NULL;

-- 10. 检查是否有status不是'0'的数据
SELECT status, COUNT(*) as count
FROM corporate_culture_question
WHERE tenant_id = 'T001'
GROUP BY status;
