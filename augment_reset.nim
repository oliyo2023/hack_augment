#!/usr/bin/env nim
##[
Augment 扩展试用期重置工具

此脚本通过修改扩展的配置文件来重置 Augment 编程扩展的试用期。
支持 Windows、macOS 和 Linux 系统。

主要功能：
- 自动检测并关闭正在运行的 VS Code/Cursor
- 备份现有配置
- 生成新的随机设备 ID
- 保留用户设置
- 完整的错误处理和日志记录

创建时间：2025年6月2日
转换为 Nim 语言
优化版本：2025年1月
]##

import std/[os, json, times, random, strutils, strformat, osproc, terminal, logging, options]
import std/[asyncdispatch, tables, sequtils]

# ============================================================================
# 常量定义
# ============================================================================

const
  # 试用期配置
  TRIAL_DURATION_DAYS = 14
  TRIAL_MAX_RESETS = 3
  
  # ID 生成配置
  DEVICE_ID_LENGTH = 64
  USER_ID_LENGTH = 32
  SESSION_ID_LENGTH = 32
  EMAIL_RANDOM_LENGTH = 16
  
  # 系统配置
  EDITOR_CLOSE_WAIT_MS = 1500
  BACKUP_RETENTION_DAYS = 30
  MAX_RETRY_ATTEMPTS = 3
  
  # 文件配置
  CONFIG_FILES = [
    "state.json",
    "subscription.json",
    "account.json"
  ]
  
  # 支持的编辑器
  EDITORS = [
    "Code",
    "Cursor"
  ]
  
  # 日志配置
  LOG_LEVEL = lvlInfo
  LOG_FILE = "augment_reset.log"

# ============================================================================
# 类型定义
# ============================================================================

type
  # 配置文件类型枚举
  ConfigFileType* = enum
    cfState = "state.json"
    cfSubscription = "subscription.json"
    cfAccount = "account.json"

  # 编辑器类型枚举
  EditorType* = enum
    etCode = "Code"
    etCursor = "Cursor"

  # 操作系统类型枚举
  OSType* = enum
    osWindows = "windows"
    osMacOS = "macos"
    osLinux = "linux"
    osUnsupported = "unsupported"

  # 操作结果类型
  OperationResult*[T] = object
    success*: bool
    data*: Option[T]
    error*: string
    timestamp*: DateTime

  # Augment 配置对象
  AugmentConfig* = object
    deviceId*: string
    userId*: string
    email*: string
    sessionId*: string
    trialStartDate*: DateTime
    trialEndDate*: DateTime
    trialCount*: int
    resetHistory*: seq[DateTime]

  # 备份结果
  BackupResult* = object
    success*: bool
    backupPath*: string
    originalPath*: string
    timestamp*: DateTime
    error*: string

  # 配置路径信息
  ConfigPathInfo* = object
    path*: string
    fileType*: ConfigFileType
    editorType*: EditorType
    exists*: bool

  # 重置统计信息
  ResetStats* = object
    totalFiles*: int
    processedFiles*: int
    backupFiles*: int
    errorFiles*: int
    startTime*: DateTime
    endTime*: DateTime

  # 自定义异常类型
  AugmentResetError* = object of CatchableError
  ConfigError* = object of AugmentResetError
  BackupError* = object of AugmentResetError
  EditorError* = object of AugmentResetError

# ============================================================================
# 系统操作模块 - 进程管理和系统交互
# ============================================================================

# 初始化日志系统
proc initLogger*() =
  let logger = newConsoleLogger(LOG_LEVEL)
  addHandler(logger)
  
  try:
    let fileLogger = newFileLogger(LOG_FILE, fmtStr = "$datetime $levelname: $message")
    addHandler(fileLogger)
  except:
    warn "无法创建日志文件，仅使用控制台日志"

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

