##[
Augment Reset - JetBrains 操作模块

处理 JetBrains 系列 IDE 的重置操作：
- 清理 Windows 注册表
- 删除 .jetbrains 配置目录
- 删除 .augment 目录
]##

import std/[os, strformat, logging, asyncdispatch, osproc, options, times, strutils]
import types, system

# ============================================================================
# Windows 注册表操作
# ============================================================================

# 清理 Windows 注册表
proc clearWindowsRegistry*(): Future[OperationResult[bool]] {.async.} =
  result = OperationResult[bool](
    success: false,
    data: some(false),
    error: "",
    timestamp: now()
  )
  
  try:
    let osType = getCurrentOS()
    if osType != osWindows:
      # 非 Windows 系统跳过注册表清理
      result.success = true
      result.data = some(true)
      info "非 Windows 系统，跳过注册表清理"
      return result
    
    info "开始清理 Windows 注册表..."
    var clearedCount = 0
    
    for regPath in REGISTRY_PATHS:
      try:
        let deleteCmd = fmt"""reg delete "{regPath}" /f"""
        info fmt"执行注册表删除命令: {deleteCmd}"
        
        let (_, exitCode) = execCmdEx(deleteCmd)
        if exitCode == 0:
          clearedCount.inc
          info fmt"成功删除注册表项: {regPath}"
        else:
          # 注册表项可能不存在，这是正常的
          info fmt"注册表项不存在或已删除: {regPath}"
      except Exception as e:
        warn fmt"删除注册表项失败: {regPath} - {e.msg}"
    
    result.success = true
    result.data = some(true)
    info fmt"注册表清理完成，处理了 {REGISTRY_PATHS.len} 个路径"
    
  except Exception as e:
    result.error = fmt"清理注册表时出错: {e.msg}"
    error result.error

# ============================================================================
# 目录清理操作
# ============================================================================

# 获取 JetBrains 相关目录路径
proc getJetBrainsPaths*(): seq[string] =
  result = @[]
  
  try:
    let osType = getCurrentOS()
    let homeDir = getHomeDir()
    
    case osType:
    of osWindows:
      # Windows: %APPDATA%\.jetbrains 和 %USERPROFILE%\.augment
      let appdata = getEnv("APPDATA")
      if appdata != "":
        result.add(appdata / ".jetbrains")
      result.add(homeDir / ".augment")
      
    of osMacOS:
      # macOS: ~/Library/Application Support/JetBrains 和 ~/.augment
      result.add(homeDir / "Library" / "Application Support" / "JetBrains")
      result.add(homeDir / ".augment")
      
    of osLinux:
      # Linux: ~/.config/JetBrains 和 ~/.augment
      result.add(homeDir / ".config" / "JetBrains")
      result.add(homeDir / ".local" / "share" / "JetBrains")
      result.add(homeDir / ".augment")
      
    of osUnsupported:
      warn "不支持的操作系统，无法获取 JetBrains 路径"
    
    info fmt"找到 {result.len} 个 JetBrains 相关路径"
    
  except Exception as e:
    error fmt"获取 JetBrains 路径时出错: {e.msg}"

# 清理单个目录
proc cleanDirectory*(dirPath: string): Future[OperationResult[bool]] {.async.} =
  result = OperationResult[bool](
    success: false,
    data: some(false),
    error: "",
    timestamp: now()
  )
  
  try:
    if not dirExists(dirPath):
      info fmt"目录不存在，跳过: {dirPath}"
      result.success = true
      result.data = some(true)
      return result
    
    info fmt"开始清理目录: {dirPath}"
    
    # 备份目录（可选，如果目录很大可能会很慢）
    # 这里我们选择直接删除，因为这些是缓存和配置目录
    
    # 删除目录
    removeDir(dirPath)
    info fmt"成功删除目录: {dirPath}"
    
    result.success = true
    result.data = some(true)
    
  except Exception as e:
    result.error = fmt"清理目录失败: {dirPath} - {e.msg}"
    error result.error

# ============================================================================
# JetBrains 完整清理
# ============================================================================

