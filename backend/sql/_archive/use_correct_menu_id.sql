-- 使用正确的菜单ID添加排行榜管理菜单
-- 根据查询结果，最大ID是2023，可用ID从2023到2014

-- 1. 使用ID 2024 和 2025 添加菜单（确保不冲突）
-- 删除可能存在的冲突菜单
DELETE FROM sys_menu WHERE menu_id = '2024' AND menu_name = '排行榜管理';
DELETE FROM sys_menu WHERE menu_id = '2025' AND menu_name = '用户统计管理';

-- 2. 添加排行榜管理菜单（使用ID 2024）
INSERT INTO sys_menu VALUES('2024', '排行榜管理', '2000', '8', 'ranking', 'train/ranking/index', '', '', 1, 0, 'C', '0', '0', 'train:ranking:list', 'chart', 'admin', sysdate(), '', null, '排行榜管理菜单');

-- 3. 添加用户统计管理菜单（使用ID 2025）
INSERT INTO sys_menu VALUES('2025', '用户统计管理', '2000', '9', 'userStatistics', 'train/ranking/userStatistics', '', '', 1, 0, 'C', '0', '0', 'train:ranking:userStats', 'user', 'admin', sysdate(), '', null, '用户统计管理菜单');

-- 4. 添加排行榜管理按钮权限
INSERT INTO sys_menu VALUES('2260', '排行榜查询', '2024', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2261', '排行榜新增', '2024', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2262', '排行榜修改', '2024', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2263', '排行榜删除', '2024', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2264', '排行榜导出', '2024', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:export', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2265', '排行榜刷新', '2024', '6', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:refresh', '#', 'admin', sysdate(), '', null, '');

-- 5. 添加用户统计管理按钮权限
INSERT INTO sys_menu VALUES('2270', '用户统计查询', '2025', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2271', '用户统计新增', '2025', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2272', '用户统计修改', '2025', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2273', '用户统计删除', '2025', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2274', '用户统计导出', '2025', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:export', '#', 'admin', sysdate(), '', null, '');

-- 6. 为超级管理员角色分配权限
INSERT INTO sys_role_menu VALUES ('1', '2024');
INSERT INTO sys_role_menu VALUES ('1', '2025');
INSERT INTO sys_role_menu VALUES ('1', '2260');
INSERT INTO sys_role_menu VALUES ('1', '2261');
INSERT INTO sys_role_menu VALUES ('1', '2262');
INSERT INTO sys_role_menu VALUES ('1', '2263');
INSERT INTO sys_role_menu VALUES ('1', '2264');
INSERT INTO sys_role_menu VALUES ('1', '2265');
INSERT INTO sys_role_menu VALUES ('1', '2270');
INSERT INTO sys_role_menu VALUES ('1', '2271');
INSERT INTO sys_role_menu VALUES ('1', '2272');
INSERT INTO sys_role_menu VALUES ('1', '2273');
INSERT INTO sys_role_menu VALUES ('1', '2274');

-- 7. 为普通角色分配权限
INSERT INTO sys_role_menu VALUES ('2', '2024');
INSERT INTO sys_role_menu VALUES ('2', '2025');
INSERT INTO sys_role_menu VALUES ('2', '2260');
INSERT INTO sys_role_menu VALUES ('2', '2261');
INSERT INTO sys_role_menu VALUES ('2', '2262');
INSERT INTO sys_role_menu VALUES ('2', '2263');
INSERT INTO sys_role_menu VALUES ('2', '2264');
INSERT INTO sys_role_menu VALUES ('2', '2265');
INSERT INTO sys_role_menu VALUES ('2', '2270');
INSERT INTO sys_role_menu VALUES ('2', '2271');
INSERT INTO sys_role_menu VALUES ('2', '2272');
INSERT INTO sys_role_menu VALUES ('2', '2273');
INSERT INTO sys_role_menu VALUES ('2', '2274');

-- 8. 查询结果确认
SELECT 
    m1.menu_id,
    m1.menu_name,
    m1.parent_id,
    m1.order_num,
    m1.path,
    m1.component,
    m1.perms,
    m1.icon,
    m1.status,
    m2.menu_name as parent_name
FROM sys_menu m1
LEFT JOIN sys_menu m2 ON m1.parent_id = m2.menu_id
WHERE m1.menu_name IN ('排行榜管理', '用户统计管理')
   OR m1.parent_id IN (
       SELECT menu_id FROM sys_menu WHERE menu_name IN ('排行榜管理', '用户统计管理')
   )
ORDER BY m1.parent_id, m1.order_num;