# 获取特定操作系统的基础路径
proc getBasePaths*(osType: OSType): Table[string, string] =
  result = initTable[string, string]()
  
  case osType:
  of osWindows:
    result["appdata"] = getEnv("APPDATA")
    result["localappdata"] = getEnv("LOCALAPPDATA")
  of osMacOS:
    let homeDir = getHomeDir()
    result["appSupport"] = homeDir / "Library" / "Application Support"
    result["caches"] = homeDir / "Library" / "Caches"
  of osLinux:
    let homeDir = getHomeDir()
    result["config"] = homeDir / ".config"
    result["cache"] = homeDir / ".cache"
  of osUnsupported:
    discard

# 构建配置文件路径
proc buildConfigPaths*(basePaths: Table[string, string], osType: OSType): seq[ConfigPathInfo] =
  result = @[]
  
  case osType:
  of osWindows:
    let appdata = basePaths.getOrDefault("appdata", "")
    let localappdata = basePaths.getOrDefault("localappdata", "")
    
    if appdata != "":
      for editor in EDITORS:
        for configFile in CONFIG_FILES:
          let path = appdata / editor / "User" / "globalStorage" / "augment.augment" / configFile
          result.add(ConfigPathInfo(
            path: path,
            fileType: parseEnum[ConfigFileType](configFile),
            editorType: parseEnum[EditorType](editor),
            exists: fileExists(path)
          ))
      
      # 缓存目录
      for editor in EDITORS:
        for cacheDir in ["Cache", "CachedData"]:
          let path = appdata / editor / cacheDir / "augment.augment"
          result.add(ConfigPathInfo(
            path: path,
            fileType: cfState, # 默认类型
            editorType: parseEnum[EditorType](editor),
            exists: dirExists(path)
          ))
    
  of osMacOS:
    let appSupport = basePaths.getOrDefault("appSupport", "")
    let caches = basePaths.getOrDefault("caches", "")
    
    if appSupport != "":
      for editor in EDITORS:
        for configFile in CONFIG_FILES:
          let path = appSupport / editor / "User" / "globalStorage" / "augment.augment" / configFile
          result.add(ConfigPathInfo(
            path: path,
            fileType: parseEnum[ConfigFileType](configFile),
            editorType: parseEnum[EditorType](editor),
            exists: fileExists(path)
          ))
    
    if caches != "":
      for editor in EDITORS:
        let path = caches / editor / "augment.augment"
        result.add(ConfigPathInfo(
          path: path,
          fileType: cfState,
          editorType: parseEnum[EditorType](editor),
          exists: dirExists(path)
        ))
  
  of osLinux:
    let config = basePaths.getOrDefault("config", "")
    let cache = basePaths.getOrDefault("cache", "")
    
    if config != "":
      for editor in EDITORS:
        for configFile in CONFIG_FILES:
          let path = config / editor / "User" / "globalStorage" / "augment.augment" / configFile
          result.add(ConfigPathInfo(
            path: path,
            fileType: parseEnum[ConfigFileType](configFile),
            editorType: parseEnum[EditorType](editor),
            exists: fileExists(path)
          ))
    
    if cache != "":
      for editor in EDITORS:
        let path = cache / editor / "augment.augment"
        result.add(ConfigPathInfo(
          path: path,
          fileType: cfState,
          editorType: parseEnum[EditorType](editor),
          exists: dirExists(path)
        ))
  
  of osUnsupported:
    discard

# 获取 Augment 配置路径
proc getAugmentConfigPaths*(): OperationResult[seq[ConfigPathInfo]] =
  result = OperationResult[seq[ConfigPathInfo]](
    success: false,
    data: some(newSeq[ConfigPathInfo]()),
    error: "",
    timestamp: now()
  )
  
  try:
    let osType = getCurrentOS()
    if osType == osUnsupported:
      result.error = "不支持的操作系统"
      return result
    
    let basePaths = getBasePaths(osType)
    let configPaths = buildConfigPaths(basePaths, osType)
    
    result.success = true
    result.data = some(configPaths)
    
    info fmt"找到 {configPaths.len} 个配置路径"
    
  except Exception as e:
    result.error = fmt"获取配置路径时出错: {e.msg}"
    error result.error

