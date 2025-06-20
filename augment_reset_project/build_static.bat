@echo off
chcp 65001 >nul
title Augment Free Trail - 静态编译构建

echo.
echo ===============================================
echo    Augment Free Trail - 静态编译构建
echo ===============================================
echo.

echo 🔧 开始静态编译构建...
echo.

echo 📦 使用 tiny_sqlite 模块进行静态编译
echo ✅ 无需外部 SQLite 库或 DLL 文件
echo ✅ 生成独立的可执行文件
echo.

echo 🚀 执行构建命令...
nimble static

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ 静态编译构建成功！
    echo.
    echo 📁 生成的文件位置：
    echo    target\output\augment_reset.exe
    echo.
    echo 🎉 程序已静态编译，包含以下特性：
    echo    • 内置 SQLite 3.31.1
    echo    • 无需外部依赖
    echo    • 可在任何 Windows 系统上运行
    echo.
) else (
    echo.
    echo ❌ 构建失败！
    echo 请检查错误信息并重试。
    echo.
)

echo 按任意键退出...
pause >nul
