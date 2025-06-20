use augment_reset::{
    core::{types::*, Result},
    database::DatabaseManager,
    filesystem::FileOperations,
};
use rusqlite::Connection;
use std::path::PathBuf;
use tempfile::TempDir;

/// 创建测试数据库
fn create_test_database(path: &PathBuf) -> Result<()> {
    let conn = Connection::open(path)?;
    
    // 创建 ItemTable 表
    conn.execute(
        "CREATE TABLE IF NOT EXISTS ItemTable (
            id INTEGER PRIMARY KEY,
            key TEXT NOT NULL,
            value TEXT
        )",
        [],
    )?;

    // 插入测试数据
    conn.execute(
        "INSERT INTO ItemTable (key, value) VALUES (?, ?)",
        ["augment.test1", "test_value_1"],
    )?;
    
    conn.execute(
        "INSERT INTO ItemTable (key, value) VALUES (?, ?)",
        ["augment.test2", "test_value_2"],
    )?;
    
    conn.execute(
        "INSERT INTO ItemTable (key, value) VALUES (?, ?)",
        ["other.key", "other_value"],
    )?;

    Ok(())
}

#[tokio::test]
async fn test_database_cleanup() -> Result<()> {
    // 创建临时目录和数据库
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("test.db");

    // 创建测试数据库
    create_test_database(&db_path)?;

    // 验证数据库创建成功
    assert!(db_path.exists(), "测试数据库文件应该存在");

    // 创建数据库路径对象
    let database_path = DatabasePath::new(EditorType::VSCode, db_path.clone());
    assert!(database_path.exists, "DatabasePath 应该标记为存在");

    // 执行清理
    let result = DatabaseManager::clean_database(&database_path).await?;

    // 打印调试信息
    println!("清理结果: success={}, deleted_records={}, error={:?}",
             result.success, result.deleted_records, result.error);

    // 验证结果
    if !result.success {
        panic!("清理失败: {:?}", result.error);
    }

    assert!(result.success, "清理应该成功");
    assert_eq!(result.deleted_records, 2, "应该删除2条 augment 相关记录");
    assert!(result.backup_path.is_some(), "应该有备份路径");

    // 验证数据库中的记录
    let conn = Connection::open(&db_path)?;
    let count: u32 = conn.query_row(
        "SELECT COUNT(*) FROM ItemTable WHERE key LIKE '%augment%'",
        [],
        |row| Ok(row.get::<_, u32>(0)?),
    )?;
    assert_eq!(count, 0, "应该没有 augment 相关记录了");

    let total_count: u32 = conn.query_row(
        "SELECT COUNT(*) FROM ItemTable",
        [],
        |row| Ok(row.get::<_, u32>(0)?),
    )?;
    assert_eq!(total_count, 1, "应该还有1条其他记录");

    Ok(())
}

#[tokio::test]
async fn test_file_backup() -> Result<()> {
    // 创建临时文件
    let temp_dir = TempDir::new().unwrap();
    let test_file = temp_dir.path().join("test.txt");
    
    // 写入测试内容
    tokio::fs::write(&test_file, "test content").await?;
    
    // 执行备份
    let backup_result = FileOperations::backup_file(&test_file).await?;
    
    // 验证备份结果
    assert!(backup_result.success);
    assert!(PathBuf::from(&backup_result.backup_path).exists());
    
    // 验证备份内容
    let backup_content = tokio::fs::read_to_string(&backup_result.backup_path).await?;
    assert_eq!(backup_content, "test content");

    Ok(())
}

#[tokio::test]
async fn test_sqlite_file_validation() -> Result<()> {
    let temp_dir = TempDir::new().unwrap();
    
    // 测试有效的 SQLite 文件
    let valid_db = temp_dir.path().join("valid.db");
    create_test_database(&valid_db)?;
    assert!(FileOperations::is_valid_sqlite_file(&valid_db).await?);
    
    // 测试无效文件
    let invalid_file = temp_dir.path().join("invalid.txt");
    tokio::fs::write(&invalid_file, "not a sqlite file").await?;
    assert!(!FileOperations::is_valid_sqlite_file(&invalid_file).await?);
    
    // 测试不存在的文件
    let nonexistent = temp_dir.path().join("nonexistent.db");
    assert!(!FileOperations::is_valid_sqlite_file(&nonexistent).await?);

    Ok(())
}