# ============================================================================
# ID 生成模块 - 安全的随机ID生成
# ============================================================================

# 生成安全的随机字符串
proc generateSecureRandomString*(length: int, useUppercase: bool = false): string =
  try:
    randomize()
    result = ""
    for i in 0..<length:
      let hexChar = toHex(rand(15), 1)
      result.add(if useUppercase: hexChar else: hexChar.toLower())
  except:
    # 如果随机生成失败，使用时间戳作为后备
    let timestamp = $now().toTime().toUnix()
    result = timestamp.repeat(length div timestamp.len + 1)[0..<length]

# 生成设备ID
proc generateDeviceId*(): string =
  try:
    result = generateSecureRandomString(DEVICE_ID_LENGTH)
    info fmt"生成新设备ID: {result[0..7]}..."
  except Exception as e:
    error fmt"生成设备ID失败: {e.msg}"
    result = "fallback_device_" & $now().toTime().toUnix()

# 生成用户ID
proc generateUserId*(): string =
  try:
    result = generateSecureRandomString(USER_ID_LENGTH)
    info fmt"生成新用户ID: {result[0..7]}..."
  except Exception as e:
    error fmt"生成用户ID失败: {e.msg}"
    result = "fallback_user_" & $now().toTime().toUnix()

# 生成会话ID
proc generateSessionId*(): string =
  try:
    result = generateSecureRandomString(SESSION_ID_LENGTH)
    info fmt"生成新会话ID: {result[0..7]}..."
  except Exception as e:
    error fmt"生成会话ID失败: {e.msg}"
    result = "fallback_session_" & $now().toTime().toUnix()

# 生成随机邮箱
proc generateEmail*(): string =
  try:
    let randomString = generateSecureRandomString(EMAIL_RANDOM_LENGTH)
    result = fmt"user_{randomString}@example.com"
    info fmt"生成新邮箱: {result}"
  except Exception as e:
    error fmt"生成邮箱失败: {e.msg}"
    result = fmt"fallback_user_{now().toTime().toUnix()}@example.com"

# 生成完整的账户配置
proc generateAccountConfig*(): AugmentConfig =
  try:
    let now = now()
    result = AugmentConfig(
      deviceId: generateDeviceId(),
      userId: generateUserId(),
      email: generateEmail(),
      sessionId: generateSessionId(),
      trialStartDate: now,
      trialEndDate: now + TRIAL_DURATION_DAYS.days,
      trialCount: 0,
      resetHistory: @[now]
    )
    info "生成新账户配置完成"
  except Exception as e:
    error fmt"生成账户配置失败: {e.msg}"
    # 返回一个基本的配置作为后备
    let timestamp = $now().toTime().toUnix()
    result = AugmentConfig(
      deviceId: "fallback_device_" & timestamp,
      userId: "fallback_user_" & timestamp,
      email: fmt"fallback_user_{timestamp}@example.com",
      sessionId: "fallback_session_" & timestamp,
      trialStartDate: now(),
      trialEndDate: now() + TRIAL_DURATION_DAYS.days,
      trialCount: 0,
      resetHistory: @[now()]
    )


# ============================================================================
# 配置文件生成模块
# ============================================================================

# 创建状态配置
proc createStateConfig*(config: AugmentConfig): JsonNode =
  try:
    result = %*{
      "deviceId": config.deviceId,
      "userId": config.userId,
      "email": config.email,
      "sessionId": config.sessionId,
      "trialStartDate": config.trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "trialEndDate": config.trialEndDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "trialDuration": TRIAL_DURATION_DAYS,
      "trialStatus": "active",
      "trialExpired": false,
      "trialRemainingDays": TRIAL_DURATION_DAYS,
      "trialCount": config.trialCount,
      "usageCount": 0,
      "totalUsageCount": 0,
      "lastUsageDate": nil,
      "messageCount": 0,
      "totalMessageCount": 0,
      "lastReset": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "firstRunDate": config.trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "lastRunDate": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "lastSessionDate": nil,
      "sessionHistory": newJArray(),
      "isFirstRun": true,
      "hasCompletedOnboarding": false,
      "hasUsedTrial": false,
      "preferences": %*{
        "theme": "light",
        "language": "en",
        "notifications": true
      },
      "tracking": %*{
        "lastCheck": nil,
        "checkCount": 0,
        "lastValidation": nil
      }
    }
  except Exception as e:
    error fmt"创建状态配置失败: {e.msg}"
    result = newJObject()

