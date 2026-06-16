-- 已有 green_hotel_course 表升级脚本：新增课程视频地址字段（幂等）
-- 适用场景：你已经执行过 create_green_hotel_course_table.sql，但当时版本未包含 video_url

SET NAMES utf8mb4;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'green_hotel_course'
    AND COLUMN_NAME = 'video_url'
);

SET @ddl = IF(
  @column_exists = 0,
  'ALTER TABLE `green_hotel_course` ADD COLUMN `video_url` varchar(500) DEFAULT NULL COMMENT ''课程视频地址'' AFTER `cover_image`;',
  'SELECT ''video_url already exists'';'
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 可选：示例更新（把 URL 改成你的真实课程视频地址）
-- UPDATE green_hotel_course
-- SET video_url = 'https://your-cdn.example.com/green-hotel-standard.mp4'
-- WHERE third_level_c = '绿色饭店标准与评定';
