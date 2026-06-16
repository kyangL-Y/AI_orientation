-- 补充考试导出权限菜单按钮（与 TrainExamController.export() 的 @PreAuthorize 对齐）
INSERT INTO sys_menu VALUES('2115', '考试导出', '2002', '6', '', '', '', '', 1, 0, 'F', '0', '0', 'train:exam:export', '#', 'admin', sysdate(), '', null, '');
