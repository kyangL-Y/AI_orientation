-- 删除重复的培训中心菜单清理脚本
-- 这个脚本会保留menu_id=2000的培训中心菜单，删除其他重复的

-- 1. 首先查看当前所有培训中心相关的菜单
SELECT menu_id, menu_name, parent_id, order_num, path, create_time 
FROM sys_menu 
WHERE menu_name LIKE '%培训%' OR path LIKE '%train%'
ORDER BY menu_id;

-- 2. 删除重复的培训中心一级菜单（保留menu_id=2000）
DELETE FROM sys_menu 
WHERE menu_name = '培训中心' 
AND menu_id != 2000;

-- 3. 删除可能重复的培训中心子菜单（保留2000开头的）
DELETE FROM sys_menu 
WHERE (menu_name LIKE '%刷题%' OR menu_name LIKE '%考试%' OR menu_name LIKE '%测评%' OR menu_name LIKE '%认证%' OR menu_name LIKE '%奖励%' OR menu_name LIKE '%排名%')
AND menu_id NOT BETWEEN 2000 AND 2999;

-- 4. 删除可能重复的角色菜单关联
DELETE FROM sys_role_menu 
WHERE menu_id IN (
    SELECT menu_id FROM sys_menu 
    WHERE menu_name = '培训中心' AND menu_id != 2000
);

-- 5. 确保只有一个培训中心菜单存在
SELECT COUNT(*) as training_center_count 
FROM sys_menu 
WHERE menu_name = '培训中心';

-- 6. 验证清理结果
SELECT menu_id, menu_name, parent_id, order_num, path 
FROM sys_menu 
WHERE parent_id = 0 
ORDER BY order_num;