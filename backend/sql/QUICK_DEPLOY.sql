-- =============================================
-- 快速部署脚本 - 知识文章阅读时长记录功能
-- =============================================
-- 
-- 使用方法：
-- 1. 复制下面的SQL语句
-- 2. 在数据库管理工具中连接到 hotel_training 数据库
-- 3. 粘贴并执行
-- 
-- 或者使用命令行：
-- mysql -h bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com -P 27608 -u root -p hotel_training
-- 然后粘贴下面的SQL
-- =============================================

-- 切换到正确的数据库
USE hotel_training;

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
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ 表创建成功！'
        ELSE '❌ 表创建失败！'
    END AS status
FROM information_schema.tables 
WHERE table_schema = 'hotel_training' 
  AND table_name = 'train_knowledge_read_log';

-- 显示表结构
DESCRIBE train_knowledge_read_log;

-- 完成提示
SELECT '🎉 部署完成！现在可以部署后端和前端了。' AS message;
