-- 检查培训模块数据
SELECT 'train_certification' as table_name, COUNT(*) as count FROM train_certification
UNION ALL
SELECT 'train_reward' as table_name, COUNT(*) as count FROM train_reward  
UNION ALL
SELECT 'train_ranking' as table_name, COUNT(*) as count FROM train_ranking
UNION ALL
SELECT 'train_exam' as table_name, COUNT(*) as count FROM train_exam
UNION ALL
SELECT 'train_assessment' as table_name, COUNT(*) as count FROM train_assessment;

-- 查看具体数据
SELECT 'train_certification data:' as info;
SELECT * FROM train_certification LIMIT 5;

SELECT 'train_reward data:' as info;
SELECT * FROM train_reward LIMIT 5;

SELECT 'train_ranking data:' as info;
SELECT * FROM train_ranking LIMIT 5;
