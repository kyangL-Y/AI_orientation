-- 为 train_quiz_attempt 表添加 exam_name 字段
-- 执行时间: 2026-02-04
-- 目的: 修复前端显示考试名称的问题

USE hz-vue;

-- 检查字段是否已存在
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hz-vue' 
  AND TABLE_NAME = 'train_quiz_attempt' 
  AND COLUMN_NAME = 'exam_name';

-- 如果字段不存在，则添加
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE train_quiz_attempt ADD COLUMN exam_name VARCHAR(255) NULL COMMENT ''考试名称'' AFTER attempt_type',
    'SELECT ''字段 exam_name 已存在'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 同时添加 duration_seconds 字段（如果不存在）
SET @col_exists2 = 0;
SELECT COUNT(*) INTO @col_exists2
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'hz-vue' 
  AND TABLE_NAME = 'train_quiz_attempt' 
  AND COLUMN_NAME = 'duration_seconds';

SET @sql2 = IF(@col_exists2 = 0,
    'ALTER TABLE train_quiz_attempt ADD COLUMN duration_seconds INT NULL COMMENT ''答题时长（秒）'' AFTER duration',
    'SELECT ''字段 duration_seconds 已存在'' AS message');

PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- 更新现有记录的 exam_name（从 session_name 复制，如果为空则设置默认值）
UPDATE train_quiz_attempt 
SET exam_name = CASE 
    WHEN session_name IS NOT NULL AND session_name != '' THEN session_name
    WHEN attempt_type = 'exam' THEN '正式考试'
    WHEN attempt_type = 'practice' THEN '综合平时测验'
    ELSE '考试'
END
WHERE exam_name IS NULL OR exam_name = '';

-- 更新 duration_seconds（从 duration 复制）
UPDATE train_quiz_attempt 
SET duration_seconds = duration
WHERE duration_seconds IS NULL AND duration IS NOT NULL;

SELECT '✅ train_quiz_attempt 表字段添加完成' AS result;
