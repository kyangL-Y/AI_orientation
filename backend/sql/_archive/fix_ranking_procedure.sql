-- ================================================
-- 修复排行榜存储过程 - 移除对 sys_user 表的依赖
-- 问题：sys_user 在主库 hz-vue，存储过程在从库 hotel_training
-- 解决：只返回 user_id，用户信息由后端代码关联查询
-- ================================================

USE hotel_training;

-- 删除旧的存储过程
DROP PROCEDURE IF EXISTS GetRankingWithPosition;

DELIMITER //
CREATE PROCEDURE GetRankingWithPosition(
    IN p_ranking_type VARCHAR(20),
    IN p_limit INT
)
BEGIN
    -- 根据类型选择不同的排行榜（不再 JOIN sys_user）
    IF p_ranking_type = 'total' THEN
        SELECT 
            @rank := @rank + 1 as rank_position,
            us.user_id,
            us.total_questions,
            us.correct_answers,
            us.accuracy_rate,
            us.total_time_spent,
            us.avg_time_per_question
        FROM user_statistics us
        CROSS JOIN (SELECT @rank := 0) r
        WHERE us.stat_type = 'total' AND us.total_questions > 0
        ORDER BY us.accuracy_rate DESC, us.total_questions DESC
        LIMIT p_limit;
    ELSEIF p_ranking_type = 'exam' THEN
        SELECT 
            @rank := @rank + 1 as rank_position,
            us.user_id,
            us.total_questions,
            us.correct_answers,
            us.accuracy_rate
        FROM user_statistics us
        CROSS JOIN (SELECT @rank := 0) r
        WHERE us.stat_type = 'exam' AND us.total_questions > 0
        ORDER BY us.accuracy_rate DESC, us.total_questions DESC
        LIMIT p_limit;
    ELSEIF p_ranking_type = 'practice' THEN
        SELECT 
            @rank := @rank + 1 as rank_position,
            us.user_id,
            us.total_questions,
            us.correct_answers,
            us.accuracy_rate
        FROM user_statistics us
        CROSS JOIN (SELECT @rank := 0) r
        WHERE us.stat_type = 'practice' AND us.total_questions > 0
        ORDER BY us.accuracy_rate DESC, us.total_questions DESC
        LIMIT p_limit;
    END IF;
END //
DELIMITER ;
