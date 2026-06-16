-- 绿色饭店课程独立表（幂等）
-- 说明：
-- 1) 独立于 course_category，专供绿色饭店模块读取
-- 2) 可重复执行，课程种子使用 NOT EXISTS 防重

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `green_hotel_course` (
  `green_course_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `main_title` varchar(100) NOT NULL DEFAULT '绿色饭店培训' COMMENT '主标题',
  `main_s` varchar(100) DEFAULT NULL COMMENT '分类',
  `specific_category` varchar(100) DEFAULT NULL COMMENT '具体分类',
  `third_level_c` varchar(255) NOT NULL COMMENT '课程名称',
  `cover_image` varchar(500) DEFAULT NULL COMMENT '封面图',
  `video_url` varchar(500) DEFAULT NULL COMMENT '课程视频地址',
  `level` varchar(20) DEFAULT 'basic' COMMENT '层级(basic/advance/expert)',
  `knowledge_points` text COMMENT '知识点',
  `sort_order` int(11) DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) DEFAULT 1 COMMENT '状态(0停用 1启用)',
  `tenant_id` varchar(20) DEFAULT NULL COMMENT '租户ID',
  `create_by` varchar(64) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT NULL COMMENT '更新人',
  `updated_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`green_course_id`),
  KEY `idx_green_hotel_course_sort` (`sort_order`),
  KEY `idx_green_hotel_course_status` (`status`),
  KEY `idx_green_hotel_course_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='绿色饭店课程表';

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`)
SELECT
  '绿色饭店培训', '绿色运营基础', '标准认知', '绿色饭店标准与评定', NULL, 'basic',
  '绿色饭店评定标准、关键指标、落地流程', 1001, 1, '000000', 'admin'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '绿色饭店标准与评定'
);

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`)
SELECT
  '绿色饭店培训', '低碳运营实践', '客房管理', '低碳客房运营实务', NULL, 'advance',
  '布草管理、水电节能、清洁耗材优化', 1002, 1, '000000', 'admin'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '低碳客房运营实务'
);

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`)
SELECT
  '绿色饭店培训', '绿色供应链', '采购管理', '绿色采购与供应链管理', NULL, 'advance',
  '环保采购准入、供应商协同、全链路可追溯', 1003, 1, '000000', 'admin'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '绿色采购与供应链管理'
);

INSERT INTO `green_hotel_course`
(`main_title`, `main_s`, `specific_category`, `third_level_c`, `video_url`, `level`, `knowledge_points`, `sort_order`, `status`, `tenant_id`, `create_by`)
SELECT
  '绿色饭店培训', '餐饮减废', '餐饮管理', '餐饮节能与减废管理', NULL, 'expert',
  '厨房能耗控制、食材损耗管理、一次性用品替代', 1004, 1, '000000', 'admin'
WHERE NOT EXISTS (
  SELECT 1 FROM green_hotel_course WHERE third_level_c = '餐饮节能与减废管理'
);

SELECT COUNT(*) AS green_hotel_course_count
FROM green_hotel_course
WHERE status = 1;
