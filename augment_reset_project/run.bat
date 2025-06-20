@echo off
REM Augment Reset Tool 启动脚本 (Windows)

echo 🚀 Augment Reset Tool v2.2.0
echo ===============================

REM 检查可执行文件是否存在
if not exist "target\output\augment_reset.exe" (
    echo ❌ 可执行文件不存在，正在构建...
    echo.
    nimble build -d:release
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ 构建失败！
        pause
        exit /b 1
    )
    echo ✅ 构建完成！
    echo.
)

REM 运行程序
echo 🔄 启动 Augment Reset Tool...
echo.
target\output\augment_reset.exe

echo.
echo 程序执行完成。
pause
