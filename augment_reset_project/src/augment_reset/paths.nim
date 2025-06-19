##[
Augment Reset - 路径管理模块

处理配置文件和数据库文件的路径获取和管理
]##

import std/[os, tables, strformat, logging, options, times, strutils]
import types, system

# ============================================================================
# 基础路径获取
# ============================================================================

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

# ============================================================================
# 配置文件路径
# ============================================================================

# 构建配置文件路径
proc buildConfigPaths*(basePaths: Table[string, string], osType: OSType): seq[ConfigPathInfo] =
  result = @[]
  
  case osType:
  of osWindows:
    let appdata = basePaths.getOrDefault("appdata", "")
    
    if appdata != "":
      for editor in EDITORS:
        for configFile in CONFIG_FILES:
          let path = appdata / editor / "User" / "globalStorage" / "augment.augment" / configFile
          result.add(ConfigPathInfo(
            path: path,
            fileType: case configFile:
              of "state.json": cfState
              of "subscription.json": cfSubscription
              of "account.json": cfAccount
              else: cfState,
            editorType: case editor:
              of "Code": etCode
              of "Cursor": etCursor
              else: etCode,
            exists: fileExists(path)
          ))
      
      # 缓存目录
      for editor in EDITORS:
        for cacheDir in ["Cache", "CachedData"]:
          let path = appdata / editor / cacheDir / "augment.augment"
          result.add(ConfigPathInfo(
            path: path,
            fileType: cfState, # 默认类型
            editorType: case editor:
              of "Code": etCode
              of "Cursor": etCursor
              else: etCode,
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
            fileType: case configFile:
              of "state.json": cfState
              of "subscription.json": cfSubscription
              of "account.json": cfAccount
              else: cfState,
            editorType: case editor:
              of "Code": etCode
              of "Cursor": etCursor
              else: etCode,
            exists: fileExists(path)
          ))
    
    if caches != "":
      for editor in EDITORS:
        let path = caches / editor / "augment.augment"
        result.add(ConfigPathInfo(
          path: path,
          fileType: cfState,
          editorType: case editor:
            of "Code": etCode
            of "Cursor": etCursor
            else: etCode,
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
            fileType: case configFile:
              of "state.json": cfState
              of "subscription.json": cfSubscription
              of "account.json": cfAccount
              else: cfState,
            editorType: case editor:
              of "Code": etCode
              of "Cursor": etCursor
              else: etCode,
            exists: fileExists(path)
          ))
    
    if cache != "":
      for editor in EDITORS:
        let path = cache / editor / "augment.augment"
        result.add(ConfigPathInfo(
          path: path,
          fileType: cfState,
          editorType: case editor:
            of "Code": etCode
            of "Cursor": etCursor
            else: etCode,
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
# 数据库文件路径
# ============================================================================

# 获取数据库路径
proc getDatabasePaths*(): OperationResult[seq[DatabasePathInfo]] =
  result = OperationResult[seq[DatabasePathInfo]](
    success: false,
    data: some(newSeq[DatabasePathInfo]()),
    error: "",
    timestamp: now()
  )
  
  try:
    let osType = getCurrentOS()
    var dbPaths: seq[DatabasePathInfo] = @[]
    
    case osType:
    of osWindows:
      let appdata = getEnv("APPDATA")
      if appdata != "":
        # Cursor 数据库
        let cursorPath = appdata / "Cursor" / "User" / "globalStorage" / "state.vscdb"
        dbPaths.add(DatabasePathInfo(
          path: cursorPath,
          editorType: etCursor,
          exists: fileExists(cursorPath)
        ))
        
        # VS Code 数据库
        let codePath = appdata / "Code" / "User" / "globalStorage" / "state.vscdb"
        dbPaths.add(DatabasePathInfo(
          path: codePath,
          editorType: etCode,
          exists: fileExists(codePath)
        ))
        
        # Void 编辑器数据库
        let voidPath = appdata / "Void" / "User" / "globalStorage" / "state.vscdb"
        dbPaths.add(DatabasePathInfo(
          path: voidPath,
          editorType: etCode, # 使用 Code 类型作为默认
          exists: fileExists(voidPath)
        ))
    
    of osMacOS:
      let homeDir = getHomeDir()
      let appSupport = homeDir / "Library" / "Application Support"
      
      # Cursor 数据库
      let cursorPath = appSupport / "Cursor" / "User" / "globalStorage" / "state.vscdb"
      dbPaths.add(DatabasePathInfo(
        path: cursorPath,
        editorType: etCursor,
        exists: fileExists(cursorPath)
      ))
      
      # VS Code 数据库
      let codePath = appSupport / "Code" / "User" / "globalStorage" / "state.vscdb"
      dbPaths.add(DatabasePathInfo(
        path: codePath,
        editorType: etCode,
        exists: fileExists(codePath)
      ))
    
    of osLinux:
      let homeDir = getHomeDir()
      let configDir = homeDir / ".config"
      
      # Cursor 数据库
      let cursorPath = configDir / "Cursor" / "User" / "globalStorage" / "state.vscdb"
      dbPaths.add(DatabasePathInfo(
        path: cursorPath,
        editorType: etCursor,
        exists: fileExists(cursorPath)
      ))
      
      # VS Code 数据库
      let codePath = configDir / "Code" / "User" / "globalStorage" / "state.vscdb"
      dbPaths.add(DatabasePathInfo(
        path: codePath,
        editorType: etCode,
        exists: fileExists(codePath)
      ))
      
      # Void 编辑器数据库
      let voidPath = configDir / "Void" / "User" / "globalStorage" / "state.vscdb"
      dbPaths.add(DatabasePathInfo(
        path: voidPath,
        editorType: etCode,
        exists: fileExists(voidPath)
      ))
    
    of osUnsupported:
      result.error = "不支持的操作系统"
      return result
    
    # 过滤掉不存在的路径
    var existingPaths: seq[DatabasePathInfo] = @[]
    for db in dbPaths:
      if db.exists:
        existingPaths.add(db)
    
    result.success = true
    result.data = some(existingPaths)
    info fmt"找到 {existingPaths.len} 个数据库文件"
    
  except Exception as e:
    result.error = fmt"获取数据库路径时出错: {e.msg}"
    error result.error
