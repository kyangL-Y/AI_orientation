-- 学习计划模块字典数据
-- 华智酒店员工培训系统

-- 1. 学习计划状态字典类型
INSERT INTO sys_dict_type (dict_name, dict_type, status, create_by, create_time, remark) VALUES
('学习计划状态', 'train_plan_status', '0', 'admin', sysdate(), '学习计划状态列表');

-- 2. 学习计划状态字典数据
INSERT INTO sys_dict_data (dict_sort, dict_label, dict_value, dict_type, css_class, list_class, is_default, status, create_by, create_time, remark) VALUES
(1, '草稿', 'draft', 'train_plan_status', '', 'info', 'N', '0', 'admin', sysdate(), '草稿状态'),
(2, '进行中', 'active', 'train_plan_status', '', 'success', 'N', '0', 'admin', sysdate(), '进行中状态'),
(3, '已完成', 'completed', 'train_plan_status', '', 'success', 'N', '0', 'admin', sysdate(), '已完成状态'),
(4, '已取消', 'cancelled', 'train_plan_status', '', 'danger', 'N', '0', 'admin', sysdate(), '已取消状态');

-- 3. 任务项状态字典类型
INSERT INTO sys_dict_type (dict_name, dict_type, status, create_by, create_time, remark) VALUES
('任务项状态', 'train_task_status', '0', 'admin', sysdate(), '任务项状态列表');

-- 4. 任务项状态字典数据
INSERT INTO sys_dict_data (dict_sort, dict_label, dict_value, dict_type, css_class, list_class, is_default, status, create_by, create_time, remark) VALUES
(1, '待完成', 'pending', 'train_task_status', '', 'info', 'N', '0', 'admin', sysdate(), '待完成状态'),
(2, '进行中', 'in_progress', 'train_task_status', '', 'warning', 'N', '0', 'admin', sysdate(), '进行中状态'),
(3, '已完成', 'completed', 'train_task_status', '', 'success', 'N', '0', 'admin', sysdate(), '已完成状态'),
(4, '已逾期', 'overdue', 'train_task_status', '', 'danger', 'N', '0', 'admin', sysdate(), '已逾期状态');

-- 5. 内容类型字典类型
INSERT INTO sys_dict_type (dict_name, dict_type, status, create_by, create_time, remark) VALUES
('内容类型', 'train_content_type', '0', 'admin', sysdate(), '培训内容类型列表');

-- 6. 内容类型字典数据
INSERT INTO sys_dict_data (dict_sort, dict_label, dict_value, dict_type, css_class, list_class, is_default, status, create_by, create_time, remark) VALUES
(1, '课程', 'course', 'train_content_type', '', 'primary', 'N', '0', 'admin', sysdate(), '课程类型'),
(2, '考试', 'quiz', 'train_content_type', '', 'success', 'N', '0', 'admin', sysdate(), '考试类型'),
(3, '任务', 'task', 'train_content_type', '', 'warning', 'N', '0', 'admin', sysdate(), '任务类型');
