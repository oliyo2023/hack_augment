//! # ID生成模块
//! 
//! 生成安全的随机ID和账户配置，用于重置Augment相关数据

use crate::core::Result;
use chrono::{DateTime, Utc, Duration};
use rand::{Rng, thread_rng};
use serde::{Deserialize, Serialize};
use log::{info, error};

/// ID生成配置常量
pub mod constants {
    /// 设备ID长度（64位十六进制）
    pub const DEVICE_ID_LENGTH: usize = 64;
    /// 用户ID长度（32位十六进制）
    pub const USER_ID_LENGTH: usize = 32;
    /// 会话ID长度（32位十六进制）
    pub const SESSION_ID_LENGTH: usize = 32;
    /// 邮箱随机部分长度
    pub const EMAIL_RANDOM_LENGTH: usize = 16;
    /// 试用期天数
    pub const TRIAL_DURATION_DAYS: i64 = 14;
}

/// Augment账户配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AugmentConfig {
    /// 设备ID
    pub device_id: String,
    /// 用户ID
    pub user_id: String,
    /// 邮箱地址
    pub email: String,
    /// 会话ID
    pub session_id: String,
    /// 试用开始日期
    pub trial_start_date: DateTime<Utc>,
    /// 试用结束日期
    pub trial_end_date: DateTime<Utc>,
    /// 试用次数
    pub trial_count: u32,
    /// 重置历史
    pub reset_history: Vec<DateTime<Utc>>,
}

/// ID生成器
pub struct IdGenerator;

impl IdGenerator {
    // Helper function to generate a 6-character random string starting with a letter
    fn generate_random_prefix() -> Result<String> {
        let mut rng = thread_rng();
        let first_char = rng.gen_range(b'a'..=b'z') as char;
        let mut prefix = String::with_capacity(6);
        prefix.push(first_char);

        for _ in 0..5 {
            let hex_char = rng.gen_range(0..16);
            let char = match hex_char {
                0..=9 => (b'0' + hex_char) as char,
                10..=15 => (b'a' + hex_char - 10) as char,
                _ => unreachable!(),
            };
            prefix.push(char);
        }
        Ok(prefix)
    }

    /// 生成安全的随机十六进制字符串
    fn generate_secure_random_string(length: usize, uppercase: bool) -> Result<String> {
        let mut rng = thread_rng();
        let mut result = String::with_capacity(length);
        
        for _ in 0..length {
            let hex_char = rng.gen_range(0..16);
            let char = match hex_char {
                0..=9 => (b'0' + hex_char) as char,
                10..=15 => {
                    let base = if uppercase { b'A' } else { b'a' };
                    (base + hex_char - 10) as char
                }
                _ => unreachable!(),
            };
            result.push(char);
        }
        
        Ok(result)
    }

    /// 生成设备ID
    pub fn generate_device_id() -> Result<String> {
        match Self::generate_secure_random_string(constants::DEVICE_ID_LENGTH, false) {
            Ok(device_id) => {
                info!("生成新设备ID: {}...", &device_id[0..8]);
                Ok(device_id)
            }
            Err(e) => {
                error!("生成设备ID失败: {}", e);
                // 使用时间戳作为后备方案
                let timestamp = Utc::now().timestamp();
                Ok(format!("fallback_device_{}", timestamp))
            }
        }
    }

    /// 生成用户ID
    pub fn generate_user_id() -> Result<String> {
        match Self::generate_secure_random_string(constants::USER_ID_LENGTH, false) {
            Ok(user_id) => {
                info!("生成新用户ID: {}...", &user_id[0..8]);
                Ok(user_id)
            }
            Err(e) => {
                error!("生成用户ID失败: {}", e);
                let timestamp = Utc::now().timestamp();
                Ok(format!("fallback_user_{}", timestamp))
            }
        }
    }

    /// 生成会话ID
    pub fn generate_session_id() -> Result<String> {
        match Self::generate_secure_random_string(constants::SESSION_ID_LENGTH, false) {
            Ok(session_id) => {
                info!("生成新会话ID: {}...", &session_id[0..8]);
                Ok(session_id)
            }
            Err(e) => {
                error!("生成会话ID失败: {}", e);
                let timestamp = Utc::now().timestamp();
                Ok(format!("fallback_session_{}", timestamp))
            }
        }
    }

    /// 生成随机邮箱
    pub fn generate_email() -> Result<String> {
        match Self::generate_random_prefix() { // Use the new helper function
            Ok(prefix) => {
                let email = format!("{}@gmail.com", prefix);
                info!("生成新邮箱: {}", email);
                Ok(email)
            }
            Err(e) => {
                error!("生成邮箱失败: {}", e);
                let timestamp = Utc::now().timestamp();
                Ok(format!("fallback_xspan_{}@gmail.com", timestamp)) // Fallback remains the same
            }
        }
    }

    /// 生成完整的账户配置
    pub fn generate_account_config() -> Result<AugmentConfig> {
        let now = Utc::now();
        
        let config = AugmentConfig {
            device_id: Self::generate_device_id()?,
            user_id: Self::generate_user_id()?,
            email: Self::generate_email()?,
            session_id: Self::generate_session_id()?,
            trial_start_date: now,
            trial_end_date: now + Duration::days(constants::TRIAL_DURATION_DAYS),
            trial_count: 0,
            reset_history: vec![now],
        };
        
        info!("生成新账户配置完成");
        Ok(config)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_device_id() {
        let device_id = IdGenerator::generate_device_id().unwrap();
        assert_eq!(device_id.len(), constants::DEVICE_ID_LENGTH);
        assert!(device_id.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_generate_user_id() {
        let user_id = IdGenerator::generate_user_id().unwrap();
        assert_eq!(user_id.len(), constants::USER_ID_LENGTH);
        assert!(user_id.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_generate_session_id() {
        let session_id = IdGenerator::generate_session_id().unwrap();
        assert_eq!(session_id.len(), constants::SESSION_ID_LENGTH);
        assert!(session_id.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_generate_email() {
        let email = IdGenerator::generate_email().unwrap();
        assert!(email.contains("@example.com"));
        assert!(email.starts_with("user_"));
    }

    #[test]
    fn test_generate_account_config() {
        let config = IdGenerator::generate_account_config().unwrap();
        assert!(!config.device_id.is_empty());
        assert!(!config.user_id.is_empty());
        assert!(!config.email.is_empty());
        assert!(!config.session_id.is_empty());
        assert!(config.trial_end_date > config.trial_start_date);
        assert_eq!(config.trial_count, 0);
        assert_eq!(config.reset_history.len(), 1);
    }

    #[test]
    fn test_secure_random_string() {
        let result = IdGenerator::generate_secure_random_string(32, false).unwrap();
        assert_eq!(result.len(), 32);
        assert!(result.chars().all(|c| c.is_ascii_hexdigit()));
        
        let result_upper = IdGenerator::generate_secure_random_string(16, true).unwrap();
        assert_eq!(result_upper.len(), 16);
        assert!(result_upper.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_uniqueness() {
        let id1 = IdGenerator::generate_device_id().unwrap();
        let id2 = IdGenerator::generate_device_id().unwrap();
        assert_ne!(id1, id2, "生成的ID应该是唯一的");
    }
}
