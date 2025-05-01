# SeewoSystemUpdate
似乎是它让我无法更新希沃一体机上的Windows

研究代码过后发现它相当激进

⸻

### 以管理员权限重新运行自身

```
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
```

利用 mshta + vbscript 技术强制提权，以管理员身份重新运行当前脚本。

⸻

### 修改 Windows 更新相关注册表项（组策略方式）

```
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate ...
```

关键设置包括：
	•	设置 WUServer 和 WUStatusServer 为 ..（非法或空地址），模拟“企业内部 WSUS” 服务器，干扰正常连接 Windows Update。
 
	•	DoNotConnectToWindowsUpdateInternetLocations=1：禁止连接微软更新服务器。
 
	•	UseWUServer=1：强制使用（伪造的）WSUS。
 
	•	NoAutoUpdate=1：禁用自动更新。

而这些设置通常用于“企业禁用更新”或“伪装 WSUS”

⸻

### 限制对 SoftwareDistribution 目录的访问权限

```
takeown.exe /f "C:\Windows\SoftwareDistribution\..."
icacls.exe "..." /remove everyone
...
icacls.exe "..." /deny everyone:(F)
```

这一段反复操作了以下目录：
	•	C:\Windows\SoftwareDistribution\DataStore
	•	C:\Windows\SoftwareDistribution\Download
	•	C:\Windows\SoftwareDistribution\sls

通过`takeown`获取所有权，随后`icacls /remove everyone` 移除所有人权限，最后`icacls /deny everyone:(F)` 拒绝访问权限（F = full control）

阻止了 Windows 更新组件访问这些目录，导致 Windows 更新无法下载/保存更新数据。

⸻

### 终止与更新相关的进程

```
taskkill /f /im MoUsoCoreWorker.exe
```

强行终止 Microsoft Update Orchestrator Worker。

⸻

### 利用 TrustedInstaller 做权限劫持

```
sc stop trustedinstaller
sc config trustedinstaller binpath= "cmd.exe /c icacls ..."
...
sc config trustedinstaller binpath= "C:\WINDOWS\servicing\TrustedInstaller.exe"
```

操作逻辑：
	1.	停止 TrustedInstaller 服务（它有极高系统权限）
	2.	修改其启动路径为一条 cmd + icacls 指令
	•	目的：借助它的权限对 MoUsoCoreWorker.exe 设置拒绝访问权限
	3.	启动该服务执行这条“假命令”
	4.	再还原回原来的 TrustedInstaller.exe 路径

🔐 作用：彻底阻止 MoUsoCoreWorker.exe 被系统访问或重新启动

⸻

### 简而言之
注册表设置	修改 WU 策略	阻止自动更新
权限控制	拒绝更新文件夹和进程访问权限	使更新功能崩溃
进程控制	终止更新相关进程	中断当前更新行为
TrustedInstaller 劫持	利用其高权限执行拒绝访问命令	永久锁死更新组件
