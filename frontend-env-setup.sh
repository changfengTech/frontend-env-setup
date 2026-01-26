#!/bin/zsh
# shellcheck shell=bash disable=SC2296,SC2299,SC2086

# ============================================
# 开发环境配置脚本
# ============================================

# 严格模式：遇到错误退出，管道错误传递
set -e
set -o pipefail

# ============================================
# 颜色定义 (遵循 CLI 最佳实践)
# ============================================
# 前景色
FG_BLACK='%F{black}'
FG_RED='%F{red}'
FG_GREEN='%F{green}'
FG_YELLOW='%F{yellow}'
FG_BLUE='%F{blue}'
FG_MAGENTA='%F{magenta}'
FG_CYAN='%F{cyan}'
FG_WHITE='%F{white}'

# 背景色
BG_RED='%K{red}'
BG_GREEN='%K{green}'
BG_YELLOW='%K{yellow}'
BG_BLUE='%K{blue}'
BG_CYAN='%K{cyan}'

# 样式
BOLD='%B'
RESET='%f%k%b'

# 图标 (使用 Unicode 符号)
ICON_SUCCESS="✔"
ICON_ERROR="✖"
ICON_WARNING="⚠"
ICON_INFO="ℹ"
ICON_SKIP="○"
ICON_ARROW="→"
ICON_CHECK="✓"

# 日志文件
LOG_DIR="$HOME/.local/log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/dev_setup_$(date +%Y%m%d_%H%M%S).log"

# ============================================
# 日志函数 (语义化配色)
# ============================================

