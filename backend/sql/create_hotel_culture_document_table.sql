-- 酒店文化资料配置表与后台菜单权限
-- 文件本体不走公开 /profile/**，由后端接口鉴权后流式下载。

CREATE TABLE IF NOT EXISTS train_hotel_culture_document (
  document_id BIGINT NOT NULL AUTO_INCREMENT COMMENT '资料ID',
  title VARCHAR(100) NOT NULL COMMENT '资料标题',
  description VARCHAR(255) DEFAULT NULL COMMENT '资料描述',
  category VARCHAR(50) NOT NULL DEFAULT 'hotel_culture' COMMENT '分类',
  tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
  scope_type VARCHAR(20) NOT NULL DEFAULT 'tenant' COMMENT '可见范围：tenant/company/dept',
  scope_dept_id BIGINT DEFAULT NULL COMMENT '范围部门ID',
  scope_dept_name VARCHAR(100) DEFAULT NULL COMMENT '范围部门名称',
  file_name VARCHAR(255) NOT NULL COMMENT '原始文件名',
  stored_name VARCHAR(255) NOT NULL COMMENT '存储文件名',
  file_path VARCHAR(500) NOT NULL COMMENT '受保护相对路径',
  file_size BIGINT DEFAULT NULL COMMENT '文件大小',
  file_type VARCHAR(20) DEFAULT NULL COMMENT '文件类型',
  sort_order INT DEFAULT 0 COMMENT '排序',
  status CHAR(1) DEFAULT '0' COMMENT '状态（0正常 1停用）',
  created_by VARCHAR(64) DEFAULT '' COMMENT '创建者',
  created_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_by VARCHAR(64) DEFAULT '' COMMENT '更新者',
  updated_time DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  remark VARCHAR(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (document_id),
  KEY idx_hotel_doc_visible (tenant_id, category, status, scope_type, scope_dept_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='酒店文化资料配置表';

SET @train_menu_id = (SELECT menu_id FROM sys_menu WHERE path = 'train' AND menu_type = 'M' LIMIT 1);
SET @customization_menu_id = (SELECT menu_id FROM sys_menu WHERE menu_name = '个性化配置' AND path = 'customization' LIMIT 1);

UPDATE sys_menu
SET parent_id = @train_menu_id
WHERE @train_menu_id IS NOT NULL
  AND menu_name = '智囊阁'
  AND path = 'knowledge';

INSERT INTO sys_menu
(menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '酒店文化资料', @customization_menu_id, 4, 'hotelCultureDocument', 'train/hotelCultureDocument/index',
       1, 0, 'C', '0', '0', 'train:hotelCultureDocument:list', 'documentation', 'admin', NOW(), '酒店文化资料管理'
WHERE @customization_menu_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'train:hotelCultureDocument:list');

UPDATE sys_menu
SET parent_id = COALESCE(@customization_menu_id, parent_id),
    order_num = 4,
    component = 'train/hotelCultureDocument/index'
WHERE perms = 'train:hotelCultureDocument:list';

SET @hotel_doc_menu_id = (SELECT menu_id FROM sys_menu WHERE perms = 'train:hotelCultureDocument:list' LIMIT 1);

INSERT INTO sys_menu
(menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '酒店文化资料查询', @hotel_doc_menu_id, 1, '', '', 1, 0, 'F', '0', '0', 'train:hotelCultureDocument:query', '#', 'admin', NOW(), ''
WHERE @hotel_doc_menu_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'train:hotelCultureDocument:query');

INSERT INTO sys_menu
(menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '酒店文化资料新增', @hotel_doc_menu_id, 2, '', '', 1, 0, 'F', '0', '0', 'train:hotelCultureDocument:add', '#', 'admin', NOW(), ''
WHERE @hotel_doc_menu_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'train:hotelCultureDocument:add');

INSERT INTO sys_menu
(menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '酒店文化资料修改', @hotel_doc_menu_id, 3, '', '', 1, 0, 'F', '0', '0', 'train:hotelCultureDocument:edit', '#', 'admin', NOW(), ''
WHERE @hotel_doc_menu_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'train:hotelCultureDocument:edit');

INSERT INTO sys_menu
(menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '酒店文化资料删除', @hotel_doc_menu_id, 4, '', '', 1, 0, 'F', '0', '0', 'train:hotelCultureDocument:remove', '#', 'admin', NOW(), ''
WHERE @hotel_doc_menu_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'train:hotelCultureDocument:remove');

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, m.menu_id
FROM sys_role r
JOIN sys_menu m ON m.perms LIKE 'train:hotelCultureDocument:%'
WHERE r.role_key IN ('admin', 'platform', 'tenant_admin')
  AND NOT EXISTS (
    SELECT 1 FROM sys_role_menu rm
    WHERE rm.role_id = r.role_id AND rm.menu_id = m.menu_id
  );

INSERT INTO sys_tenant_menu (tenant_id, menu_id)
SELECT t.tenant_id, m.menu_id
FROM sys_tenant t
JOIN sys_menu m ON m.perms LIKE 'train:hotelCultureDocument:%'
WHERE t.status = '0'
  AND NOT EXISTS (
    SELECT 1 FROM sys_tenant_menu tm
    WHERE tm.tenant_id = t.tenant_id AND tm.menu_id = m.menu_id
  );
