-- 数据迁移脚本：从 train_question 迁移到 training_question
-- 请在数据库中分步执行此脚本

-- 1. 创建新的 training_question 表
CREATE TABLE IF NOT EXISTS `training_question` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `hotel_code` varchar(50) DEFAULT NULL COMMENT '酒店代码',
  `category` varchar(100) DEFAULT NULL COMMENT '分类',
  `dept_id` bigint(20) DEFAULT NULL COMMENT '部门ID',
  `question_type` varchar(50) DEFAULT NULL COMMENT '题目类型',
  `question_text` text NOT NULL COMMENT '题目内容',
  `option_a` text DEFAULT NULL COMMENT '选项A',
  `option_b` text DEFAULT NULL COMMENT '选项B',
  `option_c` text DEFAULT NULL COMMENT '选项C',
  `option_d` text DEFAULT NULL COMMENT '选项D',
  `correct_answer` varchar(10) DEFAULT NULL COMMENT '正确答案',
  `difficulty` varchar(50) DEFAULT NULL COMMENT '难度',
  `status` int(1) DEFAULT '0' COMMENT '状态',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(64) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(64) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='培训-题库';

-- 2. 如果原表 train_question 存在数据，迁移到新表
INSERT INTO training_question (
    question_text, category, difficulty, status, remark, 
    create_by, create_time, update_by, update_time
)
SELECT 
    title as question_text, 
    category, 
    CASE 
        WHEN difficulty = 'easy' THEN '简单'
        WHEN difficulty = 'medium' THEN '中等'
        WHEN difficulty = 'hard' THEN '困难'
        ELSE difficulty 
    END as difficulty,
    0 as status,
    remark, 
    create_by, 
    create_time, 
    update_by, 
    update_time
FROM train_question 
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'train_question');

-- 3. 更新权限分配表中的question_id映射
-- 这一步需要根据实际情况手动处理，因为ID可能发生变化

-- 4. 删除旧表（请确认数据迁移成功后再执行）
-- DROP TABLE IF EXISTS train_question;