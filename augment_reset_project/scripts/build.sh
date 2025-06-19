#!/bin/bash
# Linux/macOS 构建脚本

echo "🚀 构建 Augment Reset Tool"
echo "============================"

echo ""
echo "📦 清理旧文件..."
rm -f augment_reset
rm -f src/augment_reset

echo ""
echo "🔨 编译发布版本..."
nimble build -d:release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo "📁 可执行文件: augment_reset"
    echo ""
    echo "💡 使用方法:"
    echo "   ./augment_reset"
else
    echo ""
    echo "❌ 构建失败！"
    exit 1
fi
