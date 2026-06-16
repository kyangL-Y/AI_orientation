-- ============================================
-- 创建 sys_config 表（系统参数配置表）
-- ============================================

-- 选择数据库（主库）
USE `hz-vue`;

-- 如果表已存在则删除
DROP TABLE IF EXISTS `sys_config`;

-- 创建表
CREATE TABLE `sys_config` (
  `config_id`         INT(5)          NOT NULL AUTO_INCREMENT    COMMENT '参数主键',
  `config_name`       VARCHAR(100)    DEFAULT ''                 COMMENT '参数名称',
  `config_key`        VARCHAR(100)    DEFAULT ''                 COMMENT '参数键名',
  `config_value`      VARCHAR(500)    DEFAULT ''                 COMMENT '参数键值',
  `config_type`       CHAR(1)         DEFAULT 'N'                COMMENT '系统内置（Y是 N否）',
  `create_by`         VARCHAR(64)     DEFAULT ''                 COMMENT '创建者',
  `create_time`       DATETIME                                   COMMENT '创建时间',
  `update_by`         VARCHAR(64)     DEFAULT ''                 COMMENT '更新者',
  `update_time`       DATETIME                                   COMMENT '更新时间',
  `remark`            VARCHAR(500)    DEFAULT NULL               COMMENT '备注',
  PRIMARY KEY (`config_id`)
) ENGINE=INNODB AUTO_INCREMENT=100 COMMENT = '参数配置表';

-- 插入初始数据
INSERT INTO `sys_config` VALUES(1, '主框架页-默认皮肤样式名称',     'sys.index.skinName',               'skin-blue',     'Y', 'admin', NOW(), '', NULL, '蓝色 skin-blue、绿色 skin-green、紫色 skin-purple、红色 skin-red、黄色 skin-yellow' );
INSERT INTO `sys_config` VALUES(2, '用户管理-账号初始密码',         'sys.user.initPassword',            '123456',        'Y', 'admin', NOW(), '', NULL, '初始化密码 123456' );
INSERT INTO `sys_config` VALUES(3, '主框架页-侧边栏主题',           'sys.index.sideTheme',              'theme-dark',    'Y', 'admin', NOW(), '', NULL, '深色主题theme-dark，浅色主题theme-light' );
INSERT INTO `sys_config` VALUES(4, '账号自助-验证码开关',           'sys.account.captchaEnabled',       'true',          'Y', 'admin', NOW(), '', NULL, '是否开启验证码功能（true开启，false关闭）');
INSERT INTO `sys_config` VALUES(5, '账号自助-是否开启用户注册功能', 'sys.account.registerUser',         'false',         'Y', 'admin', NOW(), '', NULL, '是否开启注册用户功能（true开启，false关闭）');
INSERT INTO `sys_config` VALUES(6, '用户登录-黑名单列表',           'sys.login.blackIPList',            '',              'Y', 'admin', NOW(), '', NULL, '设置登录IP黑名单限制，多个匹配项以;分隔，支持匹配（*通配、网段）');
INSERT INTO `sys_config` VALUES(7, '用户管理-初始密码修改策略',     'sys.account.initPasswordModify',   '1',             'Y', 'admin', NOW(), '', NULL, '0：初始密码修改策略关闭，没有任何提示，1：提醒用户，如果未修改初始密码，则在登录时就会提醒修改密码对话框');
INSERT INTO `sys_config` VALUES(8, '用户管理-账号密码更新周期',     'sys.account.passwordValidateDays', '0',             'Y', 'admin', NOW(), '', NULL, '密码更新周期（填写数字，数据初始化值为0不限制，若修改必须为大于0小于365的正整数），如果超过这个周期登录系统时，则在登录时就会提醒修改密码对话框');

-- 执行完成提示
SELECT 'sys_config表创建成功！' AS result;

