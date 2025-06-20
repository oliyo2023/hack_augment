# 🚀 Augment Reset Tool

> **专业级 Augment 扩展试用期重置工具**  
> 模块化架构 | 完整测试 | 跨平台支持

[![Nim](https://img.shields.io/badge/Nim-2.0+-yellow.svg)](https://nim-lang.org/)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-100%25-brightgreen.svg)](#)

## ✨ 功能特性

### 🎯 核心功能
- 🔄 **智能重置**：配置文件 + 数据库双重清理，确保完全重置
- 🛡️ **安全可靠**：自动备份所有修改文件，支持一键恢复
- 🎲 **随机生成**：安全的设备ID、用户ID和邮箱地址生成
- 🔍 **自动检测**：智能发现并关闭正在运行的编辑器

### 🏗️ 技术特性
- 📦 **模块化架构**：8个专门模块，职责清晰，易于维护
- 🧪 **完整测试**：100% 测试覆盖，确保代码质量
- 🌍 **跨平台支持**：Windows、macOS、Linux 原生支持
- 📝 **详细日志**：完整的操作记录和错误追踪

### 🎨 用户体验
- ⚡ **一键操作**：简单命令即可完成所有重置操作
- 💬 **友好提示**：清晰的进度显示和操作指导
- 🔧 **命令行工具**：支持 `--version`、`--help` 等标准参数
- 📊 **统计报告**：详细的操作结果和性能统计

## 🏗️ 项目结构

```
📦 hack_augment/
├── 🚀 augment_reset_project/     # 主项目（Nim 模块化版本）
│   ├── src/                      # 源代码
│   │   ├── augment_reset.nim     # 主程序入口
│   │   └── augment_reset/        # 核心模块
│   │       ├── types.nim         # 类型定义
│   │       ├── system.nim        # 系统操作
│   │       ├── paths.nim         # 路径管理
│   │       ├── idgen.nim         # ID生成
│   │       ├── config.nim        # 配置生成
│   │       ├── database.nim      # 数据库操作
│   │       ├── reset.nim         # 重置逻辑
│   │       └── version.nim       # 版本管理
│   ├── tests/                    # 测试套件
│   ├── scripts/                  # 构建脚本
│   └── docs/                     # 项目文档
├── 📚 principles/                # 原理和历史版本
│   ├── ResetAugment.py          # Python 版本
│   ├── augment-reset.js         # JavaScript 版本
│   └── README.md                # 原理说明
└── 📄 README.md                 # 项目主文档
```

## 🚀 快速开始

### 📋 系统要求

- **Nim**: 1.6.0 或更高版本
- **SQLite3**: 命令行工具（用于数据库清理）
- **操作系统**: Windows 10+、macOS 10.14+、Linux（主流发行版）

### ⚡ 一键安装和运行

#### Windows 用户
```cmd
# 进入项目目录
cd augment_reset_project

# 构建发布版本
nimble build -d:release

# 运行重置工具
.\augment_reset.exe
```

#### macOS/Linux 用户
```bash
# 进入项目目录
cd augment_reset_project

# 构建发布版本
nimble build -d:release

# 运行重置工具
./augment_reset
```

### 🔧 高级用法

```bash
# 查看版本信息
./augment_reset --version

# 查看帮助信息
./augment_reset --help

# 运行测试套件
nimble test

# 运行示例程序
nimble example

# 生成项目文档
nimble docs
```

## 📖 使用指南

### 🎯 基本使用流程

1. **准备工作**
   ```bash
   # 确保已关闭所有 VS Code 和 Cursor 实例
   # 程序会自动检测并提示关闭
   ```

2. **运行重置**
   ```bash
   ./augment_reset
   ```

3. **重置过程**
   - 🔍 自动检测正在运行的编辑器
   - 🛑 安全关闭编辑器进程
   - 📂 扫描并备份配置文件
   - 🎲 生成新的随机账户数据
   - 🗄️ 清理 SQLite 数据库记录
   - 🧹 清理过期备份文件
   - 📊 显示详细的操作统计

4. **完成重置**
   - ✅ 重启编辑器
   - 🎉 享受新的 14 天试用期

### 🛡️ 安全特性

- **自动备份**: 所有修改的文件都会自动备份，文件名包含时间戳
- **错误恢复**: 如果操作失败，可以从备份文件恢复
- **进程保护**: 确保编辑器完全关闭后才进行操作
- **权限检查**: 验证文件访问权限，避免权限错误

## 🔧 开发指南

### 🏗️ 构建项目

```bash
# 克隆项目
git clone <repository-url>
cd hack_augment/augment_reset_project

# 安装依赖
nimble install

# 开发构建
nimble build

# 发布构建
nimble build -d:release

# 运行测试
nimble test

# 代码检查
nimble check
```

### 🧪 测试系统

项目包含完整的测试套件：

```bash
# 运行所有测试
nimble test

# 运行特定测试
nim compile --run tests/test_all.nim

# 查看测试覆盖率
# 测试覆盖：系统操作、ID生成、路径管理、配置生成
```

### 📚 模块说明

| 模块 | 功能 | 行数 |
|------|------|------|
| `types.nim` | 类型定义和常量 | 120 |
| `system.nim` | 系统操作和进程管理 | 250 |
| `paths.nim` | 路径管理和文件发现 | 200 |
| `idgen.nim` | 安全ID生成 | 80 |
| `config.nim` | 配置文件生成 | 80 |
| `database.nim` | SQLite 数据库操作 | 100 |
| `reset.nim` | 主要重置逻辑 | 180 |
| `version.nim` | 版本信息管理 | 30 |

## 🔍 工作原理

Augment 扩展将试用期信息存储在两个位置：

1. **配置文件** (JSON格式)
   - 位置：`%APPDATA%/[Editor]/User/globalStorage/augment.augment/`
   - 包含：设备ID、用户ID、试用期时间等

2. **SQLite 数据库**
   - 位置：`%APPDATA%/[Editor]/User/globalStorage/state.vscdb`
   - 包含：扩展状态和使用记录

本工具通过以下步骤实现完全重置：
- 🔄 生成新的随机设备和用户标识
- 📝 重写所有相关配置文件
- 🗄️ 清理数据库中的历史记录
- 🛡️ 确保所有痕迹都被清除

详细原理请参考：[principles/README.md](principles/README.md)

## 📈 版本历史

- **v2.0.0** (2025-06-20) - 模块化重构版本
  - 🏗️ 完全模块化架构
  - 🧪 100% 测试覆盖
  - 📦 Nimble 项目管理
  - 🗄️ 数据库清理功能

- **v1.5.0** - Python 版本（已归档）
  - 🐍 Python 实现
  - 🗄️ SQLite 数据库清理

- **v1.0.0** - JavaScript 版本（已归档）
  - 🌐 Node.js 实现
  - 📁 基本配置文件重置

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 📝 代码规范

- 使用 Nim 官方代码风格
- 添加适当的注释和文档
- 确保所有测试通过
- 更新相关文档

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## ⚠️ 免责声明

本工具仅用于学习和研究目的。请遵守软件许可协议和相关法律法规。使用本工具的风险由用户自行承担。

## 🙏 致谢

- [Nim 编程语言](https://nim-lang.org/) - 优雅的系统编程语言
- [SQLite](https://www.sqlite.org/) - 轻量级数据库引擎
- 所有贡献者和测试用户

---

<div align="center">

**如果这个项目对您有帮助，请给个 ⭐ Star！**

[报告问题](../../issues) • [功能请求](../../issues) • [讨论](../../discussions)

</div>
