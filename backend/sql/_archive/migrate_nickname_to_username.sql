-- =============================================
-- 数据迁移脚本：将 nick_name 迁移到 user_name
-- 说明：将用户的昵称从 nick_name 字段迁移到 user_name 字段
-- 执行前请备份数据库！
-- =============================================

-- 1. 备份当前数据（可选，建议在执行前手动备份整个数据库）
-- CREATE TABLE sys_user_backup_20251202 AS SELECT * FROM sys_user;

-- 2. 更新策略：
--    - 如果 nick_name 有值且不为空，则将其迁移到 user_name
--    - 如果 nick_name 为空，则根据 email 或 phonenumber 生成默认 user_name
--    - 保留原有的 nick_name 数据（向后兼容）

-- 3. 执行迁移
UPDATE sys_user
SET user_name = CASE
    -- 如果 nick_name 有值且不为空，使用 nick_name
    WHEN nick_name IS NOT NULL AND nick_name != '' AND nick_name != 'NULL' THEN nick_name
    
    -- 如果 nick_name 为空但有 email，使用 email 前缀
    WHEN (nick_name IS NULL OR nick_name = '' OR nick_name = 'NULL') 
         AND email IS NOT NULL AND email != '' THEN SUBSTRING_INDEX(email, '@', 1)
    
    -- 如果 nick_name 为空但有 phonenumber，使用"用户"加后4位
    WHEN (nick_name IS NULL OR nick_name = '' OR nick_name = 'NULL') 
         AND phonenumber IS NOT NULL AND phonenumber != '' THEN CONCAT('用户', RIGHT(phonenumber, 4))
    
    -- 其他情况保持原 user_name 不变
    ELSE user_name
END
WHERE del_flag = '0';  -- 只更新未删除的用户

-- 4. 验证迁移结果
-- 查看迁移后的数据
SELECT 
    user_id,
    user_name AS '新用户名(显示昵称)',
    nick_name AS '原昵称',
    email AS '邮箱',
    phonenumber AS '手机号',
    CASE 
        WHEN nick_name IS NOT NULL AND nick_name != '' THEN '从昵称迁移'
        WHEN email IS NOT NULL AND email != '' THEN '从邮箱生成'
        WHEN phonenumber IS NOT NULL AND phonenumber != '' THEN '从手机号生成'
        ELSE '保持原值'
    END AS '迁移来源'
FROM sys_user
WHERE del_flag = '0'
ORDER BY user_id;

-- 5. 统计迁移情况
SELECT 
    '总用户数' AS '统计项',
    COUNT(*) AS '数量'
FROM sys_user
WHERE del_flag = '0'

UNION ALL

SELECT 
    '从昵称迁移' AS '统计项',
    COUNT(*) AS '数量'
FROM sys_user
WHERE del_flag = '0' 
  AND nick_name IS NOT NULL 
  AND nick_name != '' 
  AND nick_name != 'NULL'

UNION ALL

SELECT 
    '从邮箱生成' AS '统计项',
    COUNT(*) AS '数量'
FROM sys_user
WHERE del_flag = '0' 
  AND (nick_name IS NULL OR nick_name = '' OR nick_name = 'NULL')
  AND email IS NOT NULL 
  AND email != ''

UNION ALL

SELECT 
    '从手机号生成' AS '统计项',
    COUNT(*) AS '数量'
FROM sys_user
WHERE del_flag = '0' 
  AND (nick_name IS NULL OR nick_name = '' OR nick_name = 'NULL')
  AND (email IS NULL OR email = '')
  AND phonenumber IS NOT NULL 
  AND phonenumber != '';

-- =============================================
-- 可选：如果确认迁移成功且不需要向后兼容，可以清空 nick_name
-- 注意：执行此步骤前请确保前端已完全移除对 nick_name 的依赖
-- =============================================
-- UPDATE sys_user SET nick_name = NULL WHERE del_flag = '0';

-- =============================================
-- 可选：如果要完全删除 nick_name 列（不推荐，建议保留以向后兼容）
-- =============================================
-- ALTER TABLE sys_user DROP COLUMN nick_name;
