##[
Augment Reset - 使用示例

展示如何使用各个模块的功能
]##

import std/[asyncdispatch, options]
import src/augment_reset/[types, system, idgen, paths, database]

proc example() {.async.} =
  echo "🔧 Augment Reset 模块使用示例"
  echo "============================\n"
  
  # 初始化日志
  initLogger()
  
  # 1. 系统检测
  echo "1. 系统检测:"
  let osType = getCurrentOS()
  echo "   操作系统: ", osType
  
  let editorResult = isEditorRunning()
  if editorResult.success and editorResult.data.isSome():
    echo "   编辑器运行状态: ", editorResult.data.get()
  
  # 2. ID 生成
  echo "\n2. ID 生成:"
  let deviceId = generateDeviceId()
  echo "   设备ID: ", deviceId[0..15], "..."
  
  let userId = generateUserId()
  echo "   用户ID: ", userId[0..15], "..."
  
  let email = generateEmail()
  echo "   邮箱: ", email
  
  # 3. 路径管理
  echo "\n3. 路径管理:"
  let configResult = getAugmentConfigPaths()
  if configResult.success and configResult.data.isSome():
    let paths = configResult.data.get()
    echo "   找到配置路径: ", paths.len, " 个"
    for i, path in paths:
      if i < 3:  # 只显示前3个
        echo "   - ", path.path
  
  let dbResult = getDatabasePaths()
  if dbResult.success and dbResult.data.isSome():
    let dbPaths = dbResult.data.get()
    echo "   找到数据库: ", dbPaths.len, " 个"
    for i, db in dbPaths:
      if i < 3:  # 只显示前3个
        echo "   - ", db.path
  
  # 4. 账户配置生成
  echo "\n4. 账户配置生成:"
  let config = generateAccountConfig()
  echo "   用户ID: ", config.userId[0..7], "..."
  echo "   设备ID: ", config.deviceId[0..7], "..."
  echo "   邮箱: ", config.email
  echo "   试用开始: ", config.trialStartDate.format("yyyy-MM-dd")
  echo "   试用结束: ", config.trialEndDate.format("yyyy-MM-dd")
  
  echo "\n✅ 示例完成！"

when isMainModule:
  waitFor example()
