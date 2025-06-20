##[
Augment Reset - 类型定义模块

定义了项目中使用的所有数据类型和枚举
]##

import std/[times, options]

# ============================================================================
# 常量定义
# ============================================================================

const
  # 试用期配置
  TRIAL_DURATION_DAYS* = 14
  
  # ID 生成配置
  DEVICE_ID_LENGTH* = 64
  USER_ID_LENGTH* = 32
  SESSION_ID_LENGTH* = 32
  EMAIL_RANDOM_LENGTH* = 16
  
  # 系统配置
  EDITOR_CLOSE_WAIT_MS* = 1500
  BACKUP_RETENTION_DAYS* = 30
  
  # 文件配置
  CONFIG_FILES* = [
    "state.json",
    "subscription.json",
    "account.json"
  ]
  
  # 支持的编辑器
  EDITORS* = [
    "Code",
    "Cursor"
  ]

  # 支持的 JetBrains IDE
  JETBRAINS_IDES* = [
    "IntelliJIdea",
    "PyCharm",
    "WebStorm",
    "PhpStorm",
    "RubyMine",
    "CLion",
    "DataGrip",
    "GoLand",
    "Rider",
    "AndroidStudio"
  ]

  # Windows 注册表路径
  REGISTRY_PATHS* = [
    "HKEY_CURRENT_USER\\Software\\JavaSoft",
    "HKEY_CURRENT_USER\\Software\\JetBrains"
  ]
  
  # 日志配置
  LOG_FILE* = "augment_reset.log"

# ============================================================================
# 枚举类型
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
    etJetBrains = "JetBrains"

  # 操作系统类型枚举
  OSType* = enum
    osWindows = "windows"
    osMacOS = "macos"
    osLinux = "linux"
    osUnsupported = "unsupported"

  # 清理目标枚举
  CleanTarget* = enum
    ctAll = "all"
    ctVSCode = "vscode"
    ctCursor = "cursor"
    ctJetBrains = "jetbrains"

# ============================================================================
# 数据结构类型
# ============================================================================

type
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

  # 数据库路径信息
  DatabasePathInfo* = object
    path*: string
    editorType*: EditorType
    exists*: bool
    
  # 数据库清理结果
  DatabaseCleanResult* = object
    success*: bool
    dbPath*: string
    backupPath*: string
    deletedRecords*: int
    error*: string
    timestamp*: DateTime

  # JetBrains 清理结果
  JetBrainsCleanResult* = object
    success*: bool
    registryCleared*: bool
    jetbrainsDir*: string
    augmentDir*: string
    clearedPaths*: seq[string]
    error*: string
    timestamp*: DateTime

  # 清理选项配置
  CleanOptions* = object
    target*: CleanTarget
    interactive*: bool
    skipBackup*: bool
    verbose*: bool

  # 重置统计信息
  ResetStats* = object
    totalFiles*: int
    processedFiles*: int
    backupFiles*: int
    errorFiles*: int
    jetbrainsCleared*: bool
    vscodeCleared*: bool
    cursorCleared*: bool
    target*: CleanTarget
    startTime*: DateTime
    endTime*: DateTime

# ============================================================================
# 异常类型
# ============================================================================

type
  # 自定义异常类型
  AugmentResetError* = object of CatchableError
  ConfigError* = object of AugmentResetError
  BackupError* = object of AugmentResetError
  EditorError* = object of AugmentResetError
  DatabaseError* = object of AugmentResetError
  JetBrainsError* = object of AugmentResetError
  RegistryError* = object of AugmentResetError
