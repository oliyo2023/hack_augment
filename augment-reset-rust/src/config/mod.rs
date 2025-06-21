//! # 配置文件生成模块
//! 
//! 生成各种类型的配置文件内容，用于重置Augment相关数据

use crate::core::Result;
use crate::idgen::AugmentConfig;
use serde_json::{json, Value};
use log::info;

/// 配置文件类型
#[derive(Debug, Clone, PartialEq)]
pub enum ConfigFileType {
    /// 状态配置文件
    State,
    /// 订阅配置文件
    Subscription,
    /// 账户配置文件
    Account,
    /// 通用JSON配置
    Generic,
}

/// 配置文件生成器
pub struct ConfigGenerator;

impl ConfigGenerator {
    /// 根据配置文件类型创建配置内容
    pub fn create_config_by_type(
        file_type: ConfigFileType,
        account_config: &AugmentConfig,
    ) -> Result<Value> {
        match file_type {
            ConfigFileType::State => Self::create_state_config(account_config),
            ConfigFileType::Subscription => Self::create_subscription_config(account_config),
            ConfigFileType::Account => Self::create_account_config(account_config),
            ConfigFileType::Generic => Self::create_generic_config(account_config),
        }
    }

    /// 创建状态配置文件
    fn create_state_config(account_config: &AugmentConfig) -> Result<Value> {
        let config = json!({
            "deviceId": account_config.device_id,
            "userId": account_config.user_id,
            "sessionId": account_config.session_id,
            "lastActivity": account_config.trial_start_date.timestamp(),
            "settings": {
                "theme": "dark",
                "language": "en",
                "autoSave": true
            },
            "augment": {
                "enabled": true,
                "trialStartDate": account_config.trial_start_date.to_rfc3339(),
                "trialEndDate": account_config.trial_end_date.to_rfc3339(),
                "trialCount": account_config.trial_count,
                "features": {
                    "codeCompletion": true,
                    "chatAssistant": true,
                    "codeReview": true
                }
            },
            "telemetry": {
                "enabled": false,
                "deviceId": account_config.device_id,
                "sessionId": account_config.session_id
            }
        });

        info!("创建状态配置文件");
        Ok(config)
    }

    /// 创建订阅配置文件
    fn create_subscription_config(account_config: &AugmentConfig) -> Result<Value> {
        let config = json!({
            "subscription": {
                "type": "trial",
                "status": "active",
                "startDate": account_config.trial_start_date.to_rfc3339(),
                "endDate": account_config.trial_end_date.to_rfc3339(),
                "daysRemaining": 14,
                "features": [
                    "code_completion",
                    "chat_assistant",
                    "code_review",
                    "refactoring"
                ]
            },
            "user": {
                "id": account_config.user_id,
                "email": account_config.email,
                "deviceId": account_config.device_id,
                "registrationDate": account_config.trial_start_date.to_rfc3339()
            },
            "billing": {
                "currency": "USD",
                "nextBillingDate": null,
                "paymentMethod": null
            },
            "usage": {
                "requestsThisMonth": 0,
                "requestsTotal": 0,
                "lastRequestDate": null
            }
        });

        info!("创建订阅配置文件");
        Ok(config)
    }

    /// 创建账户配置文件
    fn create_account_config(account_config: &AugmentConfig) -> Result<Value> {
        let config = json!({
            "account": {
                "id": account_config.user_id,
                "email": account_config.email,
                "displayName": format!("User_{}", &account_config.user_id[0..8]),
                "avatar": null,
                "createdAt": account_config.trial_start_date.to_rfc3339(),
                "lastLoginAt": account_config.trial_start_date.to_rfc3339()
            },
            "device": {
                "id": account_config.device_id,
                "name": "Development Machine",
                "type": "desktop",
                "os": std::env::consts::OS,
                "registeredAt": account_config.trial_start_date.to_rfc3339()
            },
            "session": {
                "id": account_config.session_id,
                "startedAt": account_config.trial_start_date.to_rfc3339(),
                "expiresAt": account_config.trial_end_date.to_rfc3339(),
                "isActive": true
            },
            "preferences": {
                "notifications": true,
                "analytics": false,
                "autoUpdate": true,
                "theme": "system"
            },
            "trial": {
                "isActive": true,
                "startDate": account_config.trial_start_date.to_rfc3339(),
                "endDate": account_config.trial_end_date.to_rfc3339(),
                "daysUsed": 0,
                "resetCount": account_config.trial_count
            }
        });

        info!("创建账户配置文件");
        Ok(config)
    }

