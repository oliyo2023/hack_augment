use thiserror::Error;

/// 应用程序错误类型
#[derive(Error, Debug)]
pub enum AugmentError {
    #[error("数据库操作失败: {0}")]
    Database(#[from] rusqlite::Error),
    
    #[error("文件系统操作失败: {0}")]
    Filesystem(#[from] std::io::Error),
    
    #[error("JSON 序列化/反序列化失败: {0}")]
    Json(#[from] serde_json::Error),

    #[error("交互式输入失败: {0}")]
    Dialog(String),
    
    #[error("配置错误: {message}")]
    Config { message: String },
    
    #[error("编辑器未找到: {editor}")]
    EditorNotFound { editor: String },
    
    #[error("备份失败: {path} - {reason}")]
    BackupFailed { path: String, reason: String },
    
    #[error("数据库文件不存在: {path}")]
    DatabaseNotFound { path: String },
    
    #[error("权限不足: {operation}")]
    PermissionDenied { operation: String },
    
    #[error("操作被用户取消")]
    UserCancelled,
    
    #[error("无效的参数: {param} = {value}")]
    InvalidArgument { param: String, value: String },
    
    #[error("系统不支持: {feature}")]
    UnsupportedPlatform { feature: String },
    
    #[error("进程操作失败: {process} - {reason}")]
    ProcessError { process: String, reason: String },
    
    #[error("网络错误: {0}")]
    Network(String),
    
    #[error("超时错误: {operation} 超时 ({timeout_ms}ms)")]
    Timeout { operation: String, timeout_ms: u64 },
    
    #[error("内部错误: {message}")]
    Internal { message: String },
    
    #[error("未知错误: {0}")]
    Unknown(String),
}

impl AugmentError {
    /// 创建配置错误
    pub fn config<S: Into<String>>(message: S) -> Self {
        Self::Config {
            message: message.into(),
        }
    }

    /// 创建编辑器未找到错误
    pub fn editor_not_found<S: Into<String>>(editor: S) -> Self {
        Self::EditorNotFound {
            editor: editor.into(),
        }
    }

    /// 创建备份失败错误
    pub fn backup_failed<S: Into<String>>(path: S, reason: S) -> Self {
        Self::BackupFailed {
            path: path.into(),
            reason: reason.into(),
        }
    }

    /// 创建数据库不存在错误
    pub fn database_not_found<S: Into<String>>(path: S) -> Self {
        Self::DatabaseNotFound {
            path: path.into(),
        }
    }

    /// 创建权限不足错误
    pub fn permission_denied<S: Into<String>>(operation: S) -> Self {
        Self::PermissionDenied {
            operation: operation.into(),
        }
    }

    /// 创建无效参数错误
    pub fn invalid_argument<S: Into<String>>(param: S, value: S) -> Self {
        Self::InvalidArgument {
            param: param.into(),
            value: value.into(),
        }
    }

    /// 创建不支持的平台错误
    pub fn unsupported_platform<S: Into<String>>(feature: S) -> Self {
        Self::UnsupportedPlatform {
            feature: feature.into(),
        }
    }

    /// 创建进程错误
    pub fn process_error<S: Into<String>>(process: S, reason: S) -> Self {
        Self::ProcessError {
            process: process.into(),
            reason: reason.into(),
        }
    }

    /// 创建超时错误
    pub fn timeout<S: Into<String>>(operation: S, timeout_ms: u64) -> Self {
        Self::Timeout {
            operation: operation.into(),
            timeout_ms,
        }
    }

    /// 创建内部错误
    pub fn internal<S: Into<String>>(message: S) -> Self {
        Self::Internal {
            message: message.into(),
        }
    }

    /// 创建文件系统错误
    pub fn filesystem<E: Into<std::io::Error>>(error: E) -> Self {
        Self::Filesystem(error.into())
    }

    /// 创建系统错误
    pub fn system<S: Into<String>>(message: S) -> Self {
        Self::Internal {
            message: message.into(),
        }
    }

    /// 检查是否为致命错误
    pub fn is_fatal(&self) -> bool {
        matches!(
            self,
            Self::PermissionDenied { .. }
                | Self::UnsupportedPlatform { .. }
                | Self::Internal { .. }
        )
    }

    /// 检查是否为用户错误
    pub fn is_user_error(&self) -> bool {
        matches!(
            self,
            Self::UserCancelled
                | Self::InvalidArgument { .. }
                | Self::EditorNotFound { .. }
        )
    }

    /// 获取错误代码
    pub fn error_code(&self) -> i32 {
        match self {
            Self::Database(_) => 10,
            Self::Filesystem(_) => 11,
            Self::Json(_) => 12,
            Self::Dialog(_) => 13,
            Self::Config { .. } => 20,
            Self::EditorNotFound { .. } => 21,
            Self::BackupFailed { .. } => 22,
            Self::DatabaseNotFound { .. } => 23,
            Self::PermissionDenied { .. } => 30,
            Self::UserCancelled => 40,
            Self::InvalidArgument { .. } => 41,
            Self::UnsupportedPlatform { .. } => 50,
            Self::ProcessError { .. } => 51,
            Self::Network(_) => 60,
            Self::Timeout { .. } => 61,
            Self::Internal { .. } => 90,
            Self::Unknown(_) => 99,
        }
    }
}

// 为 dialoguer::Error 实现 From trait
impl From<dialoguer::Error> for AugmentError {
    fn from(err: dialoguer::Error) -> Self {
        Self::Dialog(err.to_string())
    }
}

/// 应用程序结果类型
pub type Result<T> = std::result::Result<T, AugmentError>;

/// 错误上下文扩展
pub trait ErrorContext<T> {
    fn with_context<F>(self, f: F) -> Result<T>
    where
        F: FnOnce() -> String;
}

impl<T, E> ErrorContext<T> for std::result::Result<T, E>
where
    E: Into<AugmentError>,
{
    fn with_context<F>(self, f: F) -> Result<T>
    where
        F: FnOnce() -> String,
    {
        self.map_err(|e| {
            let original_error = e.into();
            let context = f();
            AugmentError::internal(format!("{}: {}", context, original_error))
        })
    }
}
