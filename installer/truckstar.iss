; ==============================================================================
;  Truckstar — Instalador (Inno Setup 6)
;  Compile com: ISCC.exe truckstar.iss
;  Pre-requisito: rodar build PyInstaller antes (dist/Truckstar/ precisa existir)
; ==============================================================================

#define MyAppName "Truckstar"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Truckstar Mecânica"
#define MyAppExeName "Truckstar.exe"
#define MyAppId "{{A8B5C2D3-4E7F-4F12-9C0A-1234567890AB}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableDirPage=no
DisableProgramGroupPage=yes
OutputDir=..\installer_output
OutputBaseFilename=TruckstarSetup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\assets\truckstar.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} {#MyAppVersion}
WizardImageStretch=yes

[Languages]
Name: "brazilian"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na Área de Trabalho"; \
    GroupDescription: "Atalhos:"; Flags: checkedonce

[Files]
; Bundle inteiro do PyInstaller
Source: "..\dist\Truckstar\Truckstar.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\dist\Truckstar\_internal\*"; DestDir: "{app}\_internal"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; \
    Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; \
    Description: "Iniciar {#MyAppName}"; \
    Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Remove arquivos de configuração do usuário ao desinstalar
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}"

; ==============================================================================
;  Detecção do MySQL Server (registro do Windows)
;  Se não encontrado, mostra alerta com link de download.
; ==============================================================================
[Code]
function MySQLInstalado(): Boolean;
var
  Names: TArrayOfString;
  I: Integer;
  DisplayName: String;
begin
  Result := False;

  // Checa por serviço MySQL (versão moderna)
  if RegKeyExists(HKLM, 'SYSTEM\CurrentControlSet\Services\MySQL80') or
     RegKeyExists(HKLM, 'SYSTEM\CurrentControlSet\Services\MySQL84') or
     RegKeyExists(HKLM, 'SYSTEM\CurrentControlSet\Services\MySQL') then
  begin
    Result := True;
    Exit;
  end;

  // Checa entradas Uninstall por DisplayName contendo "MySQL Server"
  if RegGetSubkeyNames(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', Names) then
  begin
    for I := 0 to GetArrayLength(Names) - 1 do
    begin
      if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + Names[I],
         'DisplayName', DisplayName) then
      begin
        if Pos('MySQL Server', DisplayName) > 0 then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;

  // Wow6432Node (32-bit registry view)
  if RegGetSubkeyNames(HKLM, 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall', Names) then
  begin
    for I := 0 to GetArrayLength(Names) - 1 do
    begin
      if RegQueryStringValue(HKLM, 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\' + Names[I],
         'DisplayName', DisplayName) then
      begin
        if Pos('MySQL Server', DisplayName) > 0 then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
end;

function InitializeSetup(): Boolean;
var
  Resposta: Integer;
begin
  Result := True;
  if not MySQLInstalado() then
  begin
    Resposta := MsgBox(
      'O MySQL Server não foi detectado neste computador.' #13#10 #13#10 +
      'O Truckstar precisa de MySQL Server 8.0 ou superior para funcionar.' #13#10 #13#10 +
      'Você pode:' #13#10 +
      '• Continuar a instalação e instalar o MySQL depois' #13#10 +
      '• Cancelar e baixar o MySQL primeiro em https://dev.mysql.com/downloads/installer/' #13#10 #13#10 +
      'Deseja abrir a página de download do MySQL?',
      mbConfirmation, MB_YESNOCANCEL);

    case Resposta of
      IDYES:
        begin
          ShellExec('open', 'https://dev.mysql.com/downloads/installer/', '', '', SW_SHOW, ewNoWait, Resposta);
          Result := False;  // cancela instalação atual; usuário roda de novo após instalar MySQL
        end;
      IDCANCEL:
        Result := False;
      // IDNO segue com a instalação (Result já é True)
    end;
  end;
end;
