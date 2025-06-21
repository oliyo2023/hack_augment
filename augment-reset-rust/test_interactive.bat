@echo off
chcp 65001 >nul
echo 测试交互式菜单

echo.
echo ===============================================
echo    🧪 测试 1: 查看统计信息然后退出
echo ===============================================
echo.

echo 输入: 1 (查看统计信息) -> 回车 -> 2 (退出)
(echo 1 & echo. & echo 2) | .\target\release\augment-reset.exe

echo.
echo ===============================================
echo    🧪 测试 2: 直接退出
echo ===============================================
echo.

echo 输入: 2 (退出)
echo 2 | .\target\release\augment-reset.exe

echo.
echo ===============================================
echo    🧪 测试 3: 开始清理但返回主菜单然后退出
echo ===============================================
echo.

echo 输入: 0 (开始清理) -> 空格选择返回 -> 回车 -> 2 (退出)
(echo 0 & echo  & echo. & echo 2) | .\target\release\augment-reset.exe

echo.
echo 测试完成！
pause
