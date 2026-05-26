"""
Wizard de primeira execução. Se config.py não existir, abre uma tela
coletando credenciais do MySQL + Resend, testa a conexão e grava o config.
Após isso, o app continua normalmente.
"""
import os
import sys
import customtkinter as ctk
from tkinter import messagebox

import paths


def config_existe() -> bool:
    return os.path.isfile(paths.get_config_path())


_TEMPLATE = '''"""
Configuração da Truckstar. Gerada pelo wizard de primeira execução.
NÃO versione este arquivo (já está no .gitignore).
"""

# ===== BANCO DE DADOS =====
DB_HOST = {db_host!r}
DB_USER = {db_user!r}
DB_PASSWORD = {db_password!r}
DB_NAME = {db_name!r}

# ===== EMAIL (RESEND) =====
RESEND_API_KEY = {resend_key!r}
EMAIL_FROM = 'onboarding@resend.dev'
EMAIL_REMETENTE_NOME = {empresa_nome!r}
EMAIL_REPLY_TO = {reply_to!r}

# ===== SEGURANÇA =====
HASH_ITERACOES = 600_000
SENHA_MIN_CARACTERES = 8
LOGIN_MAX_TENTATIVAS = 5
LOGIN_BLOQUEIO_SEGUNDOS = 60

# ===== APLICAÇÃO =====
EMPRESA_NOME = {empresa_nome!r}
EMPRESA_DESC = {empresa_desc!r}
'''


def _testar_conexao_mysql(host: str, user: str, password: str) -> tuple:
    """Tenta conectar no MySQL. Retorna (ok: bool, mensagem: str)."""
    try:
        import pymysql
    except ImportError:
        return False, "pymysql não instalado (rode: pip install -r requirements.txt)"
    try:
        conn = pymysql.connect(host=host, user=user, password=password,
                               connect_timeout=5, charset='utf8mb4')
        conn.close()
        return True, "Conexão OK"
    except Exception as e:
        return False, "Falha: " + str(e)


