$appName = "DuoobDesktopApp"
$exeName = "duoob_desktop_app_v1.exe"
$expectedVersion = "1.0.0.0" # Change this to match your Flutter app version
$installPath = "$env:ProgramFiles\$appName\$exeName"

if (Test-Path $installPath) {
    # Get the version info from the actual .exe file
    $fileVersion = (Get-Item $installPath).VersionInfo.FileVersion
    
    # Check if the version matches or is greater than expected
    if ($fileVersion -ge $expectedVersion) {
        # Intune looks for any output to the STDOUT to signal "Found"
        Write-Output "Detected version $fileVersion"
        exit 0 # Success
    } else {
        # Version mismatch
        exit 1 # Failure
    }
} else {
    # File not found
    exit 1 # Failure
}