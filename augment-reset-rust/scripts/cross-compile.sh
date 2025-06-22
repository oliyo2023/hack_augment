#!/bin/bash

# Augment Reset 跨平台编译脚本
# 支持多种目标平台和编译选项

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目信息
PROJECT_NAME="augment-reset"
VERSION=$(grep '^version' Cargo.toml | sed 's/version = "\(.*\)"/\1/')
BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${CYAN}🌍 Augment Reset 跨平台编译工具${NC}"
echo -e "${BLUE}版本: ${VERSION} | 构建时间: ${BUILD_DATE}${NC}"
echo ""

# 支持的目标平台
declare -A TARGETS=(
    # Windows 目标
    ["x86_64-pc-windows-gnu"]="Windows x64 (GNU)"
    ["x86_64-pc-windows-msvc"]="Windows x64 (MSVC)"
    ["i686-pc-windows-gnu"]="Windows x86 (GNU)"
    
    # Linux 目标
    ["x86_64-unknown-linux-gnu"]="Linux x64 (glibc)"
    ["x86_64-unknown-linux-musl"]="Linux x64 (musl)"
    ["aarch64-unknown-linux-gnu"]="Linux ARM64"
    ["armv7-unknown-linux-gnueabihf"]="Linux ARMv7"
    
    # macOS 目标
    ["x86_64-apple-darwin"]="macOS Intel"
    ["aarch64-apple-darwin"]="macOS Apple Silicon"
    
    # FreeBSD 目标
    ["x86_64-unknown-freebsd"]="FreeBSD x64"
)

# 函数：打印消息
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 函数：检查依赖
check_dependencies() {
    print_info "检查构建依赖..."
    
    # 检查 Rust 工具链
    if ! command -v cargo &> /dev/null; then
        print_error "Cargo 未安装"
        exit 1
    fi
    
    if ! command -v rustc &> /dev/null; then
        print_error "Rust 编译器未安装"
        exit 1
    fi
    
    # 检查 cross 工具（推荐用于跨平台编译）
    if command -v cross &> /dev/null; then
        print_success "发现 cross 工具，将使用它进行跨平台编译"
        USE_CROSS=true
    else
        print_warning "未发现 cross 工具，使用 cargo 进行编译"
        print_info "建议安装 cross: cargo install cross"
        USE_CROSS=false
    fi
    
    print_success "依赖检查完成"
}

# 函数：安装目标
install_target() {
    local target=$1
    
    if ! rustup target list --installed | grep -q "^${target}$"; then
        print_info "安装目标: ${target}"
        rustup target add "${target}"
    fi
}

# 函数：编译单个目标
compile_target() {
    local target=$1
    local description="${TARGETS[$target]}"
    local feature_flag=${2:-"--features full"}
    
    print_info "编译目标: ${target} (${description})"
    
    # 安装目标
    install_target "${target}"
    
    # 创建输出目录
    local output_dir="dist/${target}"
    mkdir -p "${output_dir}"
    
    # 选择编译工具
    local compile_cmd
    if [[ "${USE_CROSS}" == "true" ]]; then
        compile_cmd="cross build --release --target ${target} ${feature_flag}"
    else
        compile_cmd="cargo build --release --target ${target} ${feature_flag}"
    fi
    
    # 执行编译
    if eval "${compile_cmd}"; then
        # 复制可执行文件
        local exe_name="${PROJECT_NAME}"
        if [[ "${target}" == *"windows"* ]]; then
            exe_name="${PROJECT_NAME}.exe"
        fi
        
        local src_path="target/${target}/release/${exe_name}"
        local dst_path="${output_dir}/${exe_name}"
        
        if [[ -f "${src_path}" ]]; then
            cp "${src_path}" "${dst_path}"
            
            # 获取文件大小
            local file_size
            if [[ "$OSTYPE" == "darwin"* ]]; then
                file_size=$(stat -f%z "${dst_path}")
            else
                file_size=$(stat -c%s "${dst_path}")
            fi
            
            # 转换为人类可读格式
            local human_size
            if (( file_size > 1048576 )); then
                human_size="$(( file_size / 1048576 )) MB"
            elif (( file_size > 1024 )); then
                human_size="$(( file_size / 1024 )) KB"
            else
                human_size="${file_size} B"
            fi
            
            print_success "编译完成: ${target} (${human_size})"
            return 0
        else
            print_error "编译产物未找到: ${src_path}"
            return 1
        fi
    else
        print_error "编译失败: ${target}"
        return 1
    fi
}

