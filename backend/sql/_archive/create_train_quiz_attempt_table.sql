-- 创建或修复 train_quiz_attempt 表的完整结构
-- 数据库：hotel_training

USE hotel_training;

-- 如果表不存在，则创建完整的表结构
CREATE TABLE IF NOT EXISTS `train_quiz_attempt` (
  `attempt_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '考试尝试ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `exam_id` BIGINT(20) DEFAULT NULL COMMENT '考试ID（如果是正式考试）',
  `attempt_type` VARCHAR(20) DEFAULT 'practice' COMMENT '答题类型：exam=考试，practice=测验',
  `score` INT DEFAULT 0 COMMENT '考试总分',
  `submitted_at` DATETIME DEFAULT NULL COMMENT '提交时间',
  `is_passed` TINYINT(1) DEFAULT 0 COMMENT '是否通过（0未通过 1通过）',
  `duration` INT DEFAULT 0 COMMENT '考试总用时（秒）',
  `question_count` INT DEFAULT 0 COMMENT '题目总数',
  `correct_count` INT DEFAULT 0 COMMENT '答对题目数',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`attempt_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_exam_id` (`exam_id`),
  KEY `idx_submitted_at` (`submitted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考试答题记录表';

SELECT '✅ 表结构已创建或已存在' AS message;
DESCRIBE train_quiz_attempt;
