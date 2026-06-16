-- 删除答题记录表中的 duration 字段
-- 执行前请先备份数据库！

-- 删除 train_answer_attempt 表的 duration 字段
-- 注意：如果字段不存在会报错，但不影响数据
ALTER TABLE train_answer_attempt DROP COLUMN duration;

-- 验证字段已删除
SHOW COLUMNS FROM train_answer_attempt;
