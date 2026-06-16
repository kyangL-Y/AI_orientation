-- 修复 sys_user 表缺少 nick_name 字段的问题
-- 日期: 2026-01-17
-- 说明: 排行榜查询需要 nick_name 字段，但当前数据库中缺少此字段

USE hz-vue;

-- 检查并添加 nick_name 字段
ALTER TABLE sys_user 
ADD COLUMN nick_name VARCHAR(30) NULL COMMENT '用户昵称' AFTER user_name;

-- 将现有用户的 user_name 复制到 nick_name 作为默认值
UPDATE sys_user SET nick_name = user_name WHERE nick_name IS NULL;

-- 验证字段是否添加成功
SELECT 'nick_name 字段添加成功' AS result;
