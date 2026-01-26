# ============================================
# 开发环境配置脚本 (Windows PowerShell)
# ============================================

#Requires -RunAsAdministrator

# 设置编码为 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 严格模式
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================
# 颜色定义 (遵循 CLI 最佳实践)
# ============================================
$Colors = @{
    Success = "Green"
    Info    = "Cyan"
    Step    = "Blue"
    Skip    = "Gray"
    Warning = "Yellow"
    Error   = "Red"
    Link    = "Blue"
}

# 图标 (使用 Unicode 符号)
$Icons = @{
    Success = [char]0x2714  # ✔
    Error   = [char]0x2716  # ✖
    Warning = [char]0x26A0  # ⚠
    Info    = [char]0x2139  # ℹ
    Skip    = [char]0x25CB  # ○
    Arrow   = [char]0x2192  # →
    Check   = [char]0x2713  # ✓
}

# 日志文件
$LogDir = "$env:USERPROFILE\.local\log"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$LogFile = "$LogDir\dev_setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ============================================
# 日志函数 (语义化配色)
# ============================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Level] $timestamp $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# 成功/完成 - 绿色前景 + 绿色图标
function Log-Success {
    param([string]$Message)
    Write-Host "$($Icons.Success) " -ForegroundColor $Colors.Success -NoNewline
    Write-Host $Message -ForegroundColor $Colors.Success
    Write-Log -Message $Message -Level "SUCCESS"
}

# 一般信息 - 青色前景
function Log-Info {
    param([string]$Message)
    Write-Host "$($Icons.Info) " -ForegroundColor $Colors.Info -NoNewline
    Write-Host $Message
    Write-Log -Message $Message -Level "INFO"
}

# 正在执行的操作 - 蓝色前景 + 箭头
function Log-Step {
    param([string]$Message)
    Write-Host "$($Icons.Arrow) " -ForegroundColor $Colors.Step -NoNewline
    Write-Host $Message -ForegroundColor $Colors.Step
    Write-Log -Message $Message -Level "STEP"
}

# 已存在/跳过 - 暗淡的灰色
function Log-Skip {
    param([string]$Message)
    Write-Host "$($Icons.Skip) " -ForegroundColor $Colors.Skip -NoNewline
    Write-Host $Message -ForegroundColor $Colors.Skip
    Write-Log -Message $Message -Level "SKIP"
}

# 警告 - 黄色前景 + 警告图标
function Log-Warn {
    param([string]$Message)
    Write-Host "$($Icons.Warning) " -ForegroundColor $Colors.Warning -NoNewline
    Write-Host $Message -ForegroundColor $Colors.Warning
    Write-Log -Message $Message -Level "WARN"
}

# 错误 - 红色前景
function Log-Error {
    param([string]$Message)
    Write-Host " $($Icons.Error) ERROR " -BackgroundColor $Colors.Error -ForegroundColor White -NoNewline
    Write-Host " $Message" -ForegroundColor $Colors.Error
    Write-Log -Message $Message -Level "ERROR"
}

# 链接/URL - 蓝色风格
function Log-Link {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor $Colors.Link
}

# 章节标题 - 蓝色背景 + 白色前景
function Log-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host " $Message " -BackgroundColor $Colors.Step -ForegroundColor White
    Write-Log -Message $Message -Level "SECTION"
}

# 最终成功 - 绿色背景 + 黑色前景
function Log-Complete {
    param([string]$Message)
    Write-Host " $($Icons.Success) $Message " -BackgroundColor $Colors.Success -ForegroundColor Black
    Write-Log -Message $Message -Level "COMPLETE"
}

# ============================================
# 工具函数
# ============================================

# 检查网络连接
function Test-NetworkConnection {
    try {
        $null = Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 5 -UseBasicParsing
    }
    catch {
        Log-Error "网络连接失败，请检查网络后重试"
        exit 1
    }
    
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 10 -UseBasicParsing
    }
    catch {
        Log-Warn "GitHub 连接较慢或不可用，部分安装可能失败"
    }
}

