-- 在后端实际连接的数据库实例上添加字段
-- 服务器: bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com:27608
-- 数据库: hotel_training
-- 用户名: root
-- 密码: 使用环境变量或安全凭据管理，不要写入脚本

USE `hotel_training`;

-- 检查当前连接的服务器信息（用于确认）
SELECT 
    DATABASE() AS current_database,
    @@hostname AS server_hostname,
    @@port AS server_port;

-- 添加path_id字段
ALTER TABLE `learning_plans` 
ADD COLUMN `path_id` bigint(20) NULL COMMENT '所属学习路径ID' AFTER `plan_id`;

-- 添加is_required字段
ALTER TABLE `learning_plans` 
ADD COLUMN `is_required` tinyint(1) DEFAULT 0 COMMENT '是否必修：1=必修，0=选修' AFTER `path_id`;

-- 添加索引
ALTER TABLE `learning_plans` 
ADD INDEX `idx_path_id` (`path_id`);

-- 验证字段是否添加成功
DESCRIBE `learning_plans`;


