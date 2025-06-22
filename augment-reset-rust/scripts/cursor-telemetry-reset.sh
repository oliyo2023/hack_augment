#!/bin/bash

# Cursor 编辑器遥测和 machineId 重置脚本 (Bash 版本)
# 用于修改 Cursor 编辑器的遥测设置和 machineId

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 参数解析
DRY_RUN=false
VERBOSE=false
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 显示帮助信息
if [[ "$SHOW_HELP" == "true" ]]; then
    echo -e "${CYAN}Cursor 编辑器遥测和 machineId 重置工具${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}用法: $0 [选项]${NC}"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  --dry-run    仅显示将要修改的文件，不实际修改"
    echo "  --verbose    显示详细输出"
    echo "  --help       显示此帮助信息"
    echo ""
    echo -e "${YELLOW}功能:${NC}"
    echo "  1. 查找 Cursor 编辑器的配置文件"
    echo "  2. 修改所有遥测相关的 ID"
    echo "  3. 查找并修改 machineId 文件"
    echo "  4. 将 machineId 文件设置为只读"
    echo ""
    exit 0
fi

# 输出函数
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

# 生成随机 ID
generate_random_id() {
    local length=${1:-32}
    cat /dev/urandom | tr -dc 'a-z0-9' | fold -w $length | head -n 1
}

# 生成 UUID
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # 手动生成 UUID 格式
        printf '%08x-%04x-%04x-%04x-%012x\n' \
            $RANDOM$RANDOM \
            $RANDOM \
            $RANDOM \
            $RANDOM \
            $RANDOM$RANDOM$RANDOM
    fi
}

# 获取 Cursor 配置目录
get_cursor_config_paths() {
    local paths=()
    
    case "$(uname)" in
        "Darwin")
            # macOS
            if [[ -n "$HOME" ]]; then
                local app_support="$HOME/Library/Application Support/Cursor"
                [[ -d "$app_support" ]] && paths+=("$app_support")
            fi
            ;;
        "Linux")
            # Linux
            if [[ -n "$HOME" ]]; then
                local config_dir="$HOME/.config/Cursor"
                [[ -d "$config_dir" ]] && paths+=("$config_dir")
                
                # 其他可能的路径
                local alt_paths=(
                    "$HOME/.cursor"
                    "$HOME/.local/share/Cursor"
                )
                
                for path in "${alt_paths[@]}"; do
                    [[ -d "$path" ]] && paths+=("$path")
                done
            fi
            ;;
        *)
            print_error "不支持的操作系统: $(uname)"
            exit 1
            ;;
    esac
    
    printf '%s\n' "${paths[@]}"
}

# 查找 JSON 文件
find_json_files() {
    local base_path="$1"
    
    if [[ ! -d "$base_path" ]]; then
        return
    fi
    
    find "$base_path" -name "*.json" -type f 2>/dev/null || true
}

# 查找 machineId 文件
find_machine_id_files() {
    local base_path="$1"
    
    if [[ ! -d "$base_path" ]]; then
        return
    fi
    
    find "$base_path" -type f \( \
        -iname "*machineid*" -o \
        -iname "*machine-id*" -o \
        -name "machineId" \
    \) 2>/dev/null || true
}

