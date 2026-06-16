-- 为 sys_tenant 表增加团队自动开通会员配置字段
ALTER TABLE sys_tenant
  ADD COLUMN auto_membership_enabled    CHAR(1)     DEFAULT '0' COMMENT '是否自动开通会员(0否1是)',
  ADD COLUMN auto_membership_level_code VARCHAR(20) DEFAULT NULL COMMENT '自动开通的会员等级代码(basic/premium/vip)',
  ADD COLUMN auto_membership_duration   INT         DEFAULT NULL COMMENT '自动开通的会员时长(天)';
