@echo off
:: 提权运行
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit

setlocal enabledelayedexpansion

:: 备份策略注册表
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "%TEMP%\WindowsUpdate_Policy_Backup.reg" >nul 2>&1

:: 删除策略注册表键（恢复默认）
echo [1/6] 正在还原注册表设置...

echo 正在检查并清除特定更新策略注册表项...

:: 禁止系统升级
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableOSUpgrade /f >nul 2>&1

:: 隐藏创建媒体工具
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v HideMCTLink /f >nul 2>&1

:: 更新失败重试机制
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartRetry /f >nul 2>&1

:: 指定版本号
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v TargetReleaseVersionInfo /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v TargetReleaseVersion /f >nul 2>&1

:: 删除完整策略键
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f >nul 2>&1

:: 删除服务器设置
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v WUServer /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v WUStatusServer /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v UseWUServer /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f >nul 2>&1

:: 删除 ProductVersion
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ProductVersion /f >nul 2>&1

echo [2/6] 正在恢复 SoftwareDistribution 目录权限...

:: 恢复文件夹权限：移除 deny -> 重置权限
for %%D in (
  "C:\Windows\SoftwareDistribution\DataStore"
  "C:\Windows\SoftwareDistribution\Download"
  "C:\Windows\SoftwareDistribution\sls"
) do (
    echo  处理目录 %%D
    takeown /f %%D /r /d y >nul
    icacls %%D /remove:d everyone /t >nul
    icacls %%D /reset /t >nul
)

:: 恢复所有权为 TrustedInstaller
icacls "C:\Windows\SoftwareDistribution" /setowner "NT SERVICE\TrustedInstaller" /T >nul

echo [3/6] 正在恢复 MoUsoCoreWorker.exe 权限...

set targetfile="C:\Windows\UUS\amd64\MoUsoCoreWorker.exe"

if not exist "%targetfile%" (
    set "targetfile=C:\Windows\System32\MoUsoCoreWorker.exe"
)

if exist %targetfile% (
    takeown /f %targetfile% >nul
    icacls %targetfile% /remove:d everyone >nul
    icacls %targetfile% /reset >nul
    icacls %targetfile% /setowner "NT SERVICE\TrustedInstaller" >nul
) 

echo [4/6] 正在恢复 TrustedInstaller 服务...

sc config TrustedInstaller binPath= "C:\WINDOWS\servicing\TrustedInstaller.exe" >nul
sc config TrustedInstaller start= manual >nul
sc start TrustedInstaller >nul

echo [5/6] 正在启动 Windows 更新相关服务...

:: Windows Update 相关服务配置
sc config wuauserv start= auto >nul
sc config bits start= delayed-auto >nul
sc config TrustedInstaller start= demand >nul
sc config cryptsvc start= auto >nul
sc config UsoSvc start= auto >nul
sc config WaaSMedicSvc start= demand >nul
sc config DoSvc start= delayed-auto >nul
sc config msiserver start= demand >nul
sc config uhssvc start= demand >nul
sc config sedsvc start= demand >nul

:: 启动服务
net start wuauserv >nul
net start bits >nul
net start TrustedInstaller >nul
net start cryptsvc >nul
net start UsoSvc >nul
net start DoSvc >nul
net start msiserver >nul
net start uhssvc >nul
net start sedsvc >nul

echo [日志] 恢复 Windows 更新组件的尝试 >> %TEMP%\restore_update.log
echo [日志] 时间: %date% %time% >> %TEMP%\restore_update.log

:: 启用计划任务
schtasks /Change /Enable /TN "Microsoft\Windows\UpdateOrchestrator\ScheduleScan"
schtasks /Change /Enable /TN "Microsoft\Windows\WindowsUpdate\Automatic App Update"

echo [6/6] 正在修复系统更新组件...
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow

if %errorlevel% neq 0 (
    echo 恢复过程中出现错误，请检查日志文件 %TEMP%\restore_update.log
    exit /b %errorlevel%
)

echo.
echo 操作完成。请重启系统后前往“设置 > 更新”中手动检查更新。
pause