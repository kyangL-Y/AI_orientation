CREATE TABLE IF NOT EXISTS `sys_user_miniapp_bind` (
  `bind_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint(20) NOT NULL COMMENT '系统用户ID',
  `platform` varchar(32) NOT NULL COMMENT '平台标识，如 wechat_miniapp',
  `app_id` varchar(64) DEFAULT NULL COMMENT '小程序 AppID',
  `open_id` varchar(128) NOT NULL COMMENT '微信 openId',
  `union_id` varchar(128) DEFAULT NULL COMMENT '微信 unionId',
  `session_key` varchar(255) DEFAULT NULL COMMENT '微信 session_key',
  `status` char(1) NOT NULL DEFAULT '0' COMMENT '状态：0-有效 1-停用',
  `last_login_time` datetime DEFAULT NULL COMMENT '最后登录时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`bind_id`),
  UNIQUE KEY `uk_platform_open_id` (`platform`, `open_id`),
  UNIQUE KEY `uk_user_platform` (`user_id`, `platform`),
  KEY `idx_platform_union_id` (`platform`, `union_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统用户与小程序账号绑定表';
