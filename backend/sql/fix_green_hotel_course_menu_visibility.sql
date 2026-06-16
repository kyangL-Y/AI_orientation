-- 绿色饭店课程菜单可见性修复（幂等）
-- 适用场景：
-- 1) 已执行 add_green_hotel_course_menu.sql 但管理端看不到菜单
-- 2) 菜单被挂在错误父级（train / learning 结构不一致）
-- 3) 当前账号角色不是 role_id=1，未拿到菜单权限

SET NAMES utf8mb4;

-- 1) 自动识别最合适的父菜单（优先课程与学习）
SET @parent_learning_path_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE menu_type = 'M' AND path = 'learning'
  ORDER BY menu_id
  LIMIT 1
);

SET @parent_learning_name_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE menu_type = 'M' AND menu_name = '课程与学习'
  ORDER BY menu_id
  LIMIT 1
);

SET @parent_train_path_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE menu_type = 'M' AND path = 'train'
  ORDER BY menu_id
  LIMIT 1
);

SET @parent_train_name_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE menu_type = 'M' AND menu_name IN ('培训中心', '培训管理')
  ORDER BY menu_id
  LIMIT 1
);

SET @target_parent_id = COALESCE(
  @parent_learning_path_id,
  @parent_learning_name_id,
  @parent_train_path_id,
  @parent_train_name_id
);

-- 2) 兜底：若仍无父菜单，则创建一个培训管理目录
INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon,
  create_by, create_time, update_by, update_time, remark
)
SELECT
  '培训管理', 0, 10, 'train', 'ParentView', '', '',
  1, 0, 'M', '0', '0', NULL, 'education',
  'admin', NOW(), '', NULL, '培训管理目录（绿色饭店课程修复脚本自动创建）'
WHERE @target_parent_id IS NULL
  AND NOT EXISTS (
    SELECT 1
    FROM sys_menu
    WHERE menu_type = 'M' AND path = 'train'
  );

SET @target_parent_id = COALESCE(
  @target_parent_id,
  (
    SELECT menu_id
    FROM sys_menu
    WHERE menu_type = 'M' AND path = 'train'
    ORDER BY menu_id
    LIMIT 1
  )
);

-- 3) 定位/创建绿色饭店课程目录菜单
SET @green_menu_id = (
  SELECT menu_id
  FROM sys_menu
  WHERE perms = 'train:greenHotelCourse:list'
  ORDER BY menu_id
  LIMIT 1
);

SET @green_menu_id = COALESCE(
  @green_menu_id,
  (
    SELECT menu_id
    FROM sys_menu
    WHERE menu_type = 'C' AND path = 'greenHotelCourse'
    ORDER BY menu_id
    LIMIT 1
  ),
  (
    SELECT menu_id
    FROM sys_menu
    WHERE menu_type = 'C' AND component = 'train/greenHotelCourse/index'
    ORDER BY menu_id
    LIMIT 1
  ),
  (
    SELECT menu_id
    FROM sys_menu
    WHERE menu_type = 'C' AND menu_name = '绿色饭店课程'
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
  '绿色饭店课程', @target_parent_id, 95, 'greenHotelCourse', 'train/greenHotelCourse/index', '', '',
  1, 0, 'C', '0', '0', 'train:greenHotelCourse:list', 'guide',
  'admin', NOW(), '', NULL, '绿色饭店课程管理菜单'
WHERE @green_menu_id IS NULL
  AND @target_parent_id IS NOT NULL;

SET @green_menu_id = COALESCE(
  @green_menu_id,
  (
    SELECT menu_id
    FROM sys_menu
    WHERE perms = 'train:greenHotelCourse:list'
    ORDER BY menu_id
    LIMIT 1
  )
);

-- 4) 统一修正绿色饭店课程菜单配置，避免历史配置不一致导致不显示
UPDATE sys_menu
SET
  menu_name = '绿色饭店课程',
  parent_id = @target_parent_id,
  order_num = 95,
  path = 'greenHotelCourse',
  component = 'train/greenHotelCourse/index',
  is_frame = 1,
  is_cache = 0,
  menu_type = 'C',
  visible = '0',
  status = '0',
  perms = 'train:greenHotelCourse:list',
  icon = 'guide',
  update_by = 'admin',
  update_time = NOW(),
  remark = '绿色饭店课程管理菜单（自动修复）'
WHERE menu_id = @green_menu_id;

-- 5) 确保按钮权限存在
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

