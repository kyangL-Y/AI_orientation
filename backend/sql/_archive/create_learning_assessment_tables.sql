-- ================================================
-- 学习能力测评系统 - 数据库表创建脚本
-- 在从库 hotel_training 中执行
-- ================================================

USE hotel_training;

-- ================================================
-- 1. 评分模型表
-- ================================================
CREATE TABLE IF NOT EXISTS train_score_model (
    model_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '模型ID',
    model_name VARCHAR(100) NOT NULL COMMENT '模型名称',
    model_code VARCHAR(50) NOT NULL COMMENT '模型编码',
    description VARCHAR(500) COMMENT '描述',
    applicable_positions TEXT COMMENT '适用岗位JSON数组',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    status CHAR(1) DEFAULT '1' COMMENT '状态 1=启用 0=停用',
    create_by VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_by VARCHAR(64) COMMENT '更新者',
    update_time DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标志 0=正常 1=删除',
    UNIQUE KEY uk_code_tenant (model_code, tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评分模型表';

-- ================================================
-- 2. 评分维度表
-- ================================================
CREATE TABLE IF NOT EXISTS train_score_dimension (
    dimension_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '维度ID',
    model_id BIGINT NOT NULL COMMENT '模型ID',
    dimension_code VARCHAR(50) NOT NULL COMMENT '维度编码',
    dimension_name VARCHAR(100) NOT NULL COMMENT '维度名称',
    weight INT NOT NULL DEFAULT 20 COMMENT '权重百分比 0-100',
    calc_formula VARCHAR(500) COMMENT '计算公式说明',
    min_value DECIMAL(10,2) DEFAULT 0 COMMENT '归一化参考最小值',
    max_value DECIMAL(10,2) DEFAULT 100 COMMENT '归一化参考最大值',
    sort_order INT DEFAULT 0 COMMENT '排序',
    INDEX idx_model_id (model_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评分维度表';

-- ================================================
-- 3. 报告生成配置表
-- ================================================
CREATE TABLE IF NOT EXISTS train_report_config (
    config_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '配置ID',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    model_id BIGINT NOT NULL COMMENT '评分模型ID',
    period_type VARCHAR(20) NOT NULL COMMENT '周期类型 weekly/monthly/quarterly',
    is_enabled CHAR(1) DEFAULT '1' COMMENT '是否启用 1=启用 0=停用',
    notify_employee CHAR(1) DEFAULT '1' COMMENT '是否通知员工 1=是 0=否',
    cron_expression VARCHAR(100) COMMENT 'Cron表达式',
    last_run_time DATETIME COMMENT '上次执行时间',
    next_run_time DATETIME COMMENT '下次执行时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_tenant_model_period (tenant_id, model_id, period_type),
    INDEX idx_tenant_id (tenant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='报告生成配置表';

-- ================================================
-- 4. 学习报告表
-- ================================================
CREATE TABLE IF NOT EXISTS train_learning_report (
    report_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '报告ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    model_id BIGINT NOT NULL COMMENT '评分模型ID',
    period_type VARCHAR(20) NOT NULL COMMENT '周期类型 weekly/monthly/quarterly',
    period_start DATE NOT NULL COMMENT '周期开始日期',
    period_end DATE NOT NULL COMMENT '周期结束日期',
    total_score DECIMAL(5,2) COMMENT '综合得分 0-100',
    dimension_scores JSON COMMENT '各维度得分JSON',
    raw_data JSON COMMENT '原始数据JSON',
    dept_rank INT COMMENT '部门排名',
    total_in_dept INT COMMENT '部门总人数',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_period (user_id, period_type, period_end),
    INDEX idx_tenant_period (tenant_id, period_type, period_end),
    INDEX idx_model_id (model_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习报告表';

-- ================================================
-- 5. 学习建议表
-- ================================================
CREATE TABLE IF NOT EXISTS train_learning_suggestion (
    suggestion_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '建议ID',
    report_id BIGINT NOT NULL COMMENT '报告ID',
    suggestion_type VARCHAR(30) NOT NULL COMMENT '建议类型 weak_area/advanced_path/recommended_course',
    target_dimension VARCHAR(50) COMMENT '目标维度',
    suggestion_content TEXT NOT NULL COMMENT '建议内容',
    related_course_id BIGINT COMMENT '关联课程ID',
    related_module_id BIGINT COMMENT '关联模块ID',
    priority INT DEFAULT 3 COMMENT '优先级 1-5，1最高',
    INDEX idx_report_id (report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习建议表';
