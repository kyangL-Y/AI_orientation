-- 删除 sys_user 表的 nick_name 字段
-- 日期: 2026-01-17
-- 说明: 系统不需要 nick_name 字段，统一使用 user_name

USE hz-vue;

-- 删除 nick_name 字段
ALTER TABLE sys_user DROP COLUMN nick_name;

-- 验证字段已删除
SELECT 'nick_name 字段已删除' AS result;
