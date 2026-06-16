-- 反向同步：将从库 train_depts_ref 数据同步到主库 sys_dept 表
-- 注意：这是一个谨慎的操作，建议在执行前备份主库数据

-- 1. 备份主库 sys_dept 表（可选）
-- CREATE TABLE sys_dept_backup_$(date +%Y%m%d) AS SELECT * FROM sys_dept;

-- 2. 方式1：完全替换同步（危险操作，仅在确定时使用）
-- 这种方式会删除主库中不在从库的记录
/*
-- 备份
CREATE TABLE sys_dept_backup AS SELECT * FROM sys_dept;

-- 清空主库表（危险！）
-- DELETE FROM sys_dept WHERE dept_id IN (100, 101, 102, 103, 104, 105, 106, 107, 108, 109);

-- 从从库同步数据（需要跨库查询权限）
INSERT INTO sys_dept (dept_id, dept_name, parent_id, ancestors, order_num, status, del_flag, create_time, update_time)
SELECT 
    dept_id, 
    dept_name, 
    parent_id, 
    ancestors,
    dept_id as order_num,  -- 使用 dept_id 作为排序号
    '0' as status,         -- 正常状态
    '0' as del_flag,       -- 未删除
    NOW() as create_time,
    NOW() as update_time
FROM slave_db.train_depts_ref;
*/

-- 3. 方式2：安全的增量同步（推荐）
-- 使用 INSERT ... ON DUPLICATE KEY UPDATE 语法

-- 首先确保从库的数据（手动插入，模拟从 train_depts_ref 获取的数据）
INSERT INTO sys_dept (
    dept_id, dept_name, parent_id, ancestors, order_num, 
    status, del_flag, create_time, update_time
) VALUES 
(100, '华智酒店', 0, '0', 100, '0', '0', NOW(), NOW()),
(101, '总公司', 100, '0,100', 101, '0', '0', NOW(), NOW()),
(102, '分公司', 100, '0,100', 102, '0', '0', NOW(), NOW()),
(103, '研发部门', 101, '0,100,101', 103, '0', '0', NOW(), NOW()),
(104, '市场部门', 101, '0,100,101', 104, '0', '0', NOW(), NOW()),
(105, '测试部门', 101, '0,100,101', 105, '0', '0', NOW(), NOW()),
(106, '财务部门', 101, '0,100,101', 106, '0', '0', NOW(), NOW()),
(107, '运维部门', 101, '0,100,101', 107, '0', '0', NOW(), NOW()),
(108, '市场部门', 102, '0,100,102', 108, '0', '0', NOW(), NOW()),
(109, '财务部门', 102, '0,100,102', 109, '0', '0', NOW(), NOW())
ON DUPLICATE KEY UPDATE
    dept_name = VALUES(dept_name),
    parent_id = VALUES(parent_id),
    ancestors = VALUES(ancestors),
    order_num = VALUES(order_num),
    update_time = NOW();

-- 4. 验证同步结果
SELECT 
    dept_id,
    dept_name,
    parent_id,
    ancestors,
    order_num,
    status,
    del_flag,
    CASE 
        WHEN parent_id = 0 THEN '集团级别'
        WHEN parent_id = 100 THEN '酒店级别'
        WHEN parent_id IN (101, 102) THEN '部门级别'
        ELSE '其他级别'
    END AS level_type,
    create_time,
    update_time
FROM sys_dept 
WHERE dept_id IN (100, 101, 102, 103, 104, 105, 106, 107, 108, 109)
ORDER BY dept_id;

-- 5. 检查数据完整性
-- 验证父子关系是否正确
SELECT 
    p.dept_id as parent_id,
    p.dept_name as parent_name,
    c.dept_id as child_id,
    c.dept_name as child_name
FROM sys_dept p
LEFT JOIN sys_dept c ON p.dept_id = c.parent_id
WHERE p.dept_id IN (100, 101, 102)
ORDER BY p.dept_id, c.dept_id;

-- 6. 如果需要回滚（从备份恢复）
/*
-- 删除同步的数据
DELETE FROM sys_dept WHERE dept_id IN (100, 101, 102, 103, 104, 105, 106, 107, 108, 109);

-- 从备份恢复
INSERT INTO sys_dept SELECT * FROM sys_dept_backup WHERE dept_id IN (100, 101, 102, 103, 104, 105, 106, 107, 108, 109);

-- 删除备份表
DROP TABLE sys_dept_backup;
*/