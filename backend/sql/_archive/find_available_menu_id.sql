-- 查找可用的菜单ID并添加排行榜管理菜单
-- 1. 先查询培训中心下现有的所有菜单ID
SELECT menu_id, menu_name, parent_id, order_num 
FROM sys_menu 
WHERE parent_id = '2000' 
ORDER BY menu_id;

-- 2. 查找可用的菜单ID（从2000开始，找到第一个不存在的ID）
-- 假设我们使用2010和2011作为新的菜单ID

-- 3. 删除可能存在的冲突菜单（如果存在）
DELETE FROM sys_menu WHERE menu_id = '2010' AND menu_name = '排行榜管理';
DELETE FROM sys_menu WHERE menu_id = '2011' AND menu_name = '用户统计管理';

-- 4. 添加排行榜管理菜单（使用ID 2010）
INSERT INTO sys_menu VALUES('2010', '排行榜管理', '2000', '6', 'ranking', 'train/ranking/index', '', '', 1, 0, 'C', '0', '0', 'train:ranking:list', 'chart', 'admin', sysdate(), '', null, '排行榜管理菜单');

-- 5. 添加用户统计管理菜单（使用ID 2011）
INSERT INTO sys_menu VALUES('2011', '用户统计管理', '2000', '7', 'userStatistics', 'train/ranking/userStatistics', '', '', 1, 0, 'C', '0', '0', 'train:ranking:userStats', 'user', 'admin', sysdate(), '', null, '用户统计管理菜单');

-- 6. 添加排行榜管理按钮权限
INSERT INTO sys_menu VALUES('2160', '排行榜查询', '2010', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2161', '排行榜新增', '2010', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2162', '排行榜修改', '2010', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2163', '排行榜删除', '2010', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2164', '排行榜导出', '2010', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:export', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2165', '排行榜刷新', '2010', '6', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:refresh', '#', 'admin', sysdate(), '', null, '');

-- 7. 添加用户统计管理按钮权限
INSERT INTO sys_menu VALUES('2170', '用户统计查询', '2011', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2171', '用户统计新增', '2011', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2172', '用户统计修改', '2011', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2173', '用户统计删除', '2011', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2174', '用户统计导出', '2011', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:export', '#', 'admin', sysdate(), '', null, '');

-- 8. 为超级管理员角色分配权限
INSERT INTO sys_role_menu VALUES ('1', '2010');
INSERT INTO sys_role_menu VALUES ('1', '2011');
INSERT INTO sys_role_menu VALUES ('1', '2160');
INSERT INTO sys_role_menu VALUES ('1', '2161');
INSERT INTO sys_role_menu VALUES ('1', '2162');
INSERT INTO sys_role_menu VALUES ('1', '2163');
INSERT INTO sys_role_menu VALUES ('1', '2164');
INSERT INTO sys_role_menu VALUES ('1', '2165');
INSERT INTO sys_role_menu VALUES ('1', '2170');
INSERT INTO sys_role_menu VALUES ('1', '2171');
INSERT INTO sys_role_menu VALUES ('1', '2172');
INSERT INTO sys_role_menu VALUES ('1', '2173');
INSERT INTO sys_role_menu VALUES ('1', '2174');

-- 9. 为普通角色分配权限
INSERT INTO sys_role_menu VALUES ('2', '2010');
INSERT INTO sys_role_menu VALUES ('2', '2011');
INSERT INTO sys_role_menu VALUES ('2', '2160');
INSERT INTO sys_role_menu VALUES ('2', '2161');
INSERT INTO sys_role_menu VALUES ('2', '2162');
INSERT INTO sys_role_menu VALUES ('2', '2163');
INSERT INTO sys_role_menu VALUES ('2', '2164');
INSERT INTO sys_role_menu VALUES ('2', '2165');
INSERT INTO sys_role_menu VALUES ('2', '2170');
INSERT INTO sys_role_menu VALUES ('2', '2171');
INSERT INTO sys_role_menu VALUES ('2', '2172');
INSERT INTO sys_role_menu VALUES ('2', '2173');
INSERT INTO sys_role_menu VALUES ('2', '2174');

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
