-- 排行榜管理模块菜单权限配置
-- 按照现有模式添加排行榜管理菜单

-- 1. 排行榜管理主菜单（替换现有的排名查看菜单）
-- 先删除现有的排名查看菜单（如果存在）
DELETE FROM sys_menu WHERE menu_id = '2006' AND menu_name = '排名查看';

-- 添加新的排行榜管理菜单
INSERT INTO sys_menu VALUES('2006', '排行榜管理', '2000', '6', 'ranking', 'train/ranking/index', '', '', 1, 0, 'C', '0', '0', 'train:ranking:list', 'chart', 'admin', sysdate(), '', null, '排行榜管理菜单');

-- 2. 用户统计管理菜单
INSERT INTO sys_menu VALUES('2007', '用户统计管理', '2000', '7', 'userStatistics', 'train/ranking/userStatistics', '', '', 1, 0, 'C', '0', '0', 'train:ranking:userStats', 'user', 'admin', sysdate(), '', null, '用户统计管理菜单');

-- 3. 排行榜管理按钮权限
INSERT INTO sys_menu VALUES('2160', '排行榜查询', '2006', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2161', '排行榜新增', '2006', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2162', '排行榜修改', '2006', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2163', '排行榜删除', '2006', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2164', '排行榜导出', '2006', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:export', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2165', '排行榜刷新', '2006', '6', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:refresh', '#', 'admin', sysdate(), '', null, '');

-- 4. 用户统计管理按钮权限
INSERT INTO sys_menu VALUES('2170', '用户统计查询', '2007', '1', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:query', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2171', '用户统计新增', '2007', '2', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:add', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2172', '用户统计修改', '2007', '3', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:edit', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2173', '用户统计删除', '2007', '4', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:remove', '#', 'admin', sysdate(), '', null, '');
INSERT INTO sys_menu VALUES('2174', '用户统计导出', '2007', '5', '', '', '', '', 1, 0, 'F', '0', '0', 'train:ranking:userStats:export', '#', 'admin', sysdate(), '', null, '');

-- 5. 超级管理员角色权限分配
INSERT INTO sys_role_menu VALUES ('1', '2006');
INSERT INTO sys_role_menu VALUES ('1', '2007');
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

-- 6. 普通角色权限分配
INSERT INTO sys_role_menu VALUES ('2', '2006');
INSERT INTO sys_role_menu VALUES ('2', '2007');
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

-- 7. 查询结果确认
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
