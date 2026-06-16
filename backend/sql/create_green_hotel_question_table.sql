-- =====================================================
-- 绿色饭店专项题库
-- =====================================================

CREATE TABLE IF NOT EXISTS `green_hotel_question` (
  `id`             BIGINT       AUTO_INCREMENT PRIMARY KEY COMMENT '题目ID',
  `tenant_id`      VARCHAR(20)  DEFAULT NULL COMMENT '租户ID',
  `category`       VARCHAR(100) DEFAULT NULL COMMENT '题目分类(绿色饭店基础/节能降耗/绿色采购/低碳客房/绿色餐饮/垃圾分类与循环利用)',
  `question_type`  VARCHAR(20)  DEFAULT '单选题' COMMENT '题目类型(单选题/多选题/判断题)',
  `question_text`  TEXT         NOT NULL COMMENT '题目内容',
  `option_a`       VARCHAR(500) DEFAULT NULL COMMENT '选项A',
  `option_b`       VARCHAR(500) DEFAULT NULL COMMENT '选项B',
  `option_c`       VARCHAR(500) DEFAULT NULL COMMENT '选项C',
  `option_d`       VARCHAR(500) DEFAULT NULL COMMENT '选项D',
  `correct_answer` VARCHAR(20)  DEFAULT NULL COMMENT '正确答案',
  `explanation`    TEXT         DEFAULT NULL COMMENT '答案解析',
  `difficulty`     VARCHAR(10)  DEFAULT '中等' COMMENT '难度(简单/中等/困难)',
  `sort_order`     INT          DEFAULT 0 COMMENT '排序号',
  `status`         CHAR(1)      DEFAULT '0' COMMENT '状态(0正常 1停用)',
  `create_by`      VARCHAR(64)  DEFAULT NULL COMMENT '创建者',
  `create_time`    DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by`      VARCHAR(64)  DEFAULT NULL COMMENT '更新者',
  `update_time`    DATETIME     DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark`         VARCHAR(500) DEFAULT NULL COMMENT '备注',
  KEY `idx_tenant_id` (`tenant_id`),
  KEY `idx_category` (`category`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='绿色饭店专项题库';

-- =====================================================
-- 插入 15 道示例题目（6个分类，每分类 2-3 道）
-- =====================================================

INSERT INTO `green_hotel_question`
  (`tenant_id`, `category`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_answer`, `explanation`, `difficulty`, `sort_order`, `status`)
VALUES
-- 绿色饭店基础 (3题)
('000000', '绿色饭店基础', '单选题',
 '中国绿色饭店等级评定标准将绿色饭店分为几个等级？',
 'A. 三个等级', 'B. 四个等级', 'C. 五个等级', 'D. 六个等级',
 'C', '根据《绿色饭店》国家标准(GB/T 21084)，绿色饭店等级分为A级至AAAAA级共五个等级。', '简单', 1, '0'),

('000000', '绿色饭店基础', '判断题',
 '绿色饭店的核心理念是"节约资源、保护环境"。',
 NULL, NULL, NULL, NULL,
 '正确', '绿色饭店的核心理念确实是"节约资源、保护环境"，同时兼顾为宾客提供安全、健康、舒适的服务。', '简单', 2, '0'),

('000000', '绿色饭店基础', '多选题',
 '以下哪些属于绿色饭店评定的核心指标？',
 'A. 节能降耗', 'B. 环境保护', 'C. 安全健康', 'D. 豪华装修',
 'A,B,C', '绿色饭店评定的核心指标包括节能降耗、环境保护、安全健康和放心消费，豪华装修不是核心指标。', '中等', 3, '0'),

-- 节能降耗 (3题)
('000000', '节能降耗', '单选题',
 '酒店客房空调的推荐温度设置夏季为多少度？',
 'A. 22℃', 'B. 24℃', 'C. 26℃', 'D. 28℃',
 'C', '根据绿色饭店标准，夏季客房空调建议设置26℃，冬季设置20℃，既保证舒适度又节约能源。', '简单', 4, '0'),

('000000', '节能降耗', '单选题',
 '酒店使用LED灯替代传统白炽灯可以节省多少能耗？',
 'A. 30%-40%', 'B. 50%-60%', 'C. 70%-80%', 'D. 90%以上',
 'C', 'LED灯相比传统白炽灯可以节省70%-80%的电能消耗，且使用寿命长达数万小时。', '中等', 5, '0'),

('000000', '节能降耗', '判断题',
 '酒店应在客人离开房间后自动关闭不必要的电器设备以节约能源。',
 NULL, NULL, NULL, NULL,
 '正确', '通过安装智能取电开关等设备，在客人离房后自动断电是绿色饭店节能降耗的重要措施。', '简单', 6, '0'),

-- 绿色采购 (2题)
('000000', '绿色采购', '单选题',
 '绿色饭店在采购一次性用品时，应优先选择哪类产品？',
 'A. 价格最低的产品', 'B. 可降解环保材料产品', 'C. 外观最精美的产品', 'D. 数量最多的产品',
 'B', '绿色采购要求优先选择可降解、可回收的环保产品，减少对环境的污染。', '简单', 7, '0'),

('000000', '绿色采购', '多选题',
 '绿色饭店在食材采购中应遵循哪些原则？',
 'A. 就近采购减少运输碳排放', 'B. 优先选择有机和绿色认证食材', 'C. 建立食材溯源体系', 'D. 只选择进口高端食材',
 'A,B,C', '绿色采购要求就近采购、优选环保认证产品、建立溯源体系，而非一味追求进口高端食材。', '中等', 8, '0'),

-- 低碳客房 (3题)
('000000', '低碳客房', '单选题',
 '绿色饭店客房中不提供一次性用品"六小件"的做法叫做什么？',
 'A. 绿色清洁', 'B. 绿色客房', 'C. 限塑令', 'D. 零废弃客房',
 'B', '不主动提供一次性用品"六小件"（牙刷、牙膏、梳子、浴擦、拖鞋、剃须刀）是绿色客房的重要举措。', '简单', 9, '0'),

('000000', '低碳客房', '判断题',
 '绿色饭店应鼓励客人重复使用毛巾和床单，以减少洗涤次数。',
 NULL, NULL, NULL, NULL,
 '正确', '通过在客房内放置温馨提示卡，鼓励客人重复使用毛巾和床单是减少水资源和洗涤剂消耗的有效方法。', '简单', 10, '0'),

('000000', '低碳客房', '单选题',
 '绿色饭店客房卫生间推荐安装哪种节水型马桶？',
 'A. 3升/次冲水量', 'B. 6升/3升双按钮冲水马桶', 'C. 9升/次冲水量', 'D. 12升/次冲水量',
 'B', '6升/3升双按钮节水马桶可根据实际需求选择大小水量冲洗，有效节约用水。', '中等', 11, '0'),

-- 绿色餐饮 (2题)
('000000', '绿色餐饮', '单选题',
 '绿色饭店餐饮服务中推行"光盘行动"的主要目的是什么？',
 'A. 减少餐具使用', 'B. 减少食物浪费', 'C. 提高上菜速度', 'D. 降低人工成本',
 'B', '光盘行动的主要目的是减少食物浪费，是绿色饭店餐饮节约的重要举措。', '简单', 12, '0'),

('000000', '绿色餐饮', '多选题',
 '绿色饭店餐饮部门应采取哪些措施减少厨房油烟排放？',
 'A. 安装高效油烟净化装置', 'B. 定期清洗和维护排烟设备', 'C. 采用低油烟烹饪方法', 'D. 取消所有煎炸类菜品',
 'A,B,C', '安装高效净化装置、定期维护设备、采用低油烟烹饪方法都是有效措施，但不需要完全取消煎炸类菜品。', '中等', 13, '0'),

-- 垃圾分类与循环利用 (2题)
('000000', '垃圾分类与循环利用', '单选题',
 '酒店使用过的废弃食用油脂应如何处理？',
 'A. 直接倒入下水道', 'B. 交给有资质的回收企业处理', 'C. 混入生活垃圾', 'D. 用于员工食堂再利用',
 'B', '废弃食用油脂应交给有资质的回收企业统一处理，严禁排入下水道或作为食用油再利用。', '简单', 14, '0'),

('000000', '垃圾分类与循环利用', '判断题',
 '绿色饭店应建立完善的垃圾分类管理制度，将垃圾分为可回收物、有害垃圾、厨余垃圾和其他垃圾。',
 NULL, NULL, NULL, NULL,
 '正确', '根据国家垃圾分类标准，绿色饭店应将垃圾分为四大类并分别处理，实现资源的最大化回收利用。', '简单', 15, '0');

-- =====================================================
-- 添加管理端菜单（绿色饭店题库管理）
-- =====================================================

INSERT INTO `sys_menu` (`menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`, `remark`)
VALUES ('绿色饭店题库', (SELECT `menu_id` FROM (SELECT `menu_id` FROM `sys_menu` WHERE `menu_name` = '培训管理' LIMIT 1) tmp), 7, 'greenHotelQuestion', 'train/greenHotelQuestion/index', 1, 0, 'C', '0', '0', 'train:greenHotelQuestion:list', 'tree', 'admin', NOW(), '绿色饭店题库菜单');

SET @greenHotelQuestionMenuId = LAST_INSERT_ID();

INSERT INTO `sys_menu` (`menu_name`, `parent_id`, `order_num`, `path`, `component`, `is_frame`, `is_cache`, `menu_type`, `visible`, `status`, `perms`, `icon`, `create_by`, `create_time`)
VALUES
('绿色饭店题库查询', @greenHotelQuestionMenuId, 1, '#', '', 1, 0, 'F', '0', '0', 'train:greenHotelQuestion:query', '#', 'admin', NOW()),
('绿色饭店题库新增', @greenHotelQuestionMenuId, 2, '#', '', 1, 0, 'F', '0', '0', 'train:greenHotelQuestion:add', '#', 'admin', NOW()),
('绿色饭店题库修改', @greenHotelQuestionMenuId, 3, '#', '', 1, 0, 'F', '0', '0', 'train:greenHotelQuestion:edit', '#', 'admin', NOW()),
('绿色饭店题库删除', @greenHotelQuestionMenuId, 4, '#', '', 1, 0, 'F', '0', '0', 'train:greenHotelQuestion:remove', '#', 'admin', NOW());

-- 为超管和平台管理员角色授权
INSERT IGNORE INTO `sys_role_menu` (`role_id`, `menu_id`)
SELECT r.role_id, m.menu_id
FROM sys_role r, sys_menu m
WHERE r.role_key IN ('admin', 'platform_admin')
  AND m.perms LIKE 'train:greenHotelQuestion:%';
