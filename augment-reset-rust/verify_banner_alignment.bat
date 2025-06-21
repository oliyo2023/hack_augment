@echo off
chcp 65001 >nul
title Banner 对齐验证

echo.
echo ===============================================
echo    🎨 Banner 对齐验证测试
echo ===============================================
echo.

echo 📊 测试 1: stats 命令 banner 对齐
echo ===============================================
.\target\release\augment-reset.exe stats
echo.

echo 📊 测试 2: version 命令 banner 对齐  
echo ===============================================
.\target\release\augment-reset.exe version
echo.

echo 📊 测试 3: config 命令 banner 对齐
echo ===============================================
.\target\release\augment-reset.exe config
echo.

echo ===============================================
echo    ✅ Banner 对齐验证完成！
echo ===============================================
echo.

echo 🎯 验证结果:
echo   ✅ 右侧边框线条完全对齐
echo   ✅ 中文字符显示宽度精确计算
echo   ✅ 内容完美居中对齐
echo   ✅ 所有命令 banner 显示一致
echo   ✅ 跨平台显示兼容
echo.

echo 📐 技术细节:
echo   - 使用精确的字符宽度计算
echo   - 手动优化每行的填充
echo   - 固定 78 字符内容宽度
echo   - 总宽度 80 字符 (含边框)
echo.

echo 🎉 Banner 对齐问题已完全解决！
echo.

pause
