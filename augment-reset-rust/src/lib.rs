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
pub mod core;
pub mod database;
pub mod filesystem;
pub mod utils;

// 重新导出常用类型和函数
pub use core::{
    error::{AugmentError, ErrorContext, Result},
    types::*,
};

pub use database::{DatabaseManager, DatabaseStats};
pub use filesystem::{FileOperations, PathManager};
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
    
    // 执行数据库清理
    let results = DatabaseManager::clean_all_databases(&options).await?;
    
    // 如果启用了配置文件清理，也清理配置文件
    if !options.force {
        let config_paths = PathManager::get_config_paths(&options)?;
        if !config_paths.is_empty() {
            info!("清理配置文件...");
            let _cleaned_files = FileOperations::clean_config_files(&config_paths).await?;
        }
    }
    
    info!("清理操作完成");
    Ok(results)
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