# 执行完整的 JetBrains 清理
proc cleanJetBrains*(): Future[OperationResult[JetBrainsCleanResult]] {.async.} =
  result = OperationResult[JetBrainsCleanResult](
    success: false,
    data: none(JetBrainsCleanResult),
    error: "",
    timestamp: now()
  )
  
  try:
    info "开始 JetBrains 系列 IDE 清理..."
    
    var cleanResult = JetBrainsCleanResult(
      success: false,
      registryCleared: false,
      jetbrainsDir: "",
      augmentDir: "",
      clearedPaths: @[],
      error: "",
      timestamp: now()
    )
    
    # 1. 清理 Windows 注册表
    echo "🗂️ 清理注册表..."
    let registryResult = await clearWindowsRegistry()
    if registryResult.success:
      cleanResult.registryCleared = true
      echo "✅ 注册表清理完成"
    else:
      echo fmt"❌ 注册表清理失败: {registryResult.error}"
    
    # 2. 获取需要清理的目录
    let jetbrainsPaths = getJetBrainsPaths()
    
    # 3. 清理每个目录
    echo "\n📁 清理配置目录..."
    for dirPath in jetbrainsPaths:
      echo fmt"🔄 处理目录: {dirPath}"
      
      let cleanDirResult = await cleanDirectory(dirPath)
      if cleanDirResult.success:
        cleanResult.clearedPaths.add(dirPath)
        echo "✅ 目录清理成功"
        
        # 记录特殊目录
        if ".jetbrains" in dirPath.toLower() or "jetbrains" in dirPath.toLower():
          cleanResult.jetbrainsDir = dirPath
        elif ".augment" in dirPath.toLower():
          cleanResult.augmentDir = dirPath
      else:
        echo fmt"❌ 目录清理失败: {cleanDirResult.error}"
    
    # 4. 设置最终结果
    cleanResult.success = cleanResult.clearedPaths.len > 0 or cleanResult.registryCleared
    
    if cleanResult.success:
      echo fmt"\n🎉 JetBrains 清理完成！清理了 {cleanResult.clearedPaths.len} 个目录"
    else:
      cleanResult.error = "没有成功清理任何项目"
    
    result.success = true
    result.data = some(cleanResult)
    
  except Exception as e:
    result.error = fmt"JetBrains 清理过程中出错: {e.msg}"
    error result.error

# ============================================================================
# JetBrains IDE 进程检测和关闭
# ============================================================================

# 检测 JetBrains IDE 是否正在运行
proc isJetBrainsRunning*(): OperationResult[bool] =
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
      # 检测常见的 JetBrains IDE 进程
      command = "tasklist /FI \"IMAGENAME eq idea64.exe\" /FI \"IMAGENAME eq pycharm64.exe\" /FI \"IMAGENAME eq webstorm64.exe\""
    of osMacOS:
      command = "pgrep -i \"idea|pycharm|webstorm|phpstorm|clion|datagrip|goland|rider\""
    of osLinux:
      command = "pgrep -i \"idea|pycharm|webstorm|phpstorm|clion|datagrip|goland|rider\""
    of osUnsupported:
      result.error = "不支持的操作系统"
      return result
    
    let output = execProcess(command)
    let isRunning = case osType:
      of osWindows: 
        "idea64.exe" in output.toLower() or 
        "pycharm64.exe" in output.toLower() or 
        "webstorm64.exe" in output.toLower()
      else: output.len > 0
    
    result.success = true
    result.data = some(isRunning)
    
    if isRunning:
      info "检测到正在运行的 JetBrains IDE"
    else:
      info "未检测到正在运行的 JetBrains IDE"
      
  except Exception as e:
    result.error = fmt"检查 JetBrains IDE 状态时出错: {e.msg}"
    error result.error

# 关闭 JetBrains IDE 进程
proc killJetBrainsProcess*(): Future[OperationResult[bool]] {.async.} =
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
      command = "taskkill /F /IM idea64.exe /T & taskkill /F /IM pycharm64.exe /T & taskkill /F /IM webstorm64.exe /T"
    of osMacOS:
      command = "pkill -i \"idea|pycharm|webstorm|phpstorm|clion|datagrip|goland|rider\""
    of osLinux:
      command = "pkill -i \"idea|pycharm|webstorm|phpstorm|clion|datagrip|goland|rider\""
    of osUnsupported:
      result.error = "不支持的操作系统"
      return result

    info fmt"执行关闭 JetBrains IDE 命令: {command}"
    discard execProcess(command)
    await sleepAsync(EDITOR_CLOSE_WAIT_MS)
    
    # 验证 IDE 是否已关闭
    let checkResult = isJetBrainsRunning()
    if checkResult.success and checkResult.data.isSome():
      let stillRunning = checkResult.data.get()
      result.success = true
      result.data = some(not stillRunning)
      
      if not stillRunning:
        info "JetBrains IDE 已成功关闭"
      else:
        warn "JetBrains IDE 仍在运行，可能需要手动关闭"
    else:
      result.error = "无法验证 JetBrains IDE 状态"
      
  except Exception as e:
    result.error = fmt"关闭 JetBrains IDE 时出错: {e.msg}"
    error result.error
