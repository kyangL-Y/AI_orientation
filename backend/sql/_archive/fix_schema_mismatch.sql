-- 修复数据库架构不匹配问题
-- 执行数据库: hotel_training

USE hotel_training;

-- ============================================
-- 步骤1: 添加 train_learning_report.ai_suggestion 字段
-- ============================================
SELECT '=== 步骤1: 检查并添加 ai_suggestion 字段 ===' as step;

SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report' 
  AND COLUMN_NAME = 'ai_suggestion';

SELECT IF(@col_exists = 0, '字段不存在，准备添加', '字段已存在，跳过') as ai_suggestion_status;

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_learning_report ADD COLUMN ai_suggestion TEXT COMMENT ''AI学习建议(JSON格式)'' AFTER raw_data',
    'SELECT ''字段 ai_suggestion 已存在'' as message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 步骤2: 添加 train_score_dimension 的 min_value 和 max_value 字段
-- ============================================
SELECT '=== 步骤2: 检查并添加 min_value 和 max_value 字段 ===' as step;

-- 检查 min_value 字段
SET @min_col_exists = 0;
SELECT COUNT(*) INTO @min_col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_score_dimension' 
  AND COLUMN_NAME = 'min_value';

SELECT IF(@min_col_exists = 0, '字段 min_value 不存在，准备添加', '字段 min_value 已存在，跳过') as min_value_status;

SET @sql = IF(@min_col_exists = 0,
    'ALTER TABLE train_score_dimension ADD COLUMN min_value DECIMAL(10,2) DEFAULT 0 COMMENT ''归一化参考最小值'' AFTER calc_formula',
    'SELECT ''字段 min_value 已存在'' as message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查 max_value 字段
SET @max_col_exists = 0;
SELECT COUNT(*) INTO @max_col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_score_dimension' 
  AND COLUMN_NAME = 'max_value';

SELECT IF(@max_col_exists = 0, '字段 max_value 不存在，准备添加', '字段 max_value 已存在，跳过') as max_value_status;

SET @sql = IF(@max_col_exists = 0,
    'ALTER TABLE train_score_dimension ADD COLUMN max_value DECIMAL(10,2) DEFAULT 100 COMMENT ''归一化参考最大值'' AFTER min_value',
    'SELECT ''字段 max_value 已存在'' as message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 步骤3: 验证修复结果
-- ============================================
SELECT '=== 步骤3: 验证修复结果 ===' as step;

-- 验证 train_learning_report 表
SELECT 
    '✅ train_learning_report.ai_suggestion' as field_check,
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_COMMENT
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report'
  AND COLUMN_NAME = 'ai_suggestion';

-- 验证 train_score_dimension 表
SELECT 
    '✅ train_score_dimension 字段' as field_check,
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_score_dimension'
  AND COLUMN_NAME IN ('min_value', 'max_value')
ORDER BY ORDINAL_POSITION;

-- 显示完整的 train_score_dimension 表结构
SELECT '=== train_score_dimension 完整表结构 ===' as step;
DESC train_score_dimension;

SELECT '=== ✅ 修复完成 ===' as result;
