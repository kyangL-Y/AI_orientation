ALTER TABLE sys_tenant
    ADD COLUMN membership_limit INT NULL DEFAULT NULL COMMENT '租户会员数量上限，空或0表示不限' AFTER auto_membership_duration;