# 创建订阅配置
proc createSubscriptionConfig*(config: AugmentConfig): JsonNode =
  try:
    result = %*{
      "status": "active",
      "type": "trial",
      "startDate": config.trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "endDate": config.trialEndDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "isActive": true,
      "isExpired": false,
      "remainingDays": TRIAL_DURATION_DAYS,
      "trialCount": config.trialCount,
      "lastTrialReset": nil,
      "previousTrials": newJArray()
    }
  except Exception as e:
    error fmt"创建订阅配置失败: {e.msg}"
    result = newJObject()

# 创建账户配置
proc createAccountConfig*(config: AugmentConfig): JsonNode =
  try:
    result = %*{
      "userId": config.userId,
      "email": config.email,
      "deviceId": config.deviceId,
      "createdAt": config.trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "lastLogin": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "isActive": true,
      "trialHistory": newJArray(),
      "deviceHistory": newJArray()
    }
  except Exception as e:
    error fmt"创建账户配置失败: {e.msg}"
    result = newJObject()

# 根据文件类型创建配置
proc createConfigByType*(fileType: ConfigFileType, config: AugmentConfig): JsonNode =
  case fileType:
  of cfState:
    result = createStateConfig(config)
  of cfSubscription:
    result = createSubscriptionConfig(config)
  of cfAccount:
    result = createAccountConfig(config)

# ============================================================================
# 主要重置逻辑
# ============================================================================

# 处理单个配置文件
proc processConfigFile*(pathInfo: ConfigPathInfo, config: AugmentConfig): Future[OperationResult[bool]] {.async.} =
  result = OperationResult[bool](
    success: false,
    data: some(false),
    error: "",
    timestamp: now()
  )
  
  try:
    info fmt"处理配置文件: {pathInfo.path}"
    
    # 确保目录存在
    let parentDir = parentDir(pathInfo.path)
    if not dirExists(parentDir):
      createDir(parentDir)
      info fmt"创建目录: {parentDir}"
    
    # 备份现有文件
    if pathInfo.exists:
      let backupResult = await backupFile(pathInfo.path)
      if not backupResult.success:
        warn fmt"备份文件失败: {backupResult.error}"
    
    # 如果是目录，删除它
    if dirExists(pathInfo.path):
      removeDir(pathInfo.path)
      info fmt"删除目录: {pathInfo.path}"
      result.success = true
      result.data = some(true)
      return result
    
    # 创建新配置
    let newConfig = createConfigByType(pathInfo.fileType, config)
    if newConfig.kind == JNull:
      result.error = "无法创建配置内容"
      return result
    
    # 保存配置文件
    writeFile(pathInfo.path, pretty(newConfig, 2))
    info fmt"配置文件已保存: {pathInfo.path}"
    
    result.success = true
    result.data = some(true)
    
  except Exception as e:
    result.error = fmt"处理配置文件失败: {e.msg}"
    error result.error

