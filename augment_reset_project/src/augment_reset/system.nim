##[
Augment Reset - 系统操作模块

处理系统相关操作：进程管理、文件操作、日志等
]##

import std/[os, times, strformat, osproc, terminal, logging, asyncdispatch, options, strutils]
import types

# ============================================================================
# 日志系统
# ============================================================================

# 初始化日志系统
proc initLogger*() =
  let logger = newConsoleLogger(lvlInfo)
  addHandler(logger)
  
  try:
    let fileLogger = newFileLogger(LOG_FILE, fmtStr = "$datetime $levelname: $message")
    addHandler(fileLogger)
  except:
    warn "无法创建日志文件，仅使用控制台日志"

# ============================================================================
# 操作系统检测
# ============================================================================

# 获取当前操作系统类型
proc getCurrentOS*(): OSType =
  when defined(windows):
    return osWindows
  elif defined(macosx):
    return osMacOS
  elif defined(linux):
    return osLinux
  else:
    return osUnsupported

# ============================================================================
# 用户交互
# ============================================================================

# 等待用户按键
proc waitForKeypress*() {.async.} =
  try:
    when defined(windows):
      if getEnv("TERM") == "":
        echo "\n按任意键退出..."
        discard getch()
    else:
      echo "\n按 Enter 键退出..."
      discard readLine(stdin)
  except:
    info "用户输入处理完成"

# ============================================================================
# 进程管理
# ============================================================================

# 检查编辑器是否正在运行
proc isEditorRunning*(): OperationResult[bool] =
  result = OperationResult[bool](
    success: false,
    data: some(false),
    error: "",
    timestamp: now()
  )
  
  try:
    let osType = getCurrentOS()
    var command: string
    
    case osType:
    of osWindows:
      command = "tasklist /FI \"IMAGENAME eq Code.exe\" /FI \"IMAGENAME eq Cursor.exe\""
    of osMacOS:
      command = "pgrep -x \"Code\" || pgrep -x \"Cursor\" || pgrep -x \"Code Helper\" || pgrep -x \"Cursor Helper\""
    of osLinux:
      command = "pgrep -x \"code\" || pgrep -x \"cursor\" || pgrep -x \"Code\" || pgrep -x \"Cursor\""
    of osUnsupported:
      result.error = "不支持的操作系统"
      return result
    
    let output = execProcess(command)
    let isRunning = case osType:
      of osWindows: "code.exe" in output.toLower() or "cursor.exe" in output.toLower()
      else: output.len > 0
    
    result.success = true
    result.data = some(isRunning)
    
    if isRunning:
      info "检测到正在运行的编辑器"
    else:
      info "未检测到正在运行的编辑器"
      
  except Exception as e:
    result.error = fmt"检查编辑器状态时出错: {e.msg}"
    error result.error

# 关闭编辑器进程
proc killEditorProcess*(): Future[OperationResult[bool]] {.async.} =
  result = OperationResult[bool](
    success: false,
    data: some(false),
    error: "",
    timestamp: now()
  )
  
  try:
    let osType = getCurrentOS()
    var command: string
    
    case osType:
    of osWindows:
      command = "taskkill /F /IM Code.exe /T & taskkill /F /IM Cursor.exe /T"
    of osMacOS:
      command = "pkill -9 \"Code\" & pkill -9 \"Cursor\""
    of osLinux:
      command = "pkill -9 \"code\" & pkill -9 \"cursor\""
    of osUnsupported:
      result.error = "不支持的操作系统"
      return result

    info fmt"执行关闭编辑器命令: {command}"
    discard execProcess(command)
    await sleepAsync(EDITOR_CLOSE_WAIT_MS)
    
    # 验证编辑器是否已关闭
    let checkResult = isEditorRunning()
    if checkResult.success and checkResult.data.isSome:
      let stillRunning = checkResult.data.get()
      result.success = true
      result.data = some(not stillRunning)
      
      if not stillRunning:
        info "编辑器已成功关闭"
      else:
        warn "编辑器仍在运行，可能需要手动关闭"
    else:
      result.error = "无法验证编辑器状态"
      
  except Exception as e:
    result.error = fmt"关闭编辑器时出错: {e.msg}"
    error result.error

# ============================================================================
# 文件操作
# ============================================================================

# 格式化时间戳
proc formatTimestamp*(date: DateTime): string =
  try:
    let year = $date.year
    let month = align($date.month.int, 2, '0')
    let day = align($date.monthday, 2, '0')
    let hours = align($date.hour, 2, '0')
    let minutes = align($date.minute, 2, '0')
    let seconds = align($date.second, 2, '0')
    let milliseconds = align($(date.nanosecond div 1_000_000), 3, '0')
    return fmt"{year}{month}{day}{hours}{minutes}{seconds}{milliseconds}"
  except:
    return "unknown_timestamp"

# 备份文件
proc backupFile*(filePath: string): Future[OperationResult[BackupResult]] {.async.} =
  result = OperationResult[BackupResult](
    success: false,
    data: none(BackupResult),
    error: "",
    timestamp: now()
  )
  
  try:
    if not fileExists(filePath):
      result.error = "源文件不存在"
      return result
    
    let timestamp = formatTimestamp(now())
    let backupPath = fmt"{filePath}.{timestamp}.bak"
    
    info fmt"备份文件: {filePath} -> {backupPath}"
    copyFile(filePath, backupPath)
    
    let backupResult = BackupResult(
      success: true,
      backupPath: backupPath,
      originalPath: filePath,
      timestamp: now(),
      error: ""
    )
    
    result.success = true
    result.data = some(backupResult)
    info fmt"文件备份成功: {backupPath}"
    
  except Exception as e:
    result.error = fmt"备份文件失败: {e.msg}"
    error result.error

# 清理过期备份文件
proc cleanupOldBackups*(directory: string): Future[OperationResult[int]] {.async.} =
  result = OperationResult[int](
    success: false,
    data: some(0),
    error: "",
    timestamp: now()
  )
  
  try:
    if not dirExists(directory):
      result.success = true
      return result
    
    let cutoffDate = (now() - BACKUP_RETENTION_DAYS.days).toTime()
    var deletedCount = 0

    for file in walkFiles(directory / "*.bak"):
      try:
        let fileInfo = getFileInfo(file)
        if fileInfo.lastWriteTime < cutoffDate:
          removeFile(file)
          deletedCount.inc
          info fmt"删除过期备份文件: {file}"
      except:
        warn fmt"无法删除备份文件: {file}"
    
    result.success = true
    result.data = some(deletedCount)
    info fmt"清理了 {deletedCount} 个过期备份文件"
    
  except Exception as e:
    result.error = fmt"清理备份文件时出错: {e.msg}"
    error result.error
