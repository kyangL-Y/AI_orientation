-- =============================================
-- 知识文章阅读记录表
-- 用于记录用户阅读文章的实际时长
-- =============================================
-- 
-- 使用说明：
-- 1. 请在 hotel_training 数据库中执行此脚本
-- 2. 如果表已存在，会跳过创建
-- 3. 执行完成后会显示创建结果
-- 
-- 执行方式：
-- mysql -h bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com -P 27608 -u root -p hotel_training < create_article_read_log.sql
-- 或者在数据库客户端中直接执行
-- =============================================

USE hotel_training;

-- 检查表是否存在
SELECT 'Checking if table exists...' AS status;

-- 创建阅读记录表
CREATE TABLE IF NOT EXISTS `train_knowledge_read_log` (
  `log_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `article_id` BIGINT(20) NOT NULL COMMENT '文章ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `read_duration` INT(11) NOT NULL DEFAULT 0 COMMENT '阅读时长（秒）',
  `start_time` DATETIME NOT NULL COMMENT '开始阅读时间',
  `end_time` DATETIME DEFAULT NULL COMMENT '结束阅读时间',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`log_id`),
  KEY `idx_article_user` (`article_id`, `user_id`),
  KEY `idx_user_time` (`user_id`, `create_time`),
  KEY `idx_article_time` (`article_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识文章阅读记录表';

-- 验证表是否创建成功
SELECT 'Table created successfully!' AS status;

-- 显示表结构
SHOW CREATE TABLE train_knowledge_read_log;

-- 显示表的列信息
DESCRIBE train_knowledge_read_log;

-- 说明：
-- 1. read_duration: 实际阅读时长，单位为秒
-- 2. start_time: 用户打开文章的时间
-- 3. end_time: 用户离开文章的时间（可能为空，如果用户没有正常关闭）
-- 4. 每次用户打开文章都会创建一条新记录
-- 5. 前端会定期（如每30秒）更新阅读时长
-- 
-- 索引说明：
-- - idx_article_user: 用于查询某用户对某文章的阅读记录
-- - idx_user_time: 用于查询某用户在某时间段的阅读记录（学习报告使用）
-- - idx_article_time: 用于查询某文章在某时间段的阅读统计
