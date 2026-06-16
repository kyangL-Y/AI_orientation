-- =============================================
-- 学习测评系统数据库表（V2版本 - 简化版）
-- 执行库：hotel_training（从库）
-- =============================================

-- 1. 评分规则表
DROP TABLE IF EXISTS train_score_dimension;
DROP TABLE IF EXISTS train_score_model;
CREATE TABLE train_score_model (
    model_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '规则ID',
    model_name VARCHAR(100) NOT NULL COMMENT '规则名称',
    description VARCHAR(500) COMMENT '描述',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    status CHAR(1) DEFAULT '1' COMMENT '状态 1=启用 0=停用',
    is_default CHAR(1) DEFAULT '0' COMMENT '是否默认规则',
    create_by VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_by VARCHAR(64) COMMENT '更新者',
    update_time DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_tenant (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评分规则表';

-- 2. 评分维度表（3个评分维度）
CREATE TABLE train_score_dimension (
    dimension_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '维度ID',
    model_id BIGINT NOT NULL COMMENT '规则ID',
    dimension_code VARCHAR(50) NOT NULL COMMENT '维度编码',
    dimension_name VARCHAR(100) NOT NULL COMMENT '维度名称',
    weight INT NOT NULL DEFAULT 33 COMMENT '权重百分比',
    calc_formula VARCHAR(500) COMMENT '计算公式说明',
    sort_order INT DEFAULT 0 COMMENT '排序',
    FOREIGN KEY (model_id) REFERENCES train_score_model(model_id) ON DELETE CASCADE,
    INDEX idx_model (model_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评分维度表';

-- 3. 部门规则配置表
DROP TABLE IF EXISTS train_dept_rule;
CREATE TABLE train_dept_rule (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '配置ID',
    dept_id BIGINT NOT NULL COMMENT '部门ID',
    model_id BIGINT NOT NULL COMMENT '评分规则ID',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    create_by VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY uk_dept_tenant (dept_id, tenant_id),
    INDEX idx_tenant (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门规则配置表';

-- 4. 学习报告表
DROP TABLE IF EXISTS train_ai_suggestion;
DROP TABLE IF EXISTS train_learning_suggestion;
DROP TABLE IF EXISTS train_learning_report;
CREATE TABLE train_learning_report (
    report_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '报告ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    model_id BIGINT NOT NULL COMMENT '使用的评分规则ID',
    period_type VARCHAR(20) NOT NULL COMMENT '报告类型 weekly/monthly/quarterly',
    period_start DATE NOT NULL COMMENT '周期开始日期',
    period_end DATE NOT NULL COMMENT '周期结束日期',
    total_score DECIMAL(5,2) COMMENT '综合得分',
    dimension_scores JSON COMMENT '各维度得分JSON',
    auxiliary_data JSON COMMENT '辅助数据JSON（学习时长、刷题数量）',
    raw_data JSON COMMENT '原始数据JSON（用于AI分析）',
    dept_rank INT COMMENT '部门排名',
    total_in_dept INT COMMENT '部门总人数',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_period (user_id, period_type, period_end),
    INDEX idx_tenant_period (tenant_id, period_type, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习报告表';

-- 5. AI学习建议表
CREATE TABLE train_ai_suggestion (
    suggestion_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '建议ID',
    report_id BIGINT NOT NULL COMMENT '报告ID',
    suggestion_content TEXT NOT NULL COMMENT 'AI生成的建议内容',
    weak_areas JSON COMMENT '识别的薄弱环节',
    recommended_courses JSON COMMENT '推荐课程ID列表',
    ai_model VARCHAR(50) COMMENT 'AI模型名称',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (report_id) REFERENCES train_learning_report(report_id) ON DELETE CASCADE,
    INDEX idx_report (report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI学习建议表';