-- 6) 统一按钮权限归属到绿色饭店课程目录
UPDATE sys_menu
SET parent_id = @green_menu_id, update_by = 'admin', update_time = NOW()
WHERE perms IN (
  'train:greenHotelCourse:query',
  'train:greenHotelCourse:add',
  'train:greenHotelCourse:edit',
  'train:greenHotelCourse:remove'
);

-- 7) 赋权：管理员 + 已有课程管理权限的角色（避免只给 role_id=1）
SET @target_parent_parent_id = (
  SELECT parent_id
  FROM sys_menu
  WHERE menu_id = @target_parent_id
  LIMIT 1
);

-- 7.1 给候选角色补目录权限（父级与上级，避免只给子菜单导致导航缺失）
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, t.menu_id
FROM (
  SELECT 1 AS role_id
  UNION
  SELECT DISTINCT srm.role_id
  FROM sys_role_menu srm
  JOIN sys_menu sm ON sm.menu_id = srm.menu_id
  WHERE sm.perms IN ('train:course:list', 'train:deptCourse:list', 'train:plans:list', 'train:path:list', 'train:greenHotelCourse:list')
) r
JOIN (
  SELECT @target_parent_id AS menu_id
  UNION
  SELECT @target_parent_parent_id AS menu_id
) t ON t.menu_id IS NOT NULL AND t.menu_id > 0
LEFT JOIN sys_role_menu exists_rm
  ON exists_rm.role_id = r.role_id
 AND exists_rm.menu_id = t.menu_id
WHERE exists_rm.role_id IS NULL;

-- 7.2 给候选角色补绿色饭店课程菜单与按钮权限
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, sm.menu_id
FROM (
  SELECT 1 AS role_id
  UNION
  SELECT DISTINCT srm.role_id
  FROM sys_role_menu srm
  JOIN sys_menu base ON base.menu_id = srm.menu_id
  WHERE base.perms IN ('train:course:list', 'train:deptCourse:list', 'train:plans:list', 'train:path:list', 'train:greenHotelCourse:list')
) r
JOIN sys_menu sm
  ON sm.perms IN (
    'train:greenHotelCourse:list',
    'train:greenHotelCourse:query',
    'train:greenHotelCourse:add',
    'train:greenHotelCourse:edit',
    'train:greenHotelCourse:remove'
  )
LEFT JOIN sys_role_menu exists_rm
  ON exists_rm.role_id = r.role_id
 AND exists_rm.menu_id = sm.menu_id
WHERE exists_rm.role_id IS NULL;

-- 8) 执行后校验
SELECT
  m.menu_id,
  m.menu_name,
  m.parent_id,
  p.menu_name AS parent_name,
  m.path,
  m.component,
  m.perms,
  m.status,
  m.visible
FROM sys_menu m
LEFT JOIN sys_menu p ON p.menu_id = m.parent_id
WHERE m.perms LIKE 'train:greenHotelCourse:%'
   OR (m.path = 'greenHotelCourse' AND m.menu_type = 'C')
ORDER BY m.menu_type, m.order_num, m.menu_id;

SELECT
  r.role_id,
  r.role_name,
  m.menu_name,
  m.perms
FROM sys_role_menu rm
JOIN sys_role r ON r.role_id = rm.role_id
JOIN sys_menu m ON m.menu_id = rm.menu_id
WHERE m.perms IN (
  'train:greenHotelCourse:list',
  'train:greenHotelCourse:query',
  'train:greenHotelCourse:add',
  'train:greenHotelCourse:edit',
  'train:greenHotelCourse:remove'
)
ORDER BY r.role_id, m.order_num, m.menu_id;
