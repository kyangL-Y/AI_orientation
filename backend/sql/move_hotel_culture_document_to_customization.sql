-- 将“酒店文化资料”管理菜单移动到“个性化配置”下。
-- 可重复执行。

SET @customization_menu_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE menu_name = '个性化配置'
    AND path = 'customization'
    AND menu_type = 'M'
  LIMIT 1
);

UPDATE sys_menu
SET parent_id = @customization_menu_id,
    order_num = 4,
    path = 'hotelCultureDocument',
    component = 'train/hotelCultureDocument/index',
    visible = '0',
    status = '0'
WHERE @customization_menu_id IS NOT NULL
  AND perms = 'train:hotelCultureDocument:list';