    /// 创建通用配置文件
    pub fn create_generic_config(account_config: &AugmentConfig) -> Result<Value> {
        let config = json!({
            "version": "2.0",
            "deviceId": account_config.device_id,
            "userId": account_config.user_id,
            "email": account_config.email,
            "sessionId": account_config.session_id,
            "timestamp": account_config.trial_start_date.to_rfc3339(),
            "trial": {
                "active": true,
                "startDate": account_config.trial_start_date.to_rfc3339(),
                "endDate": account_config.trial_end_date.to_rfc3339(),
                "count": account_config.trial_count
            },
            "features": {
                "augment": true,
                "premium": false
            },
            "metadata": {
                "platform": std::env::consts::OS,
                "arch": std::env::consts::ARCH,
                "resetHistory": account_config.reset_history.iter()
                    .map(|dt| dt.to_rfc3339())
                    .collect::<Vec<_>>()
            }
        });

        info!("创建通用配置文件");
        Ok(config)
    }

    /// 从文件路径推断配置文件类型
    pub fn infer_config_type_from_path(path: &str) -> ConfigFileType {
        let path_lower = path.to_lowercase();
        
        if path_lower.contains("state") {
            ConfigFileType::State
        } else if path_lower.contains("subscription") {
            ConfigFileType::Subscription
        } else if path_lower.contains("account") {
            ConfigFileType::Account
        } else {
            ConfigFileType::Generic
        }
    }

    /// 创建VSCode特定的配置
    pub fn create_vscode_config(account_config: &AugmentConfig) -> Result<Value> {
        let config = json!({
            "augment.deviceId": account_config.device_id,
            "augment.userId": account_config.user_id,
            "augment.sessionId": account_config.session_id,
            "augment.email": account_config.email,
            "augment.trial": {
                "startDate": account_config.trial_start_date.to_rfc3339(),
                "endDate": account_config.trial_end_date.to_rfc3339(),
                "isActive": true
            },
            "augment.features": {
                "codeCompletion": true,
                "chatAssistant": true,
                "codeReview": true
            },
            "augment.telemetry": {
                "enabled": false,
                "deviceId": account_config.device_id
            }
        });

        info!("创建VSCode特定配置");
        Ok(config)
    }

    /// 创建Cursor特定的配置
    pub fn create_cursor_config(account_config: &AugmentConfig) -> Result<Value> {
        let config = json!({
            "cursor.deviceId": account_config.device_id,
            "cursor.userId": account_config.user_id,
            "cursor.sessionId": account_config.session_id,
            "cursor.email": account_config.email,
            "cursor.trial": {
                "startDate": account_config.trial_start_date.to_rfc3339(),
                "endDate": account_config.trial_end_date.to_rfc3339(),
                "isActive": true
            },
            "cursor.ai": {
                "enabled": true,
                "model": "gpt-4",
                "maxTokens": 4096
            },
            "cursor.privacy": {
                "telemetry": false,
                "analytics": false
            }
        });

        info!("创建Cursor特定配置");
        Ok(config)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::idgen::IdGenerator;

    #[test]
    fn test_create_state_config() {
        let account_config = IdGenerator::generate_account_config().unwrap();
        let config = ConfigGenerator::create_state_config(&account_config).unwrap();
        
        assert!(config["deviceId"].is_string());
        assert!(config["userId"].is_string());
        assert!(config["augment"]["enabled"].as_bool().unwrap());
    }

    #[test]
    fn test_create_subscription_config() {
        let account_config = IdGenerator::generate_account_config().unwrap();
        let config = ConfigGenerator::create_subscription_config(&account_config).unwrap();
        
        assert_eq!(config["subscription"]["type"], "trial");
        assert_eq!(config["subscription"]["status"], "active");
        assert!(config["user"]["email"].is_string());
    }

    #[test]
    fn test_infer_config_type() {
        assert_eq!(
            ConfigGenerator::infer_config_type_from_path("/path/to/state.json"),
            ConfigFileType::State
        );
        assert_eq!(
            ConfigGenerator::infer_config_type_from_path("/path/to/subscription.json"),
            ConfigFileType::Subscription
        );
        assert_eq!(
            ConfigGenerator::infer_config_type_from_path("/path/to/account.json"),
            ConfigFileType::Account
        );
        assert_eq!(
            ConfigGenerator::infer_config_type_from_path("/path/to/config.json"),
            ConfigFileType::Generic
        );
    }
}