# 成功/完成 - 绿色前景 + 绿色图标
log_success() {
  print -P "${BOLD}${FG_GREEN}${ICON_SUCCESS}${RESET} ${FG_GREEN}$1${RESET}"
  echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

# 一般信息 - 青色前景
log_info() {
  print -P "${FG_CYAN}${ICON_INFO}${RESET} $1"
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

# 正在执行的操作 - 蓝色前景 + 箭头
log_step() {
  print -P "${BOLD}${FG_BLUE}${ICON_ARROW}${RESET} ${FG_BLUE}$1${RESET}"
  echo "[STEP] $(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

# 已存在/跳过 - 暗淡的灰色/白色
log_skip() {
  print -P "${FG_WHITE}${ICON_SKIP} $1${RESET}"
  echo "[SKIP] $(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

# 警告 - 黄色前景 + 警告图标
log_warn() {
  print -P "${BOLD}${FG_YELLOW}${ICON_WARNING}${RESET} ${FG_YELLOW}$1${RESET}"
  echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

# 错误 - 红色背景 + 白色前景
log_error() {
  print -P "${BOLD}${BG_RED}${FG_WHITE} ${ICON_ERROR} ERROR ${RESET} ${FG_RED}$1${RESET}"
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

# 链接/URL - 蓝色下划线风格
log_link() {
  print -P "${FG_BLUE}  $1${RESET}"
}

# 章节标题 - 蓝色背景 + 白色前景
log_section() {
  print ""
  print -P "${BOLD}${BG_BLUE}${FG_WHITE} $1 ${RESET}"
  echo "[SECTION] $(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

# 最终成功 - 绿色背景 + 黑色前景
log_complete() {
  print -P "${BOLD}${BG_GREEN}${FG_BLACK} ${ICON_SUCCESS} $1 ${RESET}"
  echo "[COMPLETE] $(date '+%Y-%m-%d %H:%M:%S') $1" >>"$LOG_FILE"
}

# 检查网络连接
check_network() {
  if ! curl -s --connect-timeout 5 https://www.baidu.com >/dev/null; then
    log_error "网络连接失败，请检查网络后重试"
    exit 1
  fi
  # 检查 GitHub 连接（很多资源需要从 GitHub 下载）
  if ! curl -s --connect-timeout 10 https://github.com >/dev/null; then
    log_warn "GitHub 连接较慢或不可用，部分安装可能失败"
  fi
}

# 通用 brew 包安装函数
install_brew_package() {
  local package="$1"
  # 使用 brew list 直接检测，可以正确处理 python -> python@3.x 这类情况
  if brew list "${package}" &>/dev/null; then
    log_skip "${package} 已安装"
    return 0
  fi

  log_step "安装 ${package}..."
  if brew install "${package}"; then
    log_success "${package} 安装成功"
  else
    log_error "${package} 安装失败"
    return 1
  fi
}

# 检查 pnpm 全局包是否已安装
is_pnpm_package_installed() {
  local package="$1"
  pnpm list -g --depth=0 2>/dev/null | grep -q "${package}"
}

# 通用 cask 应用安装函数
install_cask_app() {
  local cask_name="$1"
  local app_name="$2"

  # 检查是否已安装（通过 brew 或检查 Applications 目录）
  if brew list --cask "${cask_name}" &>/dev/null ||
    [ -d "/Applications/${app_name}.app" ] ||
    [ -d "$HOME/Applications/${app_name}.app" ]; then
    log_skip "${cask_name} 已安装"
    return 0
  fi

  log_step "安装 ${cask_name}..."
  if brew install --cask "${cask_name}"; then
    log_success "${cask_name} 安装成功"
  else
    log_error "${cask_name} 安装失败"
    return 1
  fi
}

# 安全地添加配置到 zshrc
add_to_zshrc() {
  local config="$1"
  local marker="$2"

  if ! grep -q "${marker}" ~/.zshrc 2>/dev/null; then
    echo "${config}" >>~/.zshrc
    log_success "${marker} 配置已写入"
  else
    log_skip "${marker} 配置已存在"
  fi
}

# ============================================
# 主流程
# ============================================

print ""
log_section "开发环境配置脚本"
log_info "日志文件: $LOG_FILE"

# 检查网络
check_network

# 备份 zshrc
if [ -f ~/.zshrc ]; then
  cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
  log_success "已备份 ~/.zshrc"
fi

# ============================================
# 安装 Homebrew
# ============================================
log_section "Homebrew"
if command -v brew &>/dev/null; then
  log_skip "Homebrew 已安装"
else
  log_step "安装 Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # 配置 Homebrew 环境
  if [[ -f /opt/homebrew/bin/brew ]]; then
    add_to_zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"' "homebrew"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if command -v brew &>/dev/null; then
    log_success "Homebrew 安装成功"
  else
    log_error "Homebrew 安装失败，请检查网络或手动安装"
    exit 1
  fi
fi

# 更新 Homebrew
log_step "更新 Homebrew..."
brew update || log_warn "Homebrew 更新失败，继续执行..."

# ============================================
# 安装命令行工具
# ============================================
log_section "命令行工具"
for software in git python fnm pnpm docker mysql opencode; do
  install_brew_package "${software}" || true
done

# ============================================
# 安装 Cask 应用
# ============================================
log_section "桌面应用程序"

# 浏览器
install_cask_app "google-chrome" "Google Chrome" || true

# 开发工具
install_cask_app "visual-studio-code" "Visual Studio Code" || true
install_cask_app "cursor" "Cursor" || true
install_cask_app "iterm2" "iTerm" || true
install_cask_app "charles" "Charles" || true
install_cask_app "apifox" "Apifox" || true
install_cask_app "android-studio" "Android Studio" || true
install_cask_app "expo-orbit" "Expo Orbit" || true
install_cask_app "claude-code" "Claude Code" || true

# 效率工具
install_cask_app "alfred" "Alfred 5" || true
install_cask_app "rectangle" "Rectangle" || true
install_cask_app "maccy" "Maccy" || true
install_cask_app "switchhosts" "SwitchHosts" || true
install_cask_app "scroll-reverser" "Scroll Reverser" || true
install_cask_app "pixpin" "PixPin" || true

# 设计与创作
install_cask_app "figma" "Figma" || true
install_cask_app "obs" "OBS" || true

# 笔记与思维导图
install_cask_app "obsidian" "Obsidian" || true
install_cask_app "xmind" "XMind" || true

# 虚拟化
install_cask_app "utm" "UTM" || true

# ============================================
# 配置 VS Code 命令行
# ============================================
log_section "VS Code 配置"
CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
if [ -d "$CODE_BIN" ]; then
  add_to_zshrc "export PATH=\"\$PATH:$CODE_BIN\"" "Visual Studio Code"
  export PATH="$PATH:$CODE_BIN"
else
  log_warn "未检测到 VS Code，跳过 code 命令配置"
fi

# ============================================
# 配置 fnm
# ============================================
log_section "Node.js 环境"
add_to_zshrc 'eval "$(fnm env --use-on-cd)"' "fnm env"
eval "$(fnm env --use-on-cd)" 2>/dev/null || true

# 检查是否已有 LTS 版本
if fnm list 2>/dev/null | grep -q 'lts-latest'; then
  log_skip "LTS Node.js 已安装"
  fnm use lts-latest 2>/dev/null || true
else
  log_step "安装 LTS Node.js..."
  if fnm install --lts; then
    fnm use lts-latest
    fnm default lts-latest
    log_success "LTS Node.js 安装成功"
  else
    log_error "Node.js 安装失败"
  fi
fi

# ============================================
# 配置 pnpm
# ============================================
log_section "pnpm 配置"
if ! grep -q '# pnpm' ~/.zshrc 2>/dev/null; then
  pnpm setup
  log_success "pnpm 环境配置完成"
else
  log_skip "pnpm 配置已存在"
fi

# 手动设置 pnpm 路径（避免 source ~/.zshrc）
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# ============================================
# 安装 npm 全局包
# ============================================
log_section "npm 全局包"

# 安装 nrm
if is_pnpm_package_installed "nrm"; then
  log_skip "nrm 已安装"
else
  log_step "安装 nrm..."
  pnpm add -g nrm || log_error "nrm 安装失败"
fi

# ============================================
# 配置 Git
# ============================================
log_section "Git 配置"
current_name=$(git config --global user.name 2>/dev/null || echo "")
current_email=$(git config --global user.email 2>/dev/null || echo "")

if [ -n "$current_name" ] && [ -n "$current_email" ]; then
  log_info "检测到已有 Git 配置："
  print -P "  ${FG_CYAN}用户名:${RESET} ${current_name}"
  print -P "  ${FG_CYAN}邮  箱:${RESET} ${current_email}"
  print -n "是否重新配置？(y/N): "
  read reconfigure
  if [[ "$reconfigure" =~ ^[Yy]$ ]]; then
    print -n "请输入你的 Git 用户名: "
    read git_username
    print -n "请输入你的 Git 邮箱: "
    read git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    log_success "Git 配置成功"
  else
    log_skip "保留现有 Git 配置"
    git_email="$current_email"
  fi
else
  print -n "请输入你的 Git 用户名: "
  read git_username
  print -n "请输入你的 Git 邮箱: "
  read git_email
  git config --global user.name "$git_username"
  git config --global user.email "$git_email"
  log_success "Git 配置成功"
fi

# ============================================
# 生成 SSH Key（检查是否已存在）
# ============================================
log_section "SSH Key"
if [ -f ~/.ssh/id_rsa.pub ]; then
  log_info "检测到 SSH key 已存在"
  print -n "是否重新生成？(y/N): "
  read regenerate_ssh
  if [[ ! "$regenerate_ssh" =~ ^[Yy]$ ]]; then
    log_skip "保留现有 SSH key"
  else
    ssh-keygen -t rsa -C "$git_email" -f ~/.ssh/id_rsa
    log_success "SSH key 生成成功"
  fi
else
  log_step "生成 SSH key..."
  ssh-keygen -t rsa -C "$git_email" -f ~/.ssh/id_rsa -N ""
  log_success "SSH key 生成成功"
fi

# 复制公钥到剪贴板
if [ -f ~/.ssh/id_rsa.pub ]; then
  pbcopy <~/.ssh/id_rsa.pub
  log_success "已复制 SSH 公钥到剪贴板"
  log_info "请打开以下链接，并将公钥粘贴保存："
  log_link "https://github.com/settings/ssh/new"
  print ""
  read -k 1 -s "?按任意键继续..."
  print ""
fi

# ============================================
# 安装 Oh My Zsh
# ============================================
log_section "Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  log_skip "Oh My Zsh 已安装"
else
  log_step "安装 Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  log_success "Oh My Zsh 安装成功"
fi

# 安装 zsh 插件
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]; then
  log_skip "zsh-syntax-highlighting 已安装"
else
  log_step "安装 zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
  log_success "zsh-syntax-highlighting 安装成功"
fi

if [ -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]; then
  log_skip "zsh-autosuggestions 已安装"
else
  log_step "安装 zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
  log_success "zsh-autosuggestions 安装成功"
fi

# 配置 zsh 插件
if ! grep -q 'zsh-syntax-highlighting' ~/.zshrc 2>/dev/null; then
  # 使用更灵活的正则匹配，支持 plugins=(git) 或 plugins=(git xxx) 等格式
  if grep -q 'plugins=(' ~/.zshrc 2>/dev/null; then
    # 在现有 plugins 中添加新插件（如果还没有的话）
    sed -i '' 's/plugins=(\([^)]*\))/plugins=(\1 zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
    # 清理可能的重复空格
    sed -i '' 's/plugins=( /plugins=(/' ~/.zshrc
    log_success "zsh 插件配置成功"
  else
    # 如果没有 plugins 配置，添加一个
    echo 'plugins=(git zsh-syntax-highlighting zsh-autosuggestions)' >>~/.zshrc
    log_success "zsh 插件配置已添加"
  fi
else
  log_skip "zsh 插件已配置"
fi

# ============================================
# 完成
# ============================================
print ""
print ""
log_complete "开发环境配置完成！"
print ""

# 后续操作提示
log_section "后续操作"

log_info "1. 执行以下命令使配置生效："
print -P "   ${BOLD}${FG_CYAN}source ~/.zshrc${RESET}"
print ""

log_info "2. 前往 App Store 安装 Xcode（iOS/macOS 开发必需）："
print -P "   ${BOLD}${FG_CYAN}打开 App Store → 搜索 Xcode → 安装${RESET}"
print -P "   ${FG_WHITE}或使用命令行：${RESET} ${FG_CYAN}xcode-select --install${RESET} ${FG_WHITE}(仅安装命令行工具)${RESET}"
print ""

log_info "3. 前往 App Store 安装以下推荐应用："
print -P "   ${FG_CYAN}• Keynote${RESET} - 演示文稿制作"
print -P "   ${FG_CYAN}• DaVinci Resolve${RESET} - 专业视频剪辑"
print -P "   ${FG_CYAN}• iRightMouse${RESET} - 右键菜单增强"
print ""

log_info "日志已保存到: $LOG_FILE"
