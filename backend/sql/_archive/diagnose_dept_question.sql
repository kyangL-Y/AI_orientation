-- 诊断部门培训题目问题

-- 1. 查看所有部门类型及题目数量
SELECT dept_type, COUNT(*) as count 
FROM dept_training_question 
WHERE status = '0' 
GROUP BY dept_type 
ORDER BY count DESC;

-- 2. 查看表结构
DESC dept_training_question;

-- 3. 查看前10条数据
SELECT id, dept_type, question_text, status 
FROM dept_training_question 
LIMIT 10;

-- 4. 检查是否有空的 dept_type
SELECT COUNT(*) as empty_dept_type_count 
FROM dept_training_question 
WHERE dept_type IS NULL OR dept_type = '';
