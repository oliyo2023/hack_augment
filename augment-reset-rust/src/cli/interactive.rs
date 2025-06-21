use crate::core::{types::*, Result, AugmentError};
use colored::*;
use dialoguer::{theme::ColorfulTheme, Confirm, MultiSelect, Select};

/// 交互式菜单管理器
pub struct InteractiveMenu;

impl InteractiveMenu {
    /// 运行主交互菜单
    pub async fn run_main_menu() -> Result<CleanOptions> {
        println!("{}", "🎯 Augment Reset - 交互模式".bright_cyan().bold());
        println!();

        // 选择编辑器
        let selected_editors = Self::select_editors()?;
        if selected_editors.is_empty() {
            println!("{}", "未选择任何编辑器，退出程序。".yellow());
            return Err(AugmentError::UserCancelled);
        }

        // 选择操作选项
        let options = Self::select_options()?;

        // 构建清理选项
        let clean_options = CleanOptions {
            clean_vscode: selected_editors.contains(&EditorType::VSCode),
            clean_cursor: selected_editors.contains(&EditorType::Cursor),
            clean_jetbrains: selected_editors.contains(&EditorType::JetBrains),
            clean_void: selected_editors.contains(&EditorType::Void),
            interactive: true,
            backup: options.backup,
            force: false,
            verbose: options.verbose,
        };

        // 显示清理预览
        Self::show_cleanup_preview(&clean_options)?;

        // 确认执行
        let confirm = Confirm::with_theme(&ColorfulTheme::default())
            .with_prompt("确认开始清理？")
            .default(true)
            .interact()?;

        if !confirm {
            println!("{}", "操作已取消。".yellow());
            return Err(AugmentError::UserCancelled);
        }

        Ok(clean_options)
    }

    /// 选择要清理的编辑器
    fn select_editors() -> Result<Vec<EditorType>> {
        // 首先显示主菜单选项
        let main_options = vec![
            "🚀 开始清理 Augment 数据",
            "📊 查看统计信息",
            "🚪 退出程序",
        ];

        let main_selection = Select::with_theme(&ColorfulTheme::default())
            .with_prompt("请选择操作")
            .items(&main_options)
            .default(0)
            .interact()?;

        match main_selection {
            0 => {
                // 继续选择编辑器
                let editors = vec![
                    ("VS Code", EditorType::VSCode),
                    ("Cursor", EditorType::Cursor),
                    ("Void", EditorType::Void),
                    ("JetBrains IDE 系列", EditorType::JetBrains),
                ];

                let mut editor_names: Vec<&str> = editors.iter().map(|(name, _)| *name).collect();
                editor_names.push("🚪 返回主菜单");

                let selections = MultiSelect::with_theme(&ColorfulTheme::default())
                    .with_prompt("请选择要清理的编辑器 (空格选择，回车确认)")
                    .items(&editor_names)
                    .defaults(&[true, true, true, false, false]) // 默认选择前三个，不选择返回选项
                    .interact()?;

                // 检查是否选择了返回选项
                if selections.contains(&(editor_names.len() - 1)) {
                    // 如果选择了返回，递归调用自己重新显示主菜单
                    return Self::select_editors();
                }

                let selected_editors: Vec<EditorType> = selections
                    .into_iter()
                    .filter(|&i| i < editors.len()) // 过滤掉返回选项
                    .map(|i| editors[i].1.clone())
                    .collect();

                Ok(selected_editors)
            }
            1 => {
                // 查看统计信息
                println!();
                if let Err(e) = Self::show_stats_menu_sync() {
                    println!("{} {}", "错误:".red(), e);
                }
                println!();
                println!("{}", "按回车键继续...".bright_black());
                std::io::stdin().read_line(&mut String::new()).ok();

                // 递归调用自己重新显示主菜单
                Self::select_editors()
            }
            2 => {
                // 退出程序
                println!("{}", "👋 感谢使用 Augment Reset！".bright_green());
                Err(AugmentError::UserCancelled)
            }
            _ => {
                // 默认退出
                Err(AugmentError::UserCancelled)
            }
        }
    }

    /// 选择操作选项
    fn select_options() -> Result<InteractiveOptions> {
        println!();
        println!("{}", "⚙️  配置选项".bright_blue().bold());

        let backup = Confirm::with_theme(&ColorfulTheme::default())
            .with_prompt("是否创建备份文件？")
            .default(true)
            .interact()?;

        let verbose = Confirm::with_theme(&ColorfulTheme::default())
            .with_prompt("是否启用详细输出？")
            .default(false)
            .interact()?;

        Ok(InteractiveOptions { backup, verbose })
    }

    /// 显示清理预览
    fn show_cleanup_preview(options: &CleanOptions) -> Result<()> {
        println!();
        println!("{}", "📋 清理预览".bright_yellow().bold());
        println!("{}", "─".repeat(50).bright_black());

        println!("{}", "将要清理的编辑器:".bright_white());
        let selected_editors = options.get_selected_editors();
        for editor in &selected_editors {
            println!("  {} {}", "✓".green(), editor);
        }

        println!();
        println!("{}", "操作选项:".bright_white());
        println!(
            "  {} 备份: {}",
            if options.backup { "✓".green() } else { "✗".red() },
            if options.backup { "启用".green() } else { "禁用".red() }
        );
        println!(
            "  {} 详细输出: {}",
            if options.verbose { "✓".green() } else { "✗".red() },
            if options.verbose { "启用".green() } else { "禁用".red() }
        );

        println!();
        println!("{}", "将要执行的操作:".bright_white());
        println!("  {} 扫描数据库文件", "1.".bright_blue());
        if options.backup {
            println!("  {} 创建备份文件", "2.".bright_blue());
        }
        println!("  {} 清理 Augment 相关记录", "3.".bright_blue());
        println!("  {} 优化数据库", "4.".bright_blue());

        println!("{}", "─".repeat(50).bright_black());
        Ok(())
    }

    /// 选择清理模式
    pub fn select_cleanup_mode() -> Result<CleanupMode> {
        let modes = vec![
            "快速清理 (仅清理数据库记录)",
            "完整清理 (清理数据库记录和配置文件)",
            "深度清理 (清理所有相关数据，包括缓存)",
        ];

        let selection = Select::with_theme(&ColorfulTheme::default())
            .with_prompt("请选择清理模式")
            .items(&modes)
            .default(0)
            .interact()?;

        let mode = match selection {
            0 => CleanupMode::Quick,
            1 => CleanupMode::Complete,
            2 => CleanupMode::Deep,
            _ => CleanupMode::Quick,
        };

        Ok(mode)
    }

    /// 显示统计信息菜单
    pub async fn show_stats_menu() -> Result<()> {
        use crate::database::DatabaseManager;
        use crate::filesystem::PathManager;

        println!("{}", "📊 数据库统计信息".bright_cyan().bold());
        println!();

        let options = CleanOptions::default();
        let db_paths = PathManager::get_database_paths(&options)?;

        if db_paths.is_empty() {
            println!("{}", "未找到任何数据库文件。".yellow());
            return Ok(());
        }

        for db_path in &db_paths {
            println!("{}", format!("📁 {}", db_path.editor_type).bright_blue().bold());
            println!("   路径: {}", db_path.path.display());

            if db_path.exists {
                match DatabaseManager::get_database_stats(db_path).await {
                    Ok(stats) => {
                        println!("   状态: {}", "存在".green());
                        println!("   总记录数: {}", stats.total_records);
                        println!("   Augment 记录数: {}", stats.augment_records);
                        println!("   文件大小: {} bytes", stats.file_size);
                    }
                    Err(e) => {
                        println!("   状态: {} ({})", "错误".red(), e);
                    }
                }
            } else {
                println!("   状态: {}", "不存在".yellow());
            }
            println!();
        }

        Ok(())
    }

    /// 显示统计信息菜单 (同步版本，用于交互式菜单)
    fn show_stats_menu_sync() -> Result<()> {
        use crate::filesystem::PathManager;

        println!("{}", "📊 数据库统计信息".bright_cyan().bold());
        println!();

        let options = CleanOptions::default();
        let db_paths = PathManager::get_database_paths(&options)?;

        if db_paths.is_empty() {
            println!("{}", "未找到任何数据库文件。".yellow());
            return Ok(());
        }

        println!("找到的数据库文件:");
        for db_path in &db_paths {
            let status = if db_path.exists {
                "存在".green()
            } else {
                "不存在".yellow()
            };
            println!("  {} {} - {}", "📁".blue(), db_path.editor_type, status);
            println!("     路径: {}", db_path.path.display().to_string().bright_black());
        }

        if db_paths.iter().any(|p| p.exists) {
            println!();
            println!("{}", "💡 提示: 使用 'augment-reset stats --detailed' 查看详细统计信息".bright_blue());
        }

        Ok(())
    }

    /// 显示备份管理菜单
    pub fn show_backup_menu() -> Result<BackupAction> {
        let actions = vec![
            "查看备份文件",
            "清理过期备份",
            "恢复备份",
            "返回主菜单",
        ];

        let selection = Select::with_theme(&ColorfulTheme::default())
            .with_prompt("请选择备份操作")
            .items(&actions)
            .default(0)
            .interact()?;

        let action = match selection {
            0 => BackupAction::List,
            1 => BackupAction::Cleanup,
            2 => BackupAction::Restore,
            3 => BackupAction::Back,
            _ => BackupAction::Back,
        };

        Ok(action)
    }

    /// 确认危险操作
    pub fn confirm_dangerous_operation(operation: &str) -> Result<bool> {
        println!();
        println!("{}", "⚠️  警告".bright_red().bold());
        println!("您即将执行: {}", operation.bright_yellow());
        println!("此操作可能无法撤销，请确认您了解操作的后果。");
        println!();

        let confirm = Confirm::with_theme(&ColorfulTheme::default())
            .with_prompt("您确定要继续吗？")
            .default(false)
            .interact()?;

        Ok(confirm)
    }
}

/// 交互选项
#[derive(Debug, Clone)]
struct InteractiveOptions {
    backup: bool,
    verbose: bool,
}

/// 清理模式
#[derive(Debug, Clone)]
pub enum CleanupMode {
    Quick,    // 快速清理
    Complete, // 完整清理
    Deep,     // 深度清理
}

/// 备份操作
#[derive(Debug, Clone)]
pub enum BackupAction {
    List,    // 列出备份
    Cleanup, // 清理备份
    Restore, // 恢复备份
    Back,    // 返回
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cleanup_mode_creation() {
        let mode = CleanupMode::Quick;
        matches!(mode, CleanupMode::Quick);
    }

    #[test]
    fn test_backup_action_creation() {
        let action = BackupAction::List;
        matches!(action, BackupAction::List);
    }
}
