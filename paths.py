"""
Resolve caminhos de runtime — onde fica config.py em modo dev vs modo .exe.

Modo dev (python main.py):
  config.py fica no mesmo diretório dos .py

Modo frozen (.exe gerado por PyInstaller):
  config.py fica em %LOCALAPPDATA%/Truckstar/config.py — diretório
  writable pelo usuário final, fora do Program Files.
"""
import os
import sys


def is_frozen() -> bool:
    return getattr(sys, 'frozen', False)


def get_config_dir() -> str:
    if is_frozen():
        base = os.environ.get('LOCALAPPDATA') or os.path.expanduser('~')
        return os.path.join(base, 'Truckstar')
    return os.path.dirname(os.path.abspath(__file__))


def get_config_path() -> str:
    return os.path.join(get_config_dir(), 'config.py')


def ensure_config_dir() -> str:
    d = get_config_dir()
    os.makedirs(d, exist_ok=True)
    return d


def prepare_import_path() -> None:
    """Garante que get_config_dir() está em sys.path para 'import config' funcionar."""
    d = ensure_config_dir()
    if d not in sys.path:
        sys.path.insert(0, d)