class TelaSetup(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Truckstar — Configuração Inicial")
        self.geometry("560x680")
        self.resizable(False, False)
        try:
            self.iconbitmap(default='')
        except Exception:
            pass
        self.sucesso = False

        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")

        ctk.CTkLabel(self, text="Bem-vindo à Truckstar",
                     font=("Arial", 22, "bold"), text_color="#4a9eff").pack(pady=(20, 4))
        ctk.CTkLabel(self, text="Configuração inicial — preencha os dados abaixo",
                     font=("Arial", 11), text_color="gray").pack()

        # ===== Banco =====
        frm_db = ctk.CTkFrame(self)
        frm_db.pack(fill="x", padx=20, pady=(15, 5))
        ctk.CTkLabel(frm_db, text="MySQL Server",
                     font=("Arial", 13, "bold")).grid(row=0, column=0, columnspan=2, pady=(8, 4), padx=10, sticky="w")

        ctk.CTkLabel(frm_db, text="Host:").grid(row=1, column=0, sticky="e", padx=8, pady=4)
        self.e_host = ctk.CTkEntry(frm_db, width=320); self.e_host.insert(0, "localhost")
        self.e_host.grid(row=1, column=1, padx=8, pady=4)

        ctk.CTkLabel(frm_db, text="Usuário:").grid(row=2, column=0, sticky="e", padx=8, pady=4)
        self.e_user = ctk.CTkEntry(frm_db, width=320); self.e_user.insert(0, "root")
        self.e_user.grid(row=2, column=1, padx=8, pady=4)

        ctk.CTkLabel(frm_db, text="Senha:").grid(row=3, column=0, sticky="e", padx=8, pady=4)
        self.e_pass = ctk.CTkEntry(frm_db, width=320, show="*")
        self.e_pass.grid(row=3, column=1, padx=8, pady=4)

        ctk.CTkLabel(frm_db, text="Banco:").grid(row=4, column=0, sticky="e", padx=8, pady=4)
        self.e_dbname = ctk.CTkEntry(frm_db, width=320); self.e_dbname.insert(0, "truckstar")
        self.e_dbname.grid(row=4, column=1, padx=8, pady=(4, 10))

        # ===== Resend =====
        frm_mail = ctk.CTkFrame(self)
        frm_mail.pack(fill="x", padx=20, pady=5)
        ctk.CTkLabel(frm_mail, text="Email (Resend) — opcional",
                     font=("Arial", 13, "bold")).grid(row=0, column=0, columnspan=2, pady=(8, 4), padx=10, sticky="w")
        ctk.CTkLabel(frm_mail, text="Deixe vazio para desativar envio de emails.",
                     font=("Arial", 9), text_color="gray").grid(row=1, column=0, columnspan=2, padx=10, sticky="w")

        ctk.CTkLabel(frm_mail, text="API Key:").grid(row=2, column=0, sticky="e", padx=8, pady=4)
        self.e_resend = ctk.CTkEntry(frm_mail, width=320, show="*",
                                     placeholder_text="re_xxxxxxxxxxxxxxxxxxxx")
        self.e_resend.grid(row=2, column=1, padx=8, pady=4)

        ctk.CTkLabel(frm_mail, text="Email da oficina (reply-to):").grid(row=3, column=0, sticky="e", padx=8, pady=4)
        self.e_reply = ctk.CTkEntry(frm_mail, width=320,
                                    placeholder_text="oficina@gmail.com")
        self.e_reply.grid(row=3, column=1, padx=8, pady=(4, 10))

        # ===== Empresa =====
        frm_emp = ctk.CTkFrame(self)
        frm_emp.pack(fill="x", padx=20, pady=5)
        ctk.CTkLabel(frm_emp, text="Identificação da Empresa",
                     font=("Arial", 13, "bold")).grid(row=0, column=0, columnspan=2, pady=(8, 4), padx=10, sticky="w")

        ctk.CTkLabel(frm_emp, text="Nome:").grid(row=1, column=0, sticky="e", padx=8, pady=4)
        self.e_empresa = ctk.CTkEntry(frm_emp, width=320); self.e_empresa.insert(0, "Truckstar")
        self.e_empresa.grid(row=1, column=1, padx=8, pady=4)

        ctk.CTkLabel(frm_emp, text="Descrição:").grid(row=2, column=0, sticky="e", padx=8, pady=4)
        self.e_desc = ctk.CTkEntry(frm_emp, width=320); self.e_desc.insert(0, "Mecânica de Caminhões")
        self.e_desc.grid(row=2, column=1, padx=8, pady=(4, 10))

        # ===== Botões =====
        frm_btn = ctk.CTkFrame(self, fg_color="transparent")
        frm_btn.pack(fill="x", padx=20, pady=15)
        ctk.CTkButton(frm_btn, text="Testar conexão MySQL", width=200, height=36,
                      command=self._testar, fg_color="gray40").pack(side="left", padx=5)
        ctk.CTkButton(frm_btn, text="Salvar e iniciar", width=200, height=36,
                      command=self._salvar, fg_color="green",
                      font=("Arial", 13, "bold")).pack(side="right", padx=5)

        self.lbl_status = ctk.CTkLabel(self, text="", font=("Arial", 10))
        self.lbl_status.pack(pady=(0, 10))

        self.protocol("WM_DELETE_WINDOW", self._cancelar)

    def _testar(self):
        host = self.e_host.get().strip()
        user = self.e_user.get().strip()
        senha = self.e_pass.get()
        if not host or not user:
            self.lbl_status.configure(text="Preencha host e usuário", text_color="red")
            return
        self.lbl_status.configure(text="Testando...", text_color="gray")
        self.update()
        ok, msg = _testar_conexao_mysql(host, user, senha)
        self.lbl_status.configure(text=msg, text_color="green" if ok else "red")

    def _salvar(self):
        host = self.e_host.get().strip()
        user = self.e_user.get().strip()
        senha = self.e_pass.get()
        dbname = self.e_dbname.get().strip()
        if not host or not user or not dbname:
            self.lbl_status.configure(text="Campos do MySQL são obrigatórios", text_color="red")
            return

        # validar nome do banco — letras, números, underscore
        import re
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', dbname):
            self.lbl_status.configure(
                text="Nome do banco deve começar com letra e conter só letras/números/_",
                text_color="red")
            return

        # testa antes de salvar
        ok, msg = _testar_conexao_mysql(host, user, senha)
        if not ok:
            if not messagebox.askyesno(
                "Conexão falhou",
                "Não foi possível conectar ao MySQL:\n\n{}\n\nSalvar mesmo assim?".format(msg),
                parent=self):
                self.lbl_status.configure(text=msg, text_color="red")
                return

        conteudo = _TEMPLATE.format(
            db_host=host, db_user=user, db_password=senha, db_name=dbname,
            resend_key=self.e_resend.get().strip(),
            reply_to=self.e_reply.get().strip(),
            empresa_nome=self.e_empresa.get().strip() or 'Truckstar',
            empresa_desc=self.e_desc.get().strip() or 'Mecânica de Caminhões',
        )
        try:
            paths.ensure_config_dir()
            with open(paths.get_config_path(), 'w', encoding='utf-8') as f:
                f.write(conteudo)
        except Exception as e:
            messagebox.showerror("Erro", "Falha ao salvar config.py: " + str(e), parent=self)
            return

        self.sucesso = True
        self.destroy()

    def _cancelar(self):
        if messagebox.askyesno("Cancelar",
                               "Sair sem configurar? O Truckstar não vai funcionar sem config.py.",
                               parent=self):
            self.destroy()


def executar_wizard() -> bool:
    """Roda o wizard. Retorna True se usuário concluiu, False se cancelou."""
    tela = TelaSetup()
    tela.mainloop()
    return tela.sucesso
