-- =============================================
-- 智囊阁知识共享平台 - 数据库表结构
-- =============================================

-- 1. 知识文章表
DROP TABLE IF EXISTS `train_knowledge_article`;
CREATE TABLE `train_knowledge_article` (
  `article_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '文章ID',
  `title` VARCHAR(200) NOT NULL COMMENT '文章标题',
  `content` TEXT NOT NULL COMMENT '文章内容(富文本HTML)',
  `cover_image` VARCHAR(500) DEFAULT NULL COMMENT '封面图片URL',
  `author_id` BIGINT(20) NOT NULL COMMENT '作者用户ID',
  `author_name` VARCHAR(50) NOT NULL COMMENT '作者姓名',
  `tenant_id` BIGINT(20) NOT NULL COMMENT '集团ID',
  `status` VARCHAR(20) NOT NULL DEFAULT 'draft' COMMENT '状态: draft草稿/pending待审核/published已发布/rejected已拒绝',
  `reject_reason` VARCHAR(500) DEFAULT NULL COMMENT '拒绝原因',
  `reviewer_id` BIGINT(20) DEFAULT NULL COMMENT '审核人ID',
  `reviewer_name` VARCHAR(50) DEFAULT NULL COMMENT '审核人姓名',
  `review_time` DATETIME DEFAULT NULL COMMENT '审核时间',
  `view_count` INT(11) NOT NULL DEFAULT 0 COMMENT '浏览次数',
  `like_count` INT(11) NOT NULL DEFAULT 0 COMMENT '点赞数',
  `favorite_count` INT(11) NOT NULL DEFAULT 0 COMMENT '收藏数',
  `comment_count` INT(11) NOT NULL DEFAULT 0 COMMENT '评论数',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `del_flag` CHAR(1) NOT NULL DEFAULT '0' COMMENT '删除标志(0正常 1删除)',
  PRIMARY KEY (`article_id`),
  KEY `idx_tenant_status` (`tenant_id`, `status`),
  KEY `idx_author` (`author_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识文章表';

-- 2. 文章图片表
DROP TABLE IF EXISTS `train_knowledge_image`;
CREATE TABLE `train_knowledge_image` (
  `image_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '图片ID',
  `article_id` BIGINT(20) NOT NULL COMMENT '文章ID',
  `image_url` VARCHAR(500) NOT NULL COMMENT '图片URL',
  `image_order` INT(11) NOT NULL DEFAULT 0 COMMENT '图片顺序',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`image_id`),
  KEY `idx_article` (`article_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文章图片表';

-- 3. 文章点赞记录表
DROP TABLE IF EXISTS `train_knowledge_like`;
CREATE TABLE `train_knowledge_like` (
  `like_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '点赞ID',
  `article_id` BIGINT(20) NOT NULL COMMENT '文章ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`like_id`),
  UNIQUE KEY `uk_article_user` (`article_id`, `user_id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文章点赞记录表';

-- 4. 文章收藏记录表
DROP TABLE IF EXISTS `train_knowledge_favorite`;
CREATE TABLE `train_knowledge_favorite` (
  `favorite_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '收藏ID',
  `article_id` BIGINT(20) NOT NULL COMMENT '文章ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`favorite_id`),
  UNIQUE KEY `uk_article_user` (`article_id`, `user_id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文章收藏记录表';

-- 5. 文章评论表
DROP TABLE IF EXISTS `train_knowledge_comment`;
CREATE TABLE `train_knowledge_comment` (
  `comment_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '评论ID',
  `article_id` BIGINT(20) NOT NULL COMMENT '文章ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '评论人ID',
  `user_name` VARCHAR(50) NOT NULL COMMENT '评论人姓名',
  `user_avatar` VARCHAR(500) DEFAULT NULL COMMENT '评论人头像',
  `content` VARCHAR(500) NOT NULL COMMENT '评论内容',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `del_flag` CHAR(1) NOT NULL DEFAULT '0' COMMENT '删除标志(0正常 1删除)',
  PRIMARY KEY (`comment_id`),
  KEY `idx_article` (`article_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文章评论表';

-- =============================================
-- 初始化说明
-- =============================================
-- 1. 执行此脚本前请确保数据库已创建
-- 2. 建议在测试环境先执行验证
-- 3. 表结构支持集团数据隔离（tenant_id字段）
-- 4. 所有表都包含必要的索引以优化查询性能
-- 5. 点赞和收藏表使用唯一索引确保数据唯一性
