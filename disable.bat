echo on
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
setlocal enabledelayedexpansion
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v WUServer /t REG_SZ /d .. /f
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v WUStatusServer /t REG_SZ /d .. /f
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v UseWUServer /t REG_DWORD /d 1 /f
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 1 /f
cmd /C C:\Windows\System32\takeown.exe /f "C:\Windows\SoftwareDistribution\DataStore" && C:\Windows\System32\icacls.exe "C:\Windows\SoftwareDistribution\DataStore" /remove everyone && C:\Windows\System32\takeown.exe /f "C:\Windows\SoftwareDistribution\download" && C:\Windows\System32\icacls.exe "C:\Windows\SoftwareDistribution\download" /remove everyone && C:\Windows\System32\takeown.exe /f "C:\Windows\SoftwareDistribution\sls" && C:\Windows\System32\icacls.exe "C:\Windows\SoftwareDistribution\sls" /remove everyone
C:\Windows\System32\takeown.exe  /f "C:\Windows\SoftwareDistribution\DataStore" 
C:\Windows\System32\icacls.exe  "C:\Windows\SoftwareDistribution\DataStore" /remove everyone 
C:\Windows\System32\takeown.exe  /f "C:\Windows\SoftwareDistribution\download" 
C:\Windows\System32\icacls.exe  "C:\Windows\SoftwareDistribution\download" /remove everyone 

C:\Windows\System32\takeown.exe  /f "C:\Windows\SoftwareDistribution\sls" 

C:\Windows\System32\icacls.exe  "C:\Windows\SoftwareDistribution\sls" /remove everyone

cmd /C C:\Windows\System32\icacls.exe "C:\Windows\SoftwareDistribution\DataStore" /deny everyone:(F) && C:\Windows\System32\icacls.exe "C:\Windows\SoftwareDistribution\download" /deny everyone:(F) && C:\Windows\System32\icacls.exe "C:\Windows\SoftwareDistribution\sls" /deny everyone:(F)
C:\Windows\System32\icacls.exe  "C:\Windows\SoftwareDistribution\DataStore" /deny everyone:(F)
C:\Windows\System32\icacls.exe  "C:\Windows\SoftwareDistribution\download" /deny everyone:(F) 

C:\Windows\System32\icacls.exe  "C:\Windows\SoftwareDistribution\sls" /deny everyone:(F)

cmd /C cd /d C:\Windows\SoftwareDistribution\Download && cd
cmd /C taskkill /f /im MoUsoCoreWorker.exe
taskkill  /f /im MoUsoCoreWorker.exe
cmd /C sc stop trustedinstaller & sc config trustedinstaller binpath= "cmd.exe /c C:\Windows\System32\icacls.exe C:\Windows\UUS\amd64\MoUsoCoreWorker.exe /deny everyone:(F)" & sc start trustedinstaller & sc stop trustedinstaller & sc config trustedinstaller binpath= "%SystemRoot%\servicing\TrustedInstaller.exe" & sc start trustedinstaller
sc  stop trustedinstaller 
sc  config trustedinstaller binpath= "cmd.exe /c C:\Windows\System32\icacls.exe C:\Windows\UUS\amd64\MoUsoCoreWorker.exe /deny everyone:(F)" 
sc  start trustedinstaller 
sc  stop trustedinstaller 
sc  config trustedinstaller binpath= "C:\WINDOWS\servicing\TrustedInstaller.exe" 
sc  start trustedinstaller
rem pause