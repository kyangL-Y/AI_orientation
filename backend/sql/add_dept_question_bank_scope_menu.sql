SET NAMES utf8mb4;

-- 部门题库权限配置菜单（幂等）

SET @train_parent_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE menu_type = 'M' AND path = 'train'
  ORDER BY menu_id
  LIMIT 1
);

SET @train_parent_id = COALESCE(
  @train_parent_id,
  (
    SELECT menu_id
    FROM sys_menu
    WHERE menu_type = 'M' AND menu_name IN ('培训管理', '培训中心')
    ORDER BY menu_id
    LIMIT 1
  )
);

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '培训管理', 0, 10, 'train', 'ParentView', '', '',
  1, 0, 'M', '0', '0', '', 'education',
  'admin', NOW(), '', NULL, '培训管理目录（部门题库权限配置自动创建）'
WHERE @train_parent_id IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE menu_type = 'M' AND path = 'train'
  );

SET @train_parent_id = COALESCE(
  @train_parent_id,
  (
    SELECT menu_id
    FROM sys_menu
    WHERE menu_type = 'M' AND path = 'train'
    ORDER BY menu_id
    LIMIT 1
  )
);

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '部门题库权限', @train_parent_id, 96, 'deptQuestionBankScope', 'train/deptQuestionBankScope/index', '', '',
  1, 0, 'C', '0', '0', 'train:deptQuestionBankScope:list', 'lock',
  'admin', NOW(), '', NULL, '部门题库权限配置页面'
WHERE @train_parent_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE perms = 'train:deptQuestionBankScope:list'
  );

SET @menu_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE perms = 'train:deptQuestionBankScope:list'
  ORDER BY menu_id
  LIMIT 1
);

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '部门题库权限查询', @menu_id, 1, '#', '', '', '',
  1, 0, 'F', '0', '0', 'train:deptQuestionBankScope:query', '#',
  'admin', NOW(), '', NULL, ''
WHERE @menu_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE perms = 'train:deptQuestionBankScope:query'
  );

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '部门题库权限编辑', @menu_id, 2, '#', '', '', '',
  1, 0, 'F', '0', '0', 'train:deptQuestionBankScope:edit', '#',
  'admin', NOW(), '', NULL, ''
WHERE @menu_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE perms = 'train:deptQuestionBankScope:edit'
  );

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, sm.menu_id
FROM sys_menu sm
WHERE sm.perms IN (
  'train:deptQuestionBankScope:list',
  'train:deptQuestionBankScope:query',
  'train:deptQuestionBankScope:edit'
)
AND NOT EXISTS (
  SELECT 1 FROM sys_role_menu srm WHERE srm.role_id = 1 AND srm.menu_id = sm.menu_id
);

SELECT menu_id, menu_name, parent_id, perms, component
FROM sys_menu
WHERE perms LIKE 'train:deptQuestionBankScope:%'
   OR (path = 'deptQuestionBankScope' AND component = 'train/deptQuestionBankScope/index')
ORDER BY menu_id;
