-- 修复 train_answer_attempt 中题目快照缺失/来源错误的数据
-- 适用场景：
-- 1. question_source 为空、错误或历史值不规范
-- 2. question_text / question_type / correct_answer / explanation / option_a~d 为空或空字符串

USE hotel_training;

-- 1. 修正可唯一识别的 question_source
UPDATE train_answer_attempt taa
LEFT JOIN train_question tq ON tq.id = taa.question_id
LEFT JOIN dept_training_question dtq ON dtq.id = taa.question_id
LEFT JOIN corporate_culture_question ccq ON ccq.id = taa.question_id
SET taa.question_source = CASE
    WHEN tq.id IS NOT NULL AND dtq.id IS NULL AND ccq.id IS NULL THEN 'ota'
    WHEN tq.id IS NULL AND dtq.id IS NOT NULL AND ccq.id IS NULL THEN 'dept'
    WHEN tq.id IS NULL AND dtq.id IS NULL AND ccq.id IS NOT NULL THEN 'culture'
    ELSE taa.question_source
END
WHERE (
    taa.question_source IS NULL
    OR TRIM(taa.question_source) = ''
    OR LOWER(TRIM(taa.question_source)) NOT IN ('ota', 'dept', 'culture')
    OR (LOWER(TRIM(taa.question_source)) = 'ota' AND tq.id IS NULL)
    OR (LOWER(TRIM(taa.question_source)) = 'dept' AND dtq.id IS NULL)
    OR (LOWER(TRIM(taa.question_source)) = 'culture' AND ccq.id IS NULL)
)
AND (
    (tq.id IS NOT NULL AND dtq.id IS NULL AND ccq.id IS NULL)
    OR (tq.id IS NULL AND dtq.id IS NOT NULL AND ccq.id IS NULL)
    OR (tq.id IS NULL AND dtq.id IS NULL AND ccq.id IS NOT NULL)
);

-- 2. 回填 OTA 题库快照
UPDATE train_answer_attempt taa
INNER JOIN train_question tq ON tq.id = taa.question_id
SET
    taa.question_text = CASE WHEN NULLIF(TRIM(taa.question_text), '') IS NULL THEN tq.question_text ELSE taa.question_text END,
    taa.question_type = CASE WHEN NULLIF(TRIM(taa.question_type), '') IS NULL THEN tq.question_type ELSE taa.question_type END,
    taa.correct_answer = CASE WHEN NULLIF(TRIM(taa.correct_answer), '') IS NULL THEN tq.correct_answer ELSE taa.correct_answer END,
    taa.explanation = CASE WHEN NULLIF(TRIM(taa.explanation), '') IS NULL THEN tq.explanation ELSE taa.explanation END,
    taa.option_a = CASE WHEN NULLIF(TRIM(taa.option_a), '') IS NULL THEN tq.option_a ELSE taa.option_a END,
    taa.option_b = CASE WHEN NULLIF(TRIM(taa.option_b), '') IS NULL THEN tq.option_b ELSE taa.option_b END,
    taa.option_c = CASE WHEN NULLIF(TRIM(taa.option_c), '') IS NULL THEN tq.option_c ELSE taa.option_c END,
    taa.option_d = CASE WHEN NULLIF(TRIM(taa.option_d), '') IS NULL THEN tq.option_d ELSE taa.option_d END,
    taa.question_source = 'ota'
WHERE LOWER(TRIM(taa.question_source)) = 'ota'
AND (
    NULLIF(TRIM(taa.question_text), '') IS NULL
    OR NULLIF(TRIM(taa.question_type), '') IS NULL
    OR NULLIF(TRIM(taa.correct_answer), '') IS NULL
    OR NULLIF(TRIM(taa.explanation), '') IS NULL
    OR NULLIF(TRIM(taa.option_a), '') IS NULL
    OR NULLIF(TRIM(taa.option_b), '') IS NULL
    OR NULLIF(TRIM(taa.option_c), '') IS NULL
    OR NULLIF(TRIM(taa.option_d), '') IS NULL
);

-- 3. 回填部门题库快照
UPDATE train_answer_attempt taa
INNER JOIN dept_training_question dtq ON dtq.id = taa.question_id
SET
    taa.question_text = CASE WHEN NULLIF(TRIM(taa.question_text), '') IS NULL THEN dtq.question_text ELSE taa.question_text END,
    taa.question_type = CASE WHEN NULLIF(TRIM(taa.question_type), '') IS NULL THEN dtq.question_type ELSE taa.question_type END,
    taa.correct_answer = CASE WHEN NULLIF(TRIM(taa.correct_answer), '') IS NULL THEN dtq.correct_answer ELSE taa.correct_answer END,
    taa.explanation = CASE WHEN NULLIF(TRIM(taa.explanation), '') IS NULL THEN dtq.explanation ELSE taa.explanation END,
    taa.option_a = CASE WHEN NULLIF(TRIM(taa.option_a), '') IS NULL THEN dtq.option_a ELSE taa.option_a END,
    taa.option_b = CASE WHEN NULLIF(TRIM(taa.option_b), '') IS NULL THEN dtq.option_b ELSE taa.option_b END,
    taa.option_c = CASE WHEN NULLIF(TRIM(taa.option_c), '') IS NULL THEN dtq.option_c ELSE taa.option_c END,
    taa.option_d = CASE WHEN NULLIF(TRIM(taa.option_d), '') IS NULL THEN dtq.option_d ELSE taa.option_d END,
    taa.question_source = 'dept'
