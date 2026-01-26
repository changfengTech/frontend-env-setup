# 前端开发环境配置脚本

一键配置前端开发环境的自动化脚本，支持 macOS 和 Windows 系统。

## 功能特性

- 🚀 **一键安装** - 自动安装所有必需的开发工具和应用
- 📦 **包管理器** - macOS 使用 Homebrew，Windows 使用 Scoop + Winget
- 🛠️ **开发工具** - Git、Node.js、pnpm、Docker 等
- 💻 **桌面应用** - VS Code、Chrome、终端工具等
- ⚙️ **环境配置** - Shell 配置、SSH Key、Git 配置
- 🎨 **终端美化** - Oh My Zsh (macOS) / Oh My Posh (Windows)

## 安装内容

### 命令行工具

| 工具 | 说明 |
|------|------|
| Git | 版本控制 |
| Python | Python 运行环境 |
| fnm | Node.js 版本管理器 |
| pnpm | 高性能包管理器 |
| Docker | 容器化平台 |
| MySQL | 数据库 |
| nrm | npm 源管理器 |

### 桌面应用程序

| 类别 | macOS | Windows |
|------|-------|---------|
| 浏览器 | Google Chrome | Google Chrome |
| 代码编辑器 | VS Code, Cursor | VS Code, Cursor |
| 终端 | iTerm2 | Windows Terminal |
| API 调试 | Charles, Apifox | Fiddler, Apifox |
| 移动开发 | Android Studio, Expo Orbit | Android Studio |
| 效率工具 | Alfred, Rectangle, Maccy | Everything, PowerToys, Ditto |
| Host 管理 | SwitchHosts | SwitchHosts |
| 截图工具 | PixPin | PixPin |
| 设计工具 | Figma | Figma |
| 录屏工具 | OBS | OBS Studio |
| 笔记 | Obsidian, XMind | Obsidian, XMind |
| 虚拟化 | UTM | - |

### 环境配置

- ✅ Node.js LTS 版本
- ✅ pnpm 全局配置
- ✅ Git 用户配置
- ✅ SSH Key 生成
- ✅ Shell 美化 (Oh My Zsh / Oh My Posh)
- ✅ 命令行增强插件

## 使用方法

### macOS

```bash
# 添加执行权限
chmod +x frontend-env-setup.sh

# 运行脚本
./frontend-env-setup.sh
```

### Windows

以 **管理员身份** 打开 PowerShell，然后执行：

```powershell
# 如果遇到执行策略限制，先执行：
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 运行脚本
.\frontend-env-setup-win.ps1
```

## 脚本特性

### 智能检测

- 自动检测已安装的软件，避免重复安装
- 检测网络连接状态
- 检测现有配置，提供保留或覆盖选项

### 日志记录

脚本会自动记录安装日志：

- **macOS**: `~/.local/log/dev_setup_YYYYMMDD_HHMMSS.log`
- **Windows**: `%USERPROFILE%\.local\log\dev_setup_YYYYMMDD_HHMMSS.log`

### 配置备份

脚本会自动备份现有配置文件：

- **macOS**: `~/.zshrc.backup.YYYYMMDD_HHMMSS`
- **Windows**: `$PROFILE.backup.YYYYMMDD_HHMMSS`

## 后续操作

### macOS

1. 执行 `source ~/.zshrc` 使配置生效
2. 前往 App Store 安装 Xcode（iOS/macOS 开发必需）
3. 将 SSH 公钥添加到 GitHub: https://github.com/settings/ssh/new

### Windows

1. 重启 PowerShell 或执行 `. $PROFILE` 使配置生效
2. 安装 Nerd Font 字体：`oh-my-posh font install`
3. 在 Windows Terminal 设置中选择 Nerd Font 字体
4. 可选：安装 WSL2 进行 Linux 开发：`wsl --install`
5. 将 SSH 公钥添加到 GitHub: https://github.com/settings/ssh/new

## 系统要求

### macOS

- macOS 10.15 (Catalina) 或更高版本
- 需要网络连接

### Windows

- Windows 10 1809 或更高版本
- PowerShell 5.1 或更高版本
- 需要管理员权限
- 需要网络连接

## 常见问题

### Q: macOS 安装 Homebrew 失败？

A: 可能是网络问题，可以尝试使用国内镜像：

```bash
/bin/bash -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
```

### Q: Windows 执行脚本提示"无法加载文件"？

A: 需要修改执行策略：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q: 如何只安装部分软件？

A: 可以编辑脚本，注释掉不需要的安装命令。

## 许可证

MIT License
