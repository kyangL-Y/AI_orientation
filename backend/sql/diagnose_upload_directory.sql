-- 诊断文件上传目录问题
-- 执行时间: 2026-01-26

-- 此脚本用于诊断文件上传 "Input/output error" 问题
-- 问题通常由以下原因引起：
-- 1. COS 挂载点权限问题
-- 2. 磁盘空间不足
-- 3. cosfs 挂载不稳定

-- 检查步骤（需要在服务器上手动执行）：

-- 1. 检查上传目录是否存在
-- ls -la /lhcos-data/uploadPath/upload

-- 2. 检查目录权限
-- stat /lhcos-data/uploadPath/upload

-- 3. 检查磁盘空间
-- df -h /lhcos-data/uploadPath

-- 4. 检查 cosfs 挂载状态
-- mount | grep lhcos-data

-- 5. 测试写入权限
-- touch /lhcos-data/uploadPath/upload/test.txt
-- echo "test" > /lhcos-data/uploadPath/upload/test.txt
-- cat /lhcos-data/uploadPath/upload/test.txt
-- rm /lhcos-data/uploadPath/upload/test.txt

-- 6. 检查应用进程的用户权限
-- ps aux | grep java

-- 临时解决方案：
-- 如果 COS 挂载有问题，可以临时切换到本地存储
-- 修改 application.yml 中的 profile 配置：
-- profile: D:/ruoyi/uploadPath  # Windows 本地
-- profile: /home/ruoyi/uploadPath  # Linux 本地

-- 永久解决方案：
-- 1. 确保 cosfs 正确挂载并有写入权限
-- 2. 设置正确的目录权限: chmod 755 /lhcos-data/uploadPath/upload
-- 3. 确保应用运行用户有权限访问该目录
-- 4. 考虑使用 COS SDK 直接上传，而不是通过 cosfs 挂载点

SELECT '文件上传诊断脚本' as message;
