# Augment Reset 跨平台编译 Makefile
# 支持多种目标平台和构建选项

# 项目配置
PROJECT_NAME := augment-reset
VERSION := $(shell grep '^version' Cargo.toml | sed 's/version = "\(.*\)"/\1/')
BUILD_DATE := $(shell date '+%Y-%m-%d %H:%M:%S')

# 颜色定义
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
BLUE := \033[34m
NC := \033[0m

# 构建目标
WINDOWS_TARGETS := x86_64-pc-windows-gnu x86_64-pc-windows-msvc i686-pc-windows-gnu
LINUX_TARGETS := x86_64-unknown-linux-gnu x86_64-unknown-linux-musl aarch64-unknown-linux-gnu
MACOS_TARGETS := x86_64-apple-darwin aarch64-apple-darwin
ALL_TARGETS := $(WINDOWS_TARGETS) $(LINUX_TARGETS) $(MACOS_TARGETS)

# 默认目标
.DEFAULT_GOAL := help

# 检查工具是否存在
HAS_CROSS := $(shell command -v cross 2> /dev/null)
HAS_CARGO := $(shell command -v cargo 2> /dev/null)
HAS_RUSTC := $(shell command -v rustc 2> /dev/null)

# 选择构建工具
ifdef HAS_CROSS
    BUILD_CMD := cross
else
    BUILD_CMD := cargo
endif

.PHONY: help info check test clean build-local build-all build-windows build-linux build-macos package install-deps install-targets

## 显示帮助信息
help:
	@echo "$(CYAN)🚀 Augment Reset 跨平台编译工具$(NC)"
	@echo "$(BLUE)版本: $(VERSION) | 构建时间: $(BUILD_DATE)$(NC)"
	@echo ""
	@echo "$(YELLOW)可用命令:$(NC)"
	@echo "  $(GREEN)help$(NC)           显示此帮助信息"
	@echo "  $(GREEN)info$(NC)           显示构建环境信息"
	@echo "  $(GREEN)check$(NC)          代码检查和格式化"
	@echo "  $(GREEN)test$(NC)           运行测试"
	@echo "  $(GREEN)clean$(NC)          清理构建产物"
	@echo ""
	@echo "$(YELLOW)构建命令:$(NC)"
	@echo "  $(GREEN)build-local$(NC)    构建本地版本"
	@echo "  $(GREEN)build-all$(NC)      构建所有平台版本"
	@echo "  $(GREEN)build-windows$(NC)  构建 Windows 版本"
	@echo "  $(GREEN)build-linux$(NC)    构建 Linux 版本"
	@echo "  $(GREEN)build-macos$(NC)    构建 macOS 版本"
	@echo ""
	@echo "$(YELLOW)发布命令:$(NC)"
	@echo "  $(GREEN)package$(NC)        创建发布包"
	@echo "  $(GREEN)release$(NC)        完整发布流程"
	@echo ""
	@echo "$(YELLOW)工具命令:$(NC)"
	@echo "  $(GREEN)install-deps$(NC)   安装构建依赖"
	@echo "  $(GREEN)install-targets$(NC) 安装所有目标平台"
	@echo ""
	@echo "$(YELLOW)示例:$(NC)"
	@echo "  make build-local     # 构建本地版本"
	@echo "  make build-all       # 构建所有平台版本"
	@echo "  make release         # 完整发布流程"

## 显示构建环境信息
info:
	@echo "$(CYAN)📊 构建环境信息$(NC)"
	@echo "项目名称: $(PROJECT_NAME)"
	@echo "版本: $(VERSION)"
	@echo "构建时间: $(BUILD_DATE)"
	@echo ""
	@echo "$(YELLOW)工具链信息:$(NC)"
ifdef HAS_RUSTC
	@echo "Rust 版本: $(shell rustc --version)"
endif
ifdef HAS_CARGO
	@echo "Cargo 版本: $(shell cargo --version)"
endif
ifdef HAS_CROSS
	@echo "Cross 版本: $(shell cross --version)"
	@echo "构建工具: cross (推荐)"
else
	@echo "构建工具: cargo (基础)"
	@echo "$(YELLOW)建议安装 cross 以获得更好的跨平台支持: cargo install cross$(NC)"
endif
	@echo ""
	@echo "$(YELLOW)目标平台:$(NC)"
	@echo "当前平台: $(shell rustc -vV | grep host | cut -d' ' -f2)"
	@echo "已安装目标: $(shell rustup target list --installed | tr '\n' ' ')"

## 检查依赖
check-deps:
ifndef HAS_CARGO
	@echo "$(RED)❌ Cargo 未安装$(NC)"
	@exit 1
endif
ifndef HAS_RUSTC
	@echo "$(RED)❌ Rust 编译器未安装$(NC)"
	@exit 1
endif
	@echo "$(GREEN)✅ 依赖检查通过$(NC)"

## 代码检查和格式化
check: check-deps
	@echo "$(BLUE)🔍 运行代码检查...$(NC)"
	@cargo fmt --check || (echo "$(YELLOW)⚠️ 代码格式不符合标准，正在自动格式化...$(NC)" && cargo fmt)
	@cargo clippy --all-targets --all-features -- -D warnings
	@echo "$(GREEN)✅ 代码检查通过$(NC)"

## 运行测试
test: check-deps
	@echo "$(BLUE)🧪 运行测试...$(NC)"
	@cargo test --verbose
	@echo "$(GREEN)✅ 所有测试通过$(NC)"

## 清理构建产物
clean:
	@echo "$(BLUE)🧹 清理构建产物...$(NC)"
	@cargo clean
	@rm -rf dist/
	@echo "$(GREEN)✅ 清理完成$(NC)"

## 安装构建依赖
install-deps:
	@echo "$(BLUE)📦 安装构建依赖...$(NC)"
ifndef HAS_CROSS
	@echo "安装 cross..."
	@cargo install cross
endif
	@echo "$(GREEN)✅ 依赖安装完成$(NC)"

## 安装所有目标平台
install-targets: check-deps
	@echo "$(BLUE)🎯 安装目标平台...$(NC)"
	@for target in $(ALL_TARGETS); do \
		echo "安装目标: $$target"; \
		rustup target add $$target; \
	done
	@echo "$(GREEN)✅ 目标平台安装完成$(NC)"

## 构建单个目标的通用函数
define build_target
	@echo "$(BLUE)🔨 构建目标: $(1)$(NC)"
	@rustup target add $(1) 2>/dev/null || true
	@mkdir -p dist/$(1)
	@$(BUILD_CMD) build --release --target $(1) --features full
	@if [ "$(1)" = *"windows"* ]; then \
		cp target/$(1)/release/$(PROJECT_NAME).exe dist/$(1)/; \
	else \
		cp target/$(1)/release/$(PROJECT_NAME) dist/$(1)/; \
	fi
	@echo "$(GREEN)✅ 构建完成: $(1)$(NC)"
endef

## 构建本地版本
build-local: check test
	@echo "$(BLUE)🏠 构建本地版本...$(NC)"
	@cargo build --release --features full
	@mkdir -p dist/local
	@if [ -f target/release/$(PROJECT_NAME).exe ]; then \
		cp target/release/$(PROJECT_NAME).exe dist/local/; \
	else \
		cp target/release/$(PROJECT_NAME) dist/local/; \
	fi
	@echo "$(GREEN)✅ 本地构建完成$(NC)"

## 构建 Windows 版本
build-windows: check test
	@echo "$(BLUE)🪟 构建 Windows 版本...$(NC)"
	@for target in $(WINDOWS_TARGETS); do \
		$(call build_target,$$target); \
	done
	@echo "$(GREEN)✅ Windows 构建完成$(NC)"

## 构建 Linux 版本
build-linux: check test
	@echo "$(BLUE)🐧 构建 Linux 版本...$(NC)"
	@for target in $(LINUX_TARGETS); do \
		$(call build_target,$$target); \
	done
	@echo "$(GREEN)✅ Linux 构建完成$(NC)"

## 构建 macOS 版本
build-macos: check test
	@echo "$(BLUE)🍎 构建 macOS 版本...$(NC)"
	@for target in $(MACOS_TARGETS); do \
		$(call build_target,$$target); \
	done
	@echo "$(GREEN)✅ macOS 构建完成$(NC)"

## 构建所有平台版本
build-all: check test
	@echo "$(BLUE)🌍 构建所有平台版本...$(NC)"
	@for target in $(ALL_TARGETS); do \
		$(call build_target,$$target); \
	done
	@echo "$(GREEN)✅ 所有平台构建完成$(NC)"

## 创建发布包
package:
	@echo "$(BLUE)📦 创建发布包...$(NC)"
	@cd dist && \
	for dir in */; do \
		if [ "$$dir" != "local/" ]; then \
			target_name=$${dir%/}; \
			echo "打包 $$target_name..."; \
			if echo "$$target_name" | grep -q "windows"; then \
				zip -r "$(PROJECT_NAME)-$$target_name-v$(VERSION).zip" "$$target_name/"; \
			else \
				tar -czf "$(PROJECT_NAME)-$$target_name-v$(VERSION).tar.gz" "$$target_name/"; \
			fi; \
		fi; \
	done
	@cd dist && \
	if command -v sha256sum >/dev/null 2>&1; then \
		sha256sum *.zip *.tar.gz > checksums.sha256 2>/dev/null || true; \
	elif command -v shasum >/dev/null 2>&1; then \
		shasum -a 256 *.zip *.tar.gz > checksums.sha256 2>/dev/null || true; \
	fi
	@echo "$(GREEN)✅ 发布包创建完成$(NC)"

## 完整发布流程
release: clean build-all package
	@echo "$(GREEN)🎉 发布构建完成！$(NC)"
	@echo ""
	@echo "$(BLUE)📁 发布文件位于 dist/ 目录中:$(NC)"
	@ls -la dist/*.zip dist/*.tar.gz dist/checksums.sha256 2>/dev/null || true

## 快速构建（跳过测试）
quick-build:
	@echo "$(YELLOW)⚡ 快速构建（跳过测试）...$(NC)"
	@cargo build --release --features full
	@echo "$(GREEN)✅ 快速构建完成$(NC)"

## 最小化构建
minimal-build: check-deps
	@echo "$(BLUE)📦 最小化构建...$(NC)"
	@cargo build --release
	@echo "$(GREEN)✅ 最小化构建完成$(NC)"

## 显示构建统计
stats:
	@echo "$(CYAN)📊 构建统计$(NC)"
	@echo "目标数量: $(words $(ALL_TARGETS))"
	@echo "Windows 目标: $(words $(WINDOWS_TARGETS))"
	@echo "Linux 目标: $(words $(LINUX_TARGETS))"
	@echo "macOS 目标: $(words $(MACOS_TARGETS))"
	@if [ -d dist ]; then \
		echo ""; \
		echo "$(YELLOW)构建产物:$(NC)"; \
		find dist -name "$(PROJECT_NAME)*" -type f | wc -l | xargs echo "可执行文件数量:"; \
		find dist -name "*.zip" -o -name "*.tar.gz" | wc -l | xargs echo "发布包数量:"; \
	fi
