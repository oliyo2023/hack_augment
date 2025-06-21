use crate::core::{types::*, Result, AugmentError};
use crate::filesystem::FileOperations;
use crate::idgen::IdGenerator;
use crate::config::ConfigGenerator;
use log::{debug, info, warn, error};
use rusqlite::{Connection, params};
use std::path::Path;

/// 数据库管理器
pub struct DatabaseManager;

impl DatabaseManager {
    /// 清理单个数据库中的 Augment 相关记录
    pub async fn clean_database(db_path: &DatabasePath) -> Result<DatabaseCleanResult> {
        let db_path_str = db_path.path.to_string_lossy().to_string();
        
        info!("开始清理 {} 数据库: {}", db_path.editor_type, db_path_str);

        if !db_path.exists {
            warn!("数据库文件不存在: {}", db_path_str);
            return Ok(DatabaseCleanResult::failure(
                db_path_str,
                "数据库文件不存在".to_string(),
                db_path.editor_type.clone(),
            ));
        }

        // 验证是否为有效的 SQLite 文件
        if !FileOperations::is_valid_sqlite_file(&db_path.path).await? {
            warn!("不是有效的 SQLite 文件: {}", db_path_str);
            return Ok(DatabaseCleanResult::failure(
                db_path_str,
                "不是有效的 SQLite 文件".to_string(),
                db_path.editor_type.clone(),
            ));
        }

        // 创建备份
        let backup_result = FileOperations::backup_file(&db_path.path).await?;
        let backup_path = if backup_result.success {
            Some(backup_result.backup_path)
        } else {
            warn!("备份失败: {}", backup_result.error.unwrap_or_default());
            None
        };

        // 执行数据库清理
        match Self::perform_database_cleanup(&db_path.path).await {
            Ok(deleted_count) => {
                info!(
                    "{} 数据库清理完成，删除了 {} 条记录",
                    db_path.editor_type, deleted_count
                );

                // 如果清理了记录，生成新的配置文件
                if deleted_count > 0 {
                    match Self::generate_new_configs(db_path).await {
                        Ok(config_result) => {
                            if config_result.success {
                                info!("✅ 新配置文件生成成功: {:?}", config_result.generated_configs);
                            } else {
                                warn!("⚠️ 配置文件生成失败: {:?}", config_result.error);
                            }
                        }
                        Err(e) => {
                            warn!("⚠️ 配置文件生成过程中出错: {}", e);
                        }
                    }
                }

                Ok(DatabaseCleanResult::success(
                    db_path_str,
                    backup_path,
                    deleted_count,
                    db_path.editor_type.clone(),
                ))
            }
            Err(e) => {
                error!("数据库清理失败: {} - {}", db_path_str, e);
                Ok(DatabaseCleanResult::failure(
                    db_path_str,
                    e.to_string(),
                    db_path.editor_type.clone(),
                ))
            }
        }
    }

    /// 执行实际的数据库清理操作
    async fn perform_database_cleanup<P: AsRef<Path>>(db_path: P) -> Result<u32> {
        let db_path = db_path.as_ref();
        
        // 在异步上下文中使用 spawn_blocking 来执行同步的数据库操作
        let db_path_owned = db_path.to_owned();
        
        tokio::task::spawn_blocking(move || {
            Self::cleanup_database_sync(&db_path_owned)
        }).await.map_err(|e| {
            AugmentError::internal(format!("数据库操作任务失败: {}", e))
        })?
    }

