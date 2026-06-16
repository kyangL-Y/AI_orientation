-- 清理旧的排名数据，为新的基于答题记录的排名系统做准备
-- 执行前请备份数据

-- 1. 清理旧的排名数据（保留表结构，只清空数据）
TRUNCATE TABLE train_ranking;

-- 2. 清理旧的排名分配数据（如果存在）
-- DROP TABLE IF EXISTS train_ranking_assign;

-- 3. 插入说明注释
INSERT INTO train_ranking (user_id, user_name, score, rank_type, period, create_time, remark) 
VALUES (0, '系统说明', 0, 'info', 'ALL', NOW(), '排名数据已更新为基于答题记录(train_answer_attempt)的自动计算系统');

-- 4. 显示清理结果
SELECT 'train_ranking 表已清理，准备接收新的基于答题记录的排名数据' as message;
SELECT COUNT(*) as remaining_records FROM train_ranking;
