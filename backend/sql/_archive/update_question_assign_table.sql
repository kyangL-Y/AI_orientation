-- 为 train_question_assign 表添加新的字段以支持灵活的权限分配
ALTER TABLE train_question_assign 
ADD COLUMN hotel_code VARCHAR(10) NULL COMMENT '酒店代码，用于酒店级权限控制' AFTER target_id,
ADD COLUMN dept_id BIGINT(20) NULL COMMENT '部门ID，用于部门级权限控制' AFTER hotel_code;

-- 更新现有的索引
ALTER TABLE train_question_assign 
ADD INDEX idx_hotel_code (hotel_code),
ADD INDEX idx_dept_id (dept_id);

-- 注释：新的权限分配策略说明
-- target_type 支持的值：
-- 'user': 按个人分配，target_id为用户ID，hotel_code和dept_id为约束条件
-- 'dept': 按部门分配，target_id为部门ID，hotel_code为约束条件
-- 'role': 按角色分配，target_id为角色ID，hotel_code和dept_id为约束条件
-- 'hotel': 按酒店分配，target_id为酒店代码对应的ID（可设计），hotel_code为酒店代码
-- 'company': 全公司分配，target_id可为公司根角色ID