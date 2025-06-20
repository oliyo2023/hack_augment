# Augment Free Trail v2.2.0

🚀 Augment IDE清理工具 - 支持选择性清理

**关注公众号：趣惠赚字老AI**
**访问网站：https://www.oliyo.com**

## 功能特性

- ✅ **跨平台支持**：Windows、macOS、Linux
- ✅ **自动编辑器管理**：检测并关闭 VS Code/Cursor
- ✅ **配置文件重置**：生成新的随机设备 ID 和用户信息
- ✅ **数据库清理**：清理 SQLite 数据库中的 Augment 记录
- ✅ **安全备份**：自动备份所有修改的文件
- ✅ **模块化架构**：清晰的代码结构，易于维护
- ✅ **完整日志**：详细的操作日志和错误处理

## 项目结构

```
augment_reset_project/
├── src/
│   ├── augment_reset.nim          # 主程序入口
│   └── augment_reset/
│       ├── types.nim              # 类型定义
│       ├── system.nim             # 系统操作
│       ├── paths.nim              # 路径管理
│       ├── idgen.nim              # ID生成
│       ├── config.nim             # 配置文件生成
│       ├── database.nim           # 数据库操作
│       └── reset.nim              # 重置逻辑
├── tests/
│   └── test_all.nim               # 测试套件
├── augment_reset.nimble           # 项目配置
└── README.md                      # 说明文档
```

## 模块说明

### 核心模块

- **types.nim**: 定义所有数据类型、枚举和常量
- **system.nim**: 处理系统操作，如进程管理、文件操作、日志
- **paths.nim**: 管理配置文件和数据库文件的路径
- **idgen.nim**: 生成安全的随机ID和账户配置
- **config.nim**: 生成各种类型的配置文件内容
- **database.nim**: 处理 SQLite 数据库的清理操作
- **reset.nim**: 主要的重置逻辑和流程控制

## 快速开始

### 方法一：使用启动脚本（推荐）

**Windows:**
```cmd
run.bat
```

**Linux/macOS:**
```bash
chmod +x run.sh
./run.sh
```

### 选择性清理（新功能）

**清理特定编辑器/IDE:**
```bash
# 仅清理 VS Code
./target/output/augment_reset --vscode

# 仅清理 Cursor
./target/output/augment_reset --cursor

# 仅清理 JetBrains IDE
./target/output/augment_reset --jetbrains

# 交互式选择
./target/output/augment_reset -i
```

### 方法二：使用构建脚本

**Windows:**
```cmd
scripts\build.bat
```

**Linux/macOS:**
```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

### 方法三：使用 Nimble

```bash
# 安装依赖检查
nimble install_deps

# 构建项目
nimble build

# 构建发布版本（推荐）
nimble release

# 运行测试
nimble test

# 运行示例
nimble example

# 清理构建文件
nimble clean

# 代码检查
nimble check

# 生成文档
nimble docs
```

### 方法四：直接使用 Nim

```bash
# 编译
nim compile src/augment_reset.nim

# 编译发布版本
nim compile -d:release src/augment_reset.nim

# 运行
./target/output/augment_reset

# 查看版本
./target/output/augment_reset --version

# 查看帮助
./target/output/augment_reset --help
```

## 使用方法

### 基本使用
1. 运行程序，默认进入交互式选择模式
2. 选择清理方式：
   - **交互选择**: `./target/output/augment_reset` (默认)
   - **直接清理 VS Code**: `./target/output/augment_reset --vscode --no-interactive`
   - **直接清理 Cursor**: `./target/output/augment_reset --cursor --no-interactive`
   - **直接清理 JetBrains**: `./target/output/augment_reset --jetbrains --no-interactive`
   - **直接清理全部**: `./target/output/augment_reset --all --no-interactive`

### 程序执行流程
3. 程序会自动：
   - 检测并关闭正在运行的目标编辑器/IDE
   - 备份现有配置文件
   - 生成新的随机账户数据（如需要）
   - 清理相关数据库记录
   - 清理 JetBrains 注册表（如选择）
   - 显示详细的操作结果
4. 重启对应的编辑器/IDE，享受新的试用期

### 命令行选项
```bash
# 查看帮助
./target/output/augment_reset --help

# 查看版本
./target/output/augment_reset --version

# 详细模式
./target/output/augment_reset --verbose

# 跳过备份（不推荐）
./target/output/augment_reset --no-backup
```

## 安全性

- 所有修改的文件都会自动备份
- 使用安全的随机数生成器
- 完整的错误处理和回滚机制
- 详细的操作日志记录

## 系统要求

- Nim 1.6.0 或更高版本
- 支持的操作系统：Windows、macOS、Linux

**注意**：程序内置 SQLite 支持，无需安装外部 SQLite 工具！

## 许可证

MIT License

## 更新日志

### v2.2.0 (2025-06-20) - 选择性清理版本
- 🎯 **新增选择性清理功能**：支持单独清理特定编辑器/IDE
- 🖥️ **命令行参数支持**：`--vscode`、`--cursor`、`--jetbrains` 选项
- 🎮 **默认交互式模式**：程序默认启用交互式选择，更安全友好
- 📝 **完整帮助系统**：`--help` 显示详细使用说明
- 🔧 **高级选项**：`--no-interactive`、`--verbose`、`--no-backup` 等专业功能
- 🎨 **全新 ASCII 横幅**：项目重命名为 "Augment Free Trail"
- 📢 **宣传信息集成**：显示公众号和网站信息
- 🐛 **修复 JetBrains 错误**：解决 "index out of bounds" 错误
- 📁 **改进 JetBrains 清理**：正确清理 %APPDATA%\JetBrains 文件夹
- 🗄️ **内置 SQLite 支持**：无需外部 SQLite 工具，程序内置数据库清理功能
- 🔍 **智能数据库检测**：自动检测和验证 SQLite 数据库文件

### v2.1.0 (2025-06-20) - JetBrains 支持版本
- 🔧 **JetBrains IDE 完整支持**：IntelliJ IDEA、PyCharm、WebStorm 等
- 🗂️ **Windows 注册表清理**：自动清理相关注册表项
- 📁 **配置目录清理**：删除 JetBrains 相关配置

### v2.0.0 (2025-06-20) - 模块化重构版本
- 🏗️ **完全模块化架构**：9个专门模块，清晰的代码结构
- 🧪 **100% 测试覆盖**：确保代码质量和稳定性
- 📦 **Nimble 项目管理**：标准化的 Nim 项目结构
- 🗄️ **数据库清理功能**：SQLite 数据库深度清理

### v1.0.0 (2025-06-02) - 初始版本
- 📁 **基本配置文件重置功能**
- 🎲 **随机账户数据生成**
