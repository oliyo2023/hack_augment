#!/usr/bin/env nim
##[
Augment 扩展试用期重置工具

此脚本通过修改扩展的配置文件来重置 Augment 编程扩展的试用期。
支持 Windows、macOS 和 Linux 系统。

主要功能：
- 自动检测并关闭正在运行的 VS Code
- 备份现有配置
- 生成新的随机设备 ID
- 保留用户设置

创建时间：2025年6月2日
转换为 Nim 语言
]##

import std/[os, json, times, random, strutils, strformat, osproc, terminal]
import std/[asyncdispatch]

proc waitForKeypress() {.async.} =
  when defined(windows):
    if getEnv("TERM") == "":
      echo "\nPress any key to exit..."
      discard getch()
  else:
    discard

proc isEditorRunning(): bool =
  try:
    when defined(windows):
      let output = execProcess("tasklist /FI \"IMAGENAME eq Code.exe\" /FI \"IMAGENAME eq Cursor.exe\"")
      return "code.exe" in output.toLower() or "cursor.exe" in output.toLower()
    elif defined(macosx):
      let output = execProcess("pgrep -x \"Code\" || pgrep -x \"Cursor\" || pgrep -x \"Code Helper\" || pgrep -x \"Cursor Helper\"")
      return output.len > 0
    elif defined(linux):
      let output = execProcess("pgrep -x \"code\" || pgrep -x \"cursor\" || pgrep -x \"Code\" || pgrep -x \"Cursor\"")
      return output.len > 0
    else:
      return false
  except:
    return false

proc killEditorProcess(): Future[bool] {.async.} =
  try:
    var command = ""
    when defined(windows):
      command = "taskkill /F /IM Code.exe /T & taskkill /F /IM Cursor.exe /T"
    elif defined(macosx):
      command = "pkill -9 \"Code\" & pkill -9 \"Cursor\""
    elif defined(linux):
      command = "pkill -9 \"code\" & pkill -9 \"cursor\""
    else:
      raise newException(OSError, "Unsupported operating system")

    discard execProcess(command)
    await sleepAsync(1500)
    
    if not isEditorRunning():
      return true
    return false
  except Exception as e:
    echo "Error closing editors: ", e.msg
    return false

proc formatTimestamp(date: DateTime): string =
  let year = $date.year
  let month = align($date.month.int, 2, '0')
  let day = align($date.monthday, 2, '0')
  let hours = align($date.hour, 2, '0')
  let minutes = align($date.minute, 2, '0')
  let seconds = align($date.second, 2, '0')
  let milliseconds = align($(date.nanosecond div 1_000_000), 3, '0')

  return fmt"{year}{month}{day}{hours}{minutes}{seconds}{milliseconds}"

proc backupFile(filePath: string): Future[string] {.async.} =
  try:
    let timestamp = formatTimestamp(now())
    let backupPath = fmt"{filePath}.{timestamp}.bak"
    copyFile(filePath, backupPath)
    return backupPath
  except Exception as e:
    raise newException(IOError, fmt"Backup failed: {e.msg}")

