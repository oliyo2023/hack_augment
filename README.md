# Augment Extension Trial Reset Tool

🔧 一个用于重置 Augment 编程扩展试用期的工具，支持 VS Code 和 Cursor 编辑器。

## 📋 功能特性

- ✅ **跨平台支持**：Windows、macOS、Linux
- ✅ **多编辑器支持**：VS Code 和 Cursor
- ✅ **自动进程管理**：自动检测并关闭运行中的编辑器
- ✅ **安全备份**：重置前自动备份现有配置
- ✅ **随机生成**：生成新的设备ID和用户ID
- ✅ **完整重置**：清除所有试用相关数据
- ✅ **双语言实现**：JavaScript 和 Nim 两个版本

## 🚀 快速开始

### JavaScript 版本

#### 前置要求
- Node.js (版本 12 或更高)

#### 使用方法
```bash
# 直接运行
node augment-reset.js

# 或者使用 npm
npm start
```

### Nim 版本

#### 前置要求
- Nim 编译器

#### 编译和运行
```bash
# 编译
nim c augment_reset.nim

# 运行
./augment_reset        # Linux/macOS
augment_reset.exe      # Windows
```

## 📁 项目结构

```
hack_augment/
├── README.md              # 项目说明文档
├── LICENSE               # 许可证文件
├── .gitignore           # Git 忽略规则
├── augment-reset.js     # JavaScript 版本
├── augment_reset.nim    # Nim 版本
└── augment_reset.exe    # 编译后的可执行文件（本地）
```

## 🔧 工作原理

1. **检测运行中的编辑器**：自动检测 VS Code 或 Cursor 是否正在运行
2. **安全关闭进程**：如果检测到编辑器运行，会尝试安全关闭
3. **备份配置文件**：在修改前创建配置文件的时间戳备份
4. **生成新身份**：创建新的设备ID、用户ID和邮箱
5. **重置试用数据**：清除所有试用相关的计数器和时间戳
6. **更新配置**：写入新的配置文件以重置试用期

## 📍 支持的配置路径

### Windows
- `%APPDATA%\Code\User\globalStorage\augment.augment\`
- `%APPDATA%\Cursor\User\globalStorage\augment.augment\`
- `%LOCALAPPDATA%\Code\User\globalStorage\augment.augment\`

### macOS
- `~/Library/Application Support/Code/User/globalStorage/augment.augment/`
- `~/Library/Application Support/Cursor/User/globalStorage/augment.augment/`
- `~/Library/Caches/Code/augment.augment/`

### Linux
- `~/.config/Code/User/globalStorage/augment.augment/`
- `~/.config/Cursor/User/globalStorage/augment.augment/`
- `~/.cache/Code/augment.augment/`

## ⚠️ 重要说明

1. **仅供学习研究**：本工具仅用于学习和研究目的
2. **备份重要数据**：使用前请备份重要的编辑器配置
3. **重启编辑器**：重置后需要重启 VS Code 或 Cursor
4. **网络环境**：如遇问题可尝试更换网络连接或使用VPN
5. **合规使用**：请遵守相关软件的使用条款

## 🛠️ 开发信息

- **原作者**：基于 @triallord 的 cursor-reset 项目
- **创建时间**：2025年6月2日
- **语言版本**：JavaScript (Node.js) 和 Nim
- **许可证**：MIT License

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests！

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## ⭐ 支持项目

如果这个项目对您有帮助，请给个 Star ⭐！

---

**免责声明**：本工具仅供学习和研究使用，使用者需自行承担使用风险。请遵守相关软件的使用条款和当地法律法规。
