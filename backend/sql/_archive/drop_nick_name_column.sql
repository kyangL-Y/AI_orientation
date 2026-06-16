-- =============================================
-- 删除 nick_name 列
-- 说明：在确认数据迁移成功后，删除不再使用的 nick_name 列
-- 执行前请确保：
-- 1. 已执行 migrate_nickname_to_username.sql 并验证成功
-- 2. 已备份数据库
-- 3. 前端代码已完全移除对 nick_name 的依赖
-- =============================================

-- 1. 再次确认数据迁移情况
SELECT 
    '迁移前检查' AS '步骤',
    COUNT(*) AS '用户总数',
    SUM(CASE WHEN user_name IS NOT NULL AND user_name != '' THEN 1 ELSE 0 END) AS 'user_name有值的用户数',
    SUM(CASE WHEN nick_name IS NOT NULL AND nick_name != '' THEN 1 ELSE 0 END) AS 'nick_name有值的用户数'
FROM sys_user
WHERE del_flag = '0';

-- 2. 查看即将删除的列的数据（最后确认）
SELECT 
    user_id,
    user_name AS '显示昵称(保留)',
    nick_name AS '原昵称(将删除)',
    email,
    phonenumber
FROM sys_user
WHERE del_flag = '0'
ORDER BY user_id
LIMIT 20;

-- 3. 删除 nick_name 列
-- 注意：此操作不可逆，请确保已备份数据库
ALTER TABLE sys_user DROP COLUMN nick_name;

-- 4. 验证删除结果
-- 查看表结构，确认 nick_name 列已被删除
DESCRIBE sys_user;

-- 5. 验证数据完整性
SELECT 
    '删除后验证' AS '步骤',
    COUNT(*) AS '用户总数',
    SUM(CASE WHEN user_name IS NOT NULL AND user_name != '' THEN 1 ELSE 0 END) AS 'user_name有值的用户数'
FROM sys_user
WHERE del_flag = '0';

-- 6. 查看删除后的用户数据
SELECT 
    user_id,
    user_name AS '显示昵称',
    email AS '邮箱',
    phonenumber AS '手机号',
    create_time AS '创建时间'
FROM sys_user
WHERE del_flag = '0'
ORDER BY user_id
LIMIT 20;

-- =============================================
-- 执行完成提示
-- =============================================
SELECT 
    '✅ nick_name 列已成功删除' AS '执行结果',
    '现在 user_name 是唯一的用户显示名称字段' AS '说明';
