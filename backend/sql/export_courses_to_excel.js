/**
 * 从数据库导出课程数据生成Excel模板
 * 使用方法：在Node.js环境中运行，或转换为浏览器脚本
 * 
 * 需要安装依赖：
 * npm install exceljs
 */

const ExcelJS = require('exceljs');
const mysql = require('mysql2/promise');

// 数据库配置（请通过环境变量传入敏感信息）
const dbConfig = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'hotel_training'
};

function assertDbConfig() {
  if (!dbConfig.password) {
    throw new Error('缺少 DB_PASSWORD 环境变量，请先设置数据库密码');
  }
}

async function exportCoursesToExcel() {
  let connection;
  
  try {
    assertDbConfig();

    // 连接数据库
    connection = await mysql.createConnection(dbConfig);
    console.log('✅ 数据库连接成功');
    
    // 查询课程数据
    const [rows] = await connection.execute(`
      SELECT 
        main_title AS '主标题',
        main_s AS '分类',
        specific_category AS '具体分类',
        third_level_c AS '课程名称',
        knowledge_points AS '知识点',
        cover_image AS '课程封面',
        CASE 
          WHEN level = 'basic' THEN '基础'
          WHEN level = 'advance' THEN '进阶'
          WHEN level = 'expert' THEN '高级'
          ELSE '基础'
        END AS '学习层级',
        sort_order AS '排序'
      FROM course_category
      ORDER BY sort_order, course_category_id
    `);
    
    console.log(`📊 查询到 ${rows.length} 条课程数据`);
    
    // 创建工作簿
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('课程数据');
    
    // 定义表头
    const headers = [
      '主标题',
      '分类',
      '具体分类',
      '课程名称',
      '知识点',
      '课程封面',
      '学习层级',
      '排序'
    ];
    
    // 设置表头样式
    worksheet.columns = headers.map(header => ({
      header,
      key: header,
      width: header === '课程名称' ? 40 : header === '知识点' ? 50 : 15
    }));
    
    // 设置表头样式
    worksheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    worksheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF366092' }
    };
    worksheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };
    
    // 添加数据
    rows.forEach(row => {
      worksheet.addRow(row);
    });
    
    // 为学习层级列添加数据验证
    const levelCol = worksheet.getColumn('学习层级');
    levelCol.eachCell((cell, rowNumber) => {
      if (rowNumber > 1) { // 跳过表头
        // 可以添加数据验证
      }
    });
    
    // 保存文件
    const filename = `课程数据导出_${new Date().toISOString().split('T')[0]}.xlsx`;
    await workbook.xlsx.writeFile(filename);
    
    console.log(`✅ Excel文件已生成：${filename}`);
    console.log(`📝 文件位置：${require('path').resolve(filename)}`);
    console.log(`💡 提示：可以直接修改此文件后重新导入`);
    
  } catch (error) {
    console.error('❌ 导出失败：', error.message);
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 数据库连接已关闭');
    }
  }
}

// 运行导出
if (require.main === module) {
  exportCoursesToExcel();
}

module.exports = { exportCoursesToExcel };

