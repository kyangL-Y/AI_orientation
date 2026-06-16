-- 添加排行榜管理菜单
-- 首先查询培训中心的菜单ID
SELECT menu_id, menu_name FROM sys_menu WHERE menu_name = '培训中心';

-- 添加排行榜管理菜单（假设培训中心菜单ID为2000，请根据实际情况调整）
INSERT INTO sys_menu (
    menu_name, 
    parent_id, 
    order_num, 
    path, 
    component, 
    query, 
    is_frame, 
    is_cache, 
    menu_type, 
    visible, 
    status, 
    perms, 
    icon, 
    create_by, 
    create_time, 
    update_by, 
    update_time, 
    remark
) VALUES (
    '排行榜管理', 
    (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' AND parent_id != 0 LIMIT 1), 
    8, 
    'ranking', 
    'train/ranking/index', 
    '', 
    1, 
    0, 
    'C', 
    '0', 
    '0', 
    'train:ranking:list', 
    'chart', 
    'admin', 
    NOW(), 
    '', 
    NULL, 
    '排行榜管理菜单'
);

-- 添加排行榜管理的子菜单
-- 1. 排行榜查看
INSERT INTO sys_menu (
    menu_name, 
    parent_id, 
    order_num, 
    path, 
    component, 
    query, 
    is_frame, 
    is_cache, 
    menu_type, 
    visible, 
    status, 
    perms, 
    icon, 
    create_by, 
    create_time, 
    update_by, 
    update_time, 
    remark
) VALUES (
    '排行榜查看', 
    (SELECT menu_id FROM sys_menu WHERE menu_name = '排行榜管理' ORDER BY menu_id DESC LIMIT 1), 
    1, 
    '', 
    '', 
    '', 
    1, 
    0, 
    'F', 
    '0', 
    '0', 
    'train:ranking:query', 
    '#', 
    'admin', 
    NOW(), 
    '', 
    NULL, 
    ''
);

-- 2. 排行榜新增
INSERT INTO sys_menu (
    menu_name, 
    parent_id, 
    order_num, 
    path, 
    component, 
    query, 
    is_frame, 
    is_cache, 
    menu_type, 
    visible, 
    status, 
    perms, 
    icon, 
    create_by, 
    create_time, 
    update_by, 
    update_time, 
    remark
) VALUES (
    '排行榜新增', 
    (SELECT menu_id FROM sys_menu WHERE menu_name = '排行榜管理' ORDER BY menu_id DESC LIMIT 1), 
    2, 
    '', 
    '', 
    '', 
    1, 
    0, 
    'F', 
    '0', 
    '0', 
    'train:ranking:add', 
    '#', 
    'admin', 
    NOW(), 
    '', 
    NULL, 
    ''
);

-- 3. 排行榜修改
INSERT INTO sys_menu (
    menu_name, 
    parent_id, 
    order_num, 
    path, 
    component, 
    query, 
    is_frame, 
    is_cache, 
    menu_type, 
    visible, 
    status, 
    perms, 
    icon, 
    create_by, 
    create_time, 
    update_by, 
    update_time, 
    remark
) VALUES (
    '排行榜修改', 
    (SELECT menu_id FROM sys_menu WHERE menu_name = '排行榜管理' ORDER BY menu_id DESC LIMIT 1), 
    3, 
    '', 
    '', 
    '', 
    1, 
    0, 
    'F', 
    '0', 
    '0', 
    'train:ranking:edit', 
    '#', 
    'admin', 
    NOW(), 
    '', 
    NULL, 
    ''
);

-- 4. 排行榜删除
INSERT INTO sys_menu (
    menu_name, 
    parent_id, 
    order_num, 
    path, 
    component, 
    query, 
    is_frame, 
    is_cache, 
    menu_type, 
    visible, 
    status, 
    perms, 
    icon, 
    create_by, 
    create_time, 
    update_by, 
    update_time, 
    remark
) VALUES (
    '排行榜删除', 
    (SELECT menu_id FROM sys_menu WHERE menu_name = '排行榜管理' ORDER BY menu_id DESC LIMIT 1), 
    4, 
    '', 
    '', 
    '', 
    1, 
    0, 
    'F', 
    '0', 
    '0', 
    'train:ranking:remove', 
    '#', 
    'admin', 
    NOW(), 
    '', 
    NULL, 
    ''
);

-- 5. 排行榜导出
INSERT INTO sys_menu (
    menu_name, 
    parent_id, 
    order_num, 
    path, 
    component, 
    query, 
    is_frame, 
    is_cache, 
    menu_type, 
    visible, 
    status, 
    perms, 
    icon, 
    create_by, 
    create_time, 
    update_by, 
    update_time, 
    remark
) VALUES (
    '排行榜导出', 
    (SELECT menu_id FROM sys_menu WHERE menu_name = '排行榜管理' ORDER BY menu_id DESC LIMIT 1), 
    5, 
    '', 
    '', 
    '', 
    1, 
    0, 
    'F', 
    '0', 
    '0', 
    'train:ranking:export', 
    '#', 
    'admin', 
    NOW(), 
    '', 
    NULL, 
    ''
);

-- 6. 排行榜刷新
INSERT INTO sys_menu (
    menu_name, 
    parent_id, 
    order_num, 
    path, 
    component, 
    query, 
    is_frame, 
    is_cache, 
    menu_type, 
    visible, 
    status, 
    perms, 
    icon, 
    create_by, 
    create_time, 
    update_by, 
    update_time, 
    remark
) VALUES (
    '排行榜刷新', 
    (SELECT menu_id FROM sys_menu WHERE menu_name = '排行榜管理' ORDER BY menu_id DESC LIMIT 1), 
    6, 
    '', 
    '', 
    '', 
    1, 
    0, 
    'F', 
    '0', 
    '0', 
    'train:ranking:refresh', 
    '#', 
    'admin', 
    NOW(), 
    '', 
    NULL, 
    ''
);

-- 添加用户统计管理菜单
INSERT INTO sys_menu (
    menu_name, 
    parent_id, 
    order_num, 
    path, 
    component, 
    query, 
    is_frame, 
    is_cache, 
    menu_type, 
    visible, 
    status, 
    perms, 
    icon, 
    create_by, 
    create_time, 
    update_by, 
    update_time, 
    remark
) VALUES (
    '用户统计管理', 
    (SELECT menu_id FROM sys_menu WHERE menu_name = '培训中心' AND parent_id != 0 LIMIT 1), 
    9, 
    'userStatistics', 
    'train/ranking/userStatistics', 
    '', 
    1, 
    0, 
    'C', 
    '0', 
    '0', 
    'train:ranking:userStats', 
    'user', 
    'admin', 
    NOW(), 
    '', 
    NULL, 
    '用户统计管理菜单'
);

-- 查询结果，确认菜单添加成功
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
