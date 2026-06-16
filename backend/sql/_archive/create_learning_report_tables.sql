-- ================================================
-- 在从库 (hotel_training) 中创建学习报告所需的表
-- 这些表用于存储学习进度和答题记录
-- ================================================

-- 1. 课程学习进度表
CREATE TABLE IF NOT EXISTS train_course_progress (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    course_id BIGINT NOT NULL COMMENT '课程ID',
    duration INT DEFAULT 0 COMMENT '学习时长（分钟）',
    progress DECIMAL(5,2) DEFAULT 0 COMMENT '学习进度（百分比）',
    status VARCHAR(20) DEFAULT 'in_progress' COMMENT '状态：in_progress/completed',
    last_position INT DEFAULT 0 COMMENT '上次学习位置',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_user_course (user_id, course_id),
    INDEX idx_user (user_id),
    INDEX idx_update_time (update_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程学习进度表';

-- 2. 答题记录表
CREATE TABLE IF NOT EXISTS train_answer_attempt (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    question_id BIGINT NOT NULL COMMENT '题目ID',
    user_answer TEXT COMMENT '用户答案',
    is_correct TINYINT(1) DEFAULT 0 COMMENT '是否正确：0-错误，1-正确',
    score DECIMAL(5,2) DEFAULT 0 COMMENT '得分',
    time_spent INT DEFAULT 0 COMMENT '答题耗时（秒）',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user (user_id),
    INDEX idx_create_time (create_time),
    INDEX idx_user_time (user_id, create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='答题记录表';

-- 3. 考试记录表
CREATE TABLE IF NOT EXISTS train_exam_record (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    exam_id BIGINT NOT NULL COMMENT '考试ID',
    score DECIMAL(5,2) DEFAULT 0 COMMENT '得分',
    total_score DECIMAL(5,2) DEFAULT 100 COMMENT '总分',
    correct_count INT DEFAULT 0 COMMENT '正确题数',
    total_count INT DEFAULT 0 COMMENT '总题数',
    time_spent INT DEFAULT 0 COMMENT '答题耗时（秒）',
    status VARCHAR(20) DEFAULT 'completed' COMMENT '状态',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user (user_id),
    INDEX idx_create_time (create_time),
    INDEX idx_user_time (user_id, create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考试记录表';

-- 4. 部门课程分配表
CREATE TABLE IF NOT EXISTS train_dept_course (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    dept_id BIGINT NOT NULL COMMENT '部门ID',
    course_id BIGINT NOT NULL COMMENT '课程ID',
    is_required TINYINT(1) DEFAULT 1 COMMENT '是否必修：0-选修，1-必修',
    deadline DATE COMMENT '完成截止日期',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY uk_dept_course (dept_id, course_id),
    INDEX idx_dept (dept_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门课程分配表';

-- 5. 学习报告表（如果不存在）
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

-- 6. 评分模型表（如果不存在）
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

-- 7. 评分维度表（如果不存在）
CREATE TABLE IF NOT EXISTS train_score_dimension (
    dimension_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '维度ID',
    model_id BIGINT NOT NULL COMMENT '规则ID',
    dimension_code VARCHAR(50) NOT NULL COMMENT '维度编码',
    dimension_name VARCHAR(100) NOT NULL COMMENT '维度名称',
    weight INT NOT NULL DEFAULT 20 COMMENT '权重百分比',
    calc_formula VARCHAR(500) COMMENT '计算公式说明',
    min_value DECIMAL(10,2) COMMENT '最小值',
    max_value DECIMAL(10,2) COMMENT '最大值',
    sort_order INT DEFAULT 0 COMMENT '排序',
    INDEX idx_model (model_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评分维度表';

-- 8. 部门规则配置表（如果不存在）
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

-- ================================================
-- 初始化默认数据
-- ================================================

-- 9. 插入默认评分模型（如果不存在）
INSERT INTO train_score_model (model_name, description, tenant_id, status, is_default, create_by, create_time)
SELECT '标准评分规则', 
       '适用于所有部门的标准评分规则，包含5个评分维度', 
       'T001', 
       '1', 
       '1', 
       'admin',
       NOW()
WHERE NOT EXISTS (SELECT 1 FROM train_score_model WHERE is_default = '1' AND status = '1' AND tenant_id = 'T001');

-- 10. 获取模型ID并插入维度
SET @model_id = (SELECT model_id FROM train_score_model WHERE is_default = '1' AND status = '1' AND tenant_id = 'T001' LIMIT 1);

-- 删除现有维度（如果存在）
DELETE FROM train_score_dimension WHERE model_id = @model_id;

-- 插入5个评分维度（每个权重20%，总计100%）
INSERT INTO train_score_dimension (model_id, dimension_code, dimension_name, weight, calc_formula, sort_order)
VALUES 
    (@model_id, 'learning_duration', '学习时长', 20, '基准值：周60分钟/月240分钟/季720分钟', 1),
    (@model_id, 'quiz_count', '刷题数量', 20, '基准值：周20题/月80题/季240题', 2),
    (@model_id, 'accuracy_rate', '答题正确率', 20, '正确题数/总答题数 × 100', 3),
    (@model_id, 'completion_rate', '模块完成率', 20, '已完成模块数/分配模块数 × 100', 4),
    (@model_id, 'assessment_score', '测评得分', 20, '考试测评的平均得分', 5);

-- ================================================
-- 插入测试数据（可选）
-- ================================================

-- 11. 插入一些测试学习进度数据
INSERT INTO train_course_progress (user_id, course_id, duration, progress, status, create_time, update_time)
SELECT 100, 1, 60, 100.00, 'completed', DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY)
WHERE NOT EXISTS (SELECT 1 FROM train_course_progress WHERE user_id = 100 AND course_id = 1);

INSERT INTO train_course_progress (user_id, course_id, duration, progress, status, create_time, update_time)
SELECT 100, 2, 45, 75.00, 'in_progress', DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)
WHERE NOT EXISTS (SELECT 1 FROM train_course_progress WHERE user_id = 100 AND course_id = 2);

-- 12. 插入一些测试答题记录
INSERT INTO train_answer_attempt (user_id, question_id, user_answer, is_correct, score, create_time)
SELECT 100, 1, 'A', 1, 10, DATE_SUB(NOW(), INTERVAL 5 DAY)
WHERE NOT EXISTS (SELECT 1 FROM train_answer_attempt WHERE user_id = 100 AND question_id = 1);

INSERT INTO train_answer_attempt (user_id, question_id, user_answer, is_correct, score, create_time)
SELECT 100, 2, 'B', 1, 10, DATE_SUB(NOW(), INTERVAL 4 DAY)
WHERE NOT EXISTS (SELECT 1 FROM train_answer_attempt WHERE user_id = 100 AND question_id = 2);

INSERT INTO train_answer_attempt (user_id, question_id, user_answer, is_correct, score, create_time)
SELECT 100, 3, 'C', 0, 0, DATE_SUB(NOW(), INTERVAL 3 DAY)
WHERE NOT EXISTS (SELECT 1 FROM train_answer_attempt WHERE user_id = 100 AND question_id = 3);

-- 13. 插入一些测试考试记录
INSERT INTO train_exam_record (user_id, exam_id, score, total_score, correct_count, total_count, create_time)
SELECT 100, 1, 85, 100, 17, 20, DATE_SUB(NOW(), INTERVAL 10 DAY)
WHERE NOT EXISTS (SELECT 1 FROM train_exam_record WHERE user_id = 100 AND exam_id = 1);

-- ================================================
-- 验证结果
-- ================================================

SELECT '========== 验证表创建结果 ==========' AS step;
SELECT 
    TABLE_NAME,
    TABLE_COMMENT
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN (
    'train_course_progress', 
    'train_answer_attempt', 
    'train_exam_record',
    'train_dept_course',
    'train_learning_report',
    'train_score_model',
    'train_score_dimension',
    'train_dept_rule'
  );

SELECT '========== 验证评分模型 ==========' AS step;
SELECT 
    m.model_id,
    m.model_name,
    m.is_default,
    m.status,
    COUNT(d.dimension_id) AS dimension_count,
    SUM(d.weight) AS total_weight
FROM train_score_model m
LEFT JOIN train_score_dimension d ON m.model_id = d.model_id
WHERE m.tenant_id = 'T001'
GROUP BY m.model_id, m.model_name, m.is_default, m.status;

SELECT '========== 验证测试数据 ==========' AS step;
SELECT 'train_course_progress' AS table_name, COUNT(*) AS record_count FROM train_course_progress WHERE user_id = 100
UNION ALL
SELECT 'train_answer_attempt', COUNT(*) FROM train_answer_attempt WHERE user_id = 100
UNION ALL
SELECT 'train_exam_record', COUNT(*) FROM train_exam_record WHERE user_id = 100;

SELECT '========== 完成 ==========' AS step;
