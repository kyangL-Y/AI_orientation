-- =============================================
-- 学习测评系统升级脚本（V1 -> V2）
-- 执行库：hotel_training
-- 说明：保留旧数据，升级表结构到V2版本
-- =============================================

USE hotel_training;

-- =============================================
-- 1. 升级 train_learning_report 表
-- =============================================

-- 检查并添加 auxiliary_data 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report' 
  AND COLUMN_NAME = 'auxiliary_data';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_learning_report ADD COLUMN auxiliary_data JSON COMMENT ''辅助数据JSON（学习时长、刷题数量等，不参与评分）'' AFTER dimension_scores',
    'SELECT ''auxiliary_data字段已存在，跳过'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =============================================
-- 2. 升级 train_score_model 表
-- =============================================

-- 检查并删除 model_code 字段（如果存在）
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_score_model' 
  AND COLUMN_NAME = 'model_code';

SET @sql = IF(@col_exists > 0,
    'ALTER TABLE train_score_model DROP COLUMN model_code',
    'SELECT ''model_code字段不存在，跳过'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 is_default 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_score_model' 
  AND COLUMN_NAME = 'is_default';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_score_model ADD COLUMN is_default CHAR(1) DEFAULT ''0'' COMMENT ''是否默认规则 1=是 0=否'' AFTER status',
    'SELECT ''is_default字段已存在，跳过'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =============================================
-- 3. 创建 train_dept_rule 表（如果不存在）
-- =============================================

CREATE TABLE IF NOT EXISTS train_dept_rule (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    dept_id BIGINT NOT NULL COMMENT '部门ID',
    model_id BIGINT NOT NULL COMMENT '评分规则ID',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY uk_dept_tenant (dept_id, tenant_id),
    INDEX idx_tenant (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门规则配置表';

-- =============================================
-- 4. 创建 train_ai_suggestion 表（如果不存在）
-- =============================================

CREATE TABLE IF NOT EXISTS train_ai_suggestion (
    suggestion_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '建议ID',
    report_id BIGINT NOT NULL COMMENT '报告ID',
    suggestion_type VARCHAR(50) COMMENT '建议类型 weak_area=薄弱环节 advanced_path=进阶建议 recommended_course=推荐课程',
    target_dimension VARCHAR(50) COMMENT '目标维度编码',
    suggestion_content TEXT NOT NULL COMMENT 'AI生成的建议内容',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_report (report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI学习建议表';

-- =============================================
-- 5. 数据迁移和清理
-- =============================================

-- 为旧数据的 auxiliary_data 字段设置默认值（空JSON对象）
UPDATE train_learning_report 
SET auxiliary_data = JSON_OBJECT('learning_duration', 0, 'quiz_count', 0)
WHERE auxiliary_data IS NULL;

-- 如果存在旧的评分模型，设置第一个为默认
SET @min_model_id = (SELECT MIN(model_id) FROM train_score_model);
SET @has_default = (SELECT COUNT(*) FROM train_score_model WHERE is_default = '1');

UPDATE train_score_model 
SET is_default = '1' 
WHERE model_id = @min_model_id
  AND @has_default = 0;

-- =============================================
-- 6. 验证升级结果
-- =============================================

SELECT '========== 升级完成 ==========' AS message;

SELECT 
    CONCAT('train_learning_report 表字段数: ', COUNT(*)) AS result
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report';

SELECT 
    CONCAT('train_score_model 表字段数: ', COUNT(*)) AS result
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_score_model';

SELECT 
    CONCAT('train_dept_rule 表是否存在: ', IF(COUNT(*) > 0, '是', '否')) AS result
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_dept_rule';

SELECT 
    CONCAT('train_ai_suggestion 表是否存在: ', IF(COUNT(*) > 0, '是', '否')) AS result
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_ai_suggestion';

SELECT 
    CONCAT('train_learning_report 数据行数: ', COUNT(*)) AS result
FROM train_learning_report;

SELECT '========== 请重启后端服务 ==========' AS message;
