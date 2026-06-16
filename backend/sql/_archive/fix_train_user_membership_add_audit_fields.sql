-- 修复 train_user_membership 表：添加审计字段
-- 问题：插入会员记录时报错 Unknown column 'create_by' in 'field list'
-- 解决：添加 create_by, create_time, update_by, update_time 字段

ALTER TABLE train_user_membership
ADD COLUMN create_by VARCHAR(64) DEFAULT '' COMMENT '创建者' AFTER source,
ADD COLUMN create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' AFTER create_by,
ADD COLUMN update_by VARCHAR(64) DEFAULT '' COMMENT '更新者' AFTER create_time,
ADD COLUMN update_time DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER update_by;

-- 验证表结构
DESC train_user_membership;