WHERE LOWER(TRIM(taa.question_source)) = 'dept'
AND (
    NULLIF(TRIM(taa.question_text), '') IS NULL
    OR NULLIF(TRIM(taa.question_type), '') IS NULL
    OR NULLIF(TRIM(taa.correct_answer), '') IS NULL
    OR NULLIF(TRIM(taa.explanation), '') IS NULL
    OR NULLIF(TRIM(taa.option_a), '') IS NULL
    OR NULLIF(TRIM(taa.option_b), '') IS NULL
    OR NULLIF(TRIM(taa.option_c), '') IS NULL
    OR NULLIF(TRIM(taa.option_d), '') IS NULL
);

-- 4. 回填企业文化题库快照
UPDATE train_answer_attempt taa
INNER JOIN corporate_culture_question ccq ON ccq.id = taa.question_id
SET
    taa.question_text = CASE WHEN NULLIF(TRIM(taa.question_text), '') IS NULL THEN ccq.question_text ELSE taa.question_text END,
    taa.question_type = CASE WHEN NULLIF(TRIM(taa.question_type), '') IS NULL THEN ccq.question_type ELSE taa.question_type END,
    taa.correct_answer = CASE WHEN NULLIF(TRIM(taa.correct_answer), '') IS NULL THEN ccq.correct_answer ELSE taa.correct_answer END,
    taa.explanation = CASE WHEN NULLIF(TRIM(taa.explanation), '') IS NULL THEN ccq.explanation ELSE taa.explanation END,
    taa.option_a = CASE WHEN NULLIF(TRIM(taa.option_a), '') IS NULL THEN ccq.option_a ELSE taa.option_a END,
    taa.option_b = CASE WHEN NULLIF(TRIM(taa.option_b), '') IS NULL THEN ccq.option_b ELSE taa.option_b END,
    taa.option_c = CASE WHEN NULLIF(TRIM(taa.option_c), '') IS NULL THEN ccq.option_c ELSE taa.option_c END,
    taa.option_d = CASE WHEN NULLIF(TRIM(taa.option_d), '') IS NULL THEN ccq.option_d ELSE taa.option_d END,
    taa.question_source = 'culture'
WHERE LOWER(TRIM(taa.question_source)) = 'culture'
AND (
    NULLIF(TRIM(taa.question_text), '') IS NULL
    OR NULLIF(TRIM(taa.question_type), '') IS NULL
    OR NULLIF(TRIM(taa.correct_answer), '') IS NULL
    OR NULLIF(TRIM(taa.explanation), '') IS NULL
    OR NULLIF(TRIM(taa.option_a), '') IS NULL
    OR NULLIF(TRIM(taa.option_b), '') IS NULL
    OR NULLIF(TRIM(taa.option_c), '') IS NULL
    OR NULLIF(TRIM(taa.option_d), '') IS NULL
);

-- 5. 修复后检查
SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN NULLIF(TRIM(question_text), '') IS NULL
              OR NULLIF(TRIM(question_type), '') IS NULL
              OR NULLIF(TRIM(correct_answer), '') IS NULL
            THEN 1 ELSE 0
        END
    ) AS remaining_core_broken_records,
    SUM(
        CASE
            WHEN question_source IS NULL
              OR TRIM(question_source) = ''
              OR LOWER(TRIM(question_source)) NOT IN ('ota', 'dept', 'culture')
            THEN 1 ELSE 0
        END
    ) AS remaining_source_broken_records
FROM train_answer_attempt;

SELECT
    LOWER(TRIM(COALESCE(question_source, 'null'))) AS question_source,
    COUNT(*) AS record_count
FROM train_answer_attempt
GROUP BY LOWER(TRIM(COALESCE(question_source, 'null')))
ORDER BY record_count DESC;

SELECT
    id,
    quiz_attempt_id,
    user_id,
    question_id,
    question_source,
    question_text,
    question_type,
    correct_answer,
    option_a,
    option_b,
    option_c,
    option_d,
    create_time
FROM train_answer_attempt
WHERE
    NULLIF(TRIM(question_text), '') IS NULL
    OR NULLIF(TRIM(question_type), '') IS NULL
    OR NULLIF(TRIM(correct_answer), '') IS NULL
    OR question_source IS NULL
    OR TRIM(question_source) = ''
    OR LOWER(TRIM(question_source)) NOT IN ('ota', 'dept', 'culture')
ORDER BY create_time DESC, id DESC
LIMIT 200;
