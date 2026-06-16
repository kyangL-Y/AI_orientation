-- 1. 岗位-学习计划关联表
CREATE TABLE IF NOT EXISTS `train_post_plan_mapping` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `post_id` bigint(20) NOT NULL COMMENT '岗位ID',
  `plan_id` bigint(20) NOT NULL COMMENT '学习计划ID',
  `is_exclusive` tinyint(1) DEFAULT '0' COMMENT '是否岗位专属(1=是,0=否)',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_post_plan` (`post_id`,`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='岗位学习计划关联表';

-- 2. 题目表 (随堂测验)
CREATE TABLE IF NOT EXISTS `train_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '题目ID',
  `content` text NOT NULL COMMENT '题干内容',
  `type` varchar(20) NOT NULL COMMENT '题目类型(CHOICE=单选, JUDGE=判断, MULTI=多选)',
  `options` json DEFAULT NULL COMMENT '选项内容(JSON格式)',
  `correct_answer` varchar(255) DEFAULT NULL COMMENT '正确答案',
  `analysis` text COMMENT '答案解析',
  `course_id` bigint(20) DEFAULT NULL COMMENT '关联课程ID',
  `video_timestamp` int(11) DEFAULT NULL COMMENT '关联视频时间点(秒)',
  `difficulty` tinyint(4) DEFAULT '1' COMMENT '难度(1-5)',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  PRIMARY KEY (`id`),
  KEY `idx_course_id` (`course_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='题库表';

-- 3. 用户随堂答题记录
CREATE TABLE IF NOT EXISTS `train_user_course_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `course_id` bigint(20) DEFAULT NULL COMMENT '课程ID(冗余)',
  `user_answer` varchar(255) DEFAULT NULL COMMENT '用户答案',
  `is_correct` tinyint(1) DEFAULT '0' COMMENT '是否正确(1=对,0=错)',
  `create_time` datetime DEFAULT NULL COMMENT '答题时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_question` (`user_id`,`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户答题记录表';

-- 4. 错题本/艾宾浩斯复习
CREATE TABLE IF NOT EXISTS `train_user_wrong_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `error_count` int(11) DEFAULT '1' COMMENT '错误次数',
  `last_error_time` datetime DEFAULT NULL COMMENT '最后一次答错时间',
  `review_stage` int(11) DEFAULT '0' COMMENT '复习阶段(0=未开始,1=1天,2=3天,3=7天,4=15天,5=30天)',
  `next_review_time` datetime DEFAULT NULL COMMENT '下次复习时间',
  `is_mastered` tinyint(1) DEFAULT '0' COMMENT '是否已掌握(1=是,0=否)',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_question` (`user_id`,`question_id`),
  KEY `idx_next_review` (`user_id`,`next_review_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户错题本';

-- 插入一些测试题目数据 (确保ID不冲突，使用IGNORE)
INSERT IGNORE INTO `train_question` (`id`, `content`, `type`, `options`, `correct_answer`, `analysis`, `course_id`, `video_timestamp`, `create_time`, `create_by`) VALUES
(1, '在处理客人投诉时，首要原则是什么？', 'CHOICE', '[{"label":"A","value":"立即反驳"},{"label":"B","value":"倾听并安抚"},{"label":"C","value":"叫保安"},{"label":"D","value":"推卸责任"}]', 'B', '处理投诉的首要原则是先平息客人的情绪，倾听他们的诉求，而不是急于辩解。', 1, 60, NOW(), 'admin'),
(2, '酒店退房的标准时间通常是几点？', 'CHOICE', '[{"label":"A","value":"10:00"},{"label":"B","value":"12:00"},{"label":"C","value":"14:00"},{"label":"D","value":"16:00"}]', 'B', '国际通用的退房时间为中午12:00。', 1, 120, NOW(), 'admin'),
(3, 'OTA订单必须在多少分钟内确认？', 'JUDGE', '[{"label":"A","value":"正确"},{"label":"B","value":"错误"}]', 'A', '为了保证用户体验，OTA平台通常要求在15-30分钟内确认订单。', 2, 30, NOW(), 'admin');
