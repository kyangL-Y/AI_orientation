ALTER TABLE `train_quiz_attempt`
ADD COLUMN `attempt_scene` VARCHAR(20) DEFAULT 'practice' COMMENT '答题场景：exam=正式考试，practice=普通测验，course_quiz=结课测验' AFTER `attempt_type`;

UPDATE `train_quiz_attempt`
SET `attempt_scene` = CASE
    WHEN `attempt_type` = 'exam' THEN 'exam'
    WHEN `exam_name` LIKE '%结课测验%' THEN 'course_quiz'
    ELSE 'practice'
END
WHERE `attempt_scene` IS NULL OR `attempt_scene` = '';
