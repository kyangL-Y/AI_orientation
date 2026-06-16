ALTER TABLE `train_exam_assign`
    MODIFY COLUMN `target_id` VARCHAR(64) NOT NULL COMMENT '目标ID（用户/部门/租户等）';
