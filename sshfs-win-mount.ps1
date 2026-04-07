# SSHFS Mount Shortcuts for Windows (SSHFS-Win + WinFsp)
# Voraussetzungen: SSHFS-Win, WinFsp, C:\sshw\ssh.exe
#
# Konfiguration: diese Variablen anpassen
$SshfsRemote     = "user@192.168.x.x"                  # user@host
$SshfsRemotePath = "/home/user/projects/myproject"     # Pfad auf dem Remote
$SshfsDrive      = "D:"                                # lokaler Laufwerksbuchstabe
$SshfsKey        = "$env:USERPROFILE\.ssh\id_ed25519"  # SSH-Key

function Mount-SshfsRemote
{
    if (Test-Path "${SshfsDrive}\")
    {
        Write-Host "Already mounted at $SshfsDrive" -ForegroundColor Yellow
        return
    }

    Write-Host "Mounting ${SshfsRemote}:${SshfsRemotePath} -> $SshfsDrive ..." -ForegroundColor Cyan

    # SSHFS-Win eigene Cygwin-ssh.exe vorschalten (verhindert Konflikt mit Windows/Git-SSH)
    $env:PATH = "C:\Program Files\SSHFS-Win\bin;$env:PATH"

    Start-Process -WindowStyle Hidden `
        -FilePath "C:\Program Files\SSHFS-Win\bin\sshfs.exe" `
        -ArgumentList @(
            "${SshfsRemote}:${SshfsRemotePath}", $SshfsDrive,
            "-o", "ssh_command=C:/sshw/ssh.exe -F /dev/null",
            "-o", "IdentityFile=$($SshfsKey -replace '\\','/')",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ServerAliveInterval=15",
            "-o", "uid=-1",
            "-o", "gid=-1"
        )

    Start-Sleep 3
    if (Test-Path "${SshfsDrive}\")
    {
        Write-Host "Mounted at $SshfsDrive" -ForegroundColor Green
    }
    else
    {
        Write-Host "Mount failed - check WinFsp driver or SSH connectivity" -ForegroundColor Red
    }
}

function Unmount-SshfsRemote
{
    # Graceful unmount via WinFsp Launcher
    $launchctl = "C:\Program Files (x86)\WinFsp\bin\launchctl-x64.exe"
    & $launchctl stop sshfs "$SshfsDrive" 2>&1 | Out-Null
    Start-Sleep 1
    # Fallback: Prozess direkt beenden
    if (Test-Path "${SshfsDrive}\")
    {
        Get-Process sshfs -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep 1
    }
    if (Test-Path "${SshfsDrive}\")
    {
        Write-Host "Unmount failed - $SshfsDrive still active" -ForegroundColor Red
    }
    else
    {
        Write-Host "Unmounted $SshfsDrive" -ForegroundColor Cyan
    }
}

# Short aliases -- bei Bedarf umbenennen
Set-Alias mnt  Mount-SshfsRemote
Set-Alias umnt Unmount-SshfsRemote
