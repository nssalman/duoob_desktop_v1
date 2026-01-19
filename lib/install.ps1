# 1. Define variables
$appName = "DuoobDesktopApp"
$exeName = "duoob_desktop_app_v1.exe"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$destDir = "$env:ProgramFiles\$appName"

# 2. Create the destination directory
if (!(Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force
}

# 3. Copy build files to Program Files
# This copies the .exe, .dlls, and the 'data' folder
Copy-Item -Path "$scriptPath\*" -Destination $destDir -Recurse -Force -Exclude "install.ps1"

# 4. Create a Public Desktop Shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:Public\Desktop\Duoob.lnk")
$Shortcut.TargetPath = "$destDir\$exeName"
$Shortcut.WorkingDirectory = $destDir
$Shortcut.Save()

Write-Output "Installation of $appName completed successfully."