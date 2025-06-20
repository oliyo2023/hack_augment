use augment_reset::{
    cli::{parse_args, Commands, InteractiveMenu},
    core::{types::CleanOptions, Result, AugmentError},
    database::DatabaseManager,
    filesystem::{FileOperations, PathManager},
    utils::{show_banner, show_version_info, show_config_info, show_completion_message},
    init_logger, run_app,
};
use colored::*;
#[cfg(feature = "indicatif")]
use indicatif::{ProgressBar, ProgressStyle};
// use log::{error, info, warn}; // 暂时注释掉未使用的导入
use std::process;

#[tokio::main]
async fn main() {
    // 解析命令行参数
    let cli = parse_args();

    // 验证参数
    if let Err(e) = cli.validate() {
        eprintln!("{} {}", "错误:".bright_red().bold(), e);
        process::exit(1);
    }

    // 初始化日志系统
    init_logger(cli.get_log_level());

    // 运行主程序
    if let Err(e) = run_main(cli).await {
        match e {
            AugmentError::UserCancelled => {
                println!("{}", "操作已取消。".yellow());
                process::exit(0);
            }
            _ => {
                eprintln!("{} {}", "错误:".bright_red().bold(), e);
                process::exit(e.error_code());
            }
        }
    }
}

async fn run_main(cli: augment_reset::cli::Cli) -> Result<()> {
    // 显示横幅（除非是静默模式）
    if !cli.quiet {
        show_banner();
    }

    match cli.command {
        Some(Commands::Version) => {
            show_version_info();
            Ok(())
        }
        Some(Commands::Config) => {
            show_config_info();
            Ok(())
        }
        Some(Commands::Stats { detailed }) => {
            show_stats(detailed).await
        }
        Some(Commands::CleanBackups { days, path }) => {
            clean_backups(days, path).await
        }
        Some(Commands::Clean { force, dry_run }) => {
            let options = build_clean_options(&cli, force);
            if dry_run {
                show_dry_run_preview(&options).await
            } else {
                run_cleanup(options, cli.quiet).await
            }
        }
        None => {
            // 默认行为：根据参数决定是否进入交互模式
            if cli.is_interactive() {
                run_interactive_cleanup().await
            } else {
                let options = build_clean_options(&cli, cli.force);
                run_cleanup(options, cli.quiet).await
            }
        }
    }
}

/// 构建清理选项
fn build_clean_options(cli: &augment_reset::cli::Cli, force: bool) -> CleanOptions {
    CleanOptions {
        clean_vscode: cli.vscode || !cli.has_specific_editors(),
        clean_cursor: cli.cursor || !cli.has_specific_editors(),
        clean_jetbrains: cli.jetbrains || !cli.has_specific_editors(),
        clean_void: cli.void || !cli.has_specific_editors(),
        interactive: cli.is_interactive() && !force,
        backup: cli.is_backup_enabled(),
        force,
        verbose: cli.verbose,
    }
}

/// 运行交互式清理
async fn run_interactive_cleanup() -> Result<()> {
    let options = InteractiveMenu::run_main_menu().await?;
    run_cleanup(options, false).await
}

/// 执行清理操作
async fn run_cleanup(options: CleanOptions, quiet: bool) -> Result<()> {
    if !quiet {
        println!("{}", "🚀 开始清理 Augment 相关数据...".bright_green().bold());
        println!();
    }

    // 创建进度条（仅在启用 indicatif 特性时）
    #[cfg(feature = "indicatif")]
    let progress = if !quiet {
        let pb = ProgressBar::new_spinner();
        pb.set_style(
            ProgressStyle::default_spinner()
                .template("{spinner:.green} {msg}")
                .unwrap(),
        );
        pb.set_message("正在扫描数据库文件...");
        Some(pb)
    } else {
        None
    };

    #[cfg(not(feature = "indicatif"))]
    let progress: Option<()> = None;

    // 执行清理
    let results = run_app(options).await?;

    #[cfg(feature = "indicatif")]
    if let Some(pb) = progress {
        pb.finish_and_clear();
    }

    // 显示结果
    if !quiet {
        display_results(&results);
    }

    Ok(())
}

