@echo off
:: 提权运行
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit

setlocal enabledelayedexpansion

echo [1/6] 正在还原注册表设置...

:: 备份策略注册表
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "%TEMP%\WindowsUpdate_Policy_Backup.reg" >nul 2>&1

:: 删除策略注册表键（恢复默认）
reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v WUServer /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v WUStatusServer /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v UseWUServer /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f >nul 2>&1

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

if not exist %targetfile% (
    set targetfile="C:\Windows\System32\MoUsoCoreWorker.exe"
)

if exist %targetfile% (
    takeown /f %targetfile% >nul
    icacls %targetfile% /remove:d everyone >nul
    icacls %targetfile% /reset >nul
    icacls %targetfile% /setowner "NT SERVICE\TrustedInstaller" >nul
) 


echo [4/6] 正在恢复 TrustedInstaller 服务...

rem sc qc TrustedInstaller >> C:\Windows\restore_update.log
sc config TrustedInstaller binPath= "C:\WINDOWS\servicing\TrustedInstaller.exe" >nul
sc config TrustedInstaller start= manual >nul
sc start TrustedInstaller >nul

echo [5/6] 正在启动 Windows Update 相关服务...

:: Windows Update 服务
sc config wuauserv start= auto >nul
net start wuauserv >nul

:: Update Orchestrator 服务
sc config UsoSvc start= auto >nul
net start UsoSvc >nul

:: BITS 服务（后台智能传输）
sc config bits start= delayed-auto >nul
net start bits >nul

echo [日志] 恢复 Windows 更新组件的尝试 >> C:\Windows\restore_update.log
echo [日志] 时间: %date% %time% >> C:\Windows\restore_update.log

:: 启用计划任务
schtasks /Change /Enable /TN "Microsoft\Windows\UpdateOrchestrator\ScheduleScan"
schtasks /Change /Enable /TN "Microsoft\Windows\WindowsUpdate\Automatic App Update"

echo [6/6] 正在修复系统更新组件...
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow

if %errorlevel% neq 0 (
    echo 恢复过程中出现错误，请检查日志文件 C:\Windows\restore_update.log
    exit /b %errorlevel%
)

echo.
echo 操作完成。请重启系统后前往“设置 > 更新”中手动检查更新。
pause