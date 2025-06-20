##[
Augment Reset - 测试套件

测试各个模块的基本功能
]##

import std/[unittest, asyncdispatch, options, strutils]
import ../src/augment_reset/[types, system, idgen, paths, jetbrains, cli]

suite "系统操作测试":
  test "操作系统检测":
    let osType = getCurrentOS()
    check osType != osUnsupported
    echo "检测到操作系统: ", osType

  test "编辑器运行状态检测":
    let result = isEditorRunning()
    check result.success == true
    echo "编辑器运行状态检测: ", if result.data.isSome(): $result.data.get() else: "未知"

suite "ID生成测试":
  test "设备ID生成":
    let deviceId = generateDeviceId()
    check deviceId.len == DEVICE_ID_LENGTH
    echo "生成的设备ID长度: ", deviceId.len

  test "用户ID生成":
    let userId = generateUserId()
    check userId.len == USER_ID_LENGTH
    echo "生成的用户ID长度: ", userId.len

  test "邮箱生成":
    let email = generateEmail()
    check "@example.com" in email
    echo "生成的邮箱: ", email

  test "账户配置生成":
    let config = generateAccountConfig()
    check config.deviceId.len > 0
    check config.userId.len > 0
    check config.email.len > 0
    echo "账户配置生成成功"

suite "路径管理测试":
  test "配置路径获取":
    let result = getAugmentConfigPaths()
    check result.success == true
    if result.data.isSome():
      let paths = result.data.get()
      echo "找到配置路径数量: ", paths.len
    else:
      echo "未找到配置路径"

suite "JetBrains 操作测试":
  test "JetBrains IDE 运行状态检测":
    let result = isJetBrainsRunning()
    check result.success == true
    echo "JetBrains IDE 运行状态: ", if result.data.isSome(): $result.data.get() else: "未知"

  test "JetBrains 路径获取":
    let paths = getJetBrainsPaths()
    check paths.len >= 0
    echo "找到 JetBrains 路径数量: ", paths.len
    for i, path in paths:
      if i < 3:  # 只显示前3个
        echo "  - ", path

suite "CLI 模块测试":
  test "清理目标解析":
    check parseCleanTarget("all") == ctAll
    check parseCleanTarget("vscode") == ctVSCode
    check parseCleanTarget("cursor") == ctCursor
    check parseCleanTarget("jetbrains") == ctJetBrains
    echo "清理目标解析测试通过"

  test "目标描述获取":
    check getTargetDescription(ctAll) == "所有编辑器/IDE"
    check getTargetDescription(ctVSCode) == "VS Code"
    check getTargetDescription(ctCursor) == "Cursor"
    check getTargetDescription(ctJetBrains) == "JetBrains IDE"
    echo "目标描述获取测试通过"

  test "目标详细信息获取":
    let allDetails = getTargetDetails(ctAll)
    check allDetails.len == 3

    let vscodeDetails = getTargetDetails(ctVSCode)
    check vscodeDetails.len == 1

    let jetbrainsDetails = getTargetDetails(ctJetBrains)
    check jetbrainsDetails.len > 5  # JetBrains 有多个 IDE

    echo "目标详细信息获取测试通过"

when isMainModule:
  echo "🧪 运行 Augment Reset 测试套件"
  echo "================================\n"
