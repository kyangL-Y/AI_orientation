ALTER TABLE hotel_training.train_progress
    ADD COLUMN course_type varchar(32) NOT NULL DEFAULT 'ota' COMMENT '课程来源类型：ota,green_hotel,dept,culture' AFTER course_name,
    ADD COLUMN course_meta json NULL COMMENT '课程回放上下文，用于继续学习恢复详情页' AFTER course_type;

CREATE INDEX idx_train_progress_user_course_type
    ON hotel_training.train_progress (user_id, course_id, course_type);

UPDATE hotel_training.train_progress
SET course_type = 'ota'
WHERE course_type IS NULL OR course_type = '';
