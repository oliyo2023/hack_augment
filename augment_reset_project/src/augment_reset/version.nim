##[
Augment Reset - 版本信息模块

定义版本信息和构建信息
]##

const
  VERSION* = "2.1.0"
  BUILD_DATE* = "2025-06-20"
  AUTHOR* = "oliyo"
  DESCRIPTION* = "Augment 扩展试用期重置工具 - 支持 JetBrains IDE"

  # 功能特性
  FEATURES* = [
    "跨平台支持 (Windows/macOS/Linux)",
    "自动编辑器管理 (VS Code/Cursor/JetBrains)",
    "配置文件重置",
    "数据库清理",
    "JetBrains IDE 支持",
    "Windows 注册表清理",
    "安全备份",
    "模块化架构",
    "完整日志记录"
  ]

# 显示版本信息
proc showVersion*() =
  echo "🚀 ", DESCRIPTION
  echo "版本: v", VERSION
  echo "构建日期: ", BUILD_DATE
  echo "作者: ", AUTHOR
  echo ""
  echo "功能特性:"
  for feature in FEATURES:
    echo "  ✅ ", feature

# 显示简短版本信息
proc getVersionString*(): string =
  return "v" & VERSION & " (" & BUILD_DATE & ")"
