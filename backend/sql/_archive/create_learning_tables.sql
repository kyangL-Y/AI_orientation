-- 学习相关核心数据表（课程、学习进度、整场考试成绩）
-- 兼容 RuoYi 规范：时间字段 create_time/update_time，字符集 utf8mb4

-- 1) 课程表
CREATE TABLE IF NOT EXISTS `train_course` (
  `course_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '课程ID',
  `title` varchar(255) NOT NULL COMMENT '课程标题',
  `description` text NULL COMMENT '课程描述',
  `cover` varchar(512) DEFAULT NULL COMMENT '封面图片URL',
  `duration` int(11) DEFAULT NULL COMMENT '课程时长(分钟)',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态(1-启用,0-停用)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`course_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程表';

-- 2) 学习进度表（用户-课程）
CREATE TABLE IF NOT EXISTS `train_user_course_progress` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态(0未开始,1学习中,2已完成)',
  `progress_percent` tinyint(3) NOT NULL DEFAULT 0 COMMENT '进度百分比(0-100)',
  `started_at` datetime DEFAULT NULL COMMENT '开始时间',
  `completed_at` datetime DEFAULT NULL COMMENT '完成时间',
  `last_learn_time` datetime DEFAULT NULL COMMENT '最近学习时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_course` (`user_id`,`course_id`),
  KEY `idx_status` (`status`),
  KEY `idx_course` (`course_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户课程学习进度';

-- 3) 整场考试成绩（由逐题记录聚合）
CREATE TABLE IF NOT EXISTS `train_quiz_attempt` (
  `attempt_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '考试尝试ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `exam_id` bigint(20) NOT NULL COMMENT '考试ID(train_exam)',
  `score` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '得分(0-100)',
  `is_passed` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否通过(0否,1是)',
  `question_count` int(11) DEFAULT NULL COMMENT '本次考试题目数量',
  `correct_count` int(11) DEFAULT NULL COMMENT '答对题目数量',
  `duration` int(11) DEFAULT NULL COMMENT '用时(秒)',
  `submitted_at` datetime DEFAULT NULL COMMENT '提交时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`attempt_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_exam` (`exam_id`),
  KEY `idx_submitted` (`submitted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='整场考试成绩(由答题明细聚合)';


