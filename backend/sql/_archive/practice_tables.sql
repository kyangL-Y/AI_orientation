-- 刷题相关数据表
-- 答题记录表
CREATE TABLE IF NOT EXISTS `train_answer_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `answer` int(11) NOT NULL COMMENT '用户答案（选项索引）',
  `is_correct` tinyint(1) NOT NULL COMMENT '是否正确（0-错误，1-正确）',
  `answer_time` datetime NOT NULL COMMENT '答题时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_question` (`user_id`, `question_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_question_id` (`question_id`),
  KEY `idx_answer_time` (`answer_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='答题记录表';

-- 题目收藏表
CREATE TABLE IF NOT EXISTS `train_question_favorite` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_question` (`user_id`, `question_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_question_id` (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='题目收藏表';

-- 插入一些示例题目数据
INSERT INTO `train_question` (`company_id`, `hotel_code`, `category`, `dept_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_answer`, `difficulty`, `sort_order`, `status`, `create_time`, `remark`) VALUES
(1, 'HZ001', '产品知识', 101, '单选题', 'OTA订单确认后，应在多少分钟内确认？', '5分钟', '10分钟', '15分钟', '30分钟', 'A', '简单', 1, 1, NOW(), 'OTA运营基础知识'),
(1, 'HZ001', '产品知识', 101, '单选题', '酒店客房清洁标准中，床单更换频率是？', '每客必换', '每天更换', '每周更换', '每月更换', 'A', '简单', 2, 1, NOW(), '客房服务标准'),
(1, 'HZ001', '安全规范', 102, '判断题', '客人退房时必须清理房间', '正确', '错误', NULL, NULL, '错误', '中等', 1, 1, NOW(), '前台操作规范'),
(1, 'HZ001', '安全规范', 102, '单选题', '酒店消防安全检查的频率是？', '每天', '每周', '每月', '每季度', 'B', '中等', 2, 1, NOW(), '消防安全管理'),
(1, 'HZ001', '操作流程', 103, '多选题', '以下哪些属于客饮服务项目？', '做美颜茶', '上架招牌茶', '唯汇客人点餐', '主动添水', 'A,B,D', '中等', 1, 1, NOW(), '客饮服务技能'),
(1, 'HZ001', '操作流程', 103, '单选题', '客房服务中，客人要求延迟退房的处理流程是？', '直接同意', '查看房态后决定', '拒绝请求', '上报经理', 'B', '简单', 2, 1, NOW(), '客房服务流程'),
(1, 'HZ001', '企业文化', 104, '单选题', '华智酒店的企业使命是什么？', '提供优质服务', '创造客户价值', '追求卓越品质', '以上都是', 'D', '简单', 1, 1, NOW(), '企业文化理念'),
(1, 'HZ001', '企业文化', 104, '判断题', '员工应该以客户满意为最高目标', '正确', '错误', NULL, NULL, '正确', '简单', 2, 1, NOW(), '服务理念'),
(1, 'HZ001', '客户服务', 105, '单选题', '处理客户投诉时，第一步应该做什么？', '道歉', '了解情况', '提供解决方案', '记录问题', 'B', '中等', 1, 1, NOW(), '客户服务技巧'),
(1, 'HZ001', '客户服务', 105, '多选题', '优质客户服务的要素包括？', '主动热情', '专业能力', '及时响应', '持续改进', 'A,B,C,D', '中等', 2, 1, NOW(), '服务质量管理');


