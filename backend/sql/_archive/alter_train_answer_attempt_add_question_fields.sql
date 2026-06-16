-- 为 train_answer_attempt 表添加题目相关字段
-- 这样在查询错题时就不需要 JOIN 题目表了
-- 执行前请确保连接到 hotel_training 数据库

USE hotel_training;

-- 检查字段是否已存在，如果不存在则添加
SET @dbname = 'hotel_training';
SET @tablename = 'train_answer_attempt';

-- 添加 question_text 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @dbname 
AND TABLE_NAME = @tablename 
AND COLUMN_NAME = 'question_text';

SET @query = IF(@col_exists = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `question_text` TEXT COMMENT ''题目内容'' AFTER `user_answer`',
    'SELECT ''question_text already exists'' AS message');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 question_type 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @dbname 
AND TABLE_NAME = @tablename 
AND COLUMN_NAME = 'question_type';

SET @query = IF(@col_exists = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `question_type` VARCHAR(50) COMMENT ''题目类型'' AFTER `question_text`',
    'SELECT ''question_type already exists'' AS message');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 option_a 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @dbname 
AND TABLE_NAME = @tablename 
AND COLUMN_NAME = 'option_a';

SET @query = IF(@col_exists = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `option_a` VARCHAR(500) COMMENT ''选项A'' AFTER `question_type`',
    'SELECT ''option_a already exists'' AS message');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 option_b 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @dbname 
AND TABLE_NAME = @tablename 
AND COLUMN_NAME = 'option_b';

SET @query = IF(@col_exists = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `option_b` VARCHAR(500) COMMENT ''选项B'' AFTER `option_a`',
    'SELECT ''option_b already exists'' AS message');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 option_c 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @dbname 
AND TABLE_NAME = @tablename 
AND COLUMN_NAME = 'option_c';

SET @query = IF(@col_exists = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `option_c` VARCHAR(500) COMMENT ''选项C'' AFTER `option_b`',
    'SELECT ''option_c already exists'' AS message');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 option_d 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @dbname 
AND TABLE_NAME = @tablename 
AND COLUMN_NAME = 'option_d';

SET @query = IF(@col_exists = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `option_d` VARCHAR(500) COMMENT ''选项D'' AFTER `option_c`',
    'SELECT ''option_d already exists'' AS message');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 correct_answer 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @dbname 
AND TABLE_NAME = @tablename 
AND COLUMN_NAME = 'correct_answer';

SET @query = IF(@col_exists = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `correct_answer` VARCHAR(100) COMMENT ''正确答案'' AFTER `option_d`',
    'SELECT ''correct_answer already exists'' AS message');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 explanation 字段
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = @dbname 
AND TABLE_NAME = @tablename 
AND COLUMN_NAME = 'explanation';

SET @query = IF(@col_exists = 0,
    'ALTER TABLE `train_answer_attempt` ADD COLUMN `explanation` TEXT COMMENT ''题目解析'' AFTER `correct_answer`',
    'SELECT ''explanation already exists'' AS message');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 显示表结构确认
SHOW COLUMNS FROM `train_answer_attempt`;

SELECT '✅ 数据库表结构修改完成！' AS message;
