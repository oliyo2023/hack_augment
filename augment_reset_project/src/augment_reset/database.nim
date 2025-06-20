##[
Augment Reset - 数据库操作模块

处理 SQLite 数据库的清理操作
使用内置 SQLite 库，无需外部依赖
]##

import std/[strformat, logging, asyncdispatch, options, times, strutils]
import tiny_sqlite
import types, system, paths

# ============================================================================
# 数据库辅助函数
# ============================================================================

# 检查数据库表是否存在
proc checkTableExists(db: DbConn, tableName: string): bool =
  try:
    let query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
    let rows = db.all(query, tableName)
    return rows.len > 0
  except:
    return false

# 检查数据库是否为有效的 SQLite 文件
proc isValidSQLiteFile(filePath: string): bool =
  try:
    let db = openDatabase(filePath)
    defer: db.close()

    # 尝试执行一个简单的查询来验证数据库
    discard db.one("SELECT sqlite_version()")
    return true
  except:
    return false

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

    # 使用 tiny_sqlite 库直接操作数据库
    var deletedRecords = 0

    try:
      # 验证数据库文件
      if not isValidSQLiteFile(dbInfo.path):
        result.error = "无效的 SQLite 数据库文件"
        return result

      # 打开数据库连接
      let db = openDatabase(dbInfo.path)
      defer: db.close()

      # 检查 ItemTable 表是否存在
      if not checkTableExists(db, "ItemTable"):
        info "ItemTable 表不存在，跳过清理"
        deletedRecords = 0
      else:
        # 首先查询要删除的记录数
        let countQuery = "SELECT COUNT(*) FROM ItemTable WHERE key LIKE '%augment%'"
        info fmt"查询 Augment 相关记录数量..."

        try:
          let countRow = db.one(countQuery)
          if countRow.isSome:
            let row = countRow.get()
            deletedRecords = row[0].intVal
            info fmt"找到 {deletedRecords} 条 Augment 相关记录"
          else:
            info "未找到 Augment 相关记录"
            deletedRecords = 0
        except:
          # 如果查询失败，设置为 0
          info "无法查询记录数量"
          deletedRecords = 0

        # 执行删除操作
        if deletedRecords > 0:
          let deleteQuery = "DELETE FROM ItemTable WHERE key LIKE '%augment%'"
          info fmt"执行删除操作: {deleteQuery}"

          db.exec(deleteQuery)
          info fmt"成功删除 {deletedRecords} 条记录"
        else:
          info "没有需要删除的记录"

    except SqliteError as e:
      result.error = fmt"SQLite 操作失败: {e.msg}"
      return result
    except Exception as e:
      result.error = fmt"数据库操作异常: {e.msg}"
      return result

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
    info fmt"{editorName} 数据库清理完成，删除了 {deletedRecords} 条记录"

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
