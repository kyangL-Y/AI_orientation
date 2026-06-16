-- 用户答题尝试记录表（支持多次作答，独立于 train_answer_record）
-- 设计要点：
-- 1) 允许同一用户对同一题目多次作答（不加唯一键限制）
-- 2) 通过 duration（秒）与 attempt_time 记录反作弊信息；业务层可据此判定 <2 秒为无效
-- 3) 预建常用索引便于按用户/题目/时间维度统计

CREATE TABLE IF NOT EXISTS `train_answer_attempt` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `is_correct` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否正确（0-错误，1-正确）',
  `attempt_time` datetime NOT NULL COMMENT '作答时间（提交时刻）',
  `module_id` bigint(20) DEFAULT NULL COMMENT '所属模块/章节ID',
  `duration` int(11) NOT NULL DEFAULT 0 COMMENT '作答用时（秒），建议业务将 <2 视为无效',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `user_answer` varchar(500) DEFAULT NULL COMMENT '用户答案',
  `question_text` text DEFAULT NULL COMMENT '题目内容',
  `question_type` varchar(50) DEFAULT NULL COMMENT '题目类型',
  `option_a` varchar(500) DEFAULT NULL COMMENT '选项A',
  `option_b` varchar(500) DEFAULT NULL COMMENT '选项B',
  `option_c` varchar(500) DEFAULT NULL COMMENT '选项C',
  `option_d` varchar(500) DEFAULT NULL COMMENT '选项D',
  `correct_answer` varchar(100) DEFAULT NULL COMMENT '正确答案',
  `explanation` text DEFAULT NULL COMMENT '题目解析',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_question_id` (`question_id`),
  KEY `idx_attempt_time` (`attempt_time`),
  KEY `idx_module_id` (`module_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户答题尝试记录表（含反作弊信息）';

