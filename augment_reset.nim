#!/usr/bin/env nim
##[
Augment Extension Trial Reset Tool

This script resets the trial period for the Augment coding extension
by modifying the extension's configuration files.
Supports Windows, macOS, and Linux systems.

Main features:
- Automatically detects and closes running VS Code
- Backs up existing configuration
- Generates new random device ID
- Preserves user settings

Author: Based on cursor-reset by @triallord
Created: 2/Jun/2025
Converted to Nim
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
  let homedir = getHomeDir()
  var paths: seq[string] = @[]

  when defined(windows):
    let appdata = getEnv("APPDATA")
    let localappdata = getEnv("LOCALAPPDATA")
    
    # Main configuration paths
    paths.add(appdata / "Code" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(appdata / "Cursor" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(appdata / "Code" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(appdata / "Cursor" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(appdata / "Code" / "User" / "globalStorage" / "augment.augment" / "account.json")
    paths.add(appdata / "Cursor" / "User" / "globalStorage" / "augment.augment" / "account.json")
    
    # Additional cache and storage locations
    paths.add(appdata / "Code" / "Cache" / "augment.augment")
    paths.add(appdata / "Cursor" / "Cache" / "augment.augment")
    paths.add(appdata / "Code" / "CachedData" / "augment.augment")
    paths.add(appdata / "Cursor" / "CachedData" / "augment.augment")
    paths.add(localappdata / "Code" / "User" / "globalStorage" / "augment.augment")
    paths.add(localappdata / "Cursor" / "User" / "globalStorage" / "augment.augment")
    
  elif defined(macosx):
    # Main configuration paths
    paths.add(homedir / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(homedir / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(homedir / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(homedir / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(homedir / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "augment.augment" / "account.json")
    paths.add(homedir / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "account.json")
    
    # Additional cache and storage locations
    paths.add(homedir / "Library" / "Caches" / "Code" / "augment.augment")
    paths.add(homedir / "Library" / "Caches" / "Cursor" / "augment.augment")
    paths.add(homedir / "Library" / "Application Support" / "Code" / "Cache" / "augment.augment")
    paths.add(homedir / "Library" / "Application Support" / "Cursor" / "Cache" / "augment.augment")
    
  elif defined(linux):
    # Main configuration paths
    paths.add(homedir / ".config" / "Code" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(homedir / ".config" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "state.json")
    paths.add(homedir / ".config" / "Code" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(homedir / ".config" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "subscription.json")
    paths.add(homedir / ".config" / "Code" / "User" / "globalStorage" / "augment.augment" / "account.json")
    paths.add(homedir / ".config" / "Cursor" / "User" / "globalStorage" / "augment.augment" / "account.json")
    
    # Additional cache and storage locations
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

proc getUserInput(prompt: string): Future[string] {.async.} =
  stdout.write(prompt)
  stdout.flushFile()
  return stdin.readLine()

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

    # Generate new account data
    echo "🎲 Generating new account data..."
    let newDeviceId = generateDeviceId()
    let newUserId = generateUserId()
    let userEmail = generateEmail()
    echo "✅ New account data generated successfully\n"

    # Calculate trial dates
    let trialStartDate = now()
    let trialEndDate = trialStartDate + 14.days

    for configPath in configPaths:
      echo fmt"\n🔄 Processing: {configPath}"

      try:
        # Create directory if it doesn't exist
        createDir(parentDir(configPath))

        # Backup existing config
        echo "💾 Backing up configuration..."
        try:
          let backupPath = await backupFile(configPath)
          echo fmt"✅ Configuration backup complete: {backupPath}\n"
        except:
          echo "ℹ️ No existing configuration to backup\n"

        # If it's a directory, remove it completely
        try:
          if dirExists(configPath):
            removeDir(configPath)
            echo "✅ Removed directory: " & configPath
            continue
        except:
          discard # Ignore errors if file/directory doesn't exist

        # Create new configuration based on file type
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
          # Default state.json configuration
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

        # Save new configuration
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
