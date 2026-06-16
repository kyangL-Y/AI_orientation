-- 添加 question_source 字段到 train_answer_attempt 表
-- 用于标识题目来源：ota(OTA题库)、dept(部门题库)、culture(企业文化题库)

ALTER TABLE train_answer_attempt
ADD COLUMN question_source VARCHAR(20) DEFAULT 'ota' COMMENT '题目来源：ota/dept/culture';

-- 为已有数据设置默认值
UPDATE train_answer_attempt SET question_source = 'ota' WHERE question_source IS NULL;
