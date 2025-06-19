# Augment Reset Tool v2.0

Augment 扩展试用期重置工具 - 模块化版本

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

### 方法一：使用构建脚本（推荐）

**Windows:**
```cmd
scripts\build.bat
```

**Linux/macOS:**
```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

### 方法二：使用 Nimble

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

### 方法三：直接使用 Nim

```bash
# 编译
nim compile src/augment_reset.nim

# 编译发布版本
nim compile -d:release src/augment_reset.nim

# 运行
./augment_reset

# 查看版本
./augment_reset --version

# 查看帮助
./augment_reset --help
```

## 使用方法

1. 关闭所有 VS Code 或 Cursor 实例
2. 运行程序：`./augment_reset`
3. 程序会自动：
   - 检测并关闭正在运行的编辑器
   - 备份现有配置文件
   - 生成新的随机账户数据
   - 清理数据库记录
   - 显示详细的操作结果
4. 重启编辑器，享受新的试用期

## 安全性

- 所有修改的文件都会自动备份
- 使用安全的随机数生成器
- 完整的错误处理和回滚机制
- 详细的操作日志记录

## 系统要求

- Nim 1.6.0 或更高版本
- SQLite3 命令行工具（用于数据库清理）
- 支持的操作系统：Windows、macOS、Linux

## 许可证

MIT License

## 更新日志

### v2.0.0 (2025-06-20)
- 完全模块化重构
- 添加数据库清理功能
- 改进错误处理和日志记录
- 使用 Nimble 项目管理
- 添加测试套件

### v1.0.0 (2025-06-02)
- 初始版本
- 基本的配置文件重置功能
