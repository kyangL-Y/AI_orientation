#!/bin/bash

# 菜单测试脚本
# 用于验证菜单数据是否正确

echo "=========================================="
echo "菜单配置验证脚本"
echo "=========================================="
echo ""

DB_HOST="bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com"
DB_PORT="27608"
DB_USER="root"
DB_PASS="Hzjd8888"
DB_NAME="hz-vue"

echo "1. 检查数据库中的菜单配置..."
echo ""

# 检查菜单类型
echo "检查考试管理和刷题管理的菜单类型："
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "
SELECT menu_id, menu_name, menu_type, component
FROM sys_menu
WHERE menu_id IN (2001, 2002);
" 2>&1 | grep -v Warning

echo ""

# 检查培训中心的分组结构
echo "检查培训中心的分组结构："
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "
SELECT
    m.menu_id,
    m.menu_name,
    m.path,
    m.component,
    COUNT(c.menu_id) as child_count
FROM sys_menu m
LEFT JOIN sys_menu c ON m.menu_id = c.parent_id AND c.menu_type != 'F'
WHERE m.parent_id = 2000
  AND m.menu_type = 'M'
GROUP BY m.menu_id
ORDER BY m.order_num;
" 2>&1 | grep -v Warning

echo ""
echo "2. 验证关键菜单的完整路径..."
echo ""

# 检查排行榜管理的路径
echo "排行榜管理的完整路径："
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "
SELECT
    CONCAT(m1.path, '/', m2.path, '/', m3.path) as full_path,
    m3.menu_name,
    m3.component
FROM sys_menu m3
JOIN sys_menu m2 ON m3.parent_id = m2.menu_id
JOIN sys_menu m1 ON m2.parent_id = m1.menu_id
WHERE m3.menu_id = 2024;
" 2>&1 | grep -v Warning

echo ""
echo "=========================================="
echo "验证完成"
echo "=========================================="
echo ""
echo "预期结果："
echo "1. 考试管理和刷题管理的 menu_type 应该是 'C'"
echo "2. 培训中心下应该有6个分组（智囊阁、题库与练习、课程与学习、考试与考核、学员统计、积分系统）"
echo "3. 排行榜管理的完整路径应该是: train/statistics/ranking"
echo ""
