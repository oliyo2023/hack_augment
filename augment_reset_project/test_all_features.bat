@echo off
chcp 65001 >nul
title Augment Free Trail - 功能测试

echo.
echo ===============================================
echo    Augment Free Trail v2.2.0 功能测试
echo ===============================================
echo.

echo 1. 测试帮助信息：
echo.
.\augment_reset.exe --help
echo.

echo.
echo ===============================================
echo.

echo 2. 测试版本信息：
echo.
.\augment_reset.exe --version
echo.

echo.
echo ===============================================
echo.

echo 3. 测试非交互式 JetBrains 清理：
echo.
echo "" | .\augment_reset.exe --jetbrains --no-interactive
echo.

echo.
echo ===============================================
echo.
echo 所有功能测试完成！
echo.
echo 关注公众号：趣惠赚字老AI
echo 访问网站：https://www.oliyo.com
echo.
pause
