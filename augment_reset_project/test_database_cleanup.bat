@echo off
chcp 65001 >nul
title Augment Free Trail - 数据库清理测试

echo.
echo ===============================================
echo    Augment Free Trail - 数据库清理测试
echo ===============================================
echo.

echo 🗄️ 测试内置 SQLite 数据库清理功能
echo.
echo 此测试将展示程序如何使用内置 SQLite 库清理数据库，
echo 无需依赖外部 SQLite 工具！
echo.

echo 1. 测试 VS Code 数据库清理：
echo.
echo "" | .\augment_reset.exe --vscode --no-interactive
echo.

echo.
echo ===============================================
echo.

echo 2. 测试 Cursor 数据库清理：
echo.
echo "" | .\augment_reset.exe --cursor --no-interactive
echo.

echo.
echo ===============================================
echo.
echo 数据库清理测试完成！
echo.
echo ✅ 程序内置 SQLite 支持
echo ✅ 无需外部 SQLite 工具
echo ✅ 智能检测和清理数据库记录
echo.
echo 关注公众号：趣惠赚字老AI
echo 访问网站：https://www.oliyo.com
echo.
pause
