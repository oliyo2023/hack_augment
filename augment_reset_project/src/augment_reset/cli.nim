##[
Augment Reset - 命令行接口模块

处理命令行参数解析和用户交互
]##

import std/[os, strformat, strutils]
import types, version, banner

# ============================================================================
# 命令行参数解析
# ============================================================================

# 显示帮助信息
proc showHelp*() =
  showHelpBanner()
  echo ""
  echo "用法:"
  echo "  augment_reset [选项] [目标]"
  echo ""
  echo "目标选项:"
  echo "  --all        清理所有支持的编辑器/IDE"
  echo "  --vscode     仅清理 VS Code"
  echo "  --cursor     仅清理 Cursor"
  echo "  --jetbrains  仅清理 JetBrains IDE"
  echo ""
  echo "注意: 默认启用交互式模式，程序会让您选择清理目标"
  echo ""
  echo "其他选项:"
  echo "  -h, --help         显示此帮助信息"
  echo "  -v, --version      显示版本信息"
  echo "  -i, --interactive  交互式选择清理目标（默认）"
  echo "  --no-interactive   禁用交互式模式，直接执行"
  echo "  --no-backup        跳过备份（不推荐）"
  echo "  --verbose          显示详细输出"
  echo ""
  echo "示例:"
  echo "  augment_reset                         # 交互式选择（默认）"
  echo "  augment_reset --vscode --no-interactive  # 直接清理 VS Code"
  echo "  augment_reset --jetbrains --no-interactive  # 直接清理 JetBrains IDE"
  echo "  augment_reset --all --no-interactive     # 直接清理所有"
  echo "  augment_reset --cursor --verbose        # 详细模式清理 Cursor"
  echo ""
  echo "交互式模式说明:"
  echo "  - 选择 0 或输入 'q' 可随时退出程序"
  echo "  - 在确认界面输入 'q' 也可退出程序"
  echo ""
  echo "支持的编辑器/IDE:"
  echo "  📝 VS Code - Microsoft Visual Studio Code"
  echo "  🖱️ Cursor - AI-powered code editor"
  echo "  🔧 JetBrains - IntelliJ IDEA, PyCharm, WebStorm, PhpStorm, GoLand, Rider, CLion, DataGrip, Android Studio"

# 解析清理目标
proc parseCleanTarget*(arg: string): CleanTarget =
  case arg.toLower():
  of "all", "a":
    return ctAll
  of "vscode", "vs", "code", "v":
    return ctVSCode
  of "cursor", "c":
    return ctCursor
  of "jetbrains", "jb", "j", "idea", "pycharm", "webstorm":
    return ctJetBrains
  else:
    echo fmt"❌ 未知的清理目标: {arg}"
    echo "使用 --help 查看支持的目标"
    quit(1)

# 解析命令行参数
proc parseCommandLine*(): CleanOptions =
  result = CleanOptions(
    target: ctAll,
    interactive: true,  # 默认启用交互式模式
    skipBackup: false,
    verbose: false
  )

  let args = commandLineParams()

  if args.len == 0:
    return result
  
  var i = 0
  while i < args.len:
    let arg = args[i]
    
    case arg:
    of "-h", "--help":
      showHelp()
      quit(0)
    of "-v", "--version":
      showVersion()
      quit(0)
    of "-i", "--interactive":
      result.interactive = true
    of "--no-interactive":
      result.interactive = false
    of "--no-backup":
      result.skipBackup = true
    of "--verbose":
      result.verbose = true
    of "--all":
      result.target = ctAll
    of "--vscode":
      result.target = ctVSCode
    of "--cursor":
      result.target = ctCursor
    of "--jetbrains":
      result.target = ctJetBrains
    else:
      if arg.startsWith("--"):
        echo fmt"❌ 未知选项: {arg}"
        echo "使用 --help 查看所有可用选项"
        quit(1)
      else:
        # 尝试解析为清理目标
        result.target = parseCleanTarget(arg)
    
    i.inc

