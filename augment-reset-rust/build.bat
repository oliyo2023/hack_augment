@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM Augment Reset (Rust版本) Windows 构建脚本

title Augment Reset - 构建脚本

echo.
echo ===============================================
echo    🚀 Augment Reset (Rust版本) 构建脚本
echo ===============================================
echo.

REM 获取版本号
for /f "tokens=3 delims= " %%a in ('findstr "^version" Cargo.toml') do (
    set VERSION=%%a
    set VERSION=!VERSION:"=!
)

echo 📦 项目: augment-reset
echo 🏷️  版本: %VERSION%
echo.

REM 检查 Rust 是否安装
where cargo >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到 Cargo，请先安装 Rust
    echo 下载地址: https://rustup.rs/
    pause
    exit /b 1
)

REM 检查 rustc 是否安装
where rustc >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到 rustc，请先安装 Rust
    pause
    exit /b 1
)

REM 显示 Rust 信息
echo 🦀 Rust 信息:
rustc --version
cargo --version
echo.

REM 解析命令行参数
set ACTION=%1
if "%ACTION%"=="" set ACTION=local

if "%ACTION%"=="help" goto :show_help
if "%ACTION%"=="-h" goto :show_help
if "%ACTION%"=="--help" goto :show_help
if "%ACTION%"=="clean" goto :clean_build
if "%ACTION%"=="test" goto :run_tests
if "%ACTION%"=="check" goto :check_code
if "%ACTION%"=="local" goto :build_local
if "%ACTION%"=="release" goto :build_release

echo ❌ 未知选项: %ACTION%
goto :show_help

:show_help
echo 用法: %0 [选项]
echo.
echo 选项:
echo   clean       清理构建产物
echo   test        运行测试
echo   check       代码检查
echo   local       构建本地版本
echo   release     构建发布版本
echo   help        显示此帮助信息
echo.
echo 示例:
echo   %0 local    # 构建本地版本
echo   %0 release  # 构建发布版本
goto :end

:clean_build
echo 🧹 清理构建产物...
cargo clean
if exist dist rmdir /s /q dist
echo ✅ 清理完成
goto :end

:run_tests
echo 🧪 运行测试...
cargo test --verbose
if %errorlevel% neq 0 (
    echo ❌ 测试失败
    pause
    exit /b 1
)
echo ✅ 所有测试通过
goto :end

:check_code
echo 🔍 运行代码检查...

REM 格式检查
echo   检查代码格式...
cargo fmt --check
if %errorlevel% neq 0 (
    echo   ⚠️  代码格式不符合标准，正在自动格式化...
    cargo fmt
)

REM Clippy 检查
echo   运行 Clippy 检查...
cargo clippy -- -D warnings
if %errorlevel% neq 0 (
    echo ❌ 代码检查失败
    pause
    exit /b 1
)

echo ✅ 代码检查通过
goto :end

:build_local
echo 🔨 构建本地版本...

REM 先进行代码检查
call :check_code
if %errorlevel% neq 0 exit /b 1

REM 运行测试
call :run_tests
if %errorlevel% neq 0 exit /b 1

REM 构建
echo   正在编译...
cargo build --release
if %errorlevel% neq 0 (
    echo ❌ 构建失败
    pause
    exit /b 1
)

REM 创建输出目录
if not exist dist\local mkdir dist\local

REM 复制可执行文件
copy target\release\augment-reset.exe dist\local\ >nul
if %errorlevel% neq 0 (
    echo ❌ 复制可执行文件失败
    pause
    exit /b 1
)

echo ✅ 本地构建完成
echo 📁 输出文件: dist\local\augment-reset.exe
goto :end

:build_release
echo 🚀 构建发布版本...

REM 先进行代码检查
call :check_code
if %errorlevel% neq 0 exit /b 1

REM 运行测试
call :run_tests
if %errorlevel% neq 0 exit /b 1

REM 构建优化版本
echo   正在编译发布版本...
cargo build --release --target x86_64-pc-windows-msvc
if %errorlevel% neq 0 (
    echo ❌ 发布版本构建失败
    pause
    exit /b 1
)

REM 创建发布目录
if not exist dist\release mkdir dist\release

REM 复制可执行文件
copy target\x86_64-pc-windows-msvc\release\augment-reset.exe dist\release\augment-reset-windows-x64.exe >nul
if %errorlevel% neq 0 (
    echo ❌ 复制发布文件失败
    pause
    exit /b 1
)

REM 创建发布包
echo   创建发布包...
cd dist\release
powershell -Command "Compress-Archive -Path 'augment-reset-windows-x64.exe' -DestinationPath 'augment-reset-windows-x64-v%VERSION%.zip' -Force"
cd ..\..

echo ✅ 发布版本构建完成
echo 📁 输出文件: dist\release\augment-reset-windows-x64.exe
echo 📦 发布包: dist\release\augment-reset-windows-x64-v%VERSION%.zip

REM 显示文件信息
echo.
echo 📊 文件信息:
dir dist\release\augment-reset-windows-x64.exe | findstr augment-reset
goto :end

:end
echo.
echo 🎉 构建脚本执行完成！
echo.
pause