/// 显示结果
fn display_results(results: &[augment_reset::core::types::DatabaseCleanResult]) {
    let mut total_deleted = 0;
    let mut success_count = 0;

    for result in results {
        if result.success {
            success_count += 1;
            total_deleted += result.deleted_records;
            println!(
                "{} {} ({}) - 删除了 {} 条记录",
                "✅".green(),
                result.editor_type,
                result.db_path,
                result.deleted_records
            );
            if let Some(backup_path) = &result.backup_path {
                println!("   💾 备份: {}", backup_path.bright_black());
            }
        } else {
            println!(
                "{} {} ({}) - 失败: {}",
                "❌".red(),
                result.editor_type,
                result.db_path,
                result.error.as_ref().unwrap_or(&"未知错误".to_string())
            );
        }
    }

    show_completion_message(success_count, results.len(), total_deleted);
}

/// 显示统计信息
async fn show_stats(detailed: bool) -> Result<()> {
    if detailed {
        InteractiveMenu::show_stats_menu().await
    } else {
        show_basic_stats().await
    }
}

/// 显示基本统计信息
async fn show_basic_stats() -> Result<()> {
    println!("{}", "📊 基本统计信息".bright_cyan().bold());
    println!();

    let options = CleanOptions::default();
    let db_paths = PathManager::get_database_paths(&options)?;

    println!("找到的数据库文件:");
    for db_path in &db_paths {
        let status = if db_path.exists { "存在".green() } else { "不存在".yellow() };
        println!("  {} {} - {}", "📁".blue(), db_path.editor_type, status);
    }

    if db_paths.is_empty() {
        println!("{}", "  未找到任何数据库文件".yellow());
    }

    println!();
    Ok(())
}

/// 清理备份文件
async fn clean_backups(days: u32, path: Option<String>) -> Result<()> {
    println!("{}", format!("🧹 清理 {} 天前的备份文件...", days).bright_cyan().bold());

    let backup_dir = match path {
        Some(p) => std::path::PathBuf::from(p),
        None => std::env::current_dir()?,
    };

    let deleted_count = FileOperations::cleanup_old_backups(&backup_dir, days).await?;

    println!();
    if deleted_count > 0 {
        println!("{} 清理了 {} 个过期备份文件", "✅".green(), deleted_count);
    } else {
        println!("{} 没有找到需要清理的备份文件", "ℹ️".blue());
    }

    Ok(())
}

/// 显示预览模式
async fn show_dry_run_preview(options: &CleanOptions) -> Result<()> {
    println!("{}", "🔍 预览模式 - 将要执行的操作".bright_yellow().bold());
    println!();

    let db_paths = PathManager::get_database_paths(options)?;

    if db_paths.is_empty() {
        println!("{}", "未找到需要处理的数据库文件。".yellow());
        return Ok(());
    }

    println!("将要处理的数据库文件:");
    for db_path in &db_paths {
        println!("  {} {} - {}", "📁".blue(), db_path.editor_type, db_path.path.display());
        
        if db_path.exists {
            match DatabaseManager::get_database_stats(db_path).await {
                Ok(stats) => {
                    println!("    总记录数: {}", stats.total_records);
                    println!("    Augment 记录数: {} (将被删除)", stats.augment_records.to_string().bright_red());
                    println!("    文件大小: {} bytes", stats.file_size);
                }
                Err(e) => {
                    println!("    状态: {} ({})", "错误".red(), e);
                }
            }
        } else {
            println!("    状态: {}", "文件不存在".yellow());
        }
        println!();
    }

    println!("{}", "注意: 这只是预览，没有实际执行任何操作。".bright_blue());
    Ok(())
}
