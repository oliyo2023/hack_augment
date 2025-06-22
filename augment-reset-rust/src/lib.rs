//! # Augment Reset
//! 
//! Augment Free Trail - Augment IDE清理工具 (Rust版本)
//! 
//! 这是一个高性能、内存安全的跨平台工具，用于清理各种代码编辑器中的 Augment 相关数据。
//! 
//! ## 特性
//! 
//! - 🚀 高性能：使用 Rust 编写，零成本抽象
//! - 🔒 内存安全：Rust 的所有权系统保证内存安全
//! - 🌍 跨平台：支持 Windows、macOS、Linux
//! - 📦 零依赖：静态编译，无需外部运行时
//! - 🗄️ 内置 SQLite：使用 rusqlite 的 bundled 特性
//! - 🔄 并发处理：支持并发清理多个数据库
//! - 💾 自动备份：清理前自动创建备份
//! - 🎨 友好界面：彩色输出和交互式菜单
//! 
//! ## 支持的编辑器
//! 
//! - VS Code
//! - Cursor
//! - Void
//! - JetBrains IDE 系列
//! 
//! ## 使用示例
//! 
//! ```rust
//! use augment_reset::{
//!     core::{types::CleanOptions, Result},
//!     database::DatabaseManager,
//!     filesystem::PathManager,
//! };
//! 
//! #[tokio::main]
//! async fn main() -> Result<()> {
//!     // 创建清理选项
//!     let options = CleanOptions::default();
//!     
//!     // 获取数据库路径
//!     let db_paths = PathManager::get_database_paths(&options)?;
//!     
//!     // 执行清理
//!     let results = DatabaseManager::clean_all_databases(&options).await?;
//!     
//!     // 处理结果
//!     for result in results {
//!         if result.success {
//!             println!("✅ 清理成功: {} (删除 {} 条记录)", 
//!                      result.db_path, result.deleted_records);
//!         } else {
//!             println!("❌ 清理失败: {} - {}", 
//!                      result.db_path, result.error.unwrap_or_default());
//!         }
//!     }
//!     
//!     Ok(())
//! }
//! ```

pub mod cli;
pub mod config;
pub mod core;
pub mod database;
pub mod filesystem;
pub mod idgen;
pub mod jetbrains;
pub mod utils;

// 重新导出常用类型和函数
pub use core::{
    error::{AugmentError, ErrorContext, Result},
    types::*,
};

pub use config::{ConfigGenerator, ConfigFileType};
pub use database::{DatabaseManager, DatabaseStats};
pub use filesystem::{FileOperations, PathManager};
pub use idgen::{IdGenerator, AugmentConfig};
pub use jetbrains::{JetBrainsCleaner, JetBrainsCleanResult};
pub use utils::*;

/// 应用程序版本
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// 应用程序名称
pub const APP_NAME: &str = env!("CARGO_PKG_NAME");

/// 应用程序描述
pub const APP_DESCRIPTION: &str = env!("CARGO_PKG_DESCRIPTION");

/// 获取应用程序信息
pub fn get_app_info() -> AppInfo {
    AppInfo {
        name: APP_NAME.to_string(),
        version: VERSION.to_string(),
        description: APP_DESCRIPTION.to_string(),
        author: "oliyo".to_string(),
        website: "https://www.oliyo.com".to_string(),
        public_account: "趣惠赚".to_string(),
    }
}

/// 应用程序信息
#[derive(Debug, Clone)]
pub struct AppInfo {
    pub name: String,
    pub version: String,
    pub description: String,
    pub author: String,
    pub website: String,
    pub public_account: String,
}

/// 初始化日志系统
pub fn init_logger(level: log::LevelFilter) {
    env_logger::Builder::from_default_env()
        .filter_level(level)
        .format_timestamp_secs()
        .init();
}

/// 运行应用程序的主要逻辑
pub async fn run_app(options: CleanOptions) -> Result<Vec<DatabaseCleanResult>> {
    use log::info;

    info!("开始执行清理操作");
    info!("清理选项: {:?}", options);

    // 生成新的账户配置（如果需要的话）
    let account_config = if options.clean_vscode || options.clean_cursor || options.clean_void {
        Some(IdGenerator::generate_account_config()?)
    } else {
        None
    };

    // 执行数据库清理
    let results = DatabaseManager::clean_all_databases(&options).await?;

    // 如果启用了JetBrains清理
    if options.clean_jetbrains {
        info!("开始JetBrains IDE清理...");
        match jetbrains::JetBrainsCleaner::clean_jetbrains().await {
            Ok(jetbrains_result) => {
                if jetbrains_result.success {
                    info!("JetBrains清理成功");
                } else {
                    info!("JetBrains清理失败: {:?}", jetbrains_result.error);
                }
            }
            Err(e) => {
                info!("JetBrains清理过程出错: {}", e);
            }
        }
    }

    // 重新生成配置文件（而不是仅仅删除）
    if let Some(config) = account_config {
        info!("重新生成配置文件...");
        let config_paths = PathManager::get_config_paths(&options)?;
        if !config_paths.is_empty() {
            let _regenerated_files = regenerate_config_files(&config_paths, &config).await?;
        }
    }

    info!("清理操作完成");
    Ok(results)
}

/// 重新生成配置文件
async fn regenerate_config_files(
    config_paths: &[std::path::PathBuf],
    account_config: &AugmentConfig,
) -> Result<Vec<String>> {
    use log::info;

    use tokio::fs;

    let mut regenerated_files = Vec::new();

    for config_path in config_paths {
        info!("重新生成配置文件: {}", config_path.display());

        // 确保父目录存在
        if let Some(parent) = config_path.parent() {
            if !parent.exists() {
                fs::create_dir_all(parent).await
                    .map_err(|e| AugmentError::filesystem(e))?;
                info!("创建目录: {}", parent.display());
            }
        }

        // 备份现有文件（如果存在）
        if config_path.exists() {
            let backup_result = FileOperations::backup_file(config_path).await?;
            if !backup_result.success {
                log::warn!("备份文件失败: {}", backup_result.error.unwrap_or_default());
            }
        }

        // 如果是目录，删除它
        if config_path.is_dir() {
            fs::remove_dir_all(config_path).await
                .map_err(|e| AugmentError::filesystem(e))?;
            info!("删除目录: {}", config_path.display());
            regenerated_files.push(config_path.to_string_lossy().to_string());
            continue;
        }

        // 根据路径推断配置文件类型
        let file_type = ConfigGenerator::infer_config_type_from_path(
            &config_path.to_string_lossy()
        );

        // 创建新配置内容
        let new_config = ConfigGenerator::create_config_by_type(file_type, account_config)?;

        // 保存配置文件
        let config_content = serde_json::to_string_pretty(&new_config)
            .map_err(|e| AugmentError::config(format!("序列化配置失败: {}", e)))?;

        fs::write(config_path, config_content).await
            .map_err(|e| AugmentError::filesystem(e))?;

        info!("配置文件已保存: {}", config_path.display());
        regenerated_files.push(config_path.to_string_lossy().to_string());
    }

    info!("重新生成了 {} 个配置文件", regenerated_files.len());
    Ok(regenerated_files)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_app_info() {
        let info = get_app_info();
        assert_eq!(info.name, "augment-reset");
        assert!(!info.version.is_empty());
        assert!(!info.description.is_empty());
    }

    #[test]
    fn test_constants() {
        assert!(!VERSION.is_empty());
        assert!(!APP_NAME.is_empty());
        assert!(!APP_DESCRIPTION.is_empty());
    }
}
