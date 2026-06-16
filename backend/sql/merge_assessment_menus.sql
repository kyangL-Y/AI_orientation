-- 合并评分模型和部门规则配置菜单

-- 更新评分模型菜单,改为"学习评估管理",指向新的合并页面
UPDATE sys_menu 
SET 
  menu_name = '学习评估管理',
  path = 'assessment-manage',
  component = 'train/assessment/index',
  perms = 'train:assessment:view',
  visible = '0',
  update_time = NOW()
WHERE menu_id = 2318;

-- 隐藏部门规则配置菜单(功能已合并到学习评估管理中)
UPDATE sys_menu 
SET 
  visible = '1',
  update_time = NOW()
WHERE menu_id = 2333;
