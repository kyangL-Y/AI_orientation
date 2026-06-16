-- =============================================
-- 确保学习测评系统V2所需的所有表和字段存在（简化版）
-- 执行库：hotel_training
-- 说明：AI建议直接存储在报告表中，不需要单独的表
-- =============================================

USE hotel_training;

-- =============================================
-- 1. 修复 train_learning_report 表 - 添加 auxiliary_data 和 ai_suggestion 字段
-- =============================================

-- 检查 auxiliary_data 字段是否存在
SET @col_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
      AND TABLE_NAME = 'train_learning_report' 
      AND COLUMN_NAME = 'auxiliary_data'
);

-- 如果不存在则添加
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_learning_report ADD COLUMN auxiliary_data JSON COMMENT ''辅助数据JSON（学习时长、刷题数量等，不参与评分）'' AFTER raw_data',
    'SELECT ''auxiliary_data字段已存在'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查 ai_suggestion 字段是否存在
SET @col_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
      AND TABLE_NAME = 'train_learning_report' 
      AND COLUMN_NAME = 'ai_suggestion'
);

-- 如果不存在则添加
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_learning_report ADD COLUMN ai_suggestion JSON COMMENT ''AI学习建议JSON'' AFTER auxiliary_data',
    'SELECT ''ai_suggestion字段已存在'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为现有数据设置默认值
UPDATE train_learning_report 
SET auxiliary_data = JSON_OBJECT('learning_duration', 0, 'quiz_count', 0)
WHERE auxiliary_data IS NULL;

-- =============================================
-- 2. 修复 train_score_model 表 - 添加 is_default 字段
-- =============================================

SET @col_exists = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'hotel_training' 
      AND TABLE_NAME = 'train_score_model' 
      AND COLUMN_NAME = 'is_default'
);

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_score_model ADD COLUMN is_default CHAR(1) DEFAULT ''0'' COMMENT ''是否默认规则 1=是 0=否'' AFTER status',
    'SELECT ''is_default字段已存在'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 设置第一个模型为默认（如果还没有默认模型）
UPDATE train_score_model 
SET is_default = '1' 
WHERE model_id = (SELECT MIN(model_id) FROM (SELECT model_id FROM train_score_model) AS t)
  AND NOT EXISTS (SELECT 1 FROM train_score_model WHERE is_default = '1');

-- =============================================
-- 3. 创建 train_dept_rule 表（如果不存在）
-- =============================================

CREATE TABLE IF NOT EXISTS train_dept_rule (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    dept_id BIGINT NOT NULL COMMENT '部门ID',
    model_id BIGINT NOT NULL COMMENT '评分规则ID',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    create_by VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY uk_dept_tenant (dept_id, tenant_id),
    INDEX idx_tenant (tenant_id),
    INDEX idx_model (model_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门规则配置表';

-- =============================================
-- 4. 验证所有表和字段
-- =============================================

SELECT '========== 验证结果 ==========' AS '';

-- 检查 auxiliary_data 字段
SELECT 
    IF(COUNT(*) > 0, '✓ auxiliary_data 字段存在', '✗ auxiliary_data 字段缺失') AS check_result
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report' 
  AND COLUMN_NAME = 'auxiliary_data';

-- 检查 ai_suggestion 字段
SELECT 
    IF(COUNT(*) > 0, '✓ ai_suggestion 字段存在', '✗ ai_suggestion 字段缺失') AS check_result
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report' 
  AND COLUMN_NAME = 'ai_suggestion';

-- 检查 is_default 字段
SELECT 
    IF(COUNT(*) > 0, '✓ is_default 字段存在', '✗ is_default 字段缺失') AS check_result
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_score_model' 
  AND COLUMN_NAME = 'is_default';

-- 检查 train_dept_rule 表
SELECT 
    IF(COUNT(*) > 0, '✓ train_dept_rule 表存在', '✗ train_dept_rule 表缺失') AS check_result
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_dept_rule';

-- 显示现有报告数据
SELECT 
    CONCAT('现有报告数据: ', COUNT(*), ' 条') AS info
FROM train_learning_report;

-- 显示默认评分模型
SELECT 
    CONCAT('默认评分模型: ', IFNULL(model_name, '未设置')) AS info
FROM train_score_model 
WHERE is_default = '1'
LIMIT 1;

SELECT '========== 修复完成！请重启后端服务 ==========' AS '';