# 检查命令是否存在
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# 刷新环境变量
function Update-EnvironmentPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# 通用 winget 包安装函数
function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$DisplayName = $PackageId
    )
    
    # 检查是否已安装
    $installed = winget list --id $PackageId 2>$null | Select-String $PackageId
    if ($installed) {
        Log-Skip "$DisplayName 已安装"
        return $true
    }
    
    Log-Step "安装 $DisplayName..."
    try {
        winget install --id $PackageId --accept-source-agreements --accept-package-agreements --silent
        if ($LASTEXITCODE -eq 0) {
            Log-Success "$DisplayName 安装成功"
            Update-EnvironmentPath
            return $true
        }
        else {
            Log-Error "$DisplayName 安装失败"
            return $false
        }
    }
    catch {
        Log-Error "$DisplayName 安装失败: $_"
        return $false
    }
}

# 通用 scoop 包安装函数
function Install-ScoopPackage {
    param([string]$Package)
    
    $installed = scoop list $Package 2>$null | Select-String $Package
    if ($installed) {
        Log-Skip "$Package 已安装"
        return $true
    }
    
    Log-Step "安装 $Package..."
    try {
        scoop install $Package
        if ($LASTEXITCODE -eq 0) {
            Log-Success "$Package 安装成功"
            return $true
        }
        else {
            Log-Error "$Package 安装失败"
            return $false
        }
    }
    catch {
        Log-Error "$Package 安装失败: $_"
        return $false
    }
}

# 检查 pnpm 全局包是否已安装
function Test-PnpmPackageInstalled {
    param([string]$Package)
    $result = pnpm list -g --depth=0 2>$null | Select-String $Package
    return $null -ne $result
}

# 添加配置到 PowerShell Profile
function Add-ToProfile {
    param(
        [string]$Config,
        [string]$Marker
    )
    
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path $profilePath -Parent
    
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }
    
    $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Contains($Marker)) {
        Log-Skip "$Marker 配置已存在"
    }
    else {
        Add-Content -Path $profilePath -Value "`n# $Marker`n$Config"
        Log-Success "$Marker 配置已写入"
    }
}

# ============================================
# 主流程
# ============================================

Write-Host ""
Log-Section "开发环境配置脚本 (Windows)"
Log-Info "日志文件: $LogFile"

# 检查网络
Test-NetworkConnection

# 备份 PowerShell Profile
$profilePath = $PROFILE.CurrentUserAllHosts
if (Test-Path $profilePath) {
    $backupPath = "$profilePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $profilePath $backupPath
    Log-Success "已备份 PowerShell Profile"
}

# ============================================
# 安装 Scoop (Windows 包管理器)
# ============================================
Log-Section "Scoop 包管理器"
if (Test-CommandExists "scoop") {
    Log-Skip "Scoop 已安装"
}
else {
    Log-Step "安装 Scoop..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        
        if (Test-CommandExists "scoop") {
            Log-Success "Scoop 安装成功"
        }
        else {
            Log-Error "Scoop 安装失败，请检查网络或手动安装"
            exit 1
        }
    }
    catch {
        Log-Error "Scoop 安装失败: $_"
        exit 1
    }
}

# 添加 extras bucket
Log-Step "添加 Scoop extras bucket..."
scoop bucket add extras 2>$null
scoop bucket add versions 2>$null

# 更新 Scoop
Log-Step "更新 Scoop..."
scoop update 2>$null

# ============================================
# 安装命令行工具
# ============================================
Log-Section "命令行工具"

# 使用 Scoop 安装命令行工具
$cliTools = @("git", "python", "fnm", "pnpm", "mysql")
foreach ($tool in $cliTools) {
    Install-ScoopPackage $tool
}

# Docker Desktop 使用 winget 安装
Install-WingetPackage "Docker.DockerDesktop" "Docker Desktop"

# ============================================
# 安装桌面应用程序
# ============================================
Log-Section "桌面应用程序"

# 浏览器
Install-WingetPackage "Google.Chrome" "Google Chrome"

# 开发工具
Install-WingetPackage "Microsoft.VisualStudioCode" "Visual Studio Code"
Install-WingetPackage "Anysphere.Cursor" "Cursor"
Install-WingetPackage "Microsoft.WindowsTerminal" "Windows Terminal"
Install-WingetPackage "Telerik.Fiddler.Classic" "Fiddler"
Install-WingetPackage "Apifox.Apifox" "Apifox"
Install-WingetPackage "Google.AndroidStudio" "Android Studio"

