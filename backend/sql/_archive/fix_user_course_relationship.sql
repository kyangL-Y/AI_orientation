-- 修复用户表和用户课程学习进度表的关联关系
-- 确保数据一致性和外键约束

-- 1. 首先检查当前表结构
-- 查看用户课程学习进度表是否存在
SHOW TABLES LIKE 'train_user_course%';

-- 2. 如果表不存在，创建用户课程学习进度表
CREATE TABLE IF NOT EXISTS `train_user_course_progress` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `course_id` bigint(20) NOT NULL COMMENT '课程ID',
  `status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '状态(0未开始,1学习中,2已完成)',
  `progress_percent` tinyint(3) NOT NULL DEFAULT 0 COMMENT '进度百分比(0-100)',
  `started_at` datetime DEFAULT NULL COMMENT '开始时间',
  `completed_at` datetime DEFAULT NULL COMMENT '完成时间',
  `last_learn_time` datetime DEFAULT NULL COMMENT '最近学习时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_course` (`user_id`,`course_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户课程学习进度';

-- 3. 添加外键约束（如果不存在）
-- 注意：添加外键约束前，需要确保数据一致性

-- 检查是否有孤立的学习进度记录（user_id在sys_user中不存在）
SELECT DISTINCT tucp.user_id 
FROM train_user_course_progress tucp 
LEFT JOIN sys_user su ON tucp.user_id = su.user_id 
WHERE su.user_id IS NULL;

-- 如果有孤立记录，可以选择删除或更新
-- 删除孤立的学习进度记录
DELETE tucp FROM train_user_course_progress tucp 
LEFT JOIN sys_user su ON tucp.user_id = su.user_id 
WHERE su.user_id IS NULL;

-- 4. 添加外键约束
-- 添加用户ID外键约束
ALTER TABLE `train_user_course_progress` 
ADD CONSTRAINT `fk_user_course_progress_user` 
FOREIGN KEY (`user_id`) REFERENCES `sys_user`(`user_id`) 
ON DELETE CASCADE ON UPDATE CASCADE;

-- 5. 检查课程表是否存在，如果存在则添加课程ID外键约束
-- 先检查课程表
SHOW TABLES LIKE 'train_course';

-- 如果课程表存在，添加课程ID外键约束
-- ALTER TABLE `train_user_course_progress` 
-- ADD CONSTRAINT `fk_user_course_progress_course` 
-- FOREIGN KEY (`course_id`) REFERENCES `train_course`(`course_id`) 
-- ON DELETE CASCADE ON UPDATE CASCADE;

-- 6. 插入一些测试数据（可选）
-- 为现有用户创建一些学习进度记录
INSERT IGNORE INTO `train_user_course_progress` (`user_id`, `course_id`, `status`, `progress_percent`, `started_at`, `last_learn_time`) 
SELECT 
  su.user_id,
  1 as course_id,  -- 假设课程ID为1
  0 as status,     -- 未开始
  0 as progress_percent,
  NULL as started_at,
  NULL as last_learn_time
FROM sys_user su 
WHERE su.user_id IN (1, 2, 100, 101, 102, 103)  -- 基于你的截图中的用户ID
ON DUPLICATE KEY UPDATE 
  update_time = CURRENT_TIMESTAMP;

-- 7. 验证关联关系
-- 查询用户及其学习进度
SELECT 
  su.user_id,
  su.user_name,
  su.nick_name,
  tucp.course_id,
  tucp.status,
  tucp.progress_percent,
  tucp.started_at,
  tucp.completed_at
FROM sys_user su
LEFT JOIN train_user_course_progress tucp ON su.user_id = tucp.user_id
WHERE su.user_id IN (1, 2, 100, 101, 102, 103)
ORDER BY su.user_id, tucp.course_id;

-- 8. 显示表结构确认
DESCRIBE train_user_course_progress;

-- 9. 显示外键约束
SELECT 
  CONSTRAINT_NAME,
  TABLE_NAME,
  COLUMN_NAME,
  REFERENCED_TABLE_NAME,
  REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'train_user_course_progress' 
  AND REFERENCED_TABLE_NAME IS NOT NULL;
