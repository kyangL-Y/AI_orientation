-- 检查 train_learning_report 表结构
USE hotel_training;

SELECT '========== train_learning_report 表结构 ==========' AS '';

SHOW COLUMNS FROM train_learning_report;

SELECT '========== 检查关键字段是否存在 ==========' AS '';

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

SELECT '========== 检查其他必需表 ==========' AS '';

-- 检查 train_score_model 表
SELECT 
    IF(COUNT(*) > 0, '✓ train_score_model 表存在', '✗ train_score_model 表缺失') AS check_result
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_score_model';

-- 检查 train_dept_rule 表
SELECT 
    IF(COUNT(*) > 0, '✓ train_dept_rule 表存在', '✗ train_dept_rule 表缺失') AS check_result
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'hotel_training' 
  AND TABLE_NAME = 'train_dept_rule';

SELECT '========== 检查评分模型数据 ==========' AS '';

SELECT model_id, model_name, is_default, status 
FROM train_score_model 
LIMIT 5;

SELECT '========== 如果看到字段缺失，请执行 ensure_v2_tables_simplified.sql ==========' AS '';
