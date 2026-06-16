-- 修复缺失的数据库字段
USE hotel_training;

-- 1. 检查并添加 train_learning_report.ai_suggestion 字段
SELECT '=== 步骤1: 添加 ai_suggestion 字段 ===' as step;

SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report' 
  AND COLUMN_NAME = 'ai_suggestion';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_learning_report ADD COLUMN ai_suggestion TEXT COMMENT ''AI学习建议(JSON格式)'' AFTER raw_data',
    'SELECT ''字段 ai_suggestion 已存在'' as message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 检查并删除 train_score_dimension 中不存在的字段（如果SQL中有但表中没有）
SELECT '=== 步骤2: 检查 train_score_dimension 表结构 ===' as step;

-- 显示当前表结构
DESC train_score_dimension;

-- 3. 验证修复结果
SELECT '=== 步骤3: 验证修复结果 ===' as step;

SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_COMMENT
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_learning_report'
  AND COLUMN_NAME = 'ai_suggestion';

SELECT '=== 修复完成 ===' as result;
