-- 按课程内容归类 OTA 与绿色饭店题库
-- 目标：
-- 1. train_question.course_id 对应 course_category.course_category_id
-- 2. green_hotel_question.course_id 对应 green_hotel_course.green_course_id
-- 3. 只执行可解释的高置信规则；找不到课程内容承接的题目只输出审计清单，不强塞课程。

START TRANSACTION;

-- OTA：先按旧分类名与课程三级标题归一化匹配。
UPDATE train_question q
JOIN course_category c
  ON REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(q.category), ' ', ''), '　', ''), '：', ':'), '，', ','), '（', '('), '）', ')') COLLATE utf8mb4_unicode_ci
   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(c.third_level_c), ' ', ''), '　', ''), '：', ':'), '，', ','), '（', '('), '）', ')') COLLATE utf8mb4_unicode_ci
SET q.course_id = c.course_category_id
WHERE q.category IS NOT NULL
  AND q.category <> ''
  AND c.third_level_c IS NOT NULL
  AND c.third_level_c <> '';

-- OTA：仅处理旧分类过粗的题目。规则必须同时受旧分类约束，避免通用词把其它课程误吸走。
UPDATE train_question q
SET q.course_id = CASE
  WHEN q.category = '1.2 流量获取与转化优化（前端运营）' THEN 176
  WHEN q.category = '1.3 合规运营与风险管控（底线保障）' THEN 177
  WHEN q.category = '客房服务'
    AND CONCAT_WS(' ', q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.explanation) REGEXP '加床|儿童政策|亲子|婴儿床' THEN 76
  WHEN q.category = '客房服务' THEN 184
  WHEN q.category = '文档导入'
    AND CONCAT_WS(' ', q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.explanation) REGEXP '千人千面|OTA平台流量' THEN 175
  WHEN q.category = '文档导入'
    AND CONCAT_WS(' ', q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.explanation) REGEXP '今夜甩卖|促销流量' THEN 189
  WHEN q.category = '文档导入'
    AND CONCAT_WS(' ', q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.explanation) REGEXP '点评分' THEN 179
  ELSE q.course_id
END
WHERE q.status = 1
  AND q.category IN (
    '1.2 流量获取与转化优化（前端运营）',
    '1.3 合规运营与风险管控（底线保障）',
    '客房服务',
    '文档导入'
  );

-- 无现有 OTA 课程内容承接的经营管理题，单独列为内容分类，不再挂到错误课程。
UPDATE train_question q
SET q.course_id = NULL,
    q.category = '全员营销与量本利日核算'
WHERE q.category = '文档导入'
  AND CONCAT_WS(' ', q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.explanation) REGEXP
      '销售平权|全员营销|PV值|伙伴价值|Basics History|协作提成|保本点|成本节约|阿米巴|量本利|部门公司化';

-- 绿色饭店：按旧分类名与绿色饭店课程三级标题归一化匹配。
UPDATE green_hotel_question q
JOIN green_hotel_course c
  ON REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(q.category), ' ', ''), '　', ''), '：', ':'), '，', ','), '（', '('), '）', ')') COLLATE utf8mb4_unicode_ci
   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(c.third_level_c), ' ', ''), '　', ''), '：', ':'), '，', ','), '（', '('), '）', ')') COLLATE utf8mb4_unicode_ci
SET q.course_id = c.green_course_id
WHERE q.category IS NOT NULL
  AND q.category <> ''
  AND c.third_level_c IS NOT NULL
  AND c.third_level_c <> '';

COMMIT;

-- 执行后审计：确认题库映射覆盖。
SELECT 'train_question' AS bank, COUNT(*) AS total, COUNT(course_id) AS mapped, COUNT(DISTINCT course_id) AS course_count
FROM train_question
UNION ALL
SELECT 'green_hotel_question' AS bank, COUNT(*) AS total, COUNT(course_id) AS mapped, COUNT(DISTINCT course_id) AS course_count
FROM green_hotel_question;

-- 需要人工补课程内容承接的题目：这些题与现有 OTA 课程知识点不匹配，不能强行挂到 OTA 课程下。
SELECT q.id, q.course_id, q.category, LEFT(q.question_text, 120) AS question_text
FROM train_question q
WHERE q.status = 1
  AND CONCAT_WS(' ', q.question_text, q.option_a, q.option_b, q.option_c, q.option_d, q.explanation) REGEXP
      '销售平权|全员营销|PV值|伙伴价值|Basics History|协作提成|保本点|成本节约|阿米巴|量本利|部门公司化'
ORDER BY q.id;

-- 抽样确认 OTA 题目是否落在课程三级标题下。
SELECT q.course_id, c.main_title, c.main_s, c.third_level_c, COUNT(*) AS question_count
FROM train_question q
LEFT JOIN course_category c ON q.course_id = c.course_category_id
GROUP BY q.course_id, c.main_title, c.main_s, c.third_level_c
ORDER BY question_count DESC, q.course_id ASC;

-- 抽样确认绿色饭店题目是否落在课程三级标题下。
SELECT q.course_id, c.main_title, c.main_s, c.third_level_c, COUNT(*) AS question_count
FROM green_hotel_question q
LEFT JOIN green_hotel_course c ON q.course_id = c.green_course_id
GROUP BY q.course_id, c.main_title, c.main_s, c.third_level_c
ORDER BY question_count DESC, q.course_id ASC;
