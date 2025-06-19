#!/usr/bin/env nim
##[
Augment 扩展试用期重置工具 - 模块化版本

此脚本通过修改扩展的配置文件和清理数据库来重置 Augment 编程扩展的试用期。
支持 Windows、macOS 和 Linux 系统。

主要功能：
- 自动检测并关闭正在运行的 VS Code/Cursor
- 备份现有配置
- 生成新的随机设备 ID
- 清理 SQLite 数据库中的 Augment 记录
- 保留用户设置
- 完整的错误处理和日志记录

创建时间：2025年6月2日
模块化重构：2025年6月20日
]##

import std/[asyncdispatch, logging, strformat, options, os]
import augment_reset/[types, system, reset, version]

# ============================================================================
# 主程序
# ============================================================================

proc main() {.async.} =
  # 检查命令行参数
  if paramCount() > 0:
    let arg = paramStr(1)
    if arg == "--version" or arg == "-v":
      showVersion()
      return
    elif arg == "--help" or arg == "-h":
      showVersion()
      echo ""
      echo "使用方法:"
      echo "  augment_reset [选项]"
      echo ""
      echo "选项:"
      echo "  -h, --help     显示帮助信息"
      echo "  -v, --version  显示版本信息"
      echo ""
      echo "不带参数运行将启动重置流程。"
      return

  echo "🚀 Augment Extension Trial Reset Tool ", getVersionString()
  echo "================================================\n"
  
  # 初始化日志系统
  initLogger()
  info "程序启动 - 模块化版本"
  
  try:
    let resetResult = await resetAugmentTrial()
    
    if resetResult.success:
      if resetResult.data.isSome():
        let stats = resetResult.data.get()
        info fmt"重置完成 - 成功: {stats.processedFiles}, 失败: {stats.errorFiles}"
      else:
        info "重置完成，但无统计数据"
    else:
      error fmt"重置失败: {resetResult.error}"
      echo fmt"\n❌ 重置失败: {resetResult.error}"
      
  except Exception as e:
    error fmt"程序执行异常: {e.msg}"
    echo fmt"\n❌ 程序执行异常: {e.msg}"
  
  info "程序结束"

when isMainModule:
  try:
    waitFor main()
  except Exception as e:
    stderr.writeLine "程序崩溃: " & e.msg
    quit(1)
