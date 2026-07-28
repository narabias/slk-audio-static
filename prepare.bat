@echo off
setlocal
where node >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Node.js 18 or newer is required: https://nodejs.org/
  pause
  exit /b 1
)
copy /Y app.js.txt app.js >nul
copy /Y tools\prepare-vendor.mjs.txt tools\prepare-vendor.mjs >nul
call npm run setup:vendor
if errorlevel 1 (
  echo [ERROR] Preparation failed.
  pause
  exit /b 1
)
echo.
echo Vendor files prepared. You may now upload the whole folder to GitHub.
pause
