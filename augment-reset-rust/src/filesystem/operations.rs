use crate::core::{types::*, Result, AugmentError};
use chrono::Utc;
use log::{debug, info, warn, error};
use std::path::{Path, PathBuf};
use tokio::fs;
use walkdir::WalkDir;

/// 文件系统操作管理器
pub struct FileOperations;

impl FileOperations {
    /// 备份文件
    pub async fn backup_file<P: AsRef<Path>>(file_path: P) -> Result<BackupResult> {
        let file_path = file_path.as_ref();
        let original_path = file_path.to_string_lossy().to_string();

        if !file_path.exists() {
            return Ok(BackupResult::failure(
                original_path,
                "源文件不存在".to_string(),
            ));
        }

        let timestamp = Utc::now().format("%Y%m%d_%H%M%S_%3f");
        let backup_path = format!("{}.{}.bak", file_path.to_string_lossy(), timestamp);

        match fs::copy(file_path, &backup_path).await {
            Ok(_) => {
                info!("文件备份成功: {} -> {}", original_path, backup_path);
                Ok(BackupResult::success(backup_path, original_path))
            }
            Err(e) => {
                error!("文件备份失败: {} - {}", original_path, e);
                Ok(BackupResult::failure(
                    original_path,
                    format!("备份失败: {}", e),
                ))
            }
        }
    }

    /// 删除文件
    pub async fn remove_file<P: AsRef<Path>>(file_path: P) -> Result<()> {
        let file_path = file_path.as_ref();
        
        if !file_path.exists() {
            debug!("文件不存在，跳过删除: {}", file_path.display());
            return Ok(());
        }

        fs::remove_file(file_path).await.map_err(|e| {
            AugmentError::Filesystem(e)
        })?;

        info!("文件删除成功: {}", file_path.display());
        Ok(())
    }

    /// 删除目录及其内容
    pub async fn remove_dir_all<P: AsRef<Path>>(dir_path: P) -> Result<()> {
        let dir_path = dir_path.as_ref();
        
        if !dir_path.exists() {
            debug!("目录不存在，跳过删除: {}", dir_path.display());
            return Ok(());
        }

        fs::remove_dir_all(dir_path).await.map_err(|e| {
            AugmentError::Filesystem(e)
        })?;

        info!("目录删除成功: {}", dir_path.display());
        Ok(())
    }

    /// 清理配置文件
    pub async fn clean_config_files(config_paths: &[PathBuf]) -> Result<Vec<String>> {
        let mut cleaned_files = Vec::new();

        for config_path in config_paths {
            if config_path.exists() {
                if config_path.is_dir() {
                    // 如果是目录，删除整个目录
                    match Self::remove_dir_all(config_path).await {
                        Ok(_) => {
                            cleaned_files.push(config_path.to_string_lossy().to_string());
                            info!("清理配置目录: {}", config_path.display());
                        }
                        Err(e) => {
                            warn!("清理配置目录失败: {} - {}", config_path.display(), e);
                        }
                    }
                } else {
                    // 如果是文件，删除文件
                    match Self::remove_file(config_path).await {
                        Ok(_) => {
                            cleaned_files.push(config_path.to_string_lossy().to_string());
                            info!("清理配置文件: {}", config_path.display());
                        }
                        Err(e) => {
                            warn!("清理配置文件失败: {} - {}", config_path.display(), e);
                        }
                    }
                }
            } else {
                debug!("配置路径不存在: {}", config_path.display());
            }
        }

        Ok(cleaned_files)
    }

    /// 清理过期备份文件
    pub async fn cleanup_old_backups<P: AsRef<Path>>(
        directory: P,
        retention_days: u32,
    ) -> Result<u32> {
        let directory = directory.as_ref();
        
        if !directory.exists() {
            debug!("备份目录不存在: {}", directory.display());
            return Ok(0);
        }

        let cutoff_time = Utc::now() - chrono::Duration::days(retention_days as i64);
        let mut deleted_count = 0;

        for entry in WalkDir::new(directory)
            .into_iter()
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().is_file())
            .filter(|e| {
                e.file_name()
                    .to_str()
                    .map(|name| name.ends_with(".bak"))
                    .unwrap_or(false)
            })
        {
            if let Ok(metadata) = entry.metadata() {
                if let Ok(modified) = metadata.modified() {
                    let modified_time = chrono::DateTime::<Utc>::from(modified);
                    if modified_time < cutoff_time {
                        match fs::remove_file(entry.path()).await {
                            Ok(_) => {
                                deleted_count += 1;
                                info!("删除过期备份文件: {}", entry.path().display());
                            }
                            Err(e) => {
                                warn!("删除备份文件失败: {} - {}", entry.path().display(), e);
                            }
                        }
                    }
                }
            }
        }

        info!("清理了 {} 个过期备份文件", deleted_count);
        Ok(deleted_count)
    }

    /// 检查文件是否为有效的 SQLite 数据库
    pub async fn is_valid_sqlite_file<P: AsRef<Path>>(file_path: P) -> Result<bool> {
        let file_path = file_path.as_ref();
        
        if !file_path.exists() {
            return Ok(false);
        }

        // 读取文件头部检查 SQLite 魔数
        match fs::read(file_path).await {
            Ok(content) => {
                if content.len() >= 16 {
                    let header = &content[0..16];
                    let sqlite_header = b"SQLite format 3\0";
                    Ok(header == sqlite_header)
                } else {
                    Ok(false)
                }
            }
            Err(_) => Ok(false),
        }
    }

    /// 获取文件大小
    pub async fn get_file_size<P: AsRef<Path>>(file_path: P) -> Result<u64> {
        let metadata = fs::metadata(file_path).await?;
        Ok(metadata.len())
    }

    /// 创建目录（如果不存在）
    pub async fn ensure_dir_exists<P: AsRef<Path>>(dir_path: P) -> Result<()> {
        let dir_path = dir_path.as_ref();
        
        if !dir_path.exists() {
            fs::create_dir_all(dir_path).await?;
            debug!("创建目录: {}", dir_path.display());
        }
        
        Ok(())
    }

    /// 检查路径是否可写
    pub fn is_writable<P: AsRef<Path>>(path: P) -> bool {
        let path = path.as_ref();
        
        if path.exists() {
            // 检查文件/目录权限
            match std::fs::metadata(path) {
                Ok(metadata) => !metadata.permissions().readonly(),
                Err(_) => false,
            }
        } else {
            // 检查父目录是否可写
            if let Some(parent) = path.parent() {
                Self::is_writable(parent)
            } else {
                false
            }
        }
    }

    /// 安全地移动文件
    pub async fn safe_move<P: AsRef<Path>>(from: P, to: P) -> Result<()> {
        let from = from.as_ref();
        let to = to.as_ref();

        // 确保目标目录存在
        if let Some(parent) = to.parent() {
            Self::ensure_dir_exists(parent).await?;
        }

        // 先复制，再删除原文件
        fs::copy(from, to).await?;
        fs::remove_file(from).await?;

        debug!("文件移动成功: {} -> {}", from.display(), to.display());
        Ok(())
    }

    /// 计算目录大小
    pub fn calculate_dir_size<P: AsRef<Path>>(dir_path: P) -> Result<u64> {
        let dir_path = dir_path.as_ref();
        let mut total_size = 0;

        for entry in WalkDir::new(dir_path)
            .into_iter()
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().is_file())
        {
            if let Ok(metadata) = entry.metadata() {
                total_size += metadata.len();
            }
        }

        Ok(total_size)
    }
}
