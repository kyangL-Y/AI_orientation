-- 绿色饭店课程管理菜单（幂等）
-- 用途：为管理端新增“绿色饭店课程管理”页面入口及按钮权限

SET NAMES utf8mb4;

-- 1) 定位培训父菜单（优先 path=train）
SET @train_parent_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE path = 'train' AND menu_type = 'M'
  LIMIT 1
);

-- 2) 若不存在培训父菜单则创建一个
INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '培训管理', 0, 10, 'train', NULL, '', '',
  1, 0, 'M', '0', '0', '', 'education',
  'admin', NOW(), '', NULL, '培训管理目录'
WHERE @train_parent_id IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE path = 'train' AND menu_type = 'M'
  );

SET @train_parent_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE path = 'train' AND menu_type = 'M'
  LIMIT 1
);

-- 3) 新增绿色饭店课程管理菜单
INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '绿色饭店课程', @train_parent_id, 95, 'greenHotelCourse', 'train/greenHotelCourse/index', '', '',
  1, 0, 'C', '0', '0', 'train:greenHotelCourse:list', 'guide',
  'admin', NOW(), '', NULL, '绿色饭店课程管理菜单'
WHERE @train_parent_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE perms = 'train:greenHotelCourse:list'
  );

SET @green_menu_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE perms = 'train:greenHotelCourse:list'
  LIMIT 1
);

-- 4) 新增按钮权限
INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '绿色饭店课程查询', @green_menu_id, 1, '#', '', '', '',
  1, 0, 'F', '0', '0', 'train:greenHotelCourse:query', '#',
  'admin', NOW(), '', NULL, ''
WHERE @green_menu_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE perms = 'train:greenHotelCourse:query'
  );

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '绿色饭店课程新增', @green_menu_id, 2, '#', '', '', '',
  1, 0, 'F', '0', '0', 'train:greenHotelCourse:add', '#',
  'admin', NOW(), '', NULL, ''
WHERE @green_menu_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE perms = 'train:greenHotelCourse:add'
  );

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '绿色饭店课程修改', @green_menu_id, 3, '#', '', '', '',
  1, 0, 'F', '0', '0', 'train:greenHotelCourse:edit', '#',
  'admin', NOW(), '', NULL, ''
WHERE @green_menu_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE perms = 'train:greenHotelCourse:edit'
  );

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '绿色饭店课程删除', @green_menu_id, 4, '#', '', '', '',
  1, 0, 'F', '0', '0', 'train:greenHotelCourse:remove', '#',
  'admin', NOW(), '', NULL, ''
WHERE @green_menu_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE perms = 'train:greenHotelCourse:remove'
  );

-- 5) 赋权给管理员角色（role_id=1）
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 1, sm.menu_id
FROM sys_menu sm
WHERE sm.perms IN (
  'train:greenHotelCourse:list',
  'train:greenHotelCourse:query',
  'train:greenHotelCourse:add',
  'train:greenHotelCourse:edit',
  'train:greenHotelCourse:remove'
)
AND NOT EXISTS (
  SELECT 1 FROM sys_role_menu srm WHERE srm.role_id = 1 AND srm.menu_id = sm.menu_id
);

SELECT menu_id, menu_name, parent_id, perms, component
FROM sys_menu
WHERE perms LIKE 'train:greenHotelCourse:%'
   OR (path = 'greenHotelCourse' AND component = 'train/greenHotelCourse/index')
ORDER BY menu_id;
