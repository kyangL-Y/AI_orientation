-- 手动同步主库 sys_dept 表数据到从库 train_depts_ref 表
-- 这个脚本用于确保从库有最新的部门层级结构数据

-- 1. 清空从库的部门快照表
TRUNCATE TABLE train_depts_ref;

-- 2. 从主库同步数据到从库（假设可以跨库查询，否则需要分步执行）
-- 方式1：如果可以跨库查询
-- INSERT INTO train_depts_ref (dept_id, dept_name, parent_id, ancestors)
-- SELECT dept_id, dept_name, parent_id, ancestors 
-- FROM main_db.sys_dept 
-- WHERE del_flag = '0' AND status = '0';

-- 方式2：手动插入数据（根据您提供的截图数据）
INSERT INTO train_depts_ref (dept_id, dept_name, parent_id, ancestors) VALUES
(100, '华智酒店', 0, '0'),
(101, '总公司', 100, '0,100'),
(102, '分公司', 100, '0,100'),
(103, '研发部门', 101, '0,100,101'),
(104, '市场部门', 101, '0,100,101'),
(105, '测试部门', 101, '0,100,101'),
(106, '财务部门', 101, '0,100,101'),
(107, '运维部门', 101, '0,100,101'),
(108, '市场部门', 102, '0,100,102'),
(109, '财务部门', 102, '0,100,102');

-- 3. 验证同步结果
SELECT 
    dept_id,
    dept_name,
    parent_id,
    ancestors,
    CASE 
        WHEN parent_id = 0 THEN '集团级别'
        WHEN parent_id = 100 THEN '酒店级别'
        WHEN parent_id IN (101, 102) THEN '部门级别'
        ELSE '其他级别'
    END AS level_type
FROM train_depts_ref 
ORDER BY dept_id;

-- 4. 验证酒店级别数据（用于前端酒店选择）
SELECT dept_id AS value, dept_name AS label, parent_id AS parentId
FROM train_depts_ref 
WHERE parent_id = 100  -- 总公司和分公司
ORDER BY dept_id;

-- 5. 验证部门级别数据（用于前端部门选择）
SELECT dept_id AS value, dept_name AS label, parent_id AS parentId
FROM train_depts_ref 
WHERE parent_id IN (101, 102)  -- 各个具体部门
ORDER BY parent_id, dept_id;