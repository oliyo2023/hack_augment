use colored::*;

/// 显示应用程序横幅
pub fn show_banner() {
    println!();

    // 使用精确计算的 banner，确保完美对齐
    // 每行内容宽度为 78 字符，加上左右边框共 80 字符
    let lines = vec![
        "╔══════════════════════════════════════════════════════════════════════════════╗",
        "║                                                                              ║",
        "║                           🚀 Augment Free Trail 🚀                           ║", // 显示宽度: 24, 左填充: 27, 右填充: 27
        "║                                                                              ║",
        "║                       Augment IDE 清理工具 (Rust版本)                        ║", // 显示宽度: 31, 左填充: 23, 右填充: 24
        "║                                                                              ║",
        "║                                 版本: v2.2.0                                 ║", // 显示宽度: 12, 左填充: 33, 右填充: 33
        "║                                                                              ║",
        "║                                公众号: 趣惠赚                                ║", // 显示宽度: 14, 左填充: 32, 右填充: 32
        "║                         网站: https://www.oliyo.com                          ║", // 显示宽度: 27, 左填充: 25, 右填充: 26
        "║                                                                              ║",
        "║                     🎯 高性能 • 内存安全 • 跨平台支持                        ║", // 显示宽度: 35, 左填充: 21, 右填充: 22
        "║                     🎯 仅限制学习研究使用，请勿用于非法用途。                ║",
        "║                                                                              ║",
        "╚══════════════════════════════════════════════════════════════════════════════╝",
    ];

    for line in lines {
        println!("{}", line.bright_cyan());
    }
    println!();
}

/// 显示简化横幅
pub fn show_simple_banner() {
    println!("{}", "🚀 Augment Free Trail v2.2.0 (Rust版本)".bright_cyan().bold());
    println!("{}", "   Augment IDE 清理工具 - 高性能跨平台版本".bright_blue());
    println!();
}

/// 显示版本信息
pub fn show_version_info() {
    println!("{}", "Augment Reset v2.2.0".bright_green().bold());
    println!("{}", "使用 Rust 重写，高性能跨平台版本".bright_blue());
    println!();
    println!("{}", "特性:".bright_yellow().bold());
    println!("  {} 内置 SQLite 支持 (rusqlite)", "✅".green());
    println!("  {} 零运行时依赖", "✅".green());
    println!("  {} 内存安全保证", "✅".green());
    println!("  {} 跨平台支持 (Windows/macOS/Linux)", "✅".green());
    println!("  {} 并发数据库处理", "✅".green());
    println!("  {} 自动备份功能", "✅".green());
    println!();
    println!("{}", "编译信息:".bright_yellow().bold());
    println!("  目标平台: {}", std::env::consts::OS);
    println!("  架构: {}", std::env::consts::ARCH);
    println!();
}

/// 显示配置信息
pub fn show_config_info() {
    println!("{}", "配置信息:".bright_yellow().bold());
    println!("  版本: 2.2.0");
    println!("  语言: Rust");
    println!("  SQLite: 内置 (rusqlite with bundled feature)");
    println!("  异步运行时: Tokio");
    println!("  命令行解析: Clap v4");
    println!("  日志系统: env_logger");
    println!("  颜色输出: colored");
    println!();
    
    println!("{}", "支持的编辑器:".bright_yellow().bold());
    println!("  {} VS Code", "📝".blue());
    println!("  {} Cursor", "🖱️".blue());
    println!("  {} Void", "🌌".blue());
    println!("  {} JetBrains IDE 系列", "🧠".blue());
    println!();
}

/// 显示帮助信息
pub fn show_help_info() {
    show_simple_banner();
    
    println!("{}", "用法:".bright_yellow().bold());
    println!("  augment-reset [选项] [命令]");
    println!();
    
    println!("{}", "命令:".bright_yellow().bold());
    println!("  clean      清理所有编辑器的 Augment 数据");
    println!("  version    显示版本信息");
    println!("  config     显示配置信息");
    println!();
    
    println!("{}", "选项:".bright_yellow().bold());
    println!("  --vscode       仅清理 VS Code");
    println!("  --cursor       仅清理 Cursor");
    println!("  --jetbrains    仅清理 JetBrains IDE");
    println!("  --void         仅清理 Void");
    println!("  --no-interactive  禁用交互模式");
    println!("  --no-backup    禁用备份");
    println!("  --force        强制执行，不询问确认");
    println!("  -v, --verbose  详细输出");
    println!("  -h, --help     显示帮助信息");
    println!();
    
    println!("{}", "示例:".bright_yellow().bold());
    println!("  augment-reset                    # 交互模式清理所有编辑器");
    println!("  augment-reset clean --force      # 强制清理所有编辑器");
    println!("  augment-reset --vscode --cursor  # 仅清理 VS Code 和 Cursor");
    println!("  augment-reset version            # 显示版本信息");
    println!();
}

/// 显示操作完成信息
pub fn show_completion_message(success_count: usize, total_count: usize, deleted_records: u32) {
    println!();
    if success_count == total_count && total_count > 0 {
        println!("{}", "🎉 清理操作完成！".bright_green().bold());
    } else if success_count > 0 {
        println!("{}", "⚠️  清理操作部分完成".bright_yellow().bold());
    } else {
        println!("{}", "❌ 清理操作失败".bright_red().bold());
    }
    
    println!();
    println!("📊 统计信息:");
    println!("  成功处理: {}/{} 个数据库", success_count, total_count);
    println!("  删除记录: {} 条", deleted_records);
    println!();
    
    if success_count == total_count && deleted_records > 0 {
        println!("{}", "✨ 所有 Augment 相关数据已成功清理！".bright_green());
    } else if deleted_records == 0 {
        println!("{}", "ℹ️  没有找到需要清理的 Augment 数据".bright_blue());
    }
    
    println!();
    println!("{}", "感谢使用 Augment Free Trail！".bright_cyan());
    println!("{}", "公众号: 趣惠赚 | 网站: https://www.oliyo.com".bright_blue());
    println!();
}
