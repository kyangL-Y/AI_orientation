CREATE TABLE IF NOT EXISTS train_user_guide_onboarding (
  id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  user_id BIGINT NOT NULL COMMENT '用户ID',
  onboarding_version VARCHAR(32) NOT NULL DEFAULT 'v1' COMMENT '引导版本',
  completed_scenarios_json TEXT NULL COMMENT '已完成场景JSON',
  completed TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否完成全部引导',
  completed_at DATETIME NULL COMMENT '全部完成时间',
  create_by VARCHAR(64) DEFAULT '' COMMENT '创建者',
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  update_by VARCHAR(64) DEFAULT '' COMMENT '更新者',
  update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_train_user_guide_onboarding_user_id (user_id),
  KEY idx_train_user_guide_onboarding_completed (completed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户新手引导状态表';

INSERT INTO train_user_guide_onboarding (
  user_id,
  onboarding_version,
  completed_scenarios_json,
  completed,
  completed_at,
  create_time,
  update_time
)
SELECT
  u.user_id,
  'v1',
  '["learning-module-overview","practice-module-overview","exam-module-overview","knowledge-module-overview","knowledge-detail-entry-overview","knowledge-creation-overview","knowledge-detail-overview","knowledge-detail-interaction-overview"]',
  1,
  NOW(),
  NOW(),
  NOW()
FROM sys_user u
LEFT JOIN train_user_guide_onboarding g ON g.user_id = u.user_id
WHERE u.del_flag = '0'
  AND g.user_id IS NULL;