    /// 同步的数据库清理操作
    fn cleanup_database_sync<P: AsRef<Path>>(db_path: P) -> Result<u32> {
        let db_path = db_path.as_ref();

        debug!("开始清理数据库: {}", db_path.display());

        // 打开数据库连接
        let conn = Connection::open(db_path)?;

        // 设置数据库连接参数
        conn.execute("PRAGMA foreign_keys = OFF", [])?;

        // PRAGMA journal_mode 会返回结果，所以我们使用 query_row 而不是 execute
        let _journal_mode: String = conn.query_row("PRAGMA journal_mode = WAL", [], |row| {
            Ok(row.get::<_, String>(0)?)
        })?;

        // 检查 ItemTable 表是否存在
        let table_exists = Self::check_table_exists(&conn, "ItemTable")?;

        if !table_exists {
            debug!("ItemTable 表不存在，跳过清理");
            return Ok(0);
        }

        // 开始事务
        let tx = conn.unchecked_transaction()?;

        // 查询要删除的记录数
        let count_query = "SELECT COUNT(*) FROM ItemTable WHERE key LIKE '%augment%'";
        let deleted_count: u32 = tx.query_row(count_query, [], |row| {
            Ok(row.get::<_, u32>(0)?)
        })?;

        debug!("找到 {} 条 Augment 相关记录", deleted_count);

        if deleted_count > 0 {
            // 执行删除操作
            let delete_query = "DELETE FROM ItemTable WHERE key LIKE '%augment%'";
            let affected_rows = tx.execute(delete_query, [])?;

            debug!("实际删除了 {} 条记录", affected_rows);

            // 验证删除结果
            let verify_count: u32 = tx.query_row(count_query, [], |row| {
                Ok(row.get::<_, u32>(0)?)
            })?;

            if verify_count > 0 {
                warn!("删除操作可能不完整，仍有 {} 条记录", verify_count);
            }
        }

        // 提交事务
        tx.commit()?;

        Ok(deleted_count)
    }

    /// 生成新的配置文件
    pub async fn generate_new_configs(db_path: &DatabasePath) -> Result<ConfigProcessResult> {
        info!("为 {} 生成新的配置文件", db_path.editor_type);

        // 生成新的账户配置
        let account_config = IdGenerator::generate_account_config()?;

        let mut processed_files = Vec::new();
        let mut generated_configs = Vec::new();

        // 根据编辑器类型生成相应的配置
        match db_path.editor_type {
            EditorType::VSCode => {
                let config = ConfigGenerator::create_vscode_config(&account_config)?;
                let config_path = db_path.path.parent()
                    .ok_or_else(|| AugmentError::internal("无法获取父目录".to_string()))?
                    .join("augment_config.json");

                let config_content = serde_json::to_string_pretty(&config)
                    .map_err(|e| AugmentError::Json(e))?;

                tokio::fs::write(&config_path, config_content).await
                    .map_err(|e| AugmentError::filesystem(e))?;

                processed_files.push(config_path.display().to_string());
                generated_configs.push("VSCode Augment Config".to_string());
            }
            EditorType::Cursor => {
                let config = ConfigGenerator::create_cursor_config(&account_config)?;
                let config_path = db_path.path.parent()
                    .ok_or_else(|| AugmentError::internal("无法获取父目录".to_string()))?
                    .join("augment_config.json");

                let config_content = serde_json::to_string_pretty(&config)
                    .map_err(|e| AugmentError::Json(e))?;

                tokio::fs::write(&config_path, config_content).await
                    .map_err(|e| AugmentError::filesystem(e))?;

                processed_files.push(config_path.display().to_string());
                generated_configs.push("Cursor Augment Config".to_string());
            }
            EditorType::Void => {
                let config = ConfigGenerator::create_generic_config(&account_config)?;
                let config_path = db_path.path.parent()
                    .ok_or_else(|| AugmentError::internal("无法获取父目录".to_string()))?
                    .join("augment_config.json");

                let config_content = serde_json::to_string_pretty(&config)
                    .map_err(|e| AugmentError::Json(e))?;

                tokio::fs::write(&config_path, config_content).await
                    .map_err(|e| AugmentError::filesystem(e))?;

                processed_files.push(config_path.display().to_string());
                generated_configs.push("Void Augment Config".to_string());
            }
            EditorType::JetBrains => {
                // JetBrains 使用不同的配置方式，在 jetbrains 模块中处理
                info!("JetBrains 配置将在专门的模块中处理");
            }
        }

        info!("配置文件生成完成，处理了 {} 个文件", processed_files.len());
        Ok(ConfigProcessResult::success(processed_files, generated_configs))
    }

    /// 检查数据库表是否存在
    fn check_table_exists(conn: &Connection, table_name: &str) -> Result<bool> {
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?";
        let mut stmt = conn.prepare(query)?;
        
        let rows: rusqlite::Result<Vec<String>> = stmt
            .query_map(params![table_name], |row| {
                Ok(row.get::<_, String>(0)?)
            })?
            .collect();
        
        match rows {
            Ok(results) => Ok(!results.is_empty()),
            Err(e) => {
                debug!("检查表存在性时出错: {}", e);
                Ok(false)
            }
        }
    }

