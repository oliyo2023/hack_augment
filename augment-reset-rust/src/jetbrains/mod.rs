//! # JetBrains IDE 清理模块
//! 
//! 处理 JetBrains 系列 IDE 的重置操作：
//! - 清理 Windows 注册表
//! - 删除 .jetbrains 配置目录
//! - 删除 .augment 目录
//! - 进程检测和关闭

use crate::core::{Result, AugmentError};
use chrono::{DateTime, Utc};
use log::{info, warn, error, debug};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::process::Command;
use tokio::time::{sleep, Duration};

/// JetBrains 清理结果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct JetBrainsCleanResult {
    /// 清理是否成功
    pub success: bool,
    /// 注册表是否已清理
    pub registry_cleared: bool,
    /// JetBrains 目录路径
    pub jetbrains_dir: String,
    /// Augment 目录路径
    pub augment_dir: String,
    /// 已清理的路径列表
    pub cleared_paths: Vec<String>,
    /// 错误信息
    pub error: Option<String>,
    /// 时间戳
    pub timestamp: DateTime<Utc>,
}

/// JetBrains IDE 清理器
pub struct JetBrainsCleaner;

impl JetBrainsCleaner {
    /// Windows 注册表路径
    const REGISTRY_PATHS: &'static [&'static str] = &[
        "HKEY_CURRENT_USER\\Software\\JavaSoft",
        "HKEY_CURRENT_USER\\Software\\JetBrains",
    ];

    /// 支持的 JetBrains IDE
    const JETBRAINS_IDES: &'static [&'static str] = &[
        "IntelliJIdea",
        "PyCharm",
        "WebStorm",
        "PhpStorm",
        "RubyMine",
        "CLion",
        "DataGrip",
        "GoLand",
        "Rider",
        "AndroidStudio",
    ];

    /// 进程等待时间（毫秒）
    const EDITOR_CLOSE_WAIT_MS: u64 = 1500;

    /// 执行完整的 JetBrains 清理
    pub async fn clean_jetbrains() -> Result<JetBrainsCleanResult> {
        info!("开始 JetBrains 系列 IDE 清理...");
        
        let mut result = JetBrainsCleanResult {
            success: false,
            registry_cleared: false,
            jetbrains_dir: String::new(),
            augment_dir: String::new(),
            cleared_paths: Vec::new(),
            error: None,
            timestamp: Utc::now(),
        };

        // 1. 检查并关闭 JetBrains IDE 进程
        println!("🔍 检查正在运行的 JetBrains IDE...");
        if Self::is_jetbrains_running()? {
            println!("⚠️ 检测到 JetBrains IDE 正在运行，尝试关闭...");
            if Self::kill_jetbrains_process().await? {
                println!("✅ JetBrains IDE 已关闭");
            } else {
                let error_msg = "无法关闭 JetBrains IDE，请手动关闭后重试";
                println!("❌ {}", error_msg);
                result.error = Some(error_msg.to_string());
                return Ok(result);
            }
        } else {
            println!("✅ 未检测到运行中的 JetBrains IDE");
        }

        // 2. 清理 Windows 注册表
        println!("🗂️ 清理注册表...");
        if Self::clear_windows_registry().await? {
            result.registry_cleared = true;
            println!("✅ 注册表清理完成");
        } else {
            println!("❌ 注册表清理失败");
        }

        // 3. 获取需要清理的目录
        let jetbrains_paths = Self::get_jetbrains_paths()?;

        // 4. 清理每个目录
        println!("\n📁 清理配置目录...");
        for dir_path in jetbrains_paths {
            println!("🔄 处理目录: {}", dir_path.display());
            
            if Self::clean_directory(&dir_path).await? {
                let path_str = dir_path.to_string_lossy().to_string();
                result.cleared_paths.push(path_str.clone());
                println!("✅ 目录清理成功");
                
                // 记录特殊目录
                let path_lower = path_str.to_lowercase();
                if path_lower.contains(".jetbrains") || path_lower.contains("jetbrains") {
                    result.jetbrains_dir = path_str;
                } else if path_lower.contains(".augment") {
                    result.augment_dir = path_str;
                }
            } else {
                println!("❌ 目录清理失败");
            }
        }

        // 5. 设置最终结果
        result.success = result.cleared_paths.len() > 0 || result.registry_cleared;
        
        if result.success {
            println!("\n🎉 JetBrains 清理完成！清理了 {} 个目录", result.cleared_paths.len());
        } else {
            result.error = Some("没有成功清理任何项目".to_string());
        }

        Ok(result)
    }

    /// 清理 Windows 注册表
    async fn clear_windows_registry() -> Result<bool> {
        if !cfg!(target_os = "windows") {
            info!("非 Windows 系统，跳过注册表清理");
            return Ok(true);
        }

        info!("开始清理 Windows 注册表...");
        let mut _cleared_count = 0;

        for reg_path in Self::REGISTRY_PATHS {
            match Self::delete_registry_key(reg_path).await {
                Ok(success) => {
                    if success {
                        _cleared_count += 1;
                        info!("成功删除注册表项: {}", reg_path);
                    } else {
                        info!("注册表项不存在或已删除: {}", reg_path);
                    }
                }
                Err(e) => {
                    warn!("删除注册表项失败: {} - {}", reg_path, e);
                }
            }
        }

        info!("注册表清理完成，处理了 {} 个路径", Self::REGISTRY_PATHS.len());
        Ok(true)
    }

    /// 删除单个注册表项
    async fn delete_registry_key(reg_path: &str) -> Result<bool> {
        if !cfg!(target_os = "windows") {
            return Ok(true);
        }

        let delete_cmd = format!("reg delete \"{}\" /f", reg_path);
        info!("执行注册表删除命令: {}", delete_cmd);

        let output = Command::new("cmd")
            .args(&["/C", &delete_cmd])
            .output()
            .map_err(|e| AugmentError::system(format!("执行注册表命令失败: {}", e)))?;

        Ok(output.status.success())
    }

    /// 获取 JetBrains 相关路径
    fn get_jetbrains_paths() -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();

        if cfg!(target_os = "windows") {
            paths.extend(Self::get_jetbrains_paths_windows()?);
        } else if cfg!(target_os = "macos") {
            paths.extend(Self::get_jetbrains_paths_macos()?);
        } else if cfg!(target_os = "linux") {
            paths.extend(Self::get_jetbrains_paths_linux()?);
        }

        info!("找到 {} 个 JetBrains 相关路径", paths.len());
        Ok(paths)
    }

    /// 获取 Windows 上的 JetBrains 路径
    fn get_jetbrains_paths_windows() -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        let appdata = PathBuf::from(std::env::var("APPDATA").map_err(|e| AugmentError::config(format!("无法获取 APPDATA 环境变量: {}", e)))?);
        let local_appdata = PathBuf::from(std::env::var("LOCALAPPDATA").map_err(|e| AugmentError::config(format!("无法获取 LOCALAPPDATA 环境变量: {}", e)))?);

        // JetBrains IDEs' specific config and cache paths
        for ide in Self::JETBRAINS_IDES {
            let config_dir = appdata.join("JetBrains").join(ide);
            if config_dir.exists() {
                paths.push(config_dir);
            }
            let cache_dir = local_appdata.join("JetBrains").join(ide);
            if cache_dir.exists() {
                paths.push(cache_dir);
            }
        }

        // Augment 目录
        let augment_dir = appdata.join(".augment");
        if augment_dir.exists() {
            paths.push(augment_dir);
        }

        Ok(paths)
    }

    /// 获取 macOS 上的 JetBrains 路径
    fn get_jetbrains_paths_macos() -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        let home_dir = dirs::home_dir().ok_or_else(|| AugmentError::config("无法获取用户主目录"))?;

        let app_support = home_dir.join("Library/Application Support/JetBrains");
        let caches = home_dir.join("Library/Caches/JetBrains");

        for ide in Self::JETBRAINS_IDES {
            let config_dir = app_support.join(ide);
            if config_dir.exists() {
                paths.push(config_dir);
            }
            let cache_dir = caches.join(ide);
            if cache_dir.exists() {
                paths.push(cache_dir);
            }
        }

        // Augment 目录
        let augment_dir = home_dir.join(".augment");
        if augment_dir.exists() {
            paths.push(augment_dir);
        }

        Ok(paths)
    }

    /// 获取 Linux 上的 JetBrains 路径
    fn get_jetbrains_paths_linux() -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        let home_dir = dirs::home_dir().ok_or_else(|| AugmentError::config("无法获取用户主目录"))?;

        let config_base = home_dir.join(".config/JetBrains");
        let cache_base = home_dir.join(".cache/JetBrains");

        for ide in Self::JETBRAINS_IDES {
            let config_dir = config_base.join(ide);
            if config_dir.exists() {
                paths.push(config_dir);
            }
            let cache_dir = cache_base.join(ide);
            if cache_dir.exists() {
                paths.push(cache_dir);
            }
        }

        // Augment 目录
        let augment_dir = home_dir.join(".augment");
        if augment_dir.exists() {
            paths.push(augment_dir);
        }

        Ok(paths)
    }

    /// 清理单个目录
    async fn clean_directory(dir_path: &PathBuf) -> Result<bool> {
        if !dir_path.exists() {
            info!("目录不存在，跳过: {}", dir_path.display());
            return Ok(true);
        }

        info!("开始清理目录: {}", dir_path.display());

        // 删除目录
        tokio::fs::remove_dir_all(dir_path)
            .await
            .map_err(|e| AugmentError::filesystem(e))?;

        info!("成功删除目录: {}", dir_path.display());
        Ok(true)
    }

    /// 检测 JetBrains IDE 是否正在运行
    fn is_jetbrains_running() -> Result<bool> {
        let output = if cfg!(target_os = "windows") {
            Command::new("tasklist")
                .args(&["/FI", "IMAGENAME eq idea64.exe"])
                .output()
        } else if cfg!(target_os = "macos") {
            Command::new("pgrep")
                .args(&["-i", "idea|pycharm|webstorm|phpstorm|clion|datagrip|goland|rider"])
                .output()
        } else {
            Command::new("pgrep")
                .args(&["-i", "idea|pycharm|webstorm|phpstorm|clion|datagrip|goland|rider"])
                .output()
        };

        match output {
            Ok(output) => {
                let stdout = String::from_utf8_lossy(&output.stdout);
                let is_running = if cfg!(target_os = "windows") {
                    stdout.contains("idea64.exe") || stdout.contains("pycharm64.exe")
                } else {
                    !stdout.trim().is_empty()
                };

                debug!("JetBrains IDE 运行状态: {}", is_running);
                Ok(is_running)
            }
            Err(e) => {
                warn!("检查 JetBrains IDE 进程失败: {}", e);
                Ok(false)
            }
        }
    }

    /// 关闭 JetBrains IDE 进程
    async fn kill_jetbrains_process() -> Result<bool> {
        let command = if cfg!(target_os = "windows") {
            "taskkill /F /IM idea64.exe /T & taskkill /F /IM pycharm64.exe /T & taskkill /F /IM webstorm64.exe /T"
        } else if cfg!(target_os = "macos") {
            "pkill -i \"idea|pycharm|webstorm|phpstorm|clion|datagrip|goland|rider\""
        } else {
            "pkill -i \"idea|pycharm|webstorm|phpstorm|clion|datagrip|goland|rider\""
        };

        info!("执行关闭 JetBrains IDE 命令: {}", command);

        let output = if cfg!(target_os = "windows") {
            Command::new("cmd")
                .args(&["/C", command])
                .output()
        } else {
            Command::new("sh")
                .args(&["-c", command])
                .output()
        };

        match output {
            Ok(_) => {
                // 等待进程关闭
                sleep(Duration::from_millis(Self::EDITOR_CLOSE_WAIT_MS)).await;

                // 验证 IDE 是否已关闭
                let still_running = Self::is_jetbrains_running()?;
                if !still_running {
                    info!("JetBrains IDE 已成功关闭");
                    Ok(true)
                } else {
                    warn!("JetBrains IDE 仍在运行，可能需要手动关闭");
                    Ok(false)
                }
            }
            Err(e) => {
                error!("关闭 JetBrains IDE 时出错: {}", e);
                Ok(false)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_jetbrains_clean_result_creation() {
        let result = JetBrainsCleanResult {
            success: true,
            registry_cleared: true,
            jetbrains_dir: "/test/jetbrains".to_string(),
            augment_dir: "/test/augment".to_string(),
            cleared_paths: vec!["/test/path1".to_string(), "/test/path2".to_string()],
            error: None,
            timestamp: Utc::now(),
        };

        assert!(result.success);
        assert!(result.registry_cleared);
        assert_eq!(result.cleared_paths.len(), 2);
    }

    #[test]
    fn test_registry_paths() {
        assert!(!JetBrainsCleaner::REGISTRY_PATHS.is_empty());
        assert!(JetBrainsCleaner::REGISTRY_PATHS.contains(&"HKEY_CURRENT_USER\\Software\\JetBrains"));
    }

    #[test]
    fn test_jetbrains_ides() {
        assert!(!JetBrainsCleaner::JETBRAINS_IDES.is_empty());
        assert!(JetBrainsCleaner::JETBRAINS_IDES.contains(&"IntelliJIdea"));
        assert!(JetBrainsCleaner::JETBRAINS_IDES.contains(&"PyCharm"));
    }

    #[tokio::test]
    async fn test_is_jetbrains_running() {
        // 这个测试可能会因为系统环境而失败，所以我们只测试函数不会panic
        let result = JetBrainsCleaner::is_jetbrains_running();
        assert!(result.is_ok());
    }
}
