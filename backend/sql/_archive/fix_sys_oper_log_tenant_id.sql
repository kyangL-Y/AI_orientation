-- 修复 sys_oper_log 表的 tenant_id 字段类型
-- 从 INT 改为 VARCHAR(20)，以支持字符串类型的租户ID

USE hz-vue;

-- 修改字段类型
ALTER TABLE sys_oper_log 
MODIFY COLUMN tenant_id VARCHAR(20) COMMENT '租户ID';

SELECT '修复完成！tenant_id 字段已改为 VARCHAR(20)' AS message;
