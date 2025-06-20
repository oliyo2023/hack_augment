# 更新日志

所有重要的项目更改都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [2.2.0] - 2025-06-20

### 新增
- 🎯 **选择性清理功能**: 支持单独清理 VS Code、Cursor 或 JetBrains IDE
- 🖥️ **命令行参数支持**: `--vscode`、`--cursor`、`--jetbrains`、`--all` 选项
- 🎮 **交互式模式**: `-i` 参数启用交互式目标选择
- 📝 **详细帮助信息**: `--help` 显示完整的使用说明和示例
- 🔧 **高级选项**: `--no-backup`、`--verbose` 等高级功能
- 📦 **新增 cli.nim 模块**: 专门处理命令行接口和用户交互

### 改进
- 🎯 **智能进程检测**: 根据选择的目标只检测相关的编辑器/IDE
- 📊 **增强统计信息**: 显示各个组件的具体清理状态
- 🔄 **优化清理流程**: 跳过不相关的清理步骤，提高效率
- 💬 **改进用户体验**: 更清晰的输出信息和操作提示
- 🧪 **扩展测试覆盖**: 新增 CLI 模块的完整测试

### 技术细节
- 新增 `CleanTarget` 枚举类型 (ctAll, ctVSCode, ctCursor, ctJetBrains)
- 新增 `CleanOptions` 配置结构
- 扩展 `ResetStats` 包含各组件清理状态
- 支持命令行参数解析和验证
- 交互式用户界面实现

### 使用示例
```bash
# 清理所有编辑器/IDE (默认)
augment_reset

# 仅清理 VS Code
augment_reset --vscode

# 仅清理 JetBrains IDE
augment_reset --jetbrains

# 交互式选择
augment_reset -i

# 详细模式清理 Cursor
augment_reset --cursor --verbose
```

## [2.1.0] - 2025-06-20

### 新增
- 🔧 **JetBrains IDE 完整支持**: 支持 IntelliJ IDEA、PyCharm、WebStorm、PhpStorm、RubyMine、CLion、DataGrip、GoLand、Rider、Android Studio
- 🗂️ **Windows 注册表清理**: 自动清理 `HKEY_CURRENT_USER\Software\JavaSoft` 和 `HKEY_CURRENT_USER\Software\JetBrains`
- 📁 **JetBrains 配置目录清理**: 删除 `.jetbrains` 和 `.augment` 目录
- 🔍 **JetBrains 进程检测**: 自动检测和关闭正在运行的 JetBrains IDE
- 📦 **新增 jetbrains.nim 模块**: 专门处理 JetBrains IDE 相关操作
- 🧪 **JetBrains 测试套件**: 新增 JetBrains 功能的单元测试

### 改进
- 🎯 **重置流程增强**: 集成 JetBrains 清理到主重置流程
- 📊 **统计信息扩展**: 重置统计中包含 JetBrains 清理状态
- 💬 **用户提示优化**: 更新重要提示，包含 JetBrains IDE 相关说明
- 📝 **文档更新**: 完整更新 README 和项目文档

### 技术细节
- 新增 `JetBrainsCleanResult` 类型定义
- 新增 `JetBrainsError` 和 `RegistryError` 异常类型
- 扩展 `ResetStats` 包含 `jetbrainsCleared` 字段
- 支持跨平台的 JetBrains 配置路径检测
- Windows 注册表操作使用 `reg delete` 命令

## [2.0.0] - 2025-06-20

### 新增
- 🏗️ **完全模块化重构**: 将单个 76,834 行文件拆分为 7 个专门模块
- 📦 **Nimble 项目管理**: 标准的 Nim 项目结构和构建系统
- 🗄️ **数据库清理功能**: 从 Python 版本移植的 SQLite 数据库清理
- 🧪 **测试套件**: 完整的单元测试覆盖
- 📚 **文档系统**: 详细的 README 和代码注释
- 🔧 **构建脚本**: Windows 和 Linux/macOS 构建脚本
- 📋 **版本管理**: 版本信息模块和命令行参数支持
- 🎯 **使用示例**: 展示各模块功能的示例程序

### 改进
- ⚡ **性能优化**: 模块化设计提高编译速度
- 🛡️ **错误处理**: 更完善的异常处理和错误恢复
- 📝 **日志系统**: 更详细的操作日志和调试信息
- 🔒 **安全性**: 改进的备份机制和数据保护
- 🎨 **代码质量**: 清晰的模块分离和职责划分

### 修复
- 🐛 修复了原版本中的一些潜在内存泄漏
- 🔧 改进了跨平台兼容性
- 📁 优化了路径处理逻辑

### 模块结构
- `types.nim`: 类型定义和常量 (120 行)
- `system.nim`: 系统操作和进程管理 (250 行)
- `paths.nim`: 路径管理和文件发现 (200 行)
- `idgen.nim`: 安全ID生成 (80 行)
- `config.nim`: 配置文件生成 (80 行)
- `database.nim`: SQLite 数据库操作 (100 行)
- `reset.nim`: 主要重置逻辑 (180 行)
- `version.nim`: 版本信息管理 (30 行)

### 技术债务
- 移除了未使用的导入和变量
- 统一了代码风格和命名约定
- 改进了模块间的依赖关系

## [1.0.0] - 2025-06-02

### 新增
- 🎉 **初始版本**: 基本的 Augment 试用期重置功能
- 🖥️ **跨平台支持**: Windows、macOS、Linux
- 🔄 **配置重置**: 生成新的随机设备 ID 和用户信息
- 💾 **备份功能**: 自动备份现有配置文件
- 🎯 **编辑器管理**: 自动检测和关闭 VS Code/Cursor
- 📊 **统计报告**: 详细的操作结果统计

### 已知问题
- 单文件结构导致维护困难
- 缺少数据库清理功能
- 测试覆盖不足

---

## 版本说明

### 语义化版本格式: MAJOR.MINOR.PATCH

- **MAJOR**: 不兼容的 API 更改
- **MINOR**: 向后兼容的功能新增
- **PATCH**: 向后兼容的问题修复

### 更改类型

- `新增`: 新功能
- `改进`: 现有功能的改进
- `修复`: 错误修复
- `移除`: 移除的功能
- `安全`: 安全相关的修复
