@echo off
chcp 65001 >nul
title Augment Reset - 文件压缩

echo.
echo ===============================================
echo    🗜️  Augment Reset - 文件大小优化
echo ===============================================
echo.

echo 📊 当前文件大小:
dir target\release\augment-reset.exe | findstr augment-reset

echo.
echo 🔧 开始优化构建...

REM 使用大小优化的配置重新构建
echo   正在使用大小优化配置重新构建...
cargo build --release --no-default-features --features minimal
if %errorlevel% neq 0 (
    echo ❌ 优化构建失败
    pause
    exit /b 1
)

echo.
echo 📊 优化后文件大小:
dir target\release\augment-reset.exe | findstr augment-reset

echo.
echo 🗜️  检查是否有 UPX 压缩工具...
where upx >nul 2>nul
if %errorlevel% equ 0 (
    echo   找到 UPX，开始压缩...
    copy target\release\augment-reset.exe target\release\augment-reset-original.exe >nul
    upx --best --lzma target\release\augment-reset.exe
    echo.
    echo 📊 压缩后文件大小:
    dir target\release\augment-reset.exe | findstr augment-reset
    echo.
    echo 📊 压缩对比:
    echo   原始文件: target\release\augment-reset-original.exe
    echo   压缩文件: target\release\augment-reset.exe
    dir target\release\augment-reset*.exe | findstr augment-reset
) else (
    echo   未找到 UPX 压缩工具
    echo   可以从 https://upx.github.io/ 下载 UPX 来进一步压缩文件
)

echo.
echo ✅ 优化完成！
echo.
pause
