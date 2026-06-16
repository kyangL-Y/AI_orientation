@echo off
echo Executing schema fix on hotel_training database...

set "DB_HOST=bj-cynosdbmysql-grp-387h2m8k.sql.tencentcdb.com"
set "DB_PORT=27608"
set "DB_USER=root"
set "DB_NAME=hotel_training"

if "%DB_PASSWORD%"=="" (
  echo ERROR: DB_PASSWORD is not set.
  echo Usage: set DB_PASSWORD=your_password
  exit /b 1
)

mysql -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -p%DB_PASSWORD% %DB_NAME% < fix_schema_mismatch.sql
echo.
echo Done! Check the output above for results.
pause
