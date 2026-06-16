@echo off
echo.
echo [信息] 执行 mvn clean verify（含测试 + JaCoCo 覆盖率报告）
echo.

%~d0
cd %~dp0

cd ..
call mvn clean verify

pause
