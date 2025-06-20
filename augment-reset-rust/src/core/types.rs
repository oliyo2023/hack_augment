use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// 编辑器类型枚举
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum EditorType {
    VSCode,
    Cursor,
    JetBrains,
    Void,
}

impl std::fmt::Display for EditorType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            EditorType::VSCode => write!(f, "VS Code"),
            EditorType::Cursor => write!(f, "Cursor"),
            EditorType::JetBrains => write!(f, "JetBrains"),
            EditorType::Void => write!(f, "Void"),
        }
    }
}

/// 数据库路径信息
#[derive(Debug, Clone)]
pub struct DatabasePath {
    pub editor_type: EditorType,
    pub path: PathBuf,
    pub exists: bool,
}

impl DatabasePath {
    pub fn new(editor_type: EditorType, path: PathBuf) -> Self {
        let exists = path.exists();
        Self {
            editor_type,
            path,
            exists,
        }
    }
}

/// 数据库清理结果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseCleanResult {
    pub success: bool,
    pub db_path: String,
    pub backup_path: Option<String>,
    pub deleted_records: u32,
    pub error: Option<String>,
    pub timestamp: DateTime<Utc>,
    pub editor_type: String,
}

impl DatabaseCleanResult {
    pub fn success(
        db_path: String,
        backup_path: Option<String>,
        deleted_records: u32,
        editor_type: EditorType,
    ) -> Self {
        Self {
            success: true,
            db_path,
            backup_path,
            deleted_records,
            error: None,
            timestamp: Utc::now(),
            editor_type: editor_type.to_string(),
        }
    }

    pub fn failure(db_path: String, error: String, editor_type: EditorType) -> Self {
        Self {
            success: false,
            db_path,
            backup_path: None,
            deleted_records: 0,
            error: Some(error),
            timestamp: Utc::now(),
            editor_type: editor_type.to_string(),
        }
    }
}

/// 清理选项配置
#[derive(Debug, Clone)]
pub struct CleanOptions {
    pub clean_vscode: bool,
    pub clean_cursor: bool,
    pub clean_jetbrains: bool,
    pub clean_void: bool,
    pub interactive: bool,
    pub backup: bool,
    pub force: bool,
    pub verbose: bool,
}

impl Default for CleanOptions {
    fn default() -> Self {
        Self {
            clean_vscode: true,
            clean_cursor: true,
            clean_jetbrains: true,
            clean_void: true,
            interactive: true,
            backup: true,
            force: false,
            verbose: false,
        }
    }
}

impl CleanOptions {
    /// 检查是否选择了任何编辑器
    pub fn has_any_editor_selected(&self) -> bool {
        self.clean_vscode || self.clean_cursor || self.clean_jetbrains || self.clean_void
    }

    /// 获取选中的编辑器列表
    pub fn get_selected_editors(&self) -> Vec<EditorType> {
        let mut editors = Vec::new();
        if self.clean_vscode {
            editors.push(EditorType::VSCode);
        }
        if self.clean_cursor {
            editors.push(EditorType::Cursor);
        }
        if self.clean_jetbrains {
            editors.push(EditorType::JetBrains);
        }
        if self.clean_void {
            editors.push(EditorType::Void);
        }
        editors
    }
}

/// 备份结果
#[derive(Debug, Clone)]
pub struct BackupResult {
    pub success: bool,
    pub backup_path: String,
    pub original_path: String,
    pub timestamp: DateTime<Utc>,
    pub error: Option<String>,
}

impl BackupResult {
    pub fn success(backup_path: String, original_path: String) -> Self {
        Self {
            success: true,
            backup_path,
            original_path,
            timestamp: Utc::now(),
            error: None,
        }
    }

    pub fn failure(original_path: String, error: String) -> Self {
        Self {
            success: false,
            backup_path: String::new(),
            original_path,
            timestamp: Utc::now(),
            error: Some(error),
        }
    }
}

/// 操作结果的通用类型
#[derive(Debug, Clone)]
pub struct OperationResult<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
    pub timestamp: DateTime<Utc>,
}

impl<T> OperationResult<T> {
    pub fn success(data: T) -> Self {
        Self {
            success: true,
            data: Some(data),
            error: None,
            timestamp: Utc::now(),
        }
    }

    pub fn failure(error: String) -> Self {
        Self {
            success: false,
            data: None,
            error: Some(error),
            timestamp: Utc::now(),
        }
    }
}

/// 应用程序配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub version: String,
    pub backup_retention_days: u32,
    pub editor_close_wait_ms: u64,
    pub log_file: String,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            version: "2.2.0".to_string(),
            backup_retention_days: 30,
            editor_close_wait_ms: 2000,
            log_file: "augment_reset.log".to_string(),
        }
    }
}
