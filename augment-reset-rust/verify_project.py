#!/usr/bin/env python3
"""
Augment Reset (Rust版本) 项目结构验证脚本
验证项目文件是否完整
"""

import os
import sys
from pathlib import Path

def check_file_exists(file_path, description):
    """检查文件是否存在"""
    if os.path.exists(file_path):
        print(f"✅ {description}: {file_path}")
        return True
    else:
        print(f"❌ {description}: {file_path} (缺失)")
        return False

def check_directory_exists(dir_path, description):
    """检查目录是否存在"""
    if os.path.isdir(dir_path):
        print(f"✅ {description}: {dir_path}")
        return True
    else:
        print(f"❌ {description}: {dir_path} (缺失)")
        return False

def main():
    print("🔍 Augment Reset (Rust版本) 项目结构验证")
    print("=" * 50)
    
    project_root = Path(__file__).parent
    os.chdir(project_root)
    
    all_good = True
    
    # 检查核心文件
    print("\n📁 核心文件:")
    core_files = [
        ("Cargo.toml", "项目配置文件"),
        ("README.md", "项目文档"),
        ("build.sh", "Linux/macOS 构建脚本"),
        ("build.bat", "Windows 构建脚本"),
    ]
    
    for file_path, description in core_files:
        if not check_file_exists(file_path, description):
            all_good = False
    
    # 检查源码目录
    print("\n📁 源码目录:")
    src_dirs = [
        ("src", "源码根目录"),
        ("src/cli", "命令行界面"),
        ("src/core", "核心模块"),
        ("src/database", "数据库模块"),
        ("src/filesystem", "文件系统模块"),
        ("src/utils", "工具模块"),
        ("tests", "测试目录"),
    ]
    
    for dir_path, description in src_dirs:
        if not check_directory_exists(dir_path, description):
            all_good = False
    
    # 检查源码文件
    print("\n📄 源码文件:")
    src_files = [
        ("src/main.rs", "主程序入口"),
        ("src/lib.rs", "库入口"),
        ("src/core/mod.rs", "核心模块入口"),
        ("src/core/types.rs", "类型定义"),
        ("src/core/error.rs", "错误处理"),
        ("src/cli/mod.rs", "CLI模块入口"),
        ("src/cli/args.rs", "参数解析"),
        ("src/cli/interactive.rs", "交互式菜单"),
        ("src/database/mod.rs", "数据库模块入口"),
        ("src/database/manager.rs", "数据库管理器"),
        ("src/filesystem/mod.rs", "文件系统模块入口"),
        ("src/filesystem/paths.rs", "路径管理"),
        ("src/filesystem/operations.rs", "文件操作"),
        ("src/utils/mod.rs", "工具模块入口"),
        ("src/utils/banner.rs", "横幅显示"),
        ("tests/integration_tests.rs", "集成测试"),
    ]
    
    for file_path, description in src_files:
        if not check_file_exists(file_path, description):
            all_good = False
    
    # 检查文件内容
    print("\n📝 文件内容检查:")
    
    # 检查 Cargo.toml
    try:
        with open("Cargo.toml", "r", encoding="utf-8") as f:
            cargo_content = f.read()
            if "rusqlite" in cargo_content and "bundled" in cargo_content:
                print("✅ Cargo.toml: SQLite bundled 特性已配置")
            else:
                print("❌ Cargo.toml: SQLite bundled 特性未正确配置")
                all_good = False
                
            if "clap" in cargo_content and "tokio" in cargo_content:
                print("✅ Cargo.toml: 主要依赖已配置")
            else:
                print("❌ Cargo.toml: 主要依赖缺失")
                all_good = False
    except Exception as e:
        print(f"❌ 无法读取 Cargo.toml: {e}")
        all_good = False
    
    # 检查 main.rs
    try:
        with open("src/main.rs", "r", encoding="utf-8") as f:
            main_content = f.read()
            if "tokio::main" in main_content:
                print("✅ main.rs: 异步主函数已配置")
            else:
                print("❌ main.rs: 异步主函数未配置")
                all_good = False
                
            if "augment_reset::" in main_content:
                print("✅ main.rs: 库导入已配置")
            else:
                print("❌ main.rs: 库导入未配置")
                all_good = False
    except Exception as e:
        print(f"❌ 无法读取 main.rs: {e}")
        all_good = False
    
    # 统计代码行数
    print("\n📊 代码统计:")
    total_lines = 0
    rust_files = []
    
    for root, dirs, files in os.walk("src"):
        for file in files:
            if file.endswith(".rs"):
                file_path = os.path.join(root, file)
                rust_files.append(file_path)
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        lines = len(f.readlines())
                        total_lines += lines
                        print(f"  {file_path}: {lines} 行")
                except Exception as e:
                    print(f"  {file_path}: 无法读取 ({e})")
    
    print(f"\n📈 总计: {len(rust_files)} 个 Rust 文件，{total_lines} 行代码")
    
    # 最终结果
    print("\n" + "=" * 50)
    if all_good:
        print("🎉 项目结构验证通过！")
        print("\n📋 下一步:")
        print("1. 安装 Rust: https://rustup.rs/")
        print("2. 运行 'cargo check' 检查代码")
        print("3. 运行 'cargo test' 执行测试")
        print("4. 运行 'cargo build --release' 构建发布版本")
        return 0
    else:
        print("❌ 项目结构验证失败！")
        print("请检查缺失的文件和目录。")
        return 1

if __name__ == "__main__":
    sys.exit(main())
