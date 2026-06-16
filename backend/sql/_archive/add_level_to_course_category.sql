-- 为 course_category 表添加学习层级字段
-- 用于支持基础/进阶/高级课程筛选

USE hotel_training;

-- 1. 检查字段是否已存在，如果不存在则添加
SET @dbname = DATABASE();
SET @tablename = 'course_category';
SET @columnname = 'level';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1', -- 字段已存在，不执行任何操作
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' VARCHAR(20) NULL DEFAULT ''basic'' COMMENT ''学习层级：basic-基础,advance-进阶,expert-高级'' AFTER cover_image')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 2. 查看修改后的表结构
DESCRIBE course_category;

-- 3. 查看前5条记录的 level 字段
SELECT 
    course_category_id,
    main_title,
    third_level_c,
    level,
    cover_image
FROM course_category 
ORDER BY course_category_id 
LIMIT 5;

-- 4. 更新示例：为课程设置不同的学习层级
-- UPDATE course_category SET level = 'basic' WHERE course_category_id IN (1,2,3);
-- UPDATE course_category SET level = 'advance' WHERE course_category_id IN (4,5,6);
-- UPDATE course_category SET level = 'expert' WHERE course_category_id IN (7,8,9);

-- 说明：
-- 1. level 字段用于区分课程的学习层级：basic(基础)、advance(进阶)、expert(高级)
-- 2. 默认值为 'basic'，确保旧数据有默认值
-- 3. 字段长度20足够存储层级值
-- 4. NULL 表示可以为空，但建议设置默认值
-- 5. 添加在 cover_image 之后，保持字段顺序合理