# 函数：编译所有目标
compile_all_targets() {
    local feature_flag=${1:-"--features full"}
    local failed_targets=()
    local success_count=0
    
    print_info "开始编译所有支持的目标..."
    
    for target in "${!TARGETS[@]}"; do
        if compile_target "${target}" "${feature_flag}"; then
            ((success_count++))
        else
            failed_targets+=("${target}")
        fi
        echo ""
    done
    
    # 显示编译结果
    print_info "编译结果汇总:"
    echo "  成功: ${success_count}/${#TARGETS[@]}"
    
    if [[ ${#failed_targets[@]} -gt 0 ]]; then
        echo "  失败的目标:"
        for target in "${failed_targets[@]}"; do
            echo "    - ${target} (${TARGETS[$target]})"
        done
    fi
}

# 函数：编译特定目标列表
compile_selected_targets() {
    local targets=("$@")
    local failed_targets=()
    local success_count=0
    
    print_info "编译选定的目标..."
    
    for target in "${targets[@]}"; do
        if [[ -n "${TARGETS[$target]}" ]]; then
            if compile_target "${target}"; then
                ((success_count++))
            else
                failed_targets+=("${target}")
            fi
        else
            print_error "不支持的目标: ${target}"
            failed_targets+=("${target}")
        fi
        echo ""
    done
    
    print_info "编译结果: 成功 ${success_count}/${#targets[@]}"
}

# 函数：显示支持的目标
show_targets() {
    print_info "支持的编译目标:"
    echo ""
    
    echo "Windows:"
    for target in "${!TARGETS[@]}"; do
        if [[ "${target}" == *"windows"* ]]; then
            echo "  ${target} - ${TARGETS[$target]}"
        fi
    done
    
    echo ""
    echo "Linux:"
    for target in "${!TARGETS[@]}"; do
        if [[ "${target}" == *"linux"* ]]; then
            echo "  ${target} - ${TARGETS[$target]}"
        fi
    done
    
    echo ""
    echo "macOS:"
    for target in "${!TARGETS[@]}"; do
        if [[ "${target}" == *"apple"* ]]; then
            echo "  ${target} - ${TARGETS[$target]}"
        fi
    done
    
    echo ""
    echo "其他:"
    for target in "${!TARGETS[@]}"; do
        if [[ "${target}" != *"windows"* && "${target}" != *"linux"* && "${target}" != *"apple"* ]]; then
            echo "  ${target} - ${TARGETS[$target]}"
        fi
    done
}

# 函数：显示帮助
show_help() {
    echo "用法: $0 [选项] [目标...]"
    echo ""
    echo "选项:"
    echo "  --all           编译所有支持的目标"
    echo "  --minimal       使用最小功能集编译"
    echo "  --list          显示所有支持的目标"
    echo "  --help          显示此帮助信息"
    echo ""
    echo "目标:"
    echo "  可以指定一个或多个目标进行编译"
    echo "  如果不指定目标，将编译当前平台的目标"
    echo ""
    echo "示例:"
    echo "  $0 --all                                    # 编译所有目标"
    echo "  $0 x86_64-pc-windows-gnu                   # 编译 Windows x64"
    echo "  $0 x86_64-unknown-linux-gnu aarch64-apple-darwin  # 编译多个目标"
    echo "  $0 --minimal x86_64-pc-windows-gnu         # 使用最小功能集编译"
}

# 主函数
main() {
    # 检查依赖
    check_dependencies
    
    # 解析命令行参数
    local compile_all=false
    local feature_flag="--features full"
    local targets=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                compile_all=true
                shift
                ;;
            --minimal)
                feature_flag=""
                shift
                ;;
            --list)
                show_targets
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                targets+=("$1")
                shift
                ;;
        esac
    done
    
    # 创建输出目录
    mkdir -p dist
    
    # 执行编译
    if [[ "${compile_all}" == "true" ]]; then
        compile_all_targets "${feature_flag}"
    elif [[ ${#targets[@]} -gt 0 ]]; then
        compile_selected_targets "${targets[@]}"
    else
        # 默认编译当前平台
        local current_target
        current_target=$(rustc -vV | grep host | cut -d' ' -f2)
        print_info "编译当前平台目标: ${current_target}"
        compile_target "${current_target}" "${feature_flag}"
    fi
    
    print_success "跨平台编译完成！"
    print_info "编译产物位于 dist/ 目录中"
}

# 运行主函数
main "$@"
