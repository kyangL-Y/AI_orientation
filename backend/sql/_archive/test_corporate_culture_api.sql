-- 测试企业文化题库API能否正确查询数据

-- 1. 模拟后端查询：按租户ID查询（带分页）
SELECT id, tenant_id, category, question_type, 
       LEFT(question_text, 50) as question_preview, 
       correct_answer, difficulty, status, create_time
FROM corporate_culture_question
WHERE tenant_id = 'T001'
ORDER BY sort_order ASC, id DESC
LIMIT 10;

-- 2. 查询分类统计（getCultureCategories接口）
SELECT category as name, COUNT(*) as count
FROM corporate_culture_question
WHERE tenant_id = 'T001' AND status = '0'
GROUP BY category
ORDER BY count DESC;

-- 3. 统计总数
SELECT COUNT(*) as total_count
FROM corporate_culture_question
WHERE tenant_id = 'T001' AND status = '0';

-- 4. 检查是否有status不为'0'的数据
SELECT status, COUNT(*) as count
FROM corporate_culture_question
WHERE tenant_id = 'T001'
GROUP BY status;
