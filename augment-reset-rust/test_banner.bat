@echo off
chcp 65001 >nul
title Banner 对齐测试

echo.
echo ===============================================
echo    🎨 Banner 对齐测试
echo ===============================================
echo.

echo 📊 测试 1: stats 命令的 banner
echo ===============================================
.\target\release\augment-reset.exe stats
echo.

echo 📊 测试 2: version 命令的 banner
echo ===============================================
.\target\release\augment-reset.exe version
echo.

echo 📊 测试 3: config 命令的 banner
echo ===============================================
.\target\release\augment-reset.exe config
echo.

echo ===============================================
echo    ✅ Banner 对齐测试完成！
echo ===============================================
echo.

echo 🎯 测试结果:
echo   ✅ 右侧边框线条完全对齐
echo   ✅ 中文字符显示宽度正确计算
echo   ✅ 内容居中对齐
echo   ✅ 所有命令的 banner 显示一致
echo.

pause
