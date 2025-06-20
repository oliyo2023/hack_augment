use clap::{Parser, Subcommand};

/// Augment Free Trail - Augment IDE清理工具 (Rust版本)
#[derive(Parser)]
#[command(name = "augment-reset")]
#[command(about = "Augment Free Trail - Augment IDE清理工具 (Rust版本)")]
#[command(version = "2.2.0")]
#[command(author = "oliyo")]
#[command(long_about = None)]
pub struct Cli {
    /// 子命令
    #[command(subcommand)]
    pub command: Option<Commands>,

    /// 仅清理 VS Code
    #[arg(long, help = "仅清理 VS Code 编辑器")]
    pub vscode: bool,

    /// 仅清理 Cursor
    #[arg(long, help = "仅清理 Cursor 编辑器")]
    pub cursor: bool,

    /// 仅清理 JetBrains IDE
    #[arg(long, help = "仅清理 JetBrains IDE 系列")]
    pub jetbrains: bool,

    /// 仅清理 Void
    #[arg(long, help = "仅清理 Void 编辑器")]
    pub void: bool,

    /// 禁用交互模式
    #[arg(long, help = "禁用交互模式，直接执行")]
    pub no_interactive: bool,

    /// 禁用备份
    #[arg(long, help = "禁用自动备份功能")]
    pub no_backup: bool,

    /// 强制执行
    #[arg(long, help = "强制执行，不询问确认")]
    pub force: bool,

    /// 详细输出
    #[arg(short, long, help = "启用详细输出模式")]
    pub verbose: bool,

    /// 静默模式
    #[arg(short, long, help = "静默模式，最小化输出")]
    pub quiet: bool,
}

/// 子命令定义
#[derive(Subcommand)]
pub enum Commands {
    /// 清理所有编辑器的 Augment 数据
    Clean {
        /// 强制执行，不询问确认
        #[arg(short, long, help = "强制执行，不询问确认")]
        force: bool,

        /// 仅显示将要清理的内容，不实际执行
        #[arg(long, help = "预览模式，仅显示将要清理的内容")]
        dry_run: bool,
    },

    /// 显示版本信息
    Version,

    /// 显示配置信息
    Config,

    /// 显示统计信息
    Stats {
        /// 显示详细统计信息
        #[arg(short, long, help = "显示详细统计信息")]
        detailed: bool,
    },

    /// 清理过期备份文件
    CleanBackups {
        /// 保留天数
        #[arg(short, long, default_value = "30", help = "备份文件保留天数")]
        days: u32,

        /// 备份目录路径
        #[arg(short, long, help = "指定备份目录路径")]
        path: Option<String>,
    },
}

impl Cli {
    /// 检查是否指定了特定编辑器
    pub fn has_specific_editors(&self) -> bool {
        self.vscode || self.cursor || self.jetbrains || self.void
    }

    /// 获取选中的编辑器列表
    pub fn get_selected_editors(&self) -> Vec<&str> {
        let mut editors = Vec::new();
        
        if self.vscode {
            editors.push("VS Code");
        }
        if self.cursor {
            editors.push("Cursor");
        }
        if self.jetbrains {
            editors.push("JetBrains");
        }
        if self.void {
            editors.push("Void");
        }
        
        editors
    }

    /// 检查是否为交互模式
    pub fn is_interactive(&self) -> bool {
        !self.no_interactive && !self.force && !self.quiet
    }

    /// 检查是否启用备份
    pub fn is_backup_enabled(&self) -> bool {
        !self.no_backup
    }

    /// 获取日志级别
    pub fn get_log_level(&self) -> log::LevelFilter {
        if self.quiet {
            log::LevelFilter::Error
        } else if self.verbose {
            log::LevelFilter::Debug
        } else {
            log::LevelFilter::Info
        }
    }

    /// 验证参数组合
    pub fn validate(&self) -> Result<(), String> {
        // 检查互斥选项
        if self.quiet && self.verbose {
            return Err("--quiet 和 --verbose 选项不能同时使用".to_string());
        }

        // 检查交互模式和强制模式
        if self.no_interactive && !self.force && self.command.is_none() {
            return Err("禁用交互模式时必须使用 --force 选项或指定具体命令".to_string());
        }

        Ok(())
    }
}

/// 解析命令行参数的辅助函数
pub fn parse_args() -> Cli {
    Cli::parse()
}

/// 显示帮助信息
pub fn show_help() {
    use crate::utils::show_help_info;
    show_help_info();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_has_specific_editors() {
        let cli = Cli {
            command: None,
            vscode: true,
            cursor: false,
            jetbrains: false,
            void: false,
            no_interactive: false,
            no_backup: false,
            force: false,
            verbose: false,
            quiet: false,
        };
        
        assert!(cli.has_specific_editors());
    }

    #[test]
    fn test_get_selected_editors() {
        let cli = Cli {
            command: None,
            vscode: true,
            cursor: true,
            jetbrains: false,
            void: false,
            no_interactive: false,
            no_backup: false,
            force: false,
            verbose: false,
            quiet: false,
        };
        
        let editors = cli.get_selected_editors();
        assert_eq!(editors, vec!["VS Code", "Cursor"]);
    }

    #[test]
    fn test_validate_conflicting_options() {
        let cli = Cli {
            command: None,
            vscode: false,
            cursor: false,
            jetbrains: false,
            void: false,
            no_interactive: false,
            no_backup: false,
            force: false,
            verbose: true,
            quiet: true,
        };
        
        assert!(cli.validate().is_err());
    }
}
