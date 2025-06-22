@echo off
setlocal enabledelayedexpansion

REM Augment Reset 跨平台编译脚本 (Windows版本)
REM 支持多种目标平台和编译选项

title Augment Reset 跨平台编译工具

REM 颜色定义 (Windows 10+ 支持 ANSI 颜色)
set "RED=[31m"
set "GREEN=[32m"
set "YELLOW=[33m"
set "BLUE=[34m"
set "CYAN=[36m"
set "NC=[0m"

REM 项目信息
set "PROJECT_NAME=augment-reset"
for /f "tokens=3 delims= " %%a in ('findstr "^version" Cargo.toml') do (
    set "VERSION=%%a"
    set "VERSION=!VERSION:"=!"
)

echo %CYAN%🌍 Augment Reset 跨平台编译工具%NC%
echo %BLUE%版本: !VERSION! ^| 时间: %date% %time%%NC%
echo.

REM 支持的目标平台
set "TARGET_COUNT=0"
set "TARGET_0=x86_64-pc-windows-gnu"
set "TARGET_DESC_0=Windows x64 (GNU)"
set /a TARGET_COUNT+=1

set "TARGET_1=x86_64-pc-windows-msvc"
set "TARGET_DESC_1=Windows x64 (MSVC)"
set /a TARGET_COUNT+=1

set "TARGET_2=i686-pc-windows-gnu"
set "TARGET_DESC_2=Windows x86 (GNU)"
set /a TARGET_COUNT+=1

set "TARGET_3=x86_64-unknown-linux-gnu"
set "TARGET_DESC_3=Linux x64 (glibc)"
set /a TARGET_COUNT+=1

set "TARGET_4=x86_64-unknown-linux-musl"
set "TARGET_DESC_4=Linux x64 (musl)"
set /a TARGET_COUNT+=1

set "TARGET_5=aarch64-unknown-linux-gnu"
set "TARGET_DESC_5=Linux ARM64"
set /a TARGET_COUNT+=1

set "TARGET_6=x86_64-apple-darwin"
set "TARGET_DESC_6=macOS Intel"
set /a TARGET_COUNT+=1

set "TARGET_7=aarch64-apple-darwin"
set "TARGET_DESC_7=macOS Apple Silicon"
set /a TARGET_COUNT+=1

REM 函数：打印消息
goto :main

:print_info
echo %BLUE%ℹ️  %~1%NC%
goto :eof

:print_success
echo %GREEN%✅ %~1%NC%
goto :eof

:print_warning
echo %YELLOW%⚠️  %~1%NC%
goto :eof

:print_error
echo %RED%❌ %~1%NC%
goto :eof

REM 函数：检查依赖
:check_dependencies
call :print_info "检查构建依赖..."

where cargo >nul 2>&1
if errorlevel 1 (
    call :print_error "Cargo 未安装"
    exit /b 1
)

where rustc >nul 2>&1
if errorlevel 1 (
    call :print_error "Rust 编译器未安装"
    exit /b 1
)

where cross >nul 2>&1
if errorlevel 1 (
    call :print_warning "未发现 cross 工具，使用 cargo 进行编译"
    call :print_info "建议安装 cross: cargo install cross"
    set "USE_CROSS=false"
) else (
    call :print_success "发现 cross 工具，将使用它进行跨平台编译"
    set "USE_CROSS=true"
)

call :print_success "依赖检查完成"
goto :eof

REM 函数：安装目标
:install_target
set "target=%~1"
rustup target list --installed | findstr /c:"%target%" >nul
if errorlevel 1 (
    call :print_info "安装目标: %target%"
    rustup target add "%target%"
)
goto :eof

REM 函数：编译单个目标
:compile_target
set "target=%~1"
set "feature_flag=%~2"
if "%feature_flag%"=="" set "feature_flag=--features full"

REM 查找目标描述
set "description="
for /l %%i in (0,1,%TARGET_COUNT%) do (
    if "!TARGET_%%i!"=="%target%" (
        set "description=!TARGET_DESC_%%i!"
        goto :found_desc
    )
)
:found_desc

call :print_info "编译目标: %target% (%description%)"

REM 安装目标
call :install_target "%target%"

REM 创建输出目录
set "output_dir=dist\%target%"
if not exist "%output_dir%" mkdir "%output_dir%"

REM 选择编译工具
if "%USE_CROSS%"=="true" (
    set "compile_cmd=cross build --release --target %target% %feature_flag%"
) else (
    set "compile_cmd=cargo build --release --target %target% %feature_flag%"
)

REM 执行编译
call :print_info "执行编译命令: %compile_cmd%"
%compile_cmd%
if errorlevel 1 (
    call :print_error "编译失败: %target%"
    goto :eof
)

REM 复制可执行文件
set "exe_name=%PROJECT_NAME%"
echo %target% | findstr "windows" >nul
if not errorlevel 1 set "exe_name=%PROJECT_NAME%.exe"

