-- 检查企业文化配置是否存在
-- 问题诊断：用户端企业文化内容显示为空

-- 1. 查看所有租户的配置情况
SELECT 
    tenant_id,
    company_name,
    enable_custom_pages,
    CASE 
        WHEN custom_pages_config IS NULL THEN 'NULL'
        WHEN custom_pages_config LIKE '%corporateCultureHtml%' THEN 'HAS_CULTURE'
        ELSE 'NO_CULTURE'
    END as culture_status,
    LENGTH(custom_pages_config) as config_size
FROM sys_tenant_customization
ORDER BY tenant_id;

-- 2. 查看默认租户(000000)的企业文化内容长度
SELECT 
    tenant_id,
    LENGTH(JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml')) as culture_html_length
FROM sys_tenant_customization
WHERE tenant_id = '000000';

-- 诊断结果：
-- 数据库中存在企业文化内容（约4685字符）
-- 内容包含在 custom_pages_config 字段的 JSON 中
-- 字段名为：corporateCultureHtml
