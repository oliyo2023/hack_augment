@echo off
chcp 65001 >nul
title Augment Reset - 超精简构建

echo.
echo ===============================================
echo    🗜️  Augment Reset - 超精简版本构建
echo ===============================================
echo.

echo 📊 当前优化版本大小:
dir target\release\augment-reset.exe | findstr augment-reset

echo.
echo 🔧 构建超精简版本...

REM 备份原始 Cargo.toml
copy Cargo.toml Cargo-full.toml >nul

REM 使用精简配置
copy Cargo-minimal.toml Cargo.toml >nul

echo   正在使用超精简配置构建...
cargo build --release
if %errorlevel% neq 0 (
    echo ❌ 超精简构建失败
    copy Cargo-full.toml Cargo.toml >nul
    pause
    exit /b 1
)

echo.
echo 📊 超精简版本大小:
dir target\release\augment-reset.exe | findstr augment-reset

REM 恢复原始配置
copy Cargo-full.toml Cargo.toml >nul

echo.
echo 📊 大小对比总结:
echo   完整版本: ~3.5 MB
echo   优化版本: ~2.3 MB  
echo   超精简版: 
dir target\release\augment-reset.exe | findstr augment-reset

echo.
echo ⚠️  注意: 超精简版本需要系统安装 SQLite 库
echo    Windows: 需要 sqlite3.dll
echo    Linux: 需要 libsqlite3
echo    macOS: 系统自带 SQLite

echo.
echo ✅ 构建完成！
pause
