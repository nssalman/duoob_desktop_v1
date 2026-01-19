[Setup]
AppName=Duoob
AppVersion=1.0.0
DefaultDirName={autopf}\Duoob
DefaultGroupName=Duoob
OutputDir=.\build\installer
OutputBaseFilename=DuoobSetup
Compression=lzma
SolidCompression=yes
; "PrivilegesRequired=admin" is usually best for Intune machine-wide deployment
PrivilegesRequired=admin 

[Files]
; Source is the folder created by 'flutter build windows'
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Duoob"; Filename: "{app}\duoob.exe"
Name: "{commondesktop}\Duoob"; Filename: "{app}\duoob.exe"