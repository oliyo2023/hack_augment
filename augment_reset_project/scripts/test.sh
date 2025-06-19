#!/bin/bash
# Linux/macOS 测试脚本

echo "🧪 运行 Augment Reset 测试套件"
echo "================================"

echo ""
echo "🔍 编译并运行测试..."
nim compile --run tests/test_all.nim

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 所有测试通过！"
else
    echo ""
    echo "❌ 测试失败！"
    exit 1
fi

echo ""
echo "🔍 运行示例程序..."
nim compile --run example.nim

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 示例运行成功！"
else
    echo ""
    echo "❌ 示例运行失败！"
    exit 1
fi
