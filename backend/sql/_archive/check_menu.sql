-- 查询后台菜单中的学习计划相关菜单
USE `hz-vue`;

SELECT 
    menu_id AS '菜单ID',
    menu_name AS '菜单名称',
    parent_id AS '父菜单ID',
    order_num AS '排序',
    path AS '路由地址',
    component AS '组件路径',
    perms AS '权限标识',
    visible AS '是否显示',
    status AS '状态'
FROM sys_menu 
WHERE menu_name LIKE '%学习%' 
   OR path LIKE '%learning%'
   OR component LIKE '%learning%'
   OR menu_name LIKE '%培训%'
ORDER BY parent_id, order_num;