#[tokio::test]
async fn test_clean_options() {
    let options = CleanOptions::default();
    
    assert!(options.clean_vscode);
    assert!(options.clean_cursor);
    assert!(options.clean_jetbrains);
    assert!(options.clean_void);
    assert!(options.backup);
    assert!(options.interactive);
    assert!(!options.force);
    
    assert!(options.has_any_editor_selected());
    
    let selected_editors = options.get_selected_editors();
    assert_eq!(selected_editors.len(), 4);
}

#[tokio::test]
async fn test_database_stats() -> Result<()> {
    // 创建临时数据库
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("stats_test.db");
    
    create_test_database(&db_path)?;
    
    let database_path = DatabasePath::new(EditorType::VSCode, db_path);
    let stats = DatabaseManager::get_database_stats(&database_path).await?;
    
    assert_eq!(stats.total_records, 3);
    assert_eq!(stats.augment_records, 2);
    assert!(stats.file_size > 0);

    Ok(())
}

#[tokio::test]
async fn test_concurrent_database_cleanup() -> Result<()> {
    // 创建多个测试数据库
    let temp_dir = TempDir::new().unwrap();
    let mut db_paths = Vec::new();

    for i in 0..3 {
        let db_path = temp_dir.path().join(format!("test_{}.db", i));
        create_test_database(&db_path)?;
        db_paths.push(DatabasePath::new(EditorType::VSCode, db_path));
    }

    // 验证所有数据库都存在
    for db_path in &db_paths {
        assert!(db_path.exists, "测试数据库 {} 应该存在", db_path.path.display());
    }

    // 这里我们不能直接测试 clean_all_databases，因为它依赖于系统路径
    // 但我们可以测试单个数据库的并发清理
    let mut tasks = Vec::new();

    for db_path in db_paths {
        let task = tokio::spawn(async move {
            DatabaseManager::clean_database(&db_path).await
        });
        tasks.push(task);
    }

    // 等待所有任务完成
    let mut success_count = 0;
    for task in tasks {
        let result = task.await.unwrap()?;
        println!("并发清理结果: success={}, deleted_records={}, error={:?}",
                 result.success, result.deleted_records, result.error);
        if result.success {
            success_count += 1;
        }
    }

    assert_eq!(success_count, 3, "所有3个数据库都应该清理成功");

    Ok(())
}

#[tokio::test]
async fn test_error_handling() {
    // 测试不存在的数据库文件
    let nonexistent_path = DatabasePath::new(
        EditorType::VSCode,
        PathBuf::from("/nonexistent/path/test.db"),
    );
    
    let result = DatabaseManager::clean_database(&nonexistent_path).await.unwrap();
    assert!(!result.success);
    assert!(result.error.is_some());
}

#[test]
fn test_editor_type_display() {
    assert_eq!(EditorType::VSCode.to_string(), "VS Code");
    assert_eq!(EditorType::Cursor.to_string(), "Cursor");
    assert_eq!(EditorType::JetBrains.to_string(), "JetBrains");
    assert_eq!(EditorType::Void.to_string(), "Void");
}

#[test]
fn test_database_clean_result() {
    let success_result = DatabaseCleanResult::success(
        "test.db".to_string(),
        Some("backup.db".to_string()),
        5,
        EditorType::VSCode,
    );
    
    assert!(success_result.success);
    assert_eq!(success_result.deleted_records, 5);
    assert!(success_result.backup_path.is_some());
    assert!(success_result.error.is_none());
    
    let failure_result = DatabaseCleanResult::failure(
        "test.db".to_string(),
        "Test error".to_string(),
        EditorType::Cursor,
    );
    
    assert!(!failure_result.success);
    assert_eq!(failure_result.deleted_records, 0);
    assert!(failure_result.backup_path.is_none());
    assert!(failure_result.error.is_some());
}