# 主要的重置函数
proc resetAugmentTrial*(): Future[OperationResult[ResetStats]] {.async.} =
  result = OperationResult[ResetStats](
    success: false,
    data: none(ResetStats),
    error: "",
    timestamp: now()
  )
  
  var stats = ResetStats(
    totalFiles: 0,
    processedFiles: 0,
    backupFiles: 0,
    errorFiles: 0,
    startTime: now(),
    endTime: now()
  )
  
  try:
    info "开始 Augment 试用期重置"
    
    # 检查并关闭编辑器
    echo "🔍 检查正在运行的编辑器..."
    let editorCheck = isEditorRunning()
    if editorCheck.success and editorCheck.data.isSome and editorCheck.data.get():
      echo "⚠️ 检测到 VS Code 或 Cursor 正在运行，尝试关闭..."
      let killResult = await killEditorProcess()
      if killResult.success and killResult.data.isSome and killResult.data.get():
        echo "✅ 编辑器已关闭\n"
      else:
        echo "❌ 无法关闭编辑器，请手动关闭后重试"
        result.error = "无法关闭编辑器"
        return result
    
    # 获取配置路径
    let pathsResult = getAugmentConfigPaths()
    if not pathsResult.success or pathsResult.data.isNone:
      result.error = pathsResult.error
      return result
    
    let configPaths = pathsResult.data.get()
    stats.totalFiles = configPaths.len
    echo fmt"📂 找到 {configPaths.len} 个配置路径"
    
    # 生成新的账户配置
    echo "🎲 生成新的账户数据..."
    let accountConfig = generateAccountConfig()
    echo "✅ 新账户数据生成成功\n"

    # 处理每个配置文件
    for pathInfo in configPaths:
      echo fmt"\n🔄 处理: {pathInfo.path}"
      
      let processResult = await processConfigFile(pathInfo, accountConfig)
      if processResult.success:
        stats.processedFiles.inc
        echo "✅ 处理成功"
      else:
        stats.errorFiles.inc
        echo fmt"❌ 处理失败: {processResult.error}"
    
    # 清理过期备份文件
    echo "\n🧹 清理过期备份文件..."
    for pathInfo in configPaths:
      let dir = parentDir(pathInfo.path)
      if dirExists(dir):
        let cleanupResult = await cleanupOldBackups(dir)
        if cleanupResult.success and cleanupResult.data.isSome:
          let deletedCount = cleanupResult.data.get()
          if deletedCount > 0:
            echo fmt"清理了 {deletedCount} 个过期备份文件"
    
    stats.endTime = now()
    
    # 显示账户详情
    echo "\n📋 账户详情:"
    echo fmt"用户ID: {accountConfig.userId[0..7]}..."
    echo fmt"设备ID: {accountConfig.deviceId[0..7]}..."
    echo fmt"邮箱: {accountConfig.email}"
    echo fmt"\n试用期: {TRIAL_DURATION_DAYS} 天"
    let startDateStr = accountConfig.trialStartDate.format("yyyy-MM-dd")
    let endDateStr = accountConfig.trialEndDate.format("yyyy-MM-dd")
    echo fmt"开始日期: {startDateStr}"
    echo fmt"结束日期: {endDateStr}"
    
    # 显示统计信息
    echo "\n📊 重置统计:"
    echo fmt"总文件数: {stats.totalFiles}"
    echo fmt"成功处理: {stats.processedFiles}"
    echo fmt"处理失败: {stats.errorFiles}"
    echo fmt"处理时间: {(stats.endTime - stats.startTime).inMilliseconds} 毫秒"
    
    echo "\n🎉 Augment 扩展试用期重置完成!"
    echo "\n⚠️ 重要提示:"
    echo "1. 请重启您的编辑器 (VS Code 或 Cursor) 以使更改生效"
    echo "2. 在提示时创建新账户"
    echo "3. 试用期将持续 14 天"
    echo "4. 如果仍有问题，请考虑使用不同的网络连接或 VPN"
    
    result.success = true
    result.data = some(stats)
    
    await waitForKeypress()
    
  except Exception as e:
    stats.endTime = now()
    result.error = fmt"重置过程中发生错误: {e.msg}"
    error result.error
    await waitForKeypress()

proc main() {.async.} =
  echo "🚀 Augment Extension Trial Reset Tool"
  echo "====================================\n"
  
  # 初始化日志系统
  initLogger()
  info "程序启动"
  
  try:
    let resetResult = await resetAugmentTrial()
    
    if resetResult.success:
      if resetResult.data.isSome:
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
