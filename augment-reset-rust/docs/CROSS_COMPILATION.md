# 🌍 Augment Reset 跨平台编译指南

本文档详细介绍如何为 Augment Reset 项目进行跨平台编译，支持 Windows、Linux、macOS 等多个平台。

## 📋 目录

- [快速开始](#快速开始)
- [支持的平台](#支持的平台)
- [环境准备](#环境准备)
- [编译方法](#编译方法)
- [自动化构建](#自动化构建)
- [故障排除](#故障排除)
- [性能优化](#性能优化)

## 🚀 快速开始

### 使用 Makefile（推荐）

```bash
# 构建所有平台版本
make build-all

# 构建特定平台
make build-windows
make build-linux
make build-macos

# 完整发布流程
make release
```

### 使用脚本

```bash
# Linux/macOS
./scripts/cross-compile.sh --all

# Windows
scripts\cross-compile.bat --all
```

### 使用 Cargo 直接编译

```bash
# 安装目标平台
rustup target add x86_64-pc-windows-gnu

# 编译
cargo build --release --target x86_64-pc-windows-gnu
```

## 🎯 支持的平台

### Windows 平台

| 目标 | 描述 | 推荐度 |
|------|------|--------|
| `x86_64-pc-windows-msvc` | Windows x64 (MSVC) | ⭐⭐⭐⭐⭐ |
| `x86_64-pc-windows-gnu` | Windows x64 (GNU) | ⭐⭐⭐⭐ |
| `i686-pc-windows-msvc` | Windows x86 (MSVC) | ⭐⭐⭐ |
| `i686-pc-windows-gnu` | Windows x86 (GNU) | ⭐⭐⭐ |

### Linux 平台

| 目标 | 描述 | 推荐度 |
|------|------|--------|
| `x86_64-unknown-linux-gnu` | Linux x64 (glibc) | ⭐⭐⭐⭐⭐ |
| `x86_64-unknown-linux-musl` | Linux x64 (musl, 静态链接) | ⭐⭐⭐⭐ |
| `aarch64-unknown-linux-gnu` | Linux ARM64 | ⭐⭐⭐⭐ |
| `armv7-unknown-linux-gnueabihf` | Linux ARMv7 | ⭐⭐⭐ |

### macOS 平台

| 目标 | 描述 | 推荐度 |
|------|------|--------|
| `x86_64-apple-darwin` | macOS Intel | ⭐⭐⭐⭐⭐ |
| `aarch64-apple-darwin` | macOS Apple Silicon | ⭐⭐⭐⭐⭐ |

### 其他平台

| 目标 | 描述 | 推荐度 |
|------|------|--------|
| `x86_64-unknown-freebsd` | FreeBSD x64 | ⭐⭐⭐ |

## 🛠️ 环境准备

### 1. 安装 Rust 工具链

```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 更新到最新版本
rustup update
```

### 2. 安装 Cross 工具（推荐）

```bash
# 安装 cross 工具，提供更好的跨平台编译支持
cargo install cross
```

### 3. 安装目标平台

```bash
# 安装所有支持的目标平台
make install-targets

# 或手动安装特定目标
rustup target add x86_64-pc-windows-gnu
rustup target add x86_64-unknown-linux-musl
rustup target add aarch64-apple-darwin
```

### 4. 平台特定依赖

#### Linux 交叉编译依赖

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gcc-multilib

# ARM64 交叉编译
sudo apt-get install -y gcc-aarch64-linux-gnu

# musl 工具
sudo apt-get install -y musl-tools

# CentOS/RHEL
sudo yum install -y gcc gcc-c++
```

#### Windows 交叉编译依赖

```bash
# 在 Linux 上编译 Windows 程序
sudo apt-get install -y gcc-mingw-w64

# 在 macOS 上编译 Windows 程序
brew install mingw-w64
```

#### macOS 交叉编译依赖

```bash
# 需要 Xcode Command Line Tools
xcode-select --install
```

## 🔨 编译方法

### 方法 1: 使用 Makefile

```bash
# 查看所有可用命令
make help

# 构建信息
make info

# 代码检查
make check

# 运行测试
make test

# 构建本地版本
make build-local

# 构建所有平台
make build-all

# 创建发布包
make package

# 完整发布流程
make release
```

### 方法 2: 使用脚本

#### Linux/macOS

```bash
# 查看帮助
./scripts/cross-compile.sh --help

# 显示支持的目标
./scripts/cross-compile.sh --list

# 编译所有目标
./scripts/cross-compile.sh --all

# 编译特定目标
./scripts/cross-compile.sh x86_64-pc-windows-gnu

# 最小化编译
./scripts/cross-compile.sh --minimal x86_64-unknown-linux-musl
```

#### Windows

```batch
REM 查看帮助
scripts\cross-compile.bat --help

REM 显示支持的目标
scripts\cross-compile.bat --list

REM 编译所有目标
scripts\cross-compile.bat --all

REM 编译特定目标
scripts\cross-compile.bat x86_64-pc-windows-msvc
```

### 方法 3: 直接使用 Cargo

```bash
# 基本编译
cargo build --release --target x86_64-pc-windows-gnu

# 使用完整功能
cargo build --release --target x86_64-pc-windows-gnu --features full

# 最小化编译
cargo build --release --target x86_64-unknown-linux-musl
```

### 方法 4: 使用 Cross

```bash
# 使用 cross 进行跨平台编译
cross build --release --target x86_64-pc-windows-gnu

# 编译并运行测试
cross test --target x86_64-unknown-linux-musl
```

## 🤖 自动化构建

### GitHub Actions

项目包含完整的 GitHub Actions 工作流 (`.github/workflows/cross-platform-build.yml`)，支持：

- 自动代码质量检查
- 多平台并行构建
- 自动创建 GitHub Release
- 生成校验和文件

### 本地 CI 脚本

```bash
# 运行完整的 CI 流程
./scripts/ci-local.sh

# 仅运行测试
./scripts/ci-local.sh test

# 仅运行构建
./scripts/ci-local.sh build
```

## 🐛 故障排除

### 常见问题

#### 1. 链接器错误

```bash
# 错误: linker `x86_64-w64-mingw32-gcc` not found
# 解决: 安装 MinGW 工具链
sudo apt-get install gcc-mingw-w64
```

#### 2. 目标平台未安装

```bash
# 错误: target 'x86_64-pc-windows-gnu' not found
# 解决: 安装目标平台
rustup target add x86_64-pc-windows-gnu
```

#### 3. SQLite 编译错误

```bash
# 错误: SQLite 相关编译错误
# 解决: 确保使用 bundled 特性
cargo build --features bundled
```

#### 4. 权限错误

```bash
# 错误: Permission denied
# 解决: 给脚本添加执行权限
chmod +x scripts/cross-compile.sh
```

### 调试技巧

```bash
# 详细输出
cargo build --verbose --target x86_64-pc-windows-gnu

# 显示链接器命令
cargo build --target x86_64-pc-windows-gnu -vv

# 检查目标平台信息
rustc --print target-list | grep windows
```

## ⚡ 性能优化

### 编译优化

```toml
# Cargo.toml 中的优化设置
[profile.release]
opt-level = "z"          # 优化文件大小
lto = true               # 链接时优化
codegen-units = 1        # 减少代码生成单元
panic = "abort"          # 移除 panic 处理代码
strip = true             # 移除调试符号
```

### 并行编译

```bash
# 设置并行编译任务数
export CARGO_BUILD_JOBS=4

# 使用 sccache 缓存编译结果
cargo install sccache
export RUSTC_WRAPPER=sccache
```

### 缓存优化

```bash
# 清理缓存
cargo clean

# 仅清理特定目标
cargo clean --target x86_64-pc-windows-gnu

# 使用 cargo-cache 管理缓存
cargo install cargo-cache
cargo cache --autoclean
```

## 📊 构建统计

查看构建统计信息：

```bash
# 使用 Makefile
make stats

# 手动查看
find target -name "augment-reset*" -type f -exec ls -lh {} \;
```

## 🔗 相关资源

- [Rust 跨平台编译官方文档](https://rust-lang.github.io/rustup/cross-compilation.html)
- [Cross 工具文档](https://github.com/cross-rs/cross)
- [Cargo 配置文档](https://doc.rust-lang.org/cargo/reference/config.html)
- [Rust 目标平台列表](https://doc.rust-lang.org/nightly/rustc/platform-support.html)

## 📝 注意事项

1. **静态链接**: 项目使用 SQLite 的 bundled 特性，确保生成的二进制文件是自包含的
2. **文件大小**: 发布版本经过优化，文件大小通常在 2-5 MB 之间
3. **兼容性**: 建议在目标平台上测试编译产物的兼容性
4. **安全性**: 发布时会生成 SHA256 校验和，确保文件完整性

## 🤝 贡献

如果您在跨平台编译过程中遇到问题或有改进建议，欢迎：

1. 提交 Issue 报告问题
2. 提交 Pull Request 改进文档或脚本
3. 分享您的编译经验和技巧
