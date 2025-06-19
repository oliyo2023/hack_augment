##[
Augment Reset - ID生成模块

生成安全的随机ID和账户配置
]##

import std/[random, times, strformat, logging, strutils]
import types

# ============================================================================
# 随机字符串生成
# ============================================================================

# 生成安全的随机字符串
proc generateSecureRandomString*(length: int, useUppercase: bool = false): string =
  try:
    randomize()
    result = ""
    for i in 0..<length:
      let hexChar = toHex(rand(15), 1)
      result.add(if useUppercase: hexChar else: hexChar.toLower())
  except:
    # 如果随机生成失败，使用时间戳作为后备
    let timestamp = $now().toTime().toUnix()
    result = timestamp.repeat(length div timestamp.len + 1)[0..<length]

# ============================================================================
# 各种ID生成
# ============================================================================

# 生成设备ID
proc generateDeviceId*(): string =
  try:
    result = generateSecureRandomString(DEVICE_ID_LENGTH)
    info fmt"生成新设备ID: {result[0..7]}..."
  except Exception as e:
    error fmt"生成设备ID失败: {e.msg}"
    result = "fallback_device_" & $now().toTime().toUnix()

# 生成用户ID
proc generateUserId*(): string =
  try:
    result = generateSecureRandomString(USER_ID_LENGTH)
    info fmt"生成新用户ID: {result[0..7]}..."
  except Exception as e:
    error fmt"生成用户ID失败: {e.msg}"
    result = "fallback_user_" & $now().toTime().toUnix()

# 生成会话ID
proc generateSessionId*(): string =
  try:
    result = generateSecureRandomString(SESSION_ID_LENGTH)
    info fmt"生成新会话ID: {result[0..7]}..."
  except Exception as e:
    error fmt"生成会话ID失败: {e.msg}"
    result = "fallback_session_" & $now().toTime().toUnix()

# 生成随机邮箱
proc generateEmail*(): string =
  try:
    let randomString = generateSecureRandomString(EMAIL_RANDOM_LENGTH)
    result = fmt"user_{randomString}@example.com"
    info fmt"生成新邮箱: {result}"
  except Exception as e:
    error fmt"生成邮箱失败: {e.msg}"
    result = fmt"fallback_user_{now().toTime().toUnix()}@example.com"

# ============================================================================
# 账户配置生成
# ============================================================================

# 生成完整的账户配置
proc generateAccountConfig*(): AugmentConfig =
  try:
    let now = now()
    result = AugmentConfig(
      deviceId: generateDeviceId(),
      userId: generateUserId(),
      email: generateEmail(),
      sessionId: generateSessionId(),
      trialStartDate: now,
      trialEndDate: now + TRIAL_DURATION_DAYS.days,
      trialCount: 0,
      resetHistory: @[now]
    )
    info "生成新账户配置完成"
  except Exception as e:
    error fmt"生成账户配置失败: {e.msg}"
    # 返回一个基本的配置作为后备
    let timestamp = $now().toTime().toUnix()
    result = AugmentConfig(
      deviceId: "fallback_device_" & timestamp,
      userId: "fallback_user_" & timestamp,
      email: fmt"fallback_user_{timestamp}@example.com",
      sessionId: "fallback_session_" & timestamp,
      trialStartDate: now(),
      trialEndDate: now() + TRIAL_DURATION_DAYS.days,
      trialCount: 0,
      resetHistory: @[now()]
    )