# 效率工具
Install-WingetPackage "voidtools.Everything" "Everything"
Install-WingetPackage "Microsoft.PowerToys" "PowerToys"
Install-WingetPackage "Ditto.Ditto" "Ditto"
Install-WingetPackage "oldj.SwitchHosts" "SwitchHosts"
Install-WingetPackage "PixPin.PixPin" "PixPin"

# 设计与创作
Install-WingetPackage "Figma.Figma" "Figma"
Install-WingetPackage "OBSProject.OBSStudio" "OBS Studio"

# 笔记与思维导图
Install-WingetPackage "Obsidian.Obsidian" "Obsidian"
Install-WingetPackage "XMind.XMind" "XMind"

# ============================================
# 配置 VS Code 命令行
# ============================================
Log-Section "VS Code 配置"
$vscodePath = "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin"
if (Test-Path $vscodePath) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$vscodePath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$vscodePath", "User")
        Log-Success "VS Code 命令行路径已添加"
    }
    else {
        Log-Skip "VS Code 命令行路径已存在"
    }
}
else {
    Log-Warn "未检测到 VS Code，跳过 code 命令配置"
}

# ============================================
# 配置 fnm
# ============================================
Log-Section "Node.js 环境"

# 添加 fnm 环境配置到 Profile
$fnmConfig = 'fnm env --use-on-cd | Out-String | Invoke-Expression'
Add-ToProfile -Config $fnmConfig -Marker "fnm env"

# 初始化 fnm
if (Test-CommandExists "fnm") {
    fnm env --use-on-cd | Out-String | Invoke-Expression
    
    # 检查是否已有 LTS 版本
    $ltsInstalled = fnm list 2>$null | Select-String "lts-latest"
    if ($ltsInstalled) {
        Log-Skip "LTS Node.js 已安装"
        fnm use lts-latest 2>$null
    }
    else {
        Log-Step "安装 LTS Node.js..."
        try {
            fnm install --lts
            fnm use lts-latest
            fnm default lts-latest
            Log-Success "LTS Node.js 安装成功"
        }
        catch {
            Log-Error "Node.js 安装失败: $_"
        }
    }
}

# ============================================
# 配置 pnpm
# ============================================
Log-Section "pnpm 配置"

if (Test-CommandExists "pnpm") {
    $pnpmHome = "$env:USERPROFILE\AppData\Local\pnpm"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$pnpmHome*") {
        pnpm setup
        Log-Success "pnpm 环境配置完成"
    }
    else {
        Log-Skip "pnpm 配置已存在"
    }
    
    # 设置 pnpm 路径
    $env:PNPM_HOME = $pnpmHome
    $env:Path = "$pnpmHome;$env:Path"
}

# ============================================
# 安装 npm 全局包
# ============================================
Log-Section "npm 全局包"

if (Test-CommandExists "pnpm") {
    if (Test-PnpmPackageInstalled "nrm") {
        Log-Skip "nrm 已安装"
    }
    else {
        Log-Step "安装 nrm..."
        try {
            pnpm add -g nrm
            Log-Success "nrm 安装成功"
        }
        catch {
            Log-Error "nrm 安装失败: $_"
        }
    }
}

# ============================================
# 配置 Git
# ============================================
Log-Section "Git 配置"

if (Test-CommandExists "git") {
    $currentName = git config --global user.name 2>$null
    $currentEmail = git config --global user.email 2>$null
    
    if ($currentName -and $currentEmail) {
        Log-Info "检测到已有 Git 配置："
        Write-Host "  用户名: " -ForegroundColor Cyan -NoNewline
        Write-Host $currentName
        Write-Host "  邮  箱: " -ForegroundColor Cyan -NoNewline
        Write-Host $currentEmail
        
        $reconfigure = Read-Host "是否重新配置？(y/N)"
        if ($reconfigure -eq "y" -or $reconfigure -eq "Y") {
            $gitUsername = Read-Host "请输入你的 Git 用户名"
            $gitEmail = Read-Host "请输入你的 Git 邮箱"
            git config --global user.name $gitUsername
            git config --global user.email $gitEmail
            Log-Success "Git 配置成功"
        }
        else {
            Log-Skip "保留现有 Git 配置"
            $gitEmail = $currentEmail
        }
    }
    else {
        $gitUsername = Read-Host "请输入你的 Git 用户名"
        $gitEmail = Read-Host "请输入你的 Git 邮箱"
        git config --global user.name $gitUsername
        git config --global user.email $gitEmail
        Log-Success "Git 配置成功"
    }
}

