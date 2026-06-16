-- 诊断企业文化内容丢失问题

-- 1. 检查 sys_tenant_customization 表结构
SHOW CREATE TABLE sys_tenant_customization;

-- 2. 查看所有租户的定制化配置
SELECT 
    id,
    tenant_id,
    company_name,
    enable_custom_pages,
    LENGTH(custom_pages_config) as config_length,
    SUBSTRING(custom_pages_config, 1, 200) as config_preview,
    create_time,
    update_time
FROM sys_tenant_customization
ORDER BY tenant_id;

-- 3. 检查是否有企业文化HTML内容
SELECT 
    tenant_id,
    company_name,
    CASE 
        WHEN custom_pages_config LIKE '%corporateCultureHtml%' THEN 'YES'
        ELSE 'NO'
    END as has_culture_html,
    LENGTH(custom_pages_config) as config_size
FROM sys_tenant_customization;

-- 4. 查看具体的企业文化配置（如果存在）
SELECT 
    tenant_id,
    custom_pages_config
FROM sys_tenant_customization
WHERE custom_pages_config LIKE '%corporateCultureHtml%'
LIMIT 1;
