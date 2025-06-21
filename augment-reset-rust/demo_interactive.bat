@echo off
chcp 65001 >nul
title Augment Reset - 交互式菜单演示

echo.
echo ===============================================
echo    🎯 Augment Reset 交互式菜单演示
echo ===============================================
echo.

echo 📋 新增的交互式菜单功能:
echo   ✅ 主菜单选项 (开始清理/查看统计/退出)
echo   ✅ 编辑器选择菜单 (支持返回主菜单)
echo   ✅ 统计信息查看
echo   ✅ 优雅的退出选项
echo.

echo 🚀 启动交互式菜单...
echo.
echo 💡 提示: 
echo   - 使用方向键选择选项
echo   - 按回车键确认选择
echo   - 在编辑器选择中使用空格键多选
echo   - 选择 "退出程序" 可以安全退出
echo.

pause

echo.
echo 正在启动 Augment Reset 交互式模式...
echo.

.\target\release\augment-reset.exe

echo.
echo 演示完成！
pause
