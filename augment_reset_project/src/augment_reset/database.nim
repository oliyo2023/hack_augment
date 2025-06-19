##[
Augment Reset - 数据库操作模块

处理 SQLite 数据库的清理操作
]##

import std/[strformat, logging, asyncdispatch, osproc, os, options, times]
import types, system, paths

# ============================================================================
# 数据库清理
# ============================================================================

# 清理单个数据库文件
proc cleanDatabase*(dbInfo: DatabasePathInfo): Future[OperationResult[DatabaseCleanResult]] {.async.} =
  result = OperationResult[DatabaseCleanResult](
    success: false,
    data: none(DatabaseCleanResult),
    error: "",
    timestamp: now()
  )
  
  try:
    if not dbInfo.exists:
      result.error = "数据库文件不存在"
      return result
    
    let editorName = if dbInfo.editorType == etCursor: "Cursor" else: "Code"
    info fmt"正在处理 {editorName} 数据库: {dbInfo.path}"
    
    # 创建备份
    let backupResult = await backupFile(dbInfo.path)
    if not backupResult.success:
      result.error = fmt"备份数据库失败: {backupResult.error}"
      return result
    
    let backupPath = if backupResult.data.isSome: backupResult.data.get().backupPath else: ""
    
    # 使用 SQLite 命令行工具删除记录
    let deleteCmd = fmt"""sqlite3 "{dbInfo.path}" "DELETE FROM ItemTable WHERE key LIKE '%augment%';" """
    
    info fmt"执行删除命令: {deleteCmd}"
    let (output, exitCode) = execCmdEx(deleteCmd)
    
    if exitCode != 0:
      result.error = fmt"删除数据库记录失败: {output}"
      return result
    
    # 获取删除的记录数（这里简化处理，实际可能需要先查询再删除）
    let deletedRecords = 0  # 简化处理
    
    let cleanResult = DatabaseCleanResult(
      success: true,
      dbPath: dbInfo.path,
      backupPath: backupPath,
      deletedRecords: deletedRecords,
      error: "",
      timestamp: now()
    )
    
    result.success = true
    result.data = some(cleanResult)
    info fmt"{editorName} 数据库清理完成"
    
  except Exception as e:
    result.error = fmt"清理数据库时出错: {e.msg}"
    error result.error

# 清理所有数据库
proc cleanAllDatabases*(): Future[OperationResult[seq[DatabaseCleanResult]]] {.async.} =
  result = OperationResult[seq[DatabaseCleanResult]](
    success: false,
    data: some(newSeq[DatabaseCleanResult]()),
    error: "",
    timestamp: now()
  )
  
  try:
    # 获取所有数据库路径
    let dbPathsResult = getDatabasePaths()
    if not dbPathsResult.success or dbPathsResult.data.isNone:
      result.error = dbPathsResult.error
      return result
    
    let dbPaths = dbPathsResult.data.get()
    if dbPaths.len == 0:
      info "未找到需要处理的数据库文件"
      result.success = true
      return result
    
    info fmt"找到 {dbPaths.len} 个数据库文件"
    var cleanResults: seq[DatabaseCleanResult] = @[]
    
    # 处理每个数据库
    for dbInfo in dbPaths:
      let cleanResult = await cleanDatabase(dbInfo)
      if cleanResult.success and cleanResult.data.isSome:
        cleanResults.add(cleanResult.data.get())
      else:
        # 即使失败也记录结果
        cleanResults.add(DatabaseCleanResult(
          success: false,
          dbPath: dbInfo.path,
          backupPath: "",
          deletedRecords: 0,
          error: cleanResult.error,
          timestamp: now()
        ))
    
    result.success = true
    result.data = some(cleanResults)
    info "数据库清理处理完成"
    
  except Exception as e:
    result.error = fmt"清理数据库时出错: {e.msg}"
    error result.error
