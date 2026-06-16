-- 知识文章表添加部门字段，实现部门隔离审核
-- 执行数据库: hotel_training (从库)

-- 1. 添加部门相关字段
ALTER TABLE train_knowledge_article 
ADD COLUMN dept_id BIGINT(20) DEFAULT NULL COMMENT '作者部门ID' AFTER author_name,
ADD COLUMN dept_name VARCHAR(100) DEFAULT NULL COMMENT '作者部门名称' AFTER dept_id;

-- 2. 添加索引
ALTER TABLE train_knowledge_article ADD INDEX idx_dept_id (dept_id);

-- 3. 更新现有数据（如果有的话，从sys_user表获取部门信息）
-- 注意：sys_user在主库hz-vue，train_knowledge_article在从库hotel_training
-- 需要手动执行或通过应用层更新

-- 说明：
-- dept_id: 文章作者所属部门ID
-- dept_name: 文章作者所属部门名称（冗余存储，避免跨库查询）
-- 
-- 审核规则：
-- 1. 超级管理员(admin)可以审核所有文章
-- 2. 部门管理员只能审核本部门及下级部门员工的文章
-- 3. 通过部门ancestors字段判断层级关系
