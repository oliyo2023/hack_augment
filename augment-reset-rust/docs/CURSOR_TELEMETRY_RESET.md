# 🔧 Cursor 编辑器遥测和 machineId 重置工具

本文档介绍如何使用专门的脚本来修改 Cursor 编辑器的遥测设置和 machineId，以保护隐私和重置编辑器标识。

## 📋 目录

- [功能概述](#功能概述)
- [支持的平台](#支持的平台)
- [使用方法](#使用方法)
- [脚本说明](#脚本说明)
- [注意事项](#注意事项)
- [故障排除](#故障排除)

## 🎯 功能概述

这些脚本可以帮助您：

1. **查找 Cursor 配置文件** - 自动定位 Cursor 编辑器的配置目录
2. **修改遥测 ID** - 更改所有遥测相关的标识符
3. **重置 machineId** - 查找并修改 machineId 文件
4. **设置只读保护** - 将 machineId 文件设置为只读，防止被重新生成
5. **自动备份** - 在修改前自动创建备份文件

## 🌍 支持的平台

| 平台 | 脚本文件 | 状态 |
|------|----------|------|
| Windows | `cursor-telemetry-reset.ps1` | ✅ 完全支持 |
| Linux | `cursor-telemetry-reset.sh` | ✅ 完全支持 |
| macOS | `cursor-telemetry-reset.sh` | ✅ 完全支持 |

## 🚀 使用方法

### Windows (PowerShell)

```powershell
# 进入脚本目录
cd augment-reset-rust\scripts

# 查看帮助
.\cursor-telemetry-reset.ps1 -Help

# 预览模式（不实际修改文件）
.\cursor-telemetry-reset.ps1 -DryRun

# 详细输出模式
.\cursor-telemetry-reset.ps1 -Verbose

# 正式执行
.\cursor-telemetry-reset.ps1
```

### Linux/macOS (Bash)

```bash
# 进入脚本目录
cd augment-reset-rust/scripts

# 查看帮助
./cursor-telemetry-reset.sh --help

# 预览模式（不实际修改文件）
./cursor-telemetry-reset.sh --dry-run

# 详细输出模式
./cursor-telemetry-reset.sh --verbose

# 正式执行
./cursor-telemetry-reset.sh
```

## 📝 脚本说明

### PowerShell 脚本 (`cursor-telemetry-reset.ps1`)

**参数选项：**
- `-DryRun` - 仅显示将要修改的文件，不实际修改
- `-Verbose` - 显示详细的处理过程
- `-Help` - 显示帮助信息

**功能特点：**
- 自动检测 Windows 系统中的 Cursor 配置目录
- 支持多种可能的安装路径
- 使用 PowerShell 原生 JSON 处理
- 彩色输出，易于阅读

### Bash 脚本 (`cursor-telemetry-reset.sh`)

**参数选项：**
- `--dry-run` - 仅显示将要修改的文件，不实际修改
- `--verbose` - 显示详细的处理过程
- `--help` - 显示帮助信息

**功能特点：**
- 支持 Linux 和 macOS 系统
- 使用 `jq` 工具处理 JSON（如果可用）
- 自动检测系统类型并使用相应的路径
- 兼容性好，支持多种 Unix 系统

### Rust 脚本 (`cursor-telemetry-reset.rs`)

**高级功能：**
- 跨平台支持
- 更强大的 JSON 处理能力
- 递归查找和修改嵌套配置
- 更好的错误处理

**使用方法：**
```bash
# 如果安装了 rust-script
rust-script cursor-telemetry-reset.rs

# 或者编译后运行
rustc cursor-telemetry-reset.rs -o cursor-telemetry-reset
./cursor-telemetry-reset
```

## 🔍 修改的配置项

脚本会查找并修改以下类型的标识符：

### JSON 配置文件中的字段

- `telemetryMachineId` - 遥测机器 ID
- `machineId` - 机器 ID
- `deviceId` - 设备 ID
- `sessionId` - 会话 ID
- `userId` - 用户 ID
- `installationId` - 安装 ID
- `sqmUserId` - SQM 用户 ID
- `sqmMachineId` - SQM 机器 ID

### 特殊文件

- `machineId` 文件
- `machine-id` 文件
- 包含 "machineid" 的文件

## 📁 配置文件位置

### Windows
```
%APPDATA%\Cursor\
%USERPROFILE%\.cursor\
%USERPROFILE%\AppData\Local\Cursor\
%USERPROFILE%\AppData\Roaming\Cursor\
```

### macOS
```
~/Library/Application Support/Cursor/
```

### Linux
```
~/.config/Cursor/
~/.cursor/
~/.local/share/Cursor/
```

## ⚠️ 注意事项

### 使用前准备

1. **关闭 Cursor 编辑器** - 确保 Cursor 完全关闭
2. **备份重要数据** - 脚本会自动备份，但建议手动备份重要配置
3. **管理员权限** - 某些系统可能需要管理员权限

### 依赖要求

**Linux/macOS:**
- `jq` - JSON 处理工具（推荐安装）
  ```bash
  # Ubuntu/Debian
  sudo apt-get install jq
  
  # macOS
  brew install jq
  
  # CentOS/RHEL
  sudo yum install jq
  ```

**Windows:**
- PowerShell 5.0+ （Windows 10 自带）

### 执行权限

**Linux/macOS:**
```bash
chmod +x cursor-telemetry-reset.sh
```

**Windows:**
```powershell
# 如果遇到执行策略问题
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🔧 故障排除

### 常见问题

#### 1. 找不到配置目录
```
❌ 未找到 Cursor 配置目录
```
**解决方案：**
- 确认 Cursor 编辑器已正确安装
- 检查是否使用了非标准安装路径
- 手动指定配置目录路径

#### 2. 权限不足
```
❌ 处理失败: 权限被拒绝
```
**解决方案：**
- 使用管理员权限运行脚本
- 检查文件是否被其他程序占用
- 确保 Cursor 编辑器已完全关闭

#### 3. JSON 解析错误
```
❌ 处理失败: JSON 格式错误
```
**解决方案：**
- 检查配置文件是否损坏
- 使用备份文件恢复
- 重新安装 Cursor 编辑器

#### 4. 缺少 jq 工具 (Linux/macOS)
```
⚠️ 需要 jq 工具来处理 JSON 文件
```
**解决方案：**
- 安装 jq 工具
- 使用 Rust 版本的脚本

### 恢复方法

如果修改后出现问题，可以使用备份文件恢复：

```bash
# 恢复 JSON 配置文件
cp config.json.backup config.json

# 恢复 machineId 文件
cp machineId.backup machineId
chmod 644 machineId  # 移除只读属性
```

## 📊 执行结果示例

```
🔧 Cursor 编辑器遥测和 machineId 重置工具
================================================

ℹ️  处理目录: /home/user/.config/Cursor

🔍 查找 JSON 配置文件...
  找到 3 个 JSON 文件
✅ 已修改: /home/user/.config/Cursor/User/settings.json
✅ 已修改: /home/user/.config/Cursor/User/globalStorage/state.json

🔍 查找 machineId 文件...
  找到 1 个 machineId 文件
✅ 已修改 machineId: /home/user/.config/Cursor/machineId
🔒 已设置为只读: /home/user/.config/Cursor/machineId

🎉 处理完成！
================================================
修改的 JSON 文件: 2
修改的 machineId 文件: 1

💡 建议:
1. 重启 Cursor 编辑器以使更改生效
2. 检查备份文件是否正确创建
3. 如有问题，可以使用备份文件恢复
4. 清除 Cursor 缓存目录以确保完全重置
```

## 🤝 贡献

如果您发现问题或有改进建议，欢迎：

1. 提交 Issue 报告问题
2. 提交 Pull Request 改进脚本
3. 分享使用经验和技巧

## 📄 许可证

本工具遵循 MIT 许可证，仅供学习和研究使用。
