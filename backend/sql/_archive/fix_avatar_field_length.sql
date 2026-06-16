-- 修改头像和封面照片字段为LONGTEXT类型，支持更大的数据
USE `hz-vue`;

-- 修改avatar字段为LONGTEXT
ALTER TABLE sys_user MODIFY COLUMN avatar LONGTEXT COMMENT '头像';

-- 修改cover_photo字段为LONGTEXT  
ALTER TABLE sys_user MODIFY COLUMN cover_photo LONGTEXT COMMENT '封面照片';

-- 查看修改结果
SHOW COLUMNS FROM sys_user WHERE Field IN ('avatar', 'cover_photo');
