-- ============================================================
-- 增量迁移脚本：hz-vue 数据库
-- 生成时间：2026-02-26
-- 用途：将标准 RuoYi 3.x 数据库升级为培训系统所需结构
-- 使用前请先备份：mysqldump -u root -p hz-vue > hz-vue-backup.sql
-- ============================================================

-- ---------- 1. sys_user 新增字段 ----------
ALTER TABLE sys_user
  ADD COLUMN IF NOT EXISTS tenant_id varchar(64) DEFAULT NULL COMMENT '租户编号' AFTER user_id,
  ADD COLUMN IF NOT EXISTS admin_level int DEFAULT 0 COMMENT '管理员级别' AFTER user_type,
  ADD COLUMN IF NOT EXISTS can_access_admin tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否可访问管理后台' AFTER admin_level,
  ADD COLUMN IF NOT EXISTS cover_photo varchar(255) DEFAULT NULL COMMENT '封面照片' AFTER avatar,
  ADD COLUMN IF NOT EXISTS position varchar(100) DEFAULT NULL COMMENT '职位名称' AFTER cover_photo;

-- 确保 admin 账户有后台访问权限
UPDATE sys_user SET admin_level=0, can_access_admin=1 WHERE user_name='admin';

-- ---------- 2. sys_dept 新增字段 ----------
ALTER TABLE sys_dept
  ADD COLUMN IF NOT EXISTS tenant_id varchar(64) DEFAULT NULL COMMENT '租户编号' AFTER dept_id;

-- ---------- 3. sys_menu 新增字段 ----------
ALTER TABLE sys_menu
  ADD COLUMN IF NOT EXISTS min_admin_level int DEFAULT 0 COMMENT '最低管理员级别' AFTER perms;

-- ---------- 4. sys_role 新增字段 ----------
ALTER TABLE sys_role
  ADD COLUMN IF NOT EXISTS role_level int DEFAULT 0 COMMENT '角色层级' AFTER data_scope;

-- ---------- 5. sys_notice 新增字段 ----------
ALTER TABLE sys_notice
  ADD COLUMN IF NOT EXISTS tenant_id varchar(64) DEFAULT NULL COMMENT '租户编号' AFTER notice_id,
  ADD COLUMN IF NOT EXISTS dept_id bigint DEFAULT NULL COMMENT '部门ID' AFTER tenant_id,
  ADD COLUMN IF NOT EXISTS scope varchar(20) DEFAULT NULL COMMENT '通知范围' AFTER dept_id;

-- ---------- 6. sys_logininfor 新增字段 ----------
ALTER TABLE sys_logininfor
  ADD COLUMN IF NOT EXISTS tenant_id varchar(64) DEFAULT NULL COMMENT '租户编号' AFTER info_id;

-- ---------- 7. sys_oper_log 新增字段 ----------
ALTER TABLE sys_oper_log
  ADD COLUMN IF NOT EXISTS tenant_id varchar(64) DEFAULT NULL COMMENT '租户编号' AFTER oper_id;

-- PLACEHOLDER_INDEXES_AND_MENUS
