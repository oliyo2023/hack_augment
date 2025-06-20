##[
Augment Reset - 重置逻辑模块

主要的重置逻辑和配置文件处理
]##

import std/[os, json, strformat, logging, asyncdispatch, options, times, sequtils]
import types, system, paths, config, idgen, database, jetbrains, cli

# ============================================================================
# 配置文件处理
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

# ============================================================================
# 主要重置函数
# ============================================================================

# 主要的重置函数
proc resetAugmentTrial*(options: CleanOptions = CleanOptions(target: ctAll, interactive: false, skipBackup: false, verbose: false)): Future[OperationResult[ResetStats]] {.async.} =
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
    jetbrainsCleared: false,
    vscodeCleared: false,
    cursorCleared: false,
    target: options.target,
    startTime: now(),
    endTime: now()
  )
  
  try:
    info fmt"开始 Augment 试用期重置 - 目标: {getTargetDescription(options.target)}"

    # 生成新的账户配置（如果需要的话）
    var accountConfig: AugmentConfig
    if options.target in [ctAll, ctVSCode, ctCursor]:
      accountConfig = generateAccountConfig()

    # 根据目标检查并关闭相应的编辑器
    if options.target in [ctAll, ctVSCode, ctCursor]:
      echo "🔍 检查正在运行的编辑器..."
      let editorCheck = isEditorRunning()
      if editorCheck.success and editorCheck.data.isSome and editorCheck.data.get():
        echo "⚠️ 检测到 VS Code 或 Cursor 正在运行，尝试关闭..."
        let killResult = await killEditorProcess()
        if killResult.success and killResult.data.isSome and killResult.data.get():
          echo "✅ 编辑器已关闭"
        else:
          echo "❌ 无法关闭编辑器，请手动关闭后重试"
          result.error = "无法关闭编辑器"
          return result
      else:
        echo "✅ 未检测到运行中的编辑器"

    # 根据目标检查并关闭 JetBrains IDE
    if options.target in [ctAll, ctJetBrains]:
      echo "\n🔍 检查正在运行的 JetBrains IDE..."
      let jetbrainsCheck = isJetBrainsRunning()
      if jetbrainsCheck.success and jetbrainsCheck.data.isSome and jetbrainsCheck.data.get():
        echo "⚠️ 检测到 JetBrains IDE 正在运行，尝试关闭..."
        let killJetBrainsResult = await killJetBrainsProcess()
        if killJetBrainsResult.success and killJetBrainsResult.data.isSome and killJetBrainsResult.data.get():
          echo "✅ JetBrains IDE 已关闭"
        else:
          echo "❌ 无法关闭 JetBrains IDE，请手动关闭后重试"
          result.error = "无法关闭 JetBrains IDE"
          return result
      else:
        echo "✅ 未检测到运行中的 JetBrains IDE"
    
    # 获取配置路径并根据目标过滤
    var configPaths: seq[ConfigPathInfo] = @[]

    if options.target in [ctAll, ctVSCode, ctCursor]:
      let pathsResult = getAugmentConfigPaths()
      if not pathsResult.success or pathsResult.data.isNone:
        result.error = pathsResult.error
        return result

      configPaths = pathsResult.data.get()

      # 根据目标过滤路径
      if options.target == ctVSCode:
        configPaths = configPaths.filter(proc(p: ConfigPathInfo): bool = p.editorType == etCode)
        stats.vscodeCleared = true
      elif options.target == ctCursor:
        configPaths = configPaths.filter(proc(p: ConfigPathInfo): bool = p.editorType == etCursor)
        stats.cursorCleared = true
      else: # ctAll
        stats.vscodeCleared = true
        stats.cursorCleared = true

      stats.totalFiles = configPaths.len
      echo fmt"📂 找到 {configPaths.len} 个配置路径"
    else:
      echo "📂 跳过 VS Code/Cursor 配置文件处理"
    
    # 处理配置文件（如果有的话）
    if configPaths.len > 0:
      echo "🎲 使用生成的账户数据处理配置文件...\n"

      # 处理每个配置文件
      for pathInfo in configPaths:
        echo fmt"🔄 处理: {pathInfo.path}"

        let processResult = await processConfigFile(pathInfo, accountConfig)
        if processResult.success:
          stats.processedFiles.inc
          echo "✅ 处理成功"
        else:
          stats.errorFiles.inc
          echo fmt"❌ 处理失败: {processResult.error}"
    
    # 清理数据库记录（仅针对 VS Code/Cursor）
    if options.target in [ctAll, ctVSCode, ctCursor]:
      echo "\n🗄️ 清理数据库记录..."
      let dbCleanResult = await cleanAllDatabases()
      if dbCleanResult.success and dbCleanResult.data.isSome:
        let dbResults = dbCleanResult.data.get()
        for dbResult in dbResults:
          if dbResult.success:
            echo fmt"✅ 数据库清理成功: {extractFilename(dbResult.dbPath)}"
          else:
            echo fmt"❌ 数据库清理失败: {extractFilename(dbResult.dbPath)} - {dbResult.error}"
      else:
        echo fmt"❌ 数据库清理失败: {dbCleanResult.error}"
    else:
      echo "\n🗄️ 跳过数据库清理（仅适用于 VS Code/Cursor）"

    # 清理 JetBrains 相关数据
    if options.target in [ctAll, ctJetBrains]:
      echo "\n🔧 清理 JetBrains IDE 数据..."
      let jetbrainsCleanResult = await cleanJetBrains()
      if jetbrainsCleanResult.success and jetbrainsCleanResult.data.isSome:
        let jetbrainsResult = jetbrainsCleanResult.data.get()
        if jetbrainsResult.success:
          stats.jetbrainsCleared = true
          echo "✅ JetBrains 数据清理完成"
          if jetbrainsResult.registryCleared:
            echo "  📋 注册表已清理"
          if jetbrainsResult.clearedPaths.len > 0:
            echo fmt"  📁 清理了 {jetbrainsResult.clearedPaths.len} 个目录"
        else:
          echo fmt"❌ JetBrains 数据清理失败: {jetbrainsResult.error}"
      else:
        echo fmt"❌ JetBrains 清理过程失败: {jetbrainsCleanResult.error}"
    else:
      echo "\n🔧 跳过 JetBrains IDE 数据清理"

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
    echo fmt"清理目标: {getTargetDescription(stats.target)}"
    echo fmt"总文件数: {stats.totalFiles}"
    echo fmt"成功处理: {stats.processedFiles}"
    echo fmt"处理失败: {stats.errorFiles}"

    # 显示各个组件的清理状态
    if options.target in [ctAll, ctVSCode]:
      let vscodeStatus = if stats.vscodeCleared: "✅ 已完成" else: "❌ 未执行"
      echo fmt"VS Code 清理: {vscodeStatus}"

    if options.target in [ctAll, ctCursor]:
      let cursorStatus = if stats.cursorCleared: "✅ 已完成" else: "❌ 未执行"
      echo fmt"Cursor 清理: {cursorStatus}"

    if options.target in [ctAll, ctJetBrains]:
      let jetbrainsStatus = if stats.jetbrainsCleared: "✅ 已完成" else: "❌ 未执行"
      echo fmt"JetBrains 清理: {jetbrainsStatus}"

    echo fmt"处理时间: {(stats.endTime - stats.startTime).inMilliseconds} 毫秒"

    echo "\n🎉 Augment 扩展试用期重置完成!"
    echo "\n⚠️ 重要提示:"
    echo "1. 请重启您的编辑器 (VS Code、Cursor 或 JetBrains IDE) 以使更改生效"
    echo "2. 在提示时创建新账户"
    echo "3. 试用期将持续 14 天"
    echo "4. JetBrains IDE 用户可能需要重新登录账户"
    echo "5. 如果仍有问题，请考虑使用不同的网络连接或 VPN"

    result.success = true
    result.data = some(stats)

    await waitForKeypress()

  except Exception as e:
    stats.endTime = now()
    result.error = fmt"重置过程中发生错误: {e.msg}"
    error result.error
    await waitForKeypress()
