-- 为sys_user表添加封面照片字段
-- 如果字段已存在，会忽略错误

ALTER TABLE sys_user ADD COLUMN cover_photo TEXT COMMENT '封面照片';
