use crate::core::{types::*, Result, AugmentError};
use log::{debug, info};
use std::path::PathBuf;

/// 路径管理器
pub struct PathManager;

impl PathManager {
    /// 获取所有编辑器的数据库路径
    pub fn get_database_paths(options: &CleanOptions) -> Result<Vec<DatabasePath>> {
        let mut paths = Vec::new();

        if cfg!(target_os = "windows") {
            paths.extend(Self::get_windows_paths(options)?);
        } else if cfg!(target_os = "macos") {
            paths.extend(Self::get_macos_paths(options)?);
        } else if cfg!(target_os = "linux") {
            paths.extend(Self::get_linux_paths(options)?);
        } else {
            return Err(AugmentError::unsupported_platform("当前操作系统"));
        }

        // 过滤存在的文件
        let existing_paths: Vec<DatabasePath> = paths
            .into_iter()
            .filter_map(|path| {
                if path.exists {
                    debug!("找到数据库文件: {} - {}", path.editor_type, path.path.display());
                    Some(path)
                } else {
                    debug!("数据库文件不存在: {} - {}", path.editor_type, path.path.display());
                    None
                }
            })
            .collect();

        info!("找到 {} 个有效的数据库文件", existing_paths.len());
        Ok(existing_paths)
    }

    /// 获取 Windows 平台的路径
    fn get_windows_paths(options: &CleanOptions) -> Result<Vec<DatabasePath>> {
        let mut paths = Vec::new();
        
        let appdata = dirs::data_dir()
            .ok_or_else(|| AugmentError::config("无法获取 APPDATA 目录"))?;

        if options.clean_vscode {
            let vscode_path = appdata
                .join("Code")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::VSCode, vscode_path));
        }

        if options.clean_cursor {
            let cursor_path = appdata
                .join("Cursor")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::Cursor, cursor_path));
        }

        if options.clean_void {
            let void_path = appdata
                .join("Void")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::Void, void_path));
        }

        if options.clean_jetbrains {
            // JetBrains IDE 配置路径
            if let Some(jetbrains_paths) = Self::get_jetbrains_paths_windows() {
                paths.extend(jetbrains_paths);
            }
        }

        Ok(paths)
    }

    /// 获取 macOS 平台的路径
    fn get_macos_paths(options: &CleanOptions) -> Result<Vec<DatabasePath>> {
        let mut paths = Vec::new();
        
        let home_dir = dirs::home_dir()
            .ok_or_else(|| AugmentError::config("无法获取用户主目录"))?;
        let app_support = home_dir.join("Library").join("Application Support");

        if options.clean_vscode {
            let vscode_path = app_support
                .join("Code")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::VSCode, vscode_path));
        }

        if options.clean_cursor {
            let cursor_path = app_support
                .join("Cursor")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::Cursor, cursor_path));
        }

        if options.clean_void {
            let void_path = app_support
                .join("Void")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::Void, void_path));
        }

        if options.clean_jetbrains {
            if let Some(jetbrains_paths) = Self::get_jetbrains_paths_macos(&home_dir) {
                paths.extend(jetbrains_paths);
            }
        }

        Ok(paths)
    }

    /// 获取 Linux 平台的路径
    fn get_linux_paths(options: &CleanOptions) -> Result<Vec<DatabasePath>> {
        let mut paths = Vec::new();
        
        let config_dir = dirs::config_dir()
            .ok_or_else(|| AugmentError::config("无法获取配置目录"))?;

        if options.clean_vscode {
            let vscode_path = config_dir
                .join("Code")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::VSCode, vscode_path));
        }

        if options.clean_cursor {
            let cursor_path = config_dir
                .join("Cursor")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::Cursor, cursor_path));
        }

        if options.clean_void {
            let void_path = config_dir
                .join("Void")
                .join("User")
                .join("globalStorage")
                .join("state.vscdb");
            paths.push(DatabasePath::new(EditorType::Void, void_path));
        }

        if options.clean_jetbrains {
            if let Some(jetbrains_paths) = Self::get_jetbrains_paths_linux(&config_dir) {
                paths.extend(jetbrains_paths);
            }
        }

        Ok(paths)
    }

    /// 获取 JetBrains IDE 在 Windows 上的路径
    fn get_jetbrains_paths_windows() -> Option<Vec<DatabasePath>> {
        // JetBrains IDE 通常在 %APPDATA%\JetBrains 下
        let appdata = dirs::data_dir()?;
        let jetbrains_dir = appdata.join("JetBrains");
        
        if !jetbrains_dir.exists() {
            return None;
        }

        let mut paths = Vec::new();
        
        // 常见的 JetBrains IDE
        let ide_names = [
            "IntelliJIdea",
            "PyCharm",
            "WebStorm",
            "PhpStorm",
            "RubyMine",
            "CLion",
            "DataGrip",
            "GoLand",
            "Rider",
        ];

        for ide_name in &ide_names {
            if let Ok(entries) = std::fs::read_dir(&jetbrains_dir) {
                for entry in entries.flatten() {
                    let dir_name = entry.file_name();
                    if let Some(name) = dir_name.to_str() {
                        if name.starts_with(ide_name) {
                            // 查找配置文件
                            let config_path = entry.path().join("options").join("recentProjects.xml");
                            if config_path.exists() {
                                paths.push(DatabasePath::new(EditorType::JetBrains, config_path));
                            }
                        }
                    }
                }
            }
        }

        if paths.is_empty() {
            None
        } else {
            Some(paths)
        }
    }

    /// 获取 JetBrains IDE 在 macOS 上的路径
    fn get_jetbrains_paths_macos(home_dir: &PathBuf) -> Option<Vec<DatabasePath>> {
        let jetbrains_dir = home_dir
            .join("Library")
            .join("Application Support")
            .join("JetBrains");
        
        if !jetbrains_dir.exists() {
            return None;
        }

        // 实现类似 Windows 的逻辑
        // 这里简化处理，实际可以扩展
        None
    }

    /// 获取 JetBrains IDE 在 Linux 上的路径
    fn get_jetbrains_paths_linux(config_dir: &PathBuf) -> Option<Vec<DatabasePath>> {
        let jetbrains_dir = config_dir.join("JetBrains");
        
        if !jetbrains_dir.exists() {
            return None;
        }

        // 实现类似 Windows 的逻辑
        // 这里简化处理，实际可以扩展
        None
    }

    /// 获取配置文件路径
    pub fn get_config_paths(options: &CleanOptions) -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();

        if cfg!(target_os = "windows") {
            paths.extend(Self::get_windows_config_paths(options)?);
        } else if cfg!(target_os = "macos") {
            paths.extend(Self::get_macos_config_paths(options)?);
        } else if cfg!(target_os = "linux") {
            paths.extend(Self::get_linux_config_paths(options)?);
        }

        Ok(paths)
    }

    /// 获取 Windows 配置文件路径
    fn get_windows_config_paths(options: &CleanOptions) -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        
        let appdata = dirs::data_dir()
            .ok_or_else(|| AugmentError::config("无法获取 APPDATA 目录"))?;

        if options.clean_vscode {
            let vscode_config = appdata
                .join("Code")
                .join("User")
                .join("globalStorage")
                .join("augment.augment");
            paths.push(vscode_config);
        }

        if options.clean_cursor {
            let cursor_config = appdata
                .join("Cursor")
                .join("User")
                .join("globalStorage")
                .join("augment.augment");
            paths.push(cursor_config);
        }

        Ok(paths)
    }

    /// 获取 macOS 配置文件路径
    fn get_macos_config_paths(options: &CleanOptions) -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        
        let home_dir = dirs::home_dir()
            .ok_or_else(|| AugmentError::config("无法获取用户主目录"))?;
        let app_support = home_dir.join("Library").join("Application Support");

        if options.clean_vscode {
            let vscode_config = app_support
                .join("Code")
                .join("User")
                .join("globalStorage")
                .join("augment.augment");
            paths.push(vscode_config);
        }

        if options.clean_cursor {
            let cursor_config = app_support
                .join("Cursor")
                .join("User")
                .join("globalStorage")
                .join("augment.augment");
            paths.push(cursor_config);
        }

        Ok(paths)
    }

    /// 获取 Linux 配置文件路径
    fn get_linux_config_paths(options: &CleanOptions) -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        
        let config_dir = dirs::config_dir()
            .ok_or_else(|| AugmentError::config("无法获取配置目录"))?;

        if options.clean_vscode {
            let vscode_config = config_dir
                .join("Code")
                .join("User")
                .join("globalStorage")
                .join("augment.augment");
            paths.push(vscode_config);
        }

        if options.clean_cursor {
            let cursor_config = config_dir
                .join("Cursor")
                .join("User")
                .join("globalStorage")
                .join("augment.augment");
            paths.push(cursor_config);
        }

        Ok(paths)
    }
}
