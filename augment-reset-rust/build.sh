#!/bin/bash

# Augment Reset (Rust版本) 构建脚本
# 支持跨平台构建和发布

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="augment-reset"
VERSION=$(grep '^version' Cargo.toml | sed 's/version = "\(.*\)"/\1/')

echo -e "${CYAN}🚀 Augment Reset (Rust版本) 构建脚本${NC}"
echo -e "${BLUE}版本: ${VERSION}${NC}"
echo ""

# 函数：打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装或不在 PATH 中"
        exit 1
    fi
}

# 函数：清理构建产物
clean_build() {
    print_info "清理构建产物..."
    cargo clean
    rm -rf dist/
    print_success "清理完成"
}

# 函数：运行测试
run_tests() {
    print_info "运行测试..."
    cargo test --verbose
    print_success "所有测试通过"
}

# 函数：代码检查
check_code() {
    print_info "运行代码检查..."
    
    # 格式检查
    cargo fmt --check || {
        print_warning "代码格式不符合标准，正在自动格式化..."
        cargo fmt
    }
    
    # Clippy 检查
    cargo clippy -- -D warnings
    
    print_success "代码检查通过"
}

# 函数：构建单个目标
build_target() {
    local target=$1
    local output_name=$2
    
    print_info "构建目标: ${target}"
    
    # 检查目标是否已安装
    if ! rustup target list --installed | grep -q "${target}"; then
        print_info "安装目标 ${target}..."
        rustup target add ${target}
    fi
    
    # 构建
    cargo build --release --target ${target}
    
    # 创建输出目录
    mkdir -p dist/${target}
    
    # 复制可执行文件
    if [[ "${target}" == *"windows"* ]]; then
        cp target/${target}/release/${PROJECT_NAME}.exe dist/${target}/${output_name}.exe
    else
        cp target/${target}/release/${PROJECT_NAME} dist/${target}/${output_name}
    fi
    
    print_success "构建完成: ${target}"
}

# 函数：跨平台构建
build_cross_platform() {
    print_info "开始跨平台构建..."
    
    # 创建 dist 目录
    mkdir -p dist
    
    # 构建目标列表
    declare -A targets=(
        ["x86_64-pc-windows-gnu"]="augment-reset-windows-x64"
        ["x86_64-unknown-linux-gnu"]="augment-reset-linux-x64"
        ["x86_64-apple-darwin"]="augment-reset-macos-x64"
        ["aarch64-apple-darwin"]="augment-reset-macos-arm64"
    )
    
    # 构建每个目标
    for target in "${!targets[@]}"; do
        output_name="${targets[$target]}"
        
        # 检查是否可以构建该目标
        if [[ "$OSTYPE" == "darwin"* ]] || [[ "${target}" != *"apple"* ]]; then
            build_target "${target}" "${output_name}"
        else
            print_warning "跳过 ${target}（当前平台不支持）"
        fi
    done
    
    print_success "跨平台构建完成"
}

# 函数：本地构建
build_local() {
    print_info "构建本地版本..."
    cargo build --release
    
    # 创建本地输出目录
    mkdir -p dist/local
    
    # 复制可执行文件
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        cp target/release/${PROJECT_NAME}.exe dist/local/
    else
        cp target/release/${PROJECT_NAME} dist/local/
    fi
    
    print_success "本地构建完成"
}

# 函数：创建发布包
create_release_packages() {
    print_info "创建发布包..."
    
    cd dist
    
    for dir in */; do
        if [[ "${dir}" != "local/" ]]; then
            target_name=${dir%/}
            print_info "打包 ${target_name}..."
            
            if [[ "${target_name}" == *"windows"* ]]; then
                zip -r "${target_name}-v${VERSION}.zip" "${target_name}/"
            else
                tar -czf "${target_name}-v${VERSION}.tar.gz" "${target_name}/"
            fi
        fi
    done
    
    cd ..
    print_success "发布包创建完成"
}

# 函数：生成校验和
generate_checksums() {
    print_info "生成校验和..."
    
    cd dist
    
    # 生成 SHA256 校验和
    if command -v sha256sum &> /dev/null; then
        sha256sum *.zip *.tar.gz > checksums.sha256 2>/dev/null || true
    elif command -v shasum &> /dev/null; then
        shasum -a 256 *.zip *.tar.gz > checksums.sha256 2>/dev/null || true
    fi
    
    cd ..
    print_success "校验和生成完成"
}

# 函数：显示构建信息
show_build_info() {
    print_info "构建信息:"
    echo "  项目名称: ${PROJECT_NAME}"
    echo "  版本: ${VERSION}"
    echo "  Rust 版本: $(rustc --version)"
    echo "  Cargo 版本: $(cargo --version)"
    echo "  目标平台: $(rustc -vV | grep host | cut -d' ' -f2)"
    echo ""
}

# 函数：显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  clean       清理构建产物"
    echo "  test        运行测试"
    echo "  check       代码检查"
    echo "  local       构建本地版本"
    echo "  cross       跨平台构建"
    echo "  package     创建发布包"
    echo "  release     完整发布流程 (check + test + cross + package)"
    echo "  help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 local    # 构建本地版本"
    echo "  $0 release  # 完整发布流程"
}

# 主函数
main() {
    # 检查必要的命令
    check_command "cargo"
    check_command "rustc"
    
    # 显示构建信息
    show_build_info
    
    # 解析命令行参数
    case "${1:-local}" in
        "clean")
            clean_build
            ;;
        "test")
            run_tests
            ;;
        "check")
            check_code
            ;;
        "local")
            check_code
            run_tests
            build_local
            ;;
        "cross")
            check_code
            run_tests
            build_cross_platform
            ;;
        "package")
            create_release_packages
            generate_checksums
            ;;
        "release")
            check_code
            run_tests
            build_cross_platform
            create_release_packages
            generate_checksums
            print_success "发布构建完成！"
            echo ""
            print_info "发布文件位于 dist/ 目录中"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
