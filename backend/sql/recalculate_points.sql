-- =====================================================
-- 重新计算用户积分脚本
-- 规则：每答对一题 = 1积分
-- =====================================================
-- 数据库: ry-vue (主库，train_user_points 表在主库)
-- =====================================================

USE `ry-vue`;

-- 1. 先清空积分日志表（可选，如果想保留历史记录可以注释掉）
-- TRUNCATE TABLE train_user_points_log;

-- 2. 重新计算所有用户积分（基于答对的题目数量，每题1分）
-- 注意：train_answer_attempt 表在从库 hotel_training 中
-- 需要跨库查询或者先导出数据

-- 方法1：如果可以跨库查询
UPDATE train_user_points tup
SET total_points = (
    SELECT COUNT(*)
    FROM `hotel_training`.train_answer_attempt taa
    WHERE taa.user_id = tup.user_id AND taa.is_correct = 1
),
update_time = NOW()
WHERE 1=1;

-- 3. 为没有积分记录但有答题记录的用户创建积分记录
INSERT INTO train_user_points (user_id, total_points, create_time, update_time)
SELECT
    taa.user_id,
    COUNT(*) as total_points,
    NOW(),
    NOW()
FROM `hotel_training`.train_answer_attempt taa
WHERE taa.is_correct = 1
AND taa.user_id NOT IN (SELECT user_id FROM train_user_points)
GROUP BY taa.user_id;

-- 4. 记录本次重新计算的日志
INSERT INTO train_user_points_log (user_id, points_change, reason, create_time)
SELECT
    user_id,
    total_points,
    '系统重新计算：按新规则每答对一题1积分',
    NOW()
FROM train_user_points
WHERE total_points > 0;

-- 5. 查看结果
SELECT
    tup.user_id,
    su.user_name,
    su.nick_name,
    tup.total_points,
    tup.update_time
FROM train_user_points tup
LEFT JOIN sys_user su ON tup.user_id = su.user_id
ORDER BY tup.total_points DESC
LIMIT 20;

SELECT '积分重新计算完成！' as message;
