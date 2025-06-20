#!/bin/bash
# Augment Reset Tool 启动脚本 (Linux/macOS)

echo "🚀 Augment Reset Tool v2.1.0"
echo "==============================="

# 检查可执行文件是否存在
if [ ! -f "target/output/augment_reset" ]; then
    echo "❌ 可执行文件不存在，正在构建..."
    echo ""
    nimble build -d:release
    if [ $? -ne 0 ]; then
        echo "❌ 构建失败！"
        exit 1
    fi
    echo "✅ 构建完成！"
    echo ""
fi

# 运行程序
echo "🔄 启动 Augment Reset Tool..."
echo ""
./target/output/augment_reset

echo ""
echo "程序执行完成。"
