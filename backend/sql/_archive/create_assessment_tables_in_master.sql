-- ================================================
-- 在主数据库 (hz-vue) 中创建学习评估相关表
-- 这些表需要在主数据库中存在，因为后端代码会查询它们
-- ================================================

-- 1. 评分规则表
CREATE TABLE IF NOT EXISTS train_score_model (
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

-- 2. 评分维度表
CREATE TABLE IF NOT EXISTS train_score_dimension (
    dimension_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '维度ID',
    model_id BIGINT NOT NULL COMMENT '规则ID',
    dimension_code VARCHAR(50) NOT NULL COMMENT '维度编码',
    dimension_name VARCHAR(100) NOT NULL COMMENT '维度名称',
    weight INT NOT NULL DEFAULT 33 COMMENT '权重百分比',
    calc_formula VARCHAR(500) COMMENT '计算公式说明',
    sort_order INT DEFAULT 0 COMMENT '排序',
    INDEX idx_model (model_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评分维度表';

-- 3. 部门规则配置表
CREATE TABLE IF NOT EXISTS train_dept_rule (
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
CREATE TABLE IF NOT EXISTS train_learning_report (
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
    ai_suggestion TEXT COMMENT 'AI生成的学习建议JSON',
    dept_rank INT COMMENT '部门排名',
    total_in_dept INT COMMENT '部门总人数',
    tenant_id VARCHAR(20) NOT NULL COMMENT '租户ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_period (user_id, period_type, period_end),
    INDEX idx_tenant_period (tenant_id, period_type, period_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学习报告表';

-- 5. 插入默认评分模型
INSERT INTO train_score_model (model_name, description, tenant_id, status, is_default, create_by, create_time)
SELECT '标准评分规则', 
       '适用于所有部门的标准评分规则', 
       'T001', 
       '1', 
       '1', 
       'admin',
       NOW()
WHERE NOT EXISTS (SELECT 1 FROM train_score_model WHERE is_default = '1' AND status = '1');

-- 6. 获取模型ID并插入维度
SET @model_id = (SELECT model_id FROM train_score_model WHERE is_default = '1' AND status = '1' LIMIT 1);

INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
SELECT @model_id, 'accuracy_rate', '答题正确率', 33, '用户答题的正确率', 1
WHERE @model_id IS NOT NULL 
  AND NOT EXISTS (SELECT 1 FROM train_score_dimension WHERE model_id = @model_id AND dimension_code = 'accuracy_rate');

INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
SELECT @model_id, 'completion_rate', '模块完成率', 33, '学习模块的完成比例', 2
WHERE @model_id IS NOT NULL 
  AND NOT EXISTS (SELECT 1 FROM train_score_dimension WHERE model_id = @model_id AND dimension_code = 'completion_rate');

INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
SELECT @model_id, 'assessment_score', '测评得分', 34, '考试测评的平均得分', 3
WHERE @model_id IS NOT NULL 
  AND NOT EXISTS (SELECT 1 FROM train_score_dimension WHERE model_id = @model_id AND dimension_code = 'assessment_score');

-- 7. 验证结果
SELECT '========== 验证表创建结果 ==========' AS step;
SELECT 
    TABLE_NAME,
    TABLE_COMMENT
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('train_score_model', 'train_score_dimension', 'train_dept_rule', 'train_learning_report');

SELECT '========== 验证评分模型 ==========' AS step;
SELECT 
    m.model_id,
    m.model_name,
    m.is_default,
    m.status,
    COUNT(d.dimension_id) AS dimension_count,
    COALESCE(SUM(d.weight), 0) AS total_weight
FROM train_score_model m
LEFT JOIN train_score_dimension d ON m.model_id = d.model_id
GROUP BY m.model_id, m.model_name, m.is_default, m.status;

SELECT '========== 完成 ==========' AS step;
