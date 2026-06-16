-- 隐藏学习评估相关菜单
-- 2026-01-26

USE `hz-vue`;

-- 查找评分模型管理和部门规则配置菜单
SELECT menu_id, menu_name, visible, parent_id 
FROM sys_menu 
WHERE menu_name IN ('评分模型管理', '部门规则配置', '学习评估')
ORDER BY menu_id;

-- 隐藏评分模型管理菜单
UPDATE sys_menu 
SET visible = '1'  -- 1表示隐藏，0表示显示
WHERE menu_name = '评分模型管理';

-- 隐藏部门规则配置菜单
UPDATE sys_menu 
SET visible = '1'
WHERE menu_name = '部门规则配置';

-- 如果有学习评估父菜单，也隐藏
UPDATE sys_menu 
SET visible = '1'
WHERE menu_name = '学习评估' AND menu_type = 'M';

-- 验证结果
SELECT menu_id, menu_name, visible, parent_id 
FROM sys_menu 
WHERE menu_name IN ('评分模型管理', '部门规则配置', '学习评估')
ORDER BY menu_id;
