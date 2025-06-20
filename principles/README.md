# 原理和历史版本

本目录包含 Augment Reset Tool 的原理说明和历史版本实现。

## 📁 文件说明

### 历史版本

- **`augment_reset_legacy.nim`** - Nim 单文件版本（v1.0）
  - 主要功能：配置文件重置 + 数据库清理
  - 支持平台：Windows、macOS、Linux
  - 实现方式：单文件 76,834 行代码
  - 状态：已重构为模块化版本

- **`ResetAugment.py`** - Python 版本的重置工具
  - 主要功能：SQLite 数据库清理
  - 支持平台：Windows、macOS、Linux
  - 实现方式：直接操作数据库文件

- **`augment-reset.js`** - JavaScript 版本的重置工具
  - 主要功能：配置文件重置
  - 支持平台：跨平台（Node.js）
  - 实现方式：文件系统操作

## 🔍 工作原理

### Augment 扩展的存储机制

Augment 扩展将试用期信息存储在两个地方：

1. **配置文件** (JSON格式)
   - 位置：`%APPDATA%/[Editor]/User/globalStorage/augment.augment/`
   - 文件：`state.json`, `subscription.json`, `account.json`
   - 内容：设备ID、用户ID、试用期开始/结束时间

2. **SQLite 数据库**
   - 位置：`%APPDATA%/[Editor]/User/globalStorage/state.vscdb`
   - 表：`ItemTable`
   - 内容：包含 'augment' 关键字的记录

### 重置策略

#### 方法一：配置文件重置
```
1. 关闭编辑器进程
2. 备份现有配置文件
3. 生成新的随机设备ID和用户ID
4. 重写配置文件
5. 重启编辑器
```

#### 方法二：数据库清理
```
1. 关闭编辑器进程
2. 备份数据库文件
3. 连接 SQLite 数据库
4. 删除包含 'augment' 的记录
5. 重启编辑器
```

#### 方法三：混合方式（推荐）
```
1. 同时执行配置文件重置和数据库清理
2. 确保所有痕迹都被清除
3. 提供最高的成功率
```

## 🔄 版本演进

### v1.0 - JavaScript 版本
- ✅ 基本的配置文件重置
- ✅ 跨平台支持
- ❌ 缺少数据库清理

### v1.5 - Python 版本
- ✅ SQLite 数据库清理
- ✅ 更完善的备份机制
- ❌ 与 JS 版本功能重复

### v2.0 - Nim 版本（当前）
- ✅ 模块化架构
- ✅ 配置文件 + 数据库双重清理
- ✅ 完整的测试覆盖
- ✅ 专业级项目结构

## 🛠️ 技术细节

### 路径发现算法
```
Windows: %APPDATA%/[Editor]/...
macOS:   ~/Library/Application Support/[Editor]/...
Linux:   ~/.config/[Editor]/...
```

### ID 生成策略
- 设备ID：64位十六进制字符串
- 用户ID：32位十六进制字符串
- 邮箱：随机字符串 + @example.com

### 安全考虑
- 所有操作前自动备份
- 使用安全的随机数生成器
- 完整的错误处理和回滚机制

## 📚 参考资料

- [VS Code Extension API](https://code.visualstudio.com/api)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Nim Language Manual](https://nim-lang.org/docs/manual.html)

## ⚠️ 免责声明

这些工具仅用于学习和研究目的。请遵守软件许可协议和相关法律法规。
