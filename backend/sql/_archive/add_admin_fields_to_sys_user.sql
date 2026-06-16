-- 为 sys_user 表添加管理员相关字段
-- 执行此脚本前请先备份数据库
-- 适用于 MySQL 5.7+

-- 先查看当前表结构，确认字段是否已存在
-- SHOW COLUMNS FROM sys_user LIKE 'user_type';
-- SHOW COLUMNS FROM sys_user LIKE 'admin_level';
-- SHOW COLUMNS FROM sys_user LIKE 'can_access_admin';

-- 添加 user_type 字段（如果已存在会报错，可忽略）
ALTER TABLE sys_user ADD COLUMN user_type VARCHAR(20) DEFAULT 'user' COMMENT '用户类型（user-普通用户，admin-管理员）';

-- 添加 admin_level 字段（如果已存在会报错，可忽略）
ALTER TABLE sys_user ADD COLUMN admin_level INT DEFAULT 5 COMMENT '管理员级别（0-5，0为最高）';

-- 添加 can_access_admin 字段（如果已存在会报错，可忽略）
ALTER TABLE sys_user ADD COLUMN can_access_admin TINYINT(1) DEFAULT 0 COMMENT '是否可访问管理后台（0-否，1-是）';

-- 如果上面的语法不支持（MySQL 8.0以下版本），请使用以下语句：
-- 先检查字段是否存在，如果不存在则添加

-- 检查并添加 user_type 字段
-- SET @exist := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sys_user' AND column_name = 'user_type');
-- SET @sql := IF(@exist = 0, 'ALTER TABLE sys_user ADD COLUMN user_type VARCHAR(20) DEFAULT ''user'' COMMENT ''用户类型''', 'SELECT 1');
-- PREPARE stmt FROM @sql;
-- EXECUTE stmt;
-- DEALLOCATE PREPARE stmt;

-- 检查并添加 admin_level 字段
-- SET @exist := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sys_user' AND column_name = 'admin_level');
-- SET @sql := IF(@exist = 0, 'ALTER TABLE sys_user ADD COLUMN admin_level INT DEFAULT 5 COMMENT ''管理员级别''', 'SELECT 1');
-- PREPARE stmt FROM @sql;
-- EXECUTE stmt;
-- DEALLOCATE PREPARE stmt;

-- 检查并添加 can_access_admin 字段
-- SET @exist := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sys_user' AND column_name = 'can_access_admin');
-- SET @sql := IF(@exist = 0, 'ALTER TABLE sys_user ADD COLUMN can_access_admin TINYINT(1) DEFAULT 0 COMMENT ''是否可访问管理后台''', 'SELECT 1');
-- PREPARE stmt FROM @sql;
-- EXECUTE stmt;
-- DEALLOCATE PREPARE stmt;

-- 为超级管理员（user_id=1）设置管理员权限
UPDATE sys_user SET user_type = 'admin', admin_level = 0, can_access_admin = 1 WHERE user_id = 1;

-- 验证字段是否添加成功
SELECT user_id, user_name, user_type, admin_level, can_access_admin FROM sys_user WHERE user_id = 1;
