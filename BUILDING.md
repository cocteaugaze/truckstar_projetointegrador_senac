# Building Truckstar Installer

Documentação para gerar o instalador `TruckstarSetup-X.Y.Z.exe` distribuível.

## Pré-requisitos (uma vez por máquina)

1. **Python 3.10+**: https://python.org/downloads/
2. **MySQL Server 8.x** (para testes locais): https://dev.mysql.com/downloads/installer/
3. **Inno Setup 6**:
   ```powershell
   winget install JRSoftware.InnoSetup
   ```
4. **Dependências Python**:
   ```powershell
   py -m pip install -r dev-requirements.txt
   ```

## Build

```powershell
.\build.ps1            # build incremental
.\build.ps1 -Clean     # limpa build anterior antes
```

O script:
1. Roda PyInstaller → gera `dist/Truckstar/` (.exe + dependências)
2. Faz scan procurando vazamento de credencial (padrão `re_*`) no bundle
3. Roda Inno Setup → gera `installer_output/TruckstarSetup-X.Y.Z.exe`

Tempo total: ~30s em uma máquina moderna.

## Arquivos importantes

| Arquivo | Função |
|---|---|
| `main.py` | Entry point — chama wizard se config.py faltar, senão abre o app |
| `setup_wizard.py` | Tela de configuração inicial (MySQL + Resend) |
| `paths.py` | Resolve onde fica `config.py` — `./` em dev, `%LOCALAPPDATA%/Truckstar/` em frozen |
| `installer/truckstar.iss` | Script do Inno Setup |
| `assets/truckstar.ico` | Ícone do app |
| `build.ps1` | Build automatizado |

## Versionamento

Para mudar a versão do instalador, edite `installer/truckstar.iss`:

```ini
#define MyAppVersion "1.0.0"
```

E rode `.\build.ps1 -Clean` de novo.

## Distribuição

O `.exe` gerado é standalone — não precisa de Python na máquina do cliente. Mas
exige MySQL Server instalado (o instalador detecta e avisa se faltar).

Aspectos do instalador:
- **Assinatura digital**: NÃO. Em ambientes corporativos com SmartScreen, o Windows
  pode avisar sobre "publisher desconhecido". Para produção comercial, considere
  assinar o `.exe` com certificado de code signing (~R$500/ano).
- **Localização do config**: `%LOCALAPPDATA%\Truckstar\config.py` — criado pelo
  wizard na primeira execução, persistido entre reinstalações.
- **Desinstalador**: incluso. Remove tudo, inclusive `%LOCALAPPDATA%\Truckstar\`.

## Troubleshooting

### "PyInstaller não encontra módulo X"

Adicione `--collect-data X` ou `--hidden-import X` em `build.ps1`.

### "AV/Windows Defender bloqueia o .exe"

Falso-positivo comum em executáveis empacotados com PyInstaller. Submeta o `.exe`
para análise em https://www.microsoft.com/wdsi/filesubmission ou assine
digitalmente.

### "ISCC: erro de compilação"

Veja `installer_output/` por logs. Confira que `dist/Truckstar/` existe antes
de rodar o Inno Setup.
