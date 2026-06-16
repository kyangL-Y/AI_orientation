-- 为题目表添加课程关联字段，并建立题目与课程的关系

-- 1. 为 train_question 表添加 course_id 字段
ALTER TABLE train_question 
ADD COLUMN course_id BIGINT(20) DEFAULT NULL COMMENT '所属课程ID' AFTER id,
ADD INDEX idx_course_id (course_id);

-- 2. 查看现有课程列表
SELECT course_id, title FROM train_course ORDER BY course_id;

-- 3. 查看现有题目的分类分布
SELECT category, COUNT(*) AS '题目数量' 
FROM train_question 
GROUP BY category 
ORDER BY category;

-- 4. 根据题目分类，将题目关联到对应课程
-- 以下是示例，请根据实际的 course_id 和分类名称进行调整

-- 示例：将"好评管理"分类的题目关联到"前台接待服务培训"课程（假设course_id=1）
-- UPDATE train_question SET course_id = 1 WHERE category = '好评管理';

-- 示例：将"差评处理"分类的题目关联到"客户服务技巧"课程（假设course_id=5）
-- UPDATE train_question SET course_id = 5 WHERE category = '差评处理';

-- 示例：将"OTA规则"分类的题目关联到"OTA运营管理培训"课程（假设course_id=3）
-- UPDATE train_question SET course_id = 3 WHERE category = 'OTA规则';

-- 5. 通用规则：根据题目分类名称和课程标题的关键字匹配
-- 前台相关题目 -> 前台课程
UPDATE train_question q
JOIN train_course c ON c.title LIKE '%前台%'
SET q.course_id = c.course_id
WHERE q.category LIKE '%前台%' OR q.question_text LIKE '%前台%';

-- 餐饮相关题目 -> 餐饮课程
UPDATE train_question q
JOIN train_course c ON c.title LIKE '%餐饮%'
SET q.course_id = c.course_id
WHERE q.category LIKE '%餐饮%' OR q.question_text LIKE '%餐饮%';

-- OTA相关题目 -> OTA课程
UPDATE train_question q
JOIN train_course c ON c.title LIKE '%OTA%'
SET q.course_id = c.course_id
WHERE q.category LIKE '%OTA%' OR q.question_text LIKE '%OTA%';

-- 客房相关题目 -> 客房课程
UPDATE train_question q
JOIN train_course c ON c.title LIKE '%客房%'
SET q.course_id = c.course_id
WHERE q.category LIKE '%客房%' OR q.question_text LIKE '%客房%';

-- 客服相关题目 -> 客户服务课程
UPDATE train_question q
JOIN train_course c ON c.title LIKE '%客户服务%' OR c.title LIKE '%客服%'
SET q.course_id = c.course_id
WHERE q.category LIKE '%客服%' OR q.question_text LIKE '%客户%';

-- 6. 查看题目与课程的关联结果
SELECT 
    c.course_id,
    c.title AS '课程名称',
    COUNT(q.id) AS '关联题目数',
    GROUP_CONCAT(DISTINCT q.category) AS '题目分类'
FROM train_course c
LEFT JOIN train_question q ON q.course_id = c.course_id
GROUP BY c.course_id, c.title
ORDER BY c.course_id;

-- 7. 查看未关联到任何课程的题目
SELECT category, COUNT(*) AS '题目数量'
FROM train_question
WHERE course_id IS NULL
GROUP BY category;