    /// 清理所有数据库
    pub async fn clean_all_databases(options: &CleanOptions) -> Result<Vec<DatabaseCleanResult>> {
        let db_paths = crate::filesystem::PathManager::get_database_paths(options)?;
        let mut results = Vec::new();

        if db_paths.is_empty() {
            info!("未找到需要处理的数据库文件");
            return Ok(results);
        }

        info!("找到 {} 个数据库文件需要处理", db_paths.len());

        // 并发处理多个数据库（限制并发数）
        let semaphore = std::sync::Arc::new(tokio::sync::Semaphore::new(3)); // 最多同时处理3个数据库
        let mut tasks = Vec::new();

        for db_path in db_paths {
            let semaphore = semaphore.clone();
            let task = tokio::spawn(async move {
                let _permit = semaphore.acquire().await.unwrap();
                Self::clean_database(&db_path).await
            });
            tasks.push(task);
        }

        // 等待所有任务完成
        for task in tasks {
            match task.await {
                Ok(result) => {
                    match result {
                        Ok(clean_result) => results.push(clean_result),
                        Err(e) => {
                            error!("数据库清理任务失败: {}", e);
                            results.push(DatabaseCleanResult::failure(
                                "未知路径".to_string(),
                                e.to_string(),
                                EditorType::VSCode, // 默认类型
                            ));
                        }
                    }
                }
                Err(e) => {
                    error!("任务执行失败: {}", e);
                    results.push(DatabaseCleanResult::failure(
                        "未知路径".to_string(),
                        format!("任务执行失败: {}", e),
                        EditorType::VSCode, // 默认类型
                    ));
                }
            }
        }

        let success_count = results.iter().filter(|r| r.success).count();
        let total_deleted: u32 = results.iter().map(|r| r.deleted_records).sum();

        info!(
            "数据库清理完成：成功 {}/{} 个，共删除 {} 条记录",
            success_count,
            results.len(),
            total_deleted
        );

        Ok(results)
    }

    /// 获取数据库统计信息
    pub async fn get_database_stats(db_path: &DatabasePath) -> Result<DatabaseStats> {
        if !db_path.exists {
            return Ok(DatabaseStats::default());
        }

        let db_path_owned = db_path.path.clone();

        // 先获取文件大小
        let file_size = FileOperations::get_file_size(&db_path_owned).await.unwrap_or(0);

        // 然后在阻塞任务中获取数据库统计信息
        let mut stats = tokio::task::spawn_blocking(move || {
            Self::get_database_stats_sync(&db_path_owned)
        }).await.map_err(|e| {
            AugmentError::internal(format!("获取数据库统计信息失败: {}", e))
        })??;

        // 设置文件大小
        stats.file_size = file_size;

        Ok(stats)
    }

    /// 同步获取数据库统计信息
    fn get_database_stats_sync<P: AsRef<Path>>(db_path: P) -> Result<DatabaseStats> {
        let conn = Connection::open(db_path.as_ref())?;

        let mut stats = DatabaseStats::default();

        // 检查表是否存在
        if !Self::check_table_exists(&conn, "ItemTable")? {
            return Ok(stats);
        }

        // 获取总记录数
        let total_count: u32 = conn.query_row(
            "SELECT COUNT(*) FROM ItemTable",
            [],
            |row| Ok(row.get::<_, u32>(0)?)
        )?;

        // 获取 Augment 相关记录数
        let augment_count: u32 = conn.query_row(
            "SELECT COUNT(*) FROM ItemTable WHERE key LIKE '%augment%'",
            [],
            |row| Ok(row.get::<_, u32>(0)?)
        )?;

        stats.total_records = total_count;
        stats.augment_records = augment_count;

        Ok(stats)
    }
}

/// 数据库统计信息
#[derive(Debug, Clone, Default)]
pub struct DatabaseStats {
    pub total_records: u32,
    pub augment_records: u32,
    pub file_size: u64,
}
