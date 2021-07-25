# PowerPaint
![PowerPaint screen](img/powerpaint.png)

## Usage

### Command Prompt:
```powershell
powershell [Net.ServicePointManager]::SecurityProtocol='Tls12'; iex (irm https://bit.ly/ps1paint)
```

### PowerShell:
```powershell
[Net.ServicePointManager]::SecurityProtocol='Tls12'; iex (irm https://bit.ly/ps1paint)
```

### Local:
```powershell
powershell [Net.ServicePointManager]::SecurityProtocol='Tls12'; .\powerpaint.ps1
```

## Troubleshooting
When you are executing a PowerShell script for the first time you may encounter the following error:
filename.ps1 cannot be loaded because running scripts is disabled on this system.

Open a new session as an administrator and type:

### Command Prompt:
```powershell
powershell Set-ExecutionPolicy RemoteSigned
```

### PowerShell:
```powershell
Set-ExecutionPolicy RemoteSigned -force