# ============================================
# 生成 SSH Key（检查是否已存在）
# ============================================
Log-Section "SSH Key"

$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"
$sshPrivateKeyPath = "$env:USERPROFILE\.ssh\id_rsa"

if (Test-Path $sshKeyPath) {
    Log-Info "检测到 SSH key 已存在"
    $regenerateSsh = Read-Host "是否重新生成？(y/N)"
    if ($regenerateSsh -ne "y" -and $regenerateSsh -ne "Y") {
        Log-Skip "保留现有 SSH key"
    }
    else {
        ssh-keygen -t rsa -C $gitEmail -f $sshPrivateKeyPath
        Log-Success "SSH key 生成成功"
    }
}
else {
    Log-Step "生成 SSH key..."
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }
    ssh-keygen -t rsa -C $gitEmail -f $sshPrivateKeyPath -N '""'
    Log-Success "SSH key 生成成功"
}

# 复制公钥到剪贴板
if (Test-Path $sshKeyPath) {
    Get-Content $sshKeyPath | Set-Clipboard
    Log-Success "已复制 SSH 公钥到剪贴板"
    Log-Info "请打开以下链接，并将公钥粘贴保存："
    Log-Link "https://github.com/settings/ssh/new"
    Write-Host ""
    Read-Host "按 Enter 键继续..."
}

# ============================================
# 安装 Oh My Posh (PowerShell 美化)
# ============================================
Log-Section "Oh My Posh"

if (Test-CommandExists "oh-my-posh") {
    Log-Skip "Oh My Posh 已安装"
}
else {
    Log-Step "安装 Oh My Posh..."
    try {
        winget install JanDeDobbeleer.OhMyPosh --accept-source-agreements --accept-package-agreements --silent
        Log-Success "Oh My Posh 安装成功"
    }
    catch {
        Log-Error "Oh My Posh 安装失败: $_"
    }
}

# 配置 Oh My Posh
$ompConfig = 'oh-my-posh init pwsh | Invoke-Expression'
Add-ToProfile -Config $ompConfig -Marker "Oh My Posh"

# 安装 PSReadLine (命令行增强)
Log-Step "配置 PSReadLine..."
$psReadLineConfig = @"
# PSReadLine 配置
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
"@
Add-ToProfile -Config $psReadLineConfig -Marker "PSReadLine"

# ============================================
# 安装 Nerd Font (终端字体)
# ============================================
Log-Section "Nerd Font 字体"
Log-Info "建议安装 Nerd Font 以获得最佳终端体验"
Log-Info "可以使用以下命令安装："
Write-Host "  oh-my-posh font install" -ForegroundColor Cyan

# ============================================
# 完成
# ============================================
Write-Host ""
Write-Host ""
Log-Complete "开发环境配置完成！"
Write-Host ""

# 后续操作提示
Log-Section "后续操作"

Log-Info "1. 重启 PowerShell 或执行以下命令使配置生效："
Write-Host "   " -NoNewline
Write-Host ". `$PROFILE" -ForegroundColor Cyan
Write-Host ""

Log-Info "2. 安装 Nerd Font 字体（终端图标显示）："
Write-Host "   " -NoNewline
Write-Host "oh-my-posh font install" -ForegroundColor Cyan
Write-Host ""

Log-Info "3. 在 Windows Terminal 设置中选择 Nerd Font 字体"
Write-Host ""

Log-Info "4. 可选：安装 WSL2 进行 Linux 开发："
Write-Host "   " -NoNewline
Write-Host "wsl --install" -ForegroundColor Cyan
Write-Host ""

Log-Info "日志已保存到: $LogFile"
