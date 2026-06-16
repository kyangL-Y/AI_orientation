ALTER TABLE dept_training_question
    ADD COLUMN IF NOT EXISTS owner_dept_id BIGINT NULL COMMENT '归属部门ID' AFTER dept_type,
    ADD COLUMN IF NOT EXISTS visible_scope VARCHAR(32) NOT NULL DEFAULT 'SELF' COMMENT '可见范围: SELF/SELF_AND_CHILDREN/CUSTOM/ALL_TENANT' AFTER owner_dept_id;

CREATE TABLE IF NOT EXISTS dept_training_question_scope (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    question_id BIGINT NOT NULL COMMENT '题目ID',
    dept_id BIGINT NOT NULL COMMENT '可见部门ID',
    tenant_id VARCHAR(20) DEFAULT NULL COMMENT '租户ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_question_dept (question_id, dept_id),
    KEY idx_question_id (question_id),
    KEY idx_dept_id (dept_id),
    KEY idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门题库可见范围授权表';

-- 注意：
-- 1. 历史环境里，部门题库通常在从库 hotel_training，登录用户部门通常在主库 hz-vue。
-- 2. 两边 dept_id 体系不一定一致，直接按部门名批量回填 owner_dept_id 可能导致“自部门题库”再次被筛空。
-- 3. 因此该脚本只补齐结构，不在这里自动回填 owner_dept_id。
-- 4. 如果已确认当前环境的题目归属部门 ID 与登录用户部门 ID 使用同一套主键，再按实际环境单独执行定向回填。
