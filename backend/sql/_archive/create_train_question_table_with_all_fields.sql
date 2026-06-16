-- 创建完整的 train_question 表，包含所有必要字段
-- 请在从库 hotel_training 中执行此脚本

-- 1. 删除原有表（如果存在）
DROP TABLE IF EXISTS `train_question`;
DROP TABLE IF EXISTS `train_question_assign`;
DROP TABLE IF EXISTS `train_users_ref`;

-- 2. 创建新的 train_question 表（包含所有字段）
CREATE TABLE `train_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '题目ID',
  `company_id` bigint(20) DEFAULT NULL COMMENT '集团ID',
  `hotel_code` varchar(10) DEFAULT NULL COMMENT '酒店代码',
  `category` varchar(50) DEFAULT NULL COMMENT '题目分类',
  `dept_id` bigint(20) DEFAULT NULL COMMENT '部门ID',
  `question_type` varchar(20) DEFAULT NULL COMMENT '题目类型(单选题/多选题/判断题/简答题/填空题)',
  `question_text` text NOT NULL COMMENT '题目内容',
  `option_a` varchar(500) DEFAULT NULL COMMENT '选项A',
  `option_b` varchar(500) DEFAULT NULL COMMENT '选项B',
  `option_c` varchar(500) DEFAULT NULL COMMENT '选项C',
  `option_d` varchar(500) DEFAULT NULL COMMENT '选项D',
  `correct_answer` varchar(10) DEFAULT NULL COMMENT '正确答案',
  `difficulty` varchar(10) DEFAULT '中等' COMMENT '题目难度(简单/中等/困难)',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序号（数字越小越靠前）',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态(0禁用 1启用)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新者',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_company_id` (`company_id`),
  KEY `idx_hotel_code` (`hotel_code`),
  KEY `idx_category` (`category`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_question_type` (`question_type`),
  KEY `idx_sort_order` (`sort_order`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COMMENT='培训题目表';

-- 3. 创建题目权限分配表
CREATE TABLE `train_question_assign` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `question_id` bigint(20) NOT NULL COMMENT '题目ID',
  `target_type` varchar(20) NOT NULL COMMENT '目标类型：user/dept/role/group/company',
  `target_id` bigint(20) NOT NULL COMMENT '目标ID',
  `hotel_code` varchar(10) DEFAULT NULL COMMENT '酒店代码（对应dept_id）',
  `dept_id` bigint(20) DEFAULT NULL COMMENT '部门ID',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建者',
  PRIMARY KEY (`id`),
  KEY `idx_question_id` (`question_id`),
  KEY `idx_target_type` (`target_type`),
  KEY `idx_target_id` (`target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-题目权限分配';

-- 4. 创建用户信息快照表
CREATE TABLE `train_users_ref` (
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `dept_id` bigint(20) DEFAULT NULL COMMENT '部门ID',
  `role_ids` varchar(200) DEFAULT NULL COMMENT '角色ID列表，逗号分隔',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`user_id`),
  KEY `idx_dept_id` (`dept_id`),
  KEY `idx_role_ids` (`role_ids`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-用户信息快照表';

-- 5. 插入一些测试数据
INSERT INTO `train_question` (`company_id`, `hotel_code`, `category`, `dept_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_answer`, `difficulty`, `sort_order`, `status`, `create_by`) VALUES
(100, '101', '前厅', 103, '单选题', '酒店前台服务标准是什么？', '微笑服务', '快速办理', '热情接待', '以上都是', 'D', '简单', 1, 1, 'admin'),
(100, '101', '客房', 104, '多选题', '客房清洁需要哪些步骤？', '整理床铺', '清洁卫生间', '更换用品', '检查设施', 'A,B,C,D', '中等', 2, 1, 'admin'),
(100, '102', '餐饮', 108, '判断题', '餐厅服务员需要佩戴工作牌', '正确', '错误', '', '', '正确', '简单', 3, 1, 'admin'),
(100, '101', '管理', 105, '简答题', '如何提高酒店服务质量？', '', '', '', '', '1.加强员工培训\n2.建立服务标准\n3.收集客户反馈\n4.持续改进', '困难', 4, 1, 'admin'),
(100, '102', '财务', 109, '填空题', '酒店收入主要包括___、___和___', '', '', '', '', '客房收入;餐饮收入;其他收入', '中等', 5, 1, 'admin');

-- 6. 插入用户快照数据（模拟用户信息）
INSERT INTO `train_users_ref` (`user_id`, `dept_id`, `role_ids`) VALUES
(1, 103, '1,2'),  -- 管理员用户，研发部门
(2, 104, '2'),    -- 普通用户，市场部门
(3, 105, '2'),    -- 普通用户，财务部门
(4, 108, '2'),    -- 普通用户，分公司市场部门
(5, 109, '2');    -- 普通用户，分公司财务部门

-- 5. 验证数据
SELECT 
    id,
    company_id,
    hotel_code,
    category,
    dept_id,
    question_type,
    LEFT(question_text, 20) as question_preview,
    difficulty,
    sort_order,
    status,
    create_time
FROM train_question 
ORDER BY sort_order ASC, id ASC;