# ============================================================================
# 交互式选择
# ============================================================================

# 交互式选择清理目标
proc interactiveSelectTarget*(): CleanTarget =
  echo "🎯 请选择要清理的目标:"
  echo ""
  echo "  1. 🌟 全部 (VS Code + Cursor + JetBrains)"
  echo "  2. 📝 VS Code"
  echo "  3. 🖱️ Cursor"
  echo "  4. 🔧 JetBrains IDE"
  echo "  0. 🚪 退出程序"
  echo ""
  
  while true:
    stdout.write("请输入选项 (0-4): ")
    stdout.flushFile()

    let input = readLine(stdin).strip()

    case input:
    of "0", "exit", "quit", "q", "退出":
      echo "👋 已退出程序"
      quit(0)
    of "1", "all", "全部", "a":
      echo "✅ 已选择: 清理所有编辑器/IDE"
      return ctAll
    of "2", "vscode", "vs", "code", "v":
      echo "✅ 已选择: 仅清理 VS Code"
      return ctVSCode
    of "3", "cursor", "c":
      echo "✅ 已选择: 仅清理 Cursor"
      return ctCursor
    of "4", "jetbrains", "jb", "j":
      echo "✅ 已选择: 仅清理 JetBrains IDE"
      return ctJetBrains
    else:
      echo "❌ 无效选项，请输入 0-4"

# 确认操作
proc confirmOperation*(target: CleanTarget): bool =
  let targetName = case target:
    of ctAll: "所有编辑器/IDE (VS Code + Cursor + JetBrains)"
    of ctVSCode: "VS Code"
    of ctCursor: "Cursor"
    of ctJetBrains: "JetBrains IDE"
  
  echo ""
  echo fmt"⚠️ 即将清理: {targetName}"
  echo "此操作将:"
  echo "  🔄 重置试用期配置"
  echo "  🗄️ 清理相关数据库"
  if target == ctJetBrains or target == ctAll:
    echo "  🗂️ 清理注册表 (Windows)"
    echo "  📁 删除配置目录"
  echo "  💾 自动备份所有文件"
  echo ""
  
  while true:
    stdout.write("确认继续? (y/N/q): ")
    stdout.flushFile()

    let input = readLine(stdin).strip().toLower()

    case input:
    of "y", "yes", "是", "确认":
      return true
    of "n", "no", "否", "取消", "":
      return false
    of "q", "quit", "exit", "退出":
      echo "👋 已退出程序"
      quit(0)
    else:
      echo "请输入 y (是)、n (否) 或 q (退出)"

# ============================================================================
# 目标描述
# ============================================================================

# 获取清理目标的描述
proc getTargetDescription*(target: CleanTarget): string =
  case target:
  of ctAll:
    return "所有编辑器/IDE"
  of ctVSCode:
    return "VS Code"
  of ctCursor:
    return "Cursor"
  of ctJetBrains:
    return "JetBrains IDE"

# 获取清理目标的详细信息
proc getTargetDetails*(target: CleanTarget): seq[string] =
  case target:
  of ctAll:
    return @[
      "📝 VS Code - Microsoft Visual Studio Code",
      "🖱️ Cursor - AI-powered code editor", 
      "🔧 JetBrains - 全系列 IDE (IDEA, PyCharm, WebStorm 等)"
    ]
  of ctVSCode:
    return @["📝 VS Code - Microsoft Visual Studio Code"]
  of ctCursor:
    return @["🖱️ Cursor - AI-powered code editor"]
  of ctJetBrains:
    return @[
      "🔧 IntelliJ IDEA - Java/Kotlin IDE",
      "🐍 PyCharm - Python IDE",
      "🌐 WebStorm - JavaScript/TypeScript IDE",
      "🐘 PhpStorm - PHP IDE",
      "🐹 GoLand - Go IDE",
      "🎯 Rider - .NET IDE",
      "⚙️ CLion - C/C++ IDE",
      "🗄️ DataGrip - Database IDE",
      "📱 Android Studio - Android IDE"
    ]
