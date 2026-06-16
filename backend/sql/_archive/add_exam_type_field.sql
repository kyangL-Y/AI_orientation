-- 为 train_exam 表添加 exam_type 字段
ALTER TABLE train_exam 
ADD COLUMN exam_type VARCHAR(20) DEFAULT 'final_exam' COMMENT '考试类型：weekly_exam-周考, monthly_exam-月考, quarterly_exam-季考, final_exam-期末考' 
AFTER name;

-- 添加索引
ALTER TABLE train_exam ADD INDEX idx_exam_type (exam_type);

-- 更新现有数据（根据考试名称智能识别）
UPDATE train_exam 
SET exam_type = CASE 
    WHEN name LIKE '%周考%' OR name LIKE '%周测%' THEN 'weekly_exam'
    WHEN name LIKE '%月考%' OR name LIKE '%月测%' THEN 'monthly_exam'
    WHEN name LIKE '%季考%' OR name LIKE '%季度%' THEN 'quarterly_exam'
    WHEN name LIKE '%期末%' OR name LIKE '%结业%' THEN 'final_exam'
    ELSE 'final_exam'
END;

-- 验证更新结果
SELECT id, name, exam_type FROM train_exam;
