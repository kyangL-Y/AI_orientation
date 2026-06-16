-- 企业文化题库表（支持多租户隔离）
-- 执行此SQL创建表结构

CREATE TABLE IF NOT EXISTS `corporate_culture_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '题目ID',
  `tenant_id` varchar(20) NOT NULL COMMENT '租户ID（用于多租户隔离）',
  `category` varchar(100) DEFAULT NULL COMMENT '题目分类（如：服务宣言、核心理念、安全篇等）',
  `question_type` varchar(20) DEFAULT '单选题' COMMENT '题目类型(单选题/多选题/判断题)',
  `question_text` text NOT NULL COMMENT '题目内容',
  `option_a` varchar(500) DEFAULT NULL COMMENT '选项A',
  `option_b` varchar(500) DEFAULT NULL COMMENT '选项B',
  `option_c` varchar(500) DEFAULT NULL COMMENT '选项C',
  `option_d` varchar(500) DEFAULT NULL COMMENT '选项D',
  `correct_answer` varchar(20) DEFAULT NULL COMMENT '正确答案(A/B/C/D，多选用逗号分隔)',
  `explanation` text COMMENT '答案解析',
  `difficulty` varchar(10) DEFAULT '中等' COMMENT '难度(简单/中等/困难)',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序号',
  `status` char(1) DEFAULT '0' COMMENT '状态(0正常 1停用)',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  KEY `idx_tenant_id` (`tenant_id`),
  KEY `idx_category` (`category`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业文化题库表';

-- 插入测试数据（华智酒店 tenant_id='T001'）
INSERT INTO `corporate_culture_question` (`tenant_id`, `category`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_answer`, `explanation`, `difficulty`) VALUES
('T001', '服务宣言', '单选题', '华智酒店的企业主张是什么？', '顾客至上', '与同道之人，成伟大之事', '追求卓越', '服务第一', 'B', '华智酒店的企业主张是"与同道之人，成伟大之事"，强调团队协作和共同成长。', '简单'),
('T001', '核心理念', '单选题', '华智酒店的酒店精神是什么？', '追求完美', '以情服务，用心做事', '顾客至上', '品质第一', 'B', '华智酒店的酒店精神是"以情服务，用心做事"，体现了服务的温度和用心。', '简单'),
('T001', '核心理念', '多选题', '华智酒店的价值观包括哪些？', '顾客至上', '追求卓越', '永葆激情', '独树一帜', 'A,B,C,D', '华智酒店的价值观包括：顾客至上、追求卓越、永葆激情、独树一帜。', '中等'),
('T001', '安全篇', '判断题', '安全理念：隐患险于明火，防范胜于救灾，责任重于泰山。', '正确', '错误', NULL, NULL, '正确', '这是华智酒店的安全理念，强调安全防范的重要性。', '简单'),
('T001', '服务篇', '单选题', '华智酒店的服务准则是什么？', '快速、准确、周到', '热情、礼貌、迅速、周到', '专业、高效、贴心', '真诚、细致、完美', 'B', '华智酒店的服务准则是"热情、礼貌、迅速、周到"。', '中等');


-- =============================================
-- 菜单配置（添加到sys_menu表）
-- =============================================

-- 查询培训管理菜单的ID（假设父菜单ID为2000，请根据实际情况调整）
-- 如果培训管理菜单ID不是2000，请先查询: SELECT * FROM sys_menu WHERE menu_name = '培训管理';

-- 添加企业文化题库菜单
INSERT INTO `sys_menu` (`menu_name`, `parent_id`, `order_num`, `path`, `component`, `query`, `route_name`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) 
VALUES ('企业文化题库', 2000, 15, 'cultureQuestion', 'train/cultureQuestion/index', NULL, 'CultureQuestion', 1, 0, 'C', '0', '0', 'train:cultureQuestion:list', 'education', 'admin', NOW(), '', NULL, '企业文化题库菜单');

-- 获取刚插入的菜单ID（用于添加按钮权限）
SET @cultureMenuId = LAST_INSERT_ID();

-- 添加按钮权限
INSERT INTO `sys_menu` (`menu_name`, `parent_id`, `order_num`, `path`, `component`, `query`, `route_name`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `update_by`, `update_time`, `remark`) VALUES
('企业文化题库查询', @cultureMenuId, 1, '', NULL, NULL, '', 1, 0, 'F', '0', '0', 'train:cultureQuestion:query', '#', 'admin', NOW(), '', NULL, ''),
('企业文化题库新增', @cultureMenuId, 2, '', NULL, NULL, '', 1, 0, 'F', '0', '0', 'train:cultureQuestion:add', '#', 'admin', NOW(), '', NULL, ''),
('企业文化题库修改', @cultureMenuId, 3, '', NULL, NULL, '', 1, 0, 'F', '0', '0', 'train:cultureQuestion:edit', '#', 'admin', NOW(), '', NULL, ''),
('企业文化题库删除', @cultureMenuId, 4, '', NULL, NULL, '', 1, 0, 'F', '0', '0', 'train:cultureQuestion:remove', '#', 'admin', NOW(), '', NULL, '');

-- 为管理员角色分配权限（假设管理员角色ID为1）
-- 先查询新增的菜单ID
INSERT INTO `sys_role_menu` (`role_id`, `menu_id`) 
SELECT 1, menu_id FROM sys_menu WHERE perms LIKE 'train:cultureQuestion:%';

