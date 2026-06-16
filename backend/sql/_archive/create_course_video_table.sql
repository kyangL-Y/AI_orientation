-- 课程视频管理表（可选，用于记录视频元数据）
CREATE TABLE IF NOT EXISTS `course_video` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `course_id` VARCHAR(50) NOT NULL COMMENT '课程ID',
  `object_key` VARCHAR(255) NOT NULL COMMENT 'COS对象键（存储路径）',
  `original_filename` VARCHAR(255) DEFAULT NULL COMMENT '原始文件名',
  `file_size` BIGINT(20) DEFAULT NULL COMMENT '文件大小（字节）',
  `video_format` VARCHAR(10) DEFAULT NULL COMMENT '视频格式（mp4/avi等）',
  `duration` INT(11) DEFAULT NULL COMMENT '视频时长（秒）',
  `status` TINYINT(1) DEFAULT 1 COMMENT '状态：1=正常，0=禁用',
  `create_by` VARCHAR(64) DEFAULT '' COMMENT '创建者',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) DEFAULT '' COMMENT '更新者',
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_course_id` (`course_id`),
  KEY `idx_status` (`status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程视频管理表';

-- 说明：
-- 1. 此表为可选表，如果不需要记录视频元数据可以不创建
-- 2. 视频文件实际存储在腾讯云COS中，此表仅用于记录和管理
-- 3. 如果使用此表，需要在Controller中增加保存逻辑