set "src_path=target\%target%\release\%exe_name%"
set "dst_path=%output_dir%\%exe_name%"

if exist "%src_path%" (
    copy "%src_path%" "%dst_path%" >nul
    
    REM 获取文件大小
    for %%F in ("%dst_path%") do set "file_size=%%~zF"
    
    REM 转换为人类可读格式
    if !file_size! gtr 1048576 (
        set /a "human_size=!file_size!/1048576"
        set "size_unit=MB"
    ) else if !file_size! gtr 1024 (
        set /a "human_size=!file_size!/1024"
        set "size_unit=KB"
    ) else (
        set "human_size=!file_size!"
        set "size_unit=B"
    )
    
    call :print_success "编译完成: %target% (!human_size! %size_unit%)"
) else (
    call :print_error "编译产物未找到: %src_path%"
)
goto :eof

REM 函数：编译所有目标
:compile_all_targets
set "feature_flag=%~1"
if "%feature_flag%"=="" set "feature_flag=--features full"

set "success_count=0"
set "failed_targets="

call :print_info "开始编译所有支持的目标..."

for /l %%i in (0,1,%TARGET_COUNT%) do (
    set "current_target=!TARGET_%%i!"
    call :compile_target "!current_target!" "%feature_flag%"
    if not errorlevel 1 (
        set /a success_count+=1
    ) else (
        set "failed_targets=!failed_targets! !current_target!"
    )
    echo.
)

call :print_info "编译结果汇总:"
echo   成功: %success_count%/%TARGET_COUNT%

if not "%failed_targets%"=="" (
    echo   失败的目标:%failed_targets%
)
goto :eof

REM 函数：显示支持的目标
:show_targets
call :print_info "支持的编译目标:"
echo.

echo Windows:
for /l %%i in (0,1,%TARGET_COUNT%) do (
    set "target=!TARGET_%%i!"
    echo !target! | findstr "windows" >nul
    if not errorlevel 1 (
        echo   !target! - !TARGET_DESC_%%i!
    )
)

echo.
echo Linux:
for /l %%i in (0,1,%TARGET_COUNT%) do (
    set "target=!TARGET_%%i!"
    echo !target! | findstr "linux" >nul
    if not errorlevel 1 (
        echo   !target! - !TARGET_DESC_%%i!
    )
)

echo.
echo macOS:
for /l %%i in (0,1,%TARGET_COUNT%) do (
    set "target=!TARGET_%%i!"
    echo !target! | findstr "apple" >nul
    if not errorlevel 1 (
        echo   !target! - !TARGET_DESC_%%i!
    )
)
goto :eof

REM 函数：显示帮助
:show_help
echo 用法: %~nx0 [选项] [目标]
echo.
echo 选项:
echo   --all           编译所有支持的目标
echo   --minimal       使用最小功能集编译
echo   --list          显示所有支持的目标
echo   --help          显示此帮助信息
echo.
echo 目标:
echo   可以指定一个目标进行编译
echo   如果不指定目标，将编译当前平台的目标
echo.
echo 示例:
echo   %~nx0 --all                           # 编译所有目标
echo   %~nx0 x86_64-pc-windows-gnu          # 编译 Windows x64
echo   %~nx0 --minimal x86_64-pc-windows-gnu # 使用最小功能集编译
goto :eof

REM 主函数
:main
REM 检查依赖
call :check_dependencies
if errorlevel 1 exit /b 1

REM 解析命令行参数
set "compile_all=false"
set "feature_flag=--features full"
set "target="

:parse_args
if "%~1"=="" goto :end_parse
if "%~1"=="--all" (
    set "compile_all=true"
    shift
    goto :parse_args
)
if "%~1"=="--minimal" (
    set "feature_flag="
    shift
    goto :parse_args
)
if "%~1"=="--list" (
    call :show_targets
    exit /b 0
)
if "%~1"=="--help" (
    call :show_help
    exit /b 0
)
if "%~1"=="-h" (
    call :show_help
    exit /b 0
)
if "%~1:~0,2%"=="--" (
    call :print_error "未知选项: %~1"
    call :show_help
    exit /b 1
)
set "target=%~1"
shift
goto :parse_args

:end_parse

REM 创建输出目录
if not exist "dist" mkdir "dist"

REM 执行编译
if "%compile_all%"=="true" (
    call :compile_all_targets "%feature_flag%"
) else if not "%target%"=="" (
    call :compile_target "%target%" "%feature_flag%"
) else (
    REM 默认编译当前平台 (Windows)
    call :print_info "编译当前平台目标: x86_64-pc-windows-msvc"
    call :compile_target "x86_64-pc-windows-msvc" "%feature_flag%"
)

call :print_success "跨平台编译完成！"
call :print_info "编译产物位于 dist\ 目录中"

endlocal
pause
