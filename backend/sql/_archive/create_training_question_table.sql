-- 创建 train_question 表
CREATE TABLE `train_question` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '题目ID',
  `hotel_code` varchar(10) NOT NULL COMMENT '酒店代码',
  `category` varchar(50) NOT NULL COMMENT '题目分类',
  `dept_id` int(11) DEFAULT NULL COMMENT '部门ID',
  `question_type` varchar(20) NOT NULL COMMENT '题目类型(单选题/多选题/判断题)',
  `question_text` text NOT NULL COMMENT '题目内容',
  `option_a` varchar(500) DEFAULT NULL COMMENT '选项A',
  `option_b` varchar(500) DEFAULT NULL COMMENT '选项B',
  `option_c` varchar(500) DEFAULT NULL COMMENT '选项C',
  `option_d` varchar(500) DEFAULT NULL COMMENT '选项D',
  `correct_answer` varchar(10) NOT NULL COMMENT '正确答案',
  `difficulty` varchar(10) DEFAULT '中等' COMMENT '题目难度(简单/中等/困难)',
  `status` tinyint(1) DEFAULT '0' COMMENT '状态(0启用 1禁用)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_hotel_code` (`hotel_code`),
  KEY `idx_category` (`category`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_question_type` (`question_type`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COMMENT='培训题目表';

-- 插入示例数据（根据您的截图数据）
INSERT INTO `train_question` (`id`, `hotel_code`, `category`, `dept_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_answer`, `difficulty`, `status`, `create_time`) VALUES
(1, 'ZYHY', 'OTA运营', 1, '单选题', 'OTA订单确认后，应在多少分钟内确认？', '5分钟', '10分钟', '15分钟', '30分钟', 'A', '简单', 0, '2025-09-17 08:56:01'),
(2, 'COMMON', '前台操作', 2, '判断题', '客人退房时必须清理房间', NULL, NULL, NULL, NULL, '错误', '中等', 0, '2025-09-17 08:56:01'),
(3, 'HZJD', '客饮服务', 4, '多选题', '以下哪些属于客饮服务项目？', '做美颜茶', '上架招牌茶', '唯汇客人点餐', '主动添水', 'A,B,D', '中等', 0, '2025-09-17 08:56:01');