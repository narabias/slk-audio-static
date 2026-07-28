@echo off
setlocal
where node >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Node.js 18 or newer is required: https://nodejs.org/
  pause
  exit /b 1
)
call npm run setup:vendor
if errorlevel 1 (
  echo [ERROR] Preparation failed.
  pause
  exit /b 1
)
echo.
echo Vendor files prepared. You may now upload the whole folder to GitHub.
pause
