[Setup]
AppId={{7B2F4A1E-9C3D-4E5F-A6B8-1D2E3F4A5B6C}}
AppVersion={#AppVersion}
AppName={#AppName}
AppPublisher={#AppPublisher}
AppPublisherURL=https://github.com/rgdevment/LinkUnbound
AppSupportURL=https://github.com/rgdevment/LinkUnbound/issues
DefaultDirName={#AppInstallDir}
DisableProgramGroupPage=yes
OutputBaseFilename={#OutputBaseFilename}
SetupIconFile={#SetupIconFile}
Compression=lzma
SolidCompression=yes
PrivilegesRequired={#PrivilegesRequired}
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#DirSourceApp}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Registry]
; ProgID — URL handler
Root: HKLM; Subkey: "SOFTWARE\Classes\LinkUnboundURL"; ValueType: string; ValueData: "LinkUnbound URL"; Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\Classes\LinkUnboundURL"; ValueName: "EditFlags"; ValueType: dword; ValueData: "2"
Root: HKLM; Subkey: "SOFTWARE\Classes\LinkUnboundURL"; ValueName: "FriendlyTypeName"; ValueType: string; ValueData: "LinkUnbound URL"
Root: HKLM; Subkey: "SOFTWARE\Classes\LinkUnboundURL\Application"; ValueName: "ApplicationName"; ValueType: string; ValueData: "LinkUnbound"
Root: HKLM; Subkey: "SOFTWARE\Classes\LinkUnboundURL\Application"; ValueName: "ApplicationDescription"; ValueType: string; ValueData: "Browser picker for Windows"
Root: HKLM; Subkey: "SOFTWARE\Classes\LinkUnboundURL\Application"; ValueName: "ApplicationIcon"; ValueType: string; ValueData: """{app}\{#AppExeName}"",0"
Root: HKLM; Subkey: "SOFTWARE\Classes\LinkUnboundURL\DefaultIcon"; ValueType: string; ValueData: """{app}\{#AppExeName}"",0"
Root: HKLM; Subkey: "SOFTWARE\Classes\LinkUnboundURL\shell\open\command"; ValueType: string; ValueData: """{app}\{#AppExeName}"" ""%1"""

; StartMenuInternet — browser declaration
Root: HKLM; Subkey: "SOFTWARE\Clients\StartMenuInternet\LinkUnbound"; ValueType: string; ValueData: "LinkUnbound"; Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\Clients\StartMenuInternet\LinkUnbound\DefaultIcon"; ValueType: string; ValueData: """{app}\{#AppExeName}"",0"
Root: HKLM; Subkey: "SOFTWARE\Clients\StartMenuInternet\LinkUnbound\shell\open\command"; ValueType: string; ValueData: """{app}\{#AppExeName}"""
Root: HKLM; Subkey: "SOFTWARE\Clients\StartMenuInternet\LinkUnbound\InstallInfo"; ValueName: "ReinstallCommand"; ValueType: string; ValueData: """{app}\{#AppExeName}"""
Root: HKLM; Subkey: "SOFTWARE\Clients\StartMenuInternet\LinkUnbound\InstallInfo"; ValueName: "IconsVisible"; ValueType: dword; ValueData: "1"

; Capabilities
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities"; ValueName: "ApplicationName"; ValueType: string; ValueData: "LinkUnbound"; Flags: uninsdeletekey
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities"; ValueName: "ApplicationDescription"; ValueType: string; ValueData: "Browser picker for Windows"
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities"; ValueName: "ApplicationIcon"; ValueType: string; ValueData: """{app}\{#AppExeName}"",0"
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities\Startmenu"; ValueName: "StartMenuInternet"; ValueType: string; ValueData: "LinkUnbound"
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities\URLAssociations"; ValueName: "http"; ValueType: string; ValueData: "LinkUnboundURL"
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities\URLAssociations"; ValueName: "https"; ValueType: string; ValueData: "LinkUnboundURL"
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities\FileAssociations"; ValueName: ".htm"; ValueType: string; ValueData: "LinkUnboundURL"
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities\FileAssociations"; ValueName: ".html"; ValueType: string; ValueData: "LinkUnboundURL"
Root: HKLM; Subkey: "SOFTWARE\LinkUnbound\Capabilities\FileAssociations"; ValueName: ".pdf"; ValueType: string; ValueData: "LinkUnboundURL"

; RegisteredApplications (only delete value, not the shared key)
Root: HKLM; Subkey: "SOFTWARE\RegisteredApplications"; ValueName: "LinkUnbound"; ValueType: string; ValueData: "SOFTWARE\LinkUnbound\Capabilities"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
const
  SHCNE_ASSOCCHANGED = $08000000;
  SHCNF_IDLIST = $0000;

procedure SHChangeNotify(wEventId, uFlags: Cardinal; dwItem1, dwItem2: Cardinal);
  external 'SHChangeNotify@shell32.dll stdcall';

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, 0, 0);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, 0, 0);
end;
