ALTER TABLE `train_quiz_attempt`
ADD COLUMN `course_quiz_key` VARCHAR(128) DEFAULT NULL COMMENT '结课测验去重键' AFTER `attempt_scene`;

UPDATE `train_quiz_attempt`
SET `course_quiz_key` = CASE
    WHEN `course_quiz_key` IS NOT NULL AND `course_quiz_key` != '' THEN `course_quiz_key`
    WHEN `exam_name` IS NOT NULL AND `exam_name` != '' THEN `exam_name`
    ELSE CONCAT('attempt-', `attempt_id`)
END
WHERE (`course_quiz_key` IS NULL OR `course_quiz_key` = '')
  AND (`attempt_scene` = 'course_quiz' OR `exam_name` LIKE '%结课测验%');
