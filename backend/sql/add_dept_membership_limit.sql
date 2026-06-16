ALTER TABLE sys_dept
    ADD COLUMN membership_limit INT NULL DEFAULT NULL COMMENT '部门会员数量上限，空或0表示不单独限制' AFTER auto_membership_duration;
