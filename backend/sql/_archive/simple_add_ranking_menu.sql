-- 简化版：添加排行榜管理菜单
-- 假设培训中心菜单ID为2000（请根据实际情况调整）

-- 1. 添加排行榜管理主菜单
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
    remark
) VALUES (
    '排行榜管理', 
    2000,  -- 培训中心菜单ID，请根据实际情况调整
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
    '排行榜管理菜单'
);

-- 2. 添加用户统计管理主菜单
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
    remark
) VALUES (
    '用户统计管理', 
    2000,  -- 培训中心菜单ID，请根据实际情况调整
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
    '用户统计管理菜单'
);

-- 查询培训中心的菜单ID（执行前先运行这个查询）
-- SELECT menu_id, menu_name FROM sys_menu WHERE menu_name = '培训中心' AND parent_id != 0;
