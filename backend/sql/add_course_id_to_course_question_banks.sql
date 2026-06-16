-- 稳定绑定课程与题目：OTA/普通题库、绿色饭店题库按 course_id 优先出题
-- 执行后：
-- 1) train_question.course_id -> course_category.course_category_id
-- 2) green_hotel_question.course_id -> green_hotel_course.green_course_id
-- 旧 category 仍保留为兜底分类。

SET NAMES utf8mb4;

SET @trainQuestionCourseIdExists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'train_question'
    AND COLUMN_NAME = 'course_id'
);
SET @sql := IF(
  @trainQuestionCourseIdExists = 0,
  'ALTER TABLE train_question ADD COLUMN course_id BIGINT NULL COMMENT ''关联课程ID(course_category.course_category_id)'' AFTER id',
  'SELECT ''train_question.course_id already exists'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @greenQuestionCourseIdExists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'green_hotel_question'
    AND COLUMN_NAME = 'course_id'
);
SET @sql := IF(
  @greenQuestionCourseIdExists = 0,
  'ALTER TABLE green_hotel_question ADD COLUMN course_id BIGINT NULL COMMENT ''关联绿色饭店课程ID(green_hotel_course.green_course_id)'' AFTER id',
  'SELECT ''green_hotel_question.course_id already exists'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @trainQuestionCourseIndexExists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'train_question'
    AND INDEX_NAME = 'idx_train_question_course_id'
);
SET @sql := IF(
  @trainQuestionCourseIndexExists = 0,
  'ALTER TABLE train_question ADD INDEX idx_train_question_course_id (course_id)',
  'SELECT ''idx_train_question_course_id already exists'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @greenQuestionCourseIndexExists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'green_hotel_question'
    AND INDEX_NAME = 'idx_green_hotel_question_course_id'
);
SET @sql := IF(
  @greenQuestionCourseIndexExists = 0,
  'ALTER TABLE green_hotel_question ADD INDEX idx_green_hotel_question_course_id (course_id)',
  'SELECT ''idx_green_hotel_question_course_id already exists'''
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE train_question q
SET q.course_id = (
  SELECT c.course_category_id
  FROM course_category c
  WHERE q.category IS NOT NULL
    AND q.category <> ''
    AND (
      q.category COLLATE utf8mb4_unicode_ci = c.third_level_c COLLATE utf8mb4_unicode_ci
      OR q.category COLLATE utf8mb4_unicode_ci = c.specific_category COLLATE utf8mb4_unicode_ci
      OR q.category COLLATE utf8mb4_unicode_ci = c.main_s COLLATE utf8mb4_unicode_ci
      OR q.category COLLATE utf8mb4_unicode_ci = c.main_title COLLATE utf8mb4_unicode_ci
    )
  ORDER BY c.sort_order ASC, c.course_category_id ASC
  LIMIT 1
)
WHERE q.course_id IS NULL
  AND q.category IS NOT NULL
  AND q.category <> '';

UPDATE train_question q
SET q.course_id = (
  SELECT c.course_category_id
  FROM course_category c
  WHERE q.category IS NOT NULL
    AND q.category <> ''
    AND (
      REPLACE(q.category COLLATE utf8mb4_unicode_ci, ' ', '') = REPLACE(c.third_level_c COLLATE utf8mb4_unicode_ci, ' ', '')
      OR REPLACE(q.category COLLATE utf8mb4_unicode_ci, ' ', '') = REPLACE(c.specific_category COLLATE utf8mb4_unicode_ci, ' ', '')
      OR REPLACE(c.third_level_c COLLATE utf8mb4_unicode_ci, ' ', '') LIKE CONCAT('%', REPLACE(q.category COLLATE utf8mb4_unicode_ci, ' ', ''), '%')
      OR REPLACE(q.category COLLATE utf8mb4_unicode_ci, ' ', '') LIKE CONCAT('%', REPLACE(c.specific_category COLLATE utf8mb4_unicode_ci, ' ', ''), '%')
    )
  ORDER BY c.sort_order ASC, c.course_category_id ASC
  LIMIT 1
)
WHERE q.course_id IS NULL
  AND q.category IS NOT NULL
  AND q.category <> '';

UPDATE train_question q
SET q.course_id = CASE q.category
  WHEN '2.1.2四步自检助新手商家订单破零' THEN 69
  WHEN '3.2.1儿童政策加床政策介绍' THEN 76
  WHEN '3.3.2EBK财务住店审核操作手册' THEN 81
  WHEN '3.4.1携程点评管理全流程' THEN 82
  WHEN '3.4.2点评违约细则' THEN 83
  WHEN '4.1.5携程酒店钻级评定' THEN 88
  ELSE q.course_id
END
WHERE q.course_id IS NULL
  AND q.category IN (
    '2.1.2四步自检助新手商家订单破零',
    '3.2.1儿童政策加床政策介绍',
    '3.3.2EBK财务住店审核操作手册',
    '3.4.1携程点评管理全流程',
    '3.4.2点评违约细则',
    '4.1.5携程酒店钻级评定'
  );

UPDATE train_question q
SET q.course_id = CASE
  WHEN q.category = '1.2 流量获取与转化优化（前端运营）' THEN 176
  WHEN q.category = '1.3 合规运营与风险管控（底线保障）' THEN 177
  WHEN q.category = '客房服务' AND q.question_text LIKE '%加床%' THEN 76
  WHEN q.category = '客房服务' THEN 184
  WHEN q.category = '文档导入' AND (q.question_text LIKE '%千人千面%' OR q.question_text LIKE '%OTA平台流量%') THEN 175
  WHEN q.category = '文档导入' AND q.question_text LIKE '%今夜甩卖%' THEN 189
  WHEN q.category = '文档导入' AND q.question_text LIKE '%点评分%' THEN 179
  ELSE q.course_id
END
WHERE q.course_id IS NULL
  AND q.category IN (
    '1.2 流量获取与转化优化（前端运营）',
    '1.3 合规运营与风险管控（底线保障）',
    '客房服务',
    '文档导入'
  );

UPDATE train_question q
SET q.course_id = NULL,
    q.category = '全员营销与量本利日核算'
WHERE q.category = '文档导入'
  AND CONCAT_WS(' ', q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.explanation) REGEXP
      '销售平权|全员营销|PV值|伙伴价值|Basics History|协作提成|保本点|成本节约|阿米巴|量本利|部门公司化';

UPDATE green_hotel_question q
SET q.course_id = (
  SELECT c.green_course_id
  FROM green_hotel_course c
  WHERE q.category IS NOT NULL
    AND q.category <> ''
    AND (
      q.category = c.third_level_c
      OR q.category = c.specific_category
      OR q.category = c.main_s
      OR q.category = c.main_title
      OR c.third_level_c LIKE CONCAT('%', q.category, '%')
      OR q.category LIKE CONCAT('%', c.specific_category, '%')
    )
  ORDER BY c.sort_order ASC, c.green_course_id ASC
  LIMIT 1
)
WHERE q.course_id IS NULL
  AND q.category IS NOT NULL
  AND q.category <> '';

UPDATE green_hotel_question q
SET q.course_id = (
  SELECT c.green_course_id
  FROM green_hotel_course c
  WHERE c.third_level_c LIKE '%绿色饭店标准%'
  ORDER BY c.sort_order ASC, c.green_course_id ASC
  LIMIT 1
)
WHERE q.course_id IS NULL
  AND q.category = '绿色饭店基础';

UPDATE green_hotel_question q
SET q.course_id = (
  SELECT c.green_course_id
  FROM green_hotel_course c
  WHERE c.third_level_c LIKE '%绿色采购%'
  ORDER BY c.sort_order ASC, c.green_course_id ASC
  LIMIT 1
)
WHERE q.course_id IS NULL
  AND q.category = '绿色采购';

UPDATE green_hotel_question q
SET q.course_id = (
  SELECT c.green_course_id
  FROM green_hotel_course c
  WHERE c.third_level_c LIKE '%低碳客房%'
  ORDER BY c.sort_order ASC, c.green_course_id ASC
  LIMIT 1
)
WHERE q.course_id IS NULL
  AND q.category = '低碳客房';

UPDATE green_hotel_question q
SET q.course_id = (
  SELECT c.green_course_id
  FROM green_hotel_course c
  WHERE c.third_level_c LIKE '%餐饮%'
  ORDER BY c.sort_order ASC, c.green_course_id ASC
  LIMIT 1
)
WHERE q.course_id IS NULL
  AND q.category = '绿色餐饮';

SELECT
  'train_question' AS table_name,
  COUNT(*) AS total_questions,
  SUM(CASE WHEN course_id IS NOT NULL THEN 1 ELSE 0 END) AS mapped_questions
FROM train_question
UNION ALL
SELECT
  'green_hotel_question' AS table_name,
  COUNT(*) AS total_questions,
  SUM(CASE WHEN course_id IS NOT NULL THEN 1 ELSE 0 END) AS mapped_questions
FROM green_hotel_question;