# 修改 JSON 文件中的遥测 ID
modify_telemetry_ids() {
    local json_path="$1"
    local modified=false
    
    if [[ ! -f "$json_path" ]]; then
        return 1
    fi
    
    # 检查是否有 jq 工具
    if ! command -v jq &> /dev/null; then
        print_warning "  需要 jq 工具来处理 JSON 文件，跳过: $json_path"
        return 1
    fi
    
    # 需要修改的字段列表
    local telemetry_fields=(
        "telemetryMachineId"
        "machineId"
        "deviceId"
        "sessionId"
        "userId"
        "installationId"
        "sqmUserId"
        "sqmMachineId"
    )
    
    # 创建临时文件
    local temp_file=$(mktemp)
    cp "$json_path" "$temp_file"
    
    # 修改字段
    for field in "${telemetry_fields[@]}"; do
        if jq -e "has(\"$field\")" "$temp_file" &>/dev/null; then
            local new_id
            if [[ "$field" == *"machine"* ]]; then
                new_id=$(generate_uuid)
            else
                new_id=$(generate_random_id)
            fi
            
            jq ".$field = \"$new_id\"" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
            modified=true
            
            if [[ "$VERBOSE" == "true" ]]; then
                echo "    修改字段: $field -> $new_id"
            fi
        fi
    done
    
    # 递归查找嵌套对象中的字段
    local nested_modified=false
    for field in "${telemetry_fields[@]}"; do
        if jq -e ".. | objects | has(\"$field\")" "$temp_file" &>/dev/null; then
            local new_id
            if [[ "$field" == *"machine"* ]]; then
                new_id=$(generate_uuid)
            else
                new_id=$(generate_random_id)
            fi
            
            jq "walk(if type == \"object\" and has(\"$field\") then .$field = \"$new_id\" else . end)" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
            nested_modified=true
            
            if [[ "$VERBOSE" == "true" ]]; then
                echo "    修改嵌套字段: $field -> $new_id"
            fi
        fi
    done
    
    if [[ "$modified" == "true" || "$nested_modified" == "true" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            print_warning "  [DRY RUN] 将修改: $json_path"
        else
            # 备份原文件
            local backup_path="$json_path.backup"
            cp "$json_path" "$backup_path"
            
            if [[ "$VERBOSE" == "true" ]]; then
                echo "    备份原文件: $backup_path"
            fi
            
            # 写入修改后的内容
            mv "$temp_file" "$json_path"
            print_success "  已修改: $json_path"
        fi
        rm -f "$temp_file"
        return 0
    else
        if [[ "$VERBOSE" == "true" ]]; then
            echo "  跳过: $json_path (无需修改)"
        fi
        rm -f "$temp_file"
        return 1
    fi
}

# 修改 machineId 文件
modify_machine_id_file() {
    local machine_id_path="$1"
    
    if [[ ! -f "$machine_id_path" ]]; then
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "  [DRY RUN] 将修改 machineId: $machine_id_path"
        print_warning "  [DRY RUN] 将设置为只读: $machine_id_path"
        return 0
    fi
    
    # 备份原文件
    local backup_path="$machine_id_path.backup"
    cp "$machine_id_path" "$backup_path"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "    备份原文件: $backup_path"
    fi
    
    # 生成新的 machineId
    local new_machine_id=$(generate_uuid)
    
    # 写入新的 machineId
    echo "$new_machine_id" > "$machine_id_path"
    print_success "  已修改 machineId: $machine_id_path"
    
    # 设置文件为只读
    chmod 444 "$machine_id_path"
    print_success "  🔒 已设置为只读: $machine_id_path"
    
    return 0
}

# 主程序
echo -e "${CYAN}🔧 Cursor 编辑器遥测和 machineId 重置工具${NC}"
echo -e "${CYAN}================================================${NC}"

if [[ "$DRY_RUN" == "true" ]]; then
    print_warning "运行在 DRY RUN 模式 - 不会实际修改文件"
fi

# 检查依赖
if ! command -v jq &> /dev/null; then
    print_warning "建议安装 jq 工具以获得更好的 JSON 处理支持"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  macOS: brew install jq"
    echo "  CentOS/RHEL: sudo yum install jq"
fi

# 初始化计数器
total_json_modified=0
total_machine_ids_modified=0

# 获取 Cursor 配置路径
readarray -t cursor_paths < <(get_cursor_config_paths)

if [[ ${#cursor_paths[@]} -eq 0 ]]; then
    print_error "未找到 Cursor 配置目录"
    exit 1
fi

for cursor_path in "${cursor_paths[@]}"; do
    echo ""
    print_info "处理目录: $cursor_path"
    
    # 查找并修改 JSON 配置文件
    echo ""
    print_info "查找 JSON 配置文件..."
    readarray -t json_files < <(find_json_files "$cursor_path")
    
    if [[ ${#json_files[@]} -eq 0 ]]; then
        echo "  未找到 JSON 文件"
    else
        echo "  找到 ${#json_files[@]} 个 JSON 文件"
        
        for json_file in "${json_files[@]}"; do
            if modify_telemetry_ids "$json_file"; then
                ((total_json_modified++))
            fi
        done
    fi
    
    # 查找并修改 machineId 文件
    echo ""
    print_info "查找 machineId 文件..."
    readarray -t machine_id_files < <(find_machine_id_files "$cursor_path")
    
    if [[ ${#machine_id_files[@]} -eq 0 ]]; then
        echo "  未找到 machineId 文件"
    else
        echo "  找到 ${#machine_id_files[@]} 个 machineId 文件"
        
        for machine_id_file in "${machine_id_files[@]}"; do
            if modify_machine_id_file "$machine_id_file"; then
                ((total_machine_ids_modified++))
            fi
        done
    fi
done

# 显示结果
echo ""
print_success "🎉 处理完成！"
echo -e "${CYAN}================================================${NC}"
echo -e "${YELLOW}修改的 JSON 文件: $total_json_modified${NC}"
echo -e "${YELLOW}修改的 machineId 文件: $total_machine_ids_modified${NC}"

if [[ $total_json_modified -gt 0 || $total_machine_ids_modified -gt 0 ]] && [[ "$DRY_RUN" != "true" ]]; then
    echo ""
    echo -e "${CYAN}💡 建议:${NC}"
    echo "1. 重启 Cursor 编辑器以使更改生效"
    echo "2. 检查备份文件是否正确创建"
    echo "3. 如有问题，可以使用备份文件恢复"
    echo "4. 清除 Cursor 缓存目录以确保完全重置"
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    print_warning "这是 DRY RUN 模式的结果。要实际修改文件，请不使用 --dry-run 参数重新运行脚本。"
fi
