-- 更新判断题的选项，确保选项A="正确"，选项B="错误"
UPDATE train_question 
SET option_a = '正确', option_b = '错误', option_c = NULL, option_d = NULL
WHERE question_type = '判断题';

-- 插入一些部门数据到 train_depts_ref 表（如果不存在）
INSERT IGNORE INTO train_depts_ref (dept_id, dept_name, parent_id, ancestors) VALUES
(100, '总公司', 0, '0'),
(101, '深圳总公司', 100, '0,100'),
(102, '长沙分公司', 100, '0,100'),
(103, '研发部门', 101, '0,100,101'),
(104, '市场部门', 101, '0,100,101'),
(105, '测试部门', 101, '0,100,101'),
(106, '财务部门', 101, '0,100,101'),
(107, '运维部门', 101, '0,100,101'),
(108, '市场部门', 102, '0,100,102'),
(109, '财务部门', 102, '0,100,102');