-- 为租户T001添加企业文化配置
-- 复制默认配置(000000)到T001

UPDATE sys_tenant_customization 
SET custom_pages_config = (
    SELECT custom_pages_config 
    FROM sys_tenant_customization 
    WHERE tenant_id = '000000'
)
WHERE tenant_id = 'T001';

-- 验证更新结果
SELECT tenant_id, LENGTH(custom_pages_config) as config_length 
FROM sys_tenant_customization 
WHERE tenant_id IN ('000000', 'T001');