proc getAugmentConfigPaths(): seq[string] =
  var paths: seq[string] = @[]

  when defined(windows):
    let appdata = getEnv("APPDATA")
    let localappdata = getEnv("LOCALAPPDATA")
    
    # 主要配置路径
    paths.add(appdata / "Code" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(appdata / "Cursor" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(appdata / "Code" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(appdata / "Cursor" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(appdata / "Code" / "User" / "globalStorage" / "augment.augment" / "account.json")
    paths.add(appdata / "Cursor" / "User" / "globalStorage" / "augment.augment" / "account.json")
    
    # 额外的缓存和存储位置
    paths.add(appdata / "Code" / "Cache" / "augment.augment")
    paths.add(appdata / "Cursor" / "Cache" / "augment.augment")
    paths.add(appdata / "Code" / "CachedData" / "augment.augment")
    paths.add(appdata / "Cursor" / "CachedData" / "augment.augment")
    paths.add(localappdata / "Code" / "User" / "globalStorage" / "augment.augment")
    paths.add(localappdata / "Cursor" / "User" / "globalStorage" / "augment.augment")
    
  elif defined(macosx):
    let homedir = getHomeDir()
    # 主要配置路径
    paths.add(homedir / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(homedir / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(homedir / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(homedir / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(homedir / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "augment.augment" / "account.json")
    paths.add(homedir / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "account.json")
    
    # 额外的缓存和存储位置
    paths.add(homedir / "Library" / "Caches" / "Code" / "augment.augment")
    paths.add(homedir / "Library" / "Caches" / "Cursor" / "augment.augment")
    paths.add(homedir / "Library" / "Application Support" / "Code" / "Cache" / "augment.augment")
    paths.add(homedir / "Library" / "Application Support" / "Cursor" / "Cache" / "augment.augment")
    
  elif defined(linux):
    let homedir = getHomeDir()
    # 主要配置路径
    paths.add(homedir / ".config" / "Code" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(homedir / ".config" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(homedir / ".config" / "Code" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(homedir / ".config" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(homedir / ".config" / "Code" / "User" / "globalStorage" / "augment.augment" / "account.json")
    paths.add(homedir / ".config" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "account.json")
    
    # 额外的缓存和存储位置
    paths.add(homedir / ".cache" / "Code" / "augment.augment")
    paths.add(homedir / ".cache" / "Cursor" / "augment.augment")
    paths.add(homedir / ".config" / "Code" / "Cache" / "augment.augment")
    paths.add(homedir / ".config" / "Cursor" / "Cache" / "augment.augment")
  else:
    raise newException(OSError, "Unsupported operating system")

  return paths

proc generateDeviceId(): string =
  randomize()
  var deviceId = ""
  for i in 0..<64:
    deviceId.add(toHex(rand(15), 1).toLower())
  return deviceId

proc generateEmail(): string =
  randomize()
  var randomString = ""
  for i in 0..<16:
    randomString.add(toHex(rand(15), 1).toLower())
  return fmt"user_{randomString}@example.com"

proc generateUserId(): string =
  randomize()
  var userId = ""
  for i in 0..<32:
    userId.add(toHex(rand(15), 1).toLower())
  return userId


proc resetAugmentTrial() {.async.} =
  try:
    echo "🔍 Checking for running editors..."
    if isEditorRunning():
      echo "⚠️ VS Code or Cursor is running, attempting to close..."
      if await killEditorProcess():
        echo "✅ Editors have been closed\n"
      else:
        echo "❌ Failed to close editors"
        return

    let configPaths = getAugmentConfigPaths()
    echo "📂 Found configuration paths: ", configPaths

    # 生成新的账户数据
    echo "🎲 Generating new account data..."
    let newDeviceId = generateDeviceId()
    let newUserId = generateUserId()
    let userEmail = generateEmail()
    echo "✅ New account data generated successfully\n"

    # 计算试用期日期
    let trialStartDate = now()
    let trialEndDate = trialStartDate + 14.days

    for configPath in configPaths:
      echo fmt"\n🔄 Processing: {configPath}"

      try:
        # 如果目录不存在则创建
        createDir(parentDir(configPath))

        # 备份现有配置
        echo "💾 Backing up configuration..."
        try:
          let backupPath = await backupFile(configPath)
          echo fmt"✅ Configuration backup complete: {backupPath}\n"
        except:
          echo "ℹ️ No existing configuration to backup\n"

        # 如果是目录，则完全删除
        try:
          if dirExists(configPath):
            removeDir(configPath)
            echo "✅ Removed directory: " & configPath
            continue
        except:
          discard # 如果文件/目录不存在则忽略错误

        # 根据文件类型创建新配置
        var newConfig: JsonNode
        if "subscription.json" in configPath:
          newConfig = %*{
            "status": "active",
            "type": "trial",
            "startDate": trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "endDate": trialEndDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "isActive": true,
            "isExpired": false,
            "remainingDays": 14,
            "trialCount": 0,
            "lastTrialReset": nil,
            "previousTrials": newJArray()
          }
        elif "account.json" in configPath:
          newConfig = %*{
            "userId": newUserId,
            "email": userEmail,
            "deviceId": newDeviceId,
            "createdAt": trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "lastLogin": trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "isActive": true,
            "trialHistory": newJArray(),
            "deviceHistory": newJArray()
          }
        else:
          # 默认的 state.json 配置
          newConfig = %*{
            "deviceId": newDeviceId,
            "userId": newUserId,
            "email": userEmail,
            "trialStartDate": trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "trialEndDate": trialEndDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "trialDuration": 14,
            "trialStatus": "active",
            "trialExpired": false,
            "trialRemainingDays": 14,
            "trialCount": 0,
            "usageCount": 0,
            "totalUsageCount": 0,
            "lastUsageDate": nil,
            "messageCount": 0,
            "totalMessageCount": 0,
            "lastReset": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "firstRunDate": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "lastRunDate": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
            "sessionId": generateUserId(),
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

        # 保存新配置
        writeFile(configPath, pretty(newConfig, 2))
        echo "✅ New configuration saved successfully\n"

        if "state.json" in configPath:
          echo "Account Details:"
          echo "User ID: ", newUserId
          echo "Device ID: ", newDeviceId
          echo "Email: ", userEmail
          echo "\nTrial period: 14 days"
          echo "Start date: ", trialStartDate.format("yyyy-MM-dd")
          echo "End date: ", trialEndDate.format("yyyy-MM-dd")
      except Exception as e:
        echo fmt"❌ Error processing {configPath}: {e.msg}"

    echo "\n🎉 Augment extension trial reset complete!"
    echo "\n⚠️ Important:"
    echo "1. Please restart your editor (VS Code or Cursor) for changes to take effect"
    echo "2. Create a new account when prompted"
    echo "3. The trial period will be active for 14 days"
    echo "4. Consider using a different network connection or VPN if issues persist"

    await waitForKeypress()
  except Exception as e:
    echo "❌ An error occurred: ", e.msg
    await waitForKeypress()

proc main() {.async.} =
  try:
    await resetAugmentTrial()
  except Exception as e:
    echo "\n❌ Program execution error: ", e.msg
    await waitForKeypress()

when isMainModule:
  waitFor main()
