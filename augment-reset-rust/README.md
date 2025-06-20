# 🚀 Augment Reset (Rust版本)

**Augment Free Trail** - 高性能跨平台 Augment IDE 清理工具

[![Rust](https://img.shields.io/badge/rust-1.75+-orange.svg)](https://www.rust-lang.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](https://github.com/oliyo/augment-reset-rust)

## ✨ 特性

- 🚀 **高性能**: 使用 Rust 编写，零成本抽象，接近 C 的性能
- 🔒 **内存安全**: Rust 的所有权系统保证内存安全，无空指针异常
- 🌍 **跨平台**: 支持 Windows、macOS、Linux
- 📦 **零依赖**: 静态编译，无需外部运行时或 DLL 文件
- 🗄️ **内置 SQLite**: 使用 rusqlite 的 bundled 特性，无需系统 SQLite
- 🔄 **并发处理**: 支持并发清理多个数据库，提高效率
- 💾 **自动备份**: 清理前自动创建备份，安全可靠
- 🎨 **友好界面**: 彩色输出、进度条和交互式菜单
- 🛡️ **错误处理**: 完善的错误处理和恢复机制

## 🎯 支持的编辑器

- **VS Code** - Visual Studio Code
- **Cursor** - AI-powered code editor
- **Void** - Modern code editor
- **JetBrains IDE 系列** - IntelliJ IDEA, PyCharm, WebStorm 等

## 📦 安装

### 从源码编译

```bash
# 克隆仓库
git clone https://github.com/oliyo/augment-reset-rust.git
cd augment-reset-rust

# 安装依赖
cargo build --release

# 运行程序
./target/release/augment-reset
```

### 预编译二进制文件

从 [Releases](https://github.com/oliyo/augment-reset-rust/releases) 页面下载适合您平台的预编译二进制文件。

## 🚀 使用方法

### 交互模式（推荐）

```bash
# 启动交互式菜单
augment-reset
```

### 命令行模式

```bash
# 清理所有编辑器
augment-reset clean

# 仅清理特定编辑器
augment-reset --vscode --cursor

# 强制清理，不询问确认
augment-reset clean --force

# 预览模式，查看将要清理的内容
augment-reset clean --dry-run

# 禁用备份
augment-reset --no-backup clean

# 详细输出
augment-reset -v clean
```

### 其他功能

```bash
# 显示版本信息
augment-reset version

# 显示配置信息
augment-reset config

# 显示统计信息
augment-reset stats

# 清理过期备份文件（30天前）
augment-reset clean-backups --days 30
```

## 📊 使用示例

### 基本清理

```bash
$ augment-reset

╔══════════════════════════════════════════════════════════════════════════════╗
║                          🚀 Augment Free Trail 🚀                          ║
║                        Augment IDE 清理工具 (Rust版本)                       ║
║                              版本: v2.2.0                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

🎯 Augment Reset - 交互模式

? 请选择要清理的编辑器 › 
  ✓ VS Code
  ✓ Cursor
  ✓ Void
    JetBrains IDE 系列

? 是否创建备份文件？ › Yes
? 确认开始清理？ › Yes

🚀 开始清理 Augment 相关数据...

✅ VS Code (/Users/user/Library/Application Support/Code/User/globalStorage/state.vscdb) - 删除了 15 条记录
   💾 备份: /Users/user/Library/Application Support/Code/User/globalStorage/state.vscdb.20241220_143022_123.bak
✅ Cursor (/Users/user/Library/Application Support/Cursor/User/globalStorage/state.vscdb) - 删除了 8 条记录
   💾 备份: /Users/user/Library/Application Support/Cursor/User/globalStorage/state.vscdb.20241220_143023_456.bak

🎉 清理完成！成功处理 2/2 个数据库，共删除 23 条记录。
```

### 命令行清理

```bash
$ augment-reset --vscode clean --force

🚀 开始清理 Augment 相关数据...

✅ VS Code (/home/user/.config/Code/User/globalStorage/state.vscdb) - 删除了 12 条记录

🎉 清理完成！成功处理 1/1 个数据库，共删除 12 条记录。
```

## 🏗️ 项目结构

```
augment-reset-rust/
├── src/
│   ├── main.rs              # 主程序入口
│   ├── lib.rs               # 库入口
│   ├── cli/                 # 命令行界面
│   │   ├── args.rs          # 参数解析
│   │   └── interactive.rs   # 交互式菜单
│   ├── core/                # 核心类型和错误处理
│   │   ├── types.rs         # 数据类型定义
│   │   └── error.rs         # 错误类型
│   ├── database/            # 数据库操作
│   │   └── manager.rs       # 数据库管理器
│   ├── filesystem/          # 文件系统操作
│   │   ├── paths.rs         # 路径管理
│   │   └── operations.rs    # 文件操作
│   └── utils/               # 工具函数
│       └── banner.rs        # 横幅显示
├── tests/                   # 集成测试
├── Cargo.toml              # 项目配置
└── README.md               # 项目文档
```

## 🔧 开发

### 环境要求

- Rust 1.75+
- Cargo

### 开发命令

```bash
# 运行测试
cargo test

# 运行集成测试
cargo test --test integration_tests

# 检查代码
cargo check

# 格式化代码
cargo fmt

# 代码检查
cargo clippy

# 生成文档
cargo doc --open

# 性能分析构建
cargo build --release
```

### 添加新的编辑器支持

1. 在 `src/core/types.rs` 中添加新的编辑器类型
2. 在 `src/filesystem/paths.rs` 中添加路径检测逻辑
3. 更新命令行参数和交互式菜单
4. 添加相应的测试

## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [rusqlite](https://github.com/rusqlite/rusqlite) - SQLite 绑定
- [clap](https://github.com/clap-rs/clap) - 命令行参数解析
- [tokio](https://github.com/tokio-rs/tokio) - 异步运行时
- [dialoguer](https://github.com/console-rs/dialoguer) - 交互式菜单
- [colored](https://github.com/colored-rs/colored) - 彩色输出

## 📞 联系我们

- **公众号**: 趣惠赚
- **网站**: https://www.oliyo.com
- **GitHub**: https://github.com/oliyo/augment-reset-rust

---

**Augment Free Trail** - 让您的开发环境更加清洁！ 🚀
