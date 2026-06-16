-- 最终修复：使用更大的菜单ID添加排行榜管理菜单
-- 1. 先查询所有现有的菜单ID，找到最大的ID
SELECT MAX(CAST(menu_id AS UNSIGNED)) as max_menu_id FROM sys_menu;

-- 2. 查询培训中心下现有的所有菜单
SELECT menu_id, menu_name, parent_id, order_num 
FROM sys_menu 
WHERE parent_id = '2000' 
ORDER BY CAST(menu_id AS UNSIGNED);

-- 3. 使用更大的ID（2020和2021）添加菜单
-- 删除可能存在的冲突菜单
DELETE FROM sys_menu WHERE menu_id = '2020' AND menu_name = '排行榜管理';
DELETE FROM sys_menu WHERE menu_id = '2021' AND menu_name = '用户统计管理';

-- 4. 添加排行榜管理菜单（使用ID 2020）
INSERT INTO sys_menu VALUES('2020', '排行榜管理', '2000', '8', 'ranking', 'train/ranking/index', '', '', 1, 0, 'C', '0', '0', 'train:ranking:list', 'chart', 'admin', sysdate(), '', null, '排行榜管理菜单');

-- 5. 添加用户统计管理菜单（使用ID 2021）
INSERT INTO sys_menu VALUES('2021', '用户统计管理', '2000', '9', 'userStatistics', 'train/ranking/userStatistics', '', '', 1, 0, 'C', '0', '0', 'train:ranking:userStats', 'user', 'admin', sysdate(), '', null, '用户统计管理菜单');

-- 6. 添加排行榜管理按钮权限
INSERT INTO sys_menu VALUES('2260', '排行榜查询', '2020', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2261', '排行榜新增', '2020', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2262', '排行榜修改', '2020', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2263', '排行榜删除', '2020', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2264', '排行榜导出', '2020', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:export', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2265', '排行榜刷新', '2020', '6', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:refresh', '#', 'admin', sysdate(), '', null, '');

-- 7. 添加用户统计管理按钮权限
INSERT INTO sys_menu VALUES('2270', '用户统计查询', '2021', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2271', '用户统计新增', '2021', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2272', '用户统计修改', '2021', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2273', '用户统计删除', '2021', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2274', '用户统计导出', '2021', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:export', '#', 'admin', sysdate(), '', null, '');

-- 8. 为超级管理员角色分配权限
INSERT INTO sys_role_menu VALUES ('1', '2020');
INSERT INTO sys_role_menu VALUES ('1', '2021');
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

-- 9. 为普通角色分配权限
INSERT INTO sys_role_menu VALUES ('2', '2020');
INSERT INTO sys_role_menu VALUES ('2', '2021');
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

-- 10. 查询结果确认
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
