##[
Augment Reset - 配置文件生成模块

生成各种类型的配置文件内容
]##

import std/[json, times, strformat, logging]
import types

# ============================================================================
# 配置文件生成
# ============================================================================

# 创建状态配置
proc createStateConfig*(config: AugmentConfig): JsonNode =
  try:
    result = %*{
      "deviceId": config.deviceId,
      "userId": config.userId,
      "email": config.email,
      "sessionId": config.sessionId,
      "trialStartDate": config.trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "trialEndDate": config.trialEndDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "trialDuration": TRIAL_DURATION_DAYS,
      "trialStatus": "active",
      "trialExpired": false,
      "trialRemainingDays": TRIAL_DURATION_DAYS,
      "trialCount": config.trialCount,
      "usageCount": 0,
      "totalUsageCount": 0,
      "lastUsageDate": nil,
      "messageCount": 0,
      "totalMessageCount": 0,
      "lastReset": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "firstRunDate": config.trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "lastRunDate": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "lastSessionDate": nil,
      "sessionHistory": newJArray(),
      "isFirstRun": true,
      "hasCompletedOnboarding": false,
      "hasUsedTrial": false,
      "preferences": %*{
        "theme": "light",
        "language": "en",
        "notifications": true
      },
      "tracking": %*{
        "lastCheck": nil,
        "checkCount": 0,
        "lastValidation": nil
      }
    }
  except Exception as e:
    error fmt"创建状态配置失败: {e.msg}"
    result = newJObject()

# 创建订阅配置
proc createSubscriptionConfig*(config: AugmentConfig): JsonNode =
  try:
    result = %*{
      "status": "active",
      "type": "trial",
      "startDate": config.trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "endDate": config.trialEndDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "isActive": true,
      "isExpired": false,
      "remainingDays": TRIAL_DURATION_DAYS,
      "trialCount": config.trialCount,
      "lastTrialReset": nil,
      "previousTrials": newJArray()
    }
  except Exception as e:
    error fmt"创建订阅配置失败: {e.msg}"
    result = newJObject()

# 创建账户配置
proc createAccountConfig*(config: AugmentConfig): JsonNode =
  try:
    result = %*{
      "userId": config.userId,
      "email": config.email,
      "deviceId": config.deviceId,
      "createdAt": config.trialStartDate.format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "lastLogin": now().format("yyyy-MM-dd'T'HH:mm:ss'.'fff'Z'"),
      "isActive": true,
      "trialHistory": newJArray(),
      "deviceHistory": newJArray()
    }
  except Exception as e:
    error fmt"创建账户配置失败: {e.msg}"
    result = newJObject()

# 根据文件类型创建配置
proc createConfigByType*(fileType: ConfigFileType, config: AugmentConfig): JsonNode =
  case fileType:
  of cfState:
    result = createStateConfig(config)
  of cfSubscription:
    result = createSubscriptionConfig(config)
  of cfAccount:
    result = createAccountConfig(config)
