SET NAMES utf8mb4;

-- 部门题库分类级授权表
-- 说明：
-- 1. 此表用于按 dept_type 统一配置“哪些部门可以看到哪些部门题库”
-- 2. 题库数据通常在 hotel_training，从库执行即可
-- 3. 唯一键保证同一租户、同一题库分类、同一可见部门不会重复

CREATE TABLE IF NOT EXISTS dept_question_bank_scope (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    tenant_id VARCHAR(20) NOT NULL DEFAULT '000000' COMMENT '租户ID',
    dept_type VARCHAR(100) NOT NULL COMMENT '题库分类',
    visible_dept_id BIGINT NOT NULL COMMENT '可见部门ID',
    create_by VARCHAR(64) DEFAULT '' COMMENT '创建人',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_by VARCHAR(64) DEFAULT '' COMMENT '更新人',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_tenant_dept_type_visible_dept (tenant_id, dept_type, visible_dept_id),
    KEY idx_tenant_dept_type (tenant_id, dept_type),
    KEY idx_visible_dept_id (visible_dept_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门题库分类级可见范围配置表';

-- 可选核对
SELECT dept_type, COUNT(*) AS question_count
FROM dept_training_question
WHERE status = '0'
GROUP BY dept_type
ORDER BY question_count DESC, dept_type ASC;
