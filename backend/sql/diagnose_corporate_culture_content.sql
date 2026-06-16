-- 诊断企业文化内容显示问题
-- 日期: 2026-01-23

USE hz-vue;

-- 1. 检查所有租户的企业文化配置
SELECT 
    tenant_id,
    company_name,
    LENGTH(custom_pages_config) as config_size_bytes,
    ROUND(LENGTH(custom_pages_config) / 1024, 2) as config_size_kb,
    JSON_LENGTH(custom_pages_config) as json_keys,
    CASE 
        WHEN JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml') IS NOT NULL 
        THEN LENGTH(JSON_UNQUOTE(JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml')))
        ELSE 0
    END as culture_html_length,
    create_time,
    update_time
FROM sys_tenant_customization
WHERE custom_pages_config IS NOT NULL
ORDER BY tenant_id;

-- 2. 检查企业文化内容的前500字符（用于预览）
SELECT 
    tenant_id,
    company_name,
    SUBSTRING(JSON_UNQUOTE(JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml')), 1, 500) as culture_preview
FROM sys_tenant_customization
WHERE custom_pages_config IS NOT NULL
  AND JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml') IS NOT NULL;

-- 3. 统计企业文化内容中的标题数量（h2标签）
SELECT 
    tenant_id,
    company_name,
    (LENGTH(JSON_UNQUOTE(JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml'))) 
     - LENGTH(REPLACE(JSON_UNQUOTE(JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml')), '<h2>', ''))) 
     / LENGTH('<h2>') as h2_count
FROM sys_tenant_customization
WHERE custom_pages_config IS NOT NULL
  AND JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml') IS NOT NULL;

-- 4. 检查是否有内容被截断的迹象
SELECT 
    tenant_id,
    CASE 
        WHEN JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml') IS NULL THEN '无内容'
        WHEN LENGTH(JSON_UNQUOTE(JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml'))) = 0 THEN '空内容'
        WHEN JSON_UNQUOTE(JSON_EXTRACT(custom_pages_config, '$.corporateCultureHtml')) NOT LIKE '%创新篇%' THEN '可能被截断'
        ELSE '内容完整'
    END as content_status
FROM sys_tenant_customization
WHERE custom_pages_config IS NOT NULL;
