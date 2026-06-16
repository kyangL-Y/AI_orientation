-- 清理旧的排名数据，重新基于答题记录表计算排名
-- 1. 清空旧的排名数据
DELETE FROM train_ranking WHERE rank_type = 'overall' AND period = 'ALL';

-- 2. 检查答题记录表数据
SELECT 
    user_id,
    COUNT(*) as total_attempts,
    SUM(is_correct) as correct_attempts,
    COUNT(DISTINCT module_id) as modules_covered
FROM train_answer_attempt 
GROUP BY user_id
ORDER BY total_attempts DESC;

-- 3. 基于答题记录重新计算排名
-- 这个会通过后端接口 /train/ranking/refresh 来执行

-- 4. 验证新的排名数据
SELECT 
    r.user_id,
    r.user_name,
    r.score,
    r.rank_type,
    r.period,
    r.create_time
FROM train_ranking r
WHERE r.rank_type = 'overall' AND r.period = 'ALL'
ORDER BY r.score DESC;
