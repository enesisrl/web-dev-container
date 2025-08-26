# Ambiente Docker LAMP con PHP 7.4 + MySQL 8.0

Questo repository contiene un ambiente di sviluppo completo basato su Docker che include:

- **Apache 2.4** con PHP 7.4
- **MySQL 8.0**
- **phpMyAdmin**
- **Redis 7**
- **Supporto SSL/HTTPS completo**

## 📋 Requisiti di Sistema

### 🍎 macOS
- **Docker Desktop per Mac**
- **Homebrew**
- **mkcert** per certificati SSL fidati

### 🪟 Windows
- **Docker Desktop per Windows**
- **PowerShell 5.1+** (incluso in Windows 10/11)
- **mkcert** per certificati SSL (opzionale ma consigliato)

### 🐧 Linux
- **Docker** e **Docker Compose**
- **mkcert** (opzionale per SSL)

## 🚀 Avvio Rapido

### Su Windows:

1. **Clona o scarica il repository**
2. **Apri PowerShell come amministratore nella directory del progetto**
3. **Esegui lo script di setup automatico:**
   ```powershell
   .\utility\windows\setup_windows.ps1
   ```
4. **Modifica docker-compose.yml** come indicato dallo script
5. **Avvia l'ambiente:**
   ```powershell
   docker-compose up -d
   ```

### Su macOS:

1. **Installa mkcert:**
   ```bash
   brew install mkcert
   mkcert -install
   ```
2. **Clona il repository e avvia:**
   ```bash
   cp conf/apache/vhosts.conf.example conf/apache/vhosts.conf
   cp conf/apache/vhosts-ssl.conf.example conf/apache/vhosts-ssl.conf
   docker-compose up -d
   ```

### Su Linux:
```bash
cp conf/apache/vhosts.conf.example conf/apache/vhosts.conf
cp conf/apache/vhosts-ssl.conf.example conf/apache/vhosts-ssl.conf
docker-compose up -d
```

## 📁 Struttura del Progetto

```
.
├── Dockerfile                    # Immagine personalizzata PHP 7.4 + Apache
├── docker-compose.yml            # Configurazione servizi Docker
├── conf/                         # File di configurazione
│   ├── apache/                  # Configurazioni Apache
│   │   ├── vhosts.conf.example
│   │   ├── vhosts-ssl.conf.example
│   │   ├── php74-custom.ini
│   │   └── ssl/                # Certificati SSL
│   └── mysql/                  # Configurazioni MySQL
│       └── my.cnf
├── data/                        # Dati persistenti MySQL
├── init/                        # Script di inizializzazione DB
├── utility/                     # Script di utilità
│   ├── windows/                # Script per windows
│   │   ├── import_db.ps1           # Import database (Windows PowerShell)
│   │   ├── import_db.bat           # Import database (Windows Batch)
│   │   ├── makesslcert.ps1         # Generazione certificati SSL (Windows PowerShell)
│   │   ├── makesslcert.bat         # Generazione certificati SSL (Windows Batch)
│   │   └── setup_windows.ps1       # Setup automatico Windows
│   ├── import_db.sh            # Import database (macOS/Linux)
│   └──  makesslcert.sh          # Generazione certificati SSL (macOS/Linux)
└── www/                         # File web (se presente)
```

## 🔧 Servizi Inclusi

### 🌐 Apache + PHP 7.4
- **Porta HTTP:** 8081
- **Porta HTTPS:** 8443
- **Directory Web:** Configurabile per ogni sistema
- **Estensioni PHP installate:**
    - mysqli, pdo, pdo_mysql, pdo_pgsql, pdo_sqlite
    - gd, intl, mbstring, zip, opcache
    - redis, mongodb
    - dom, xml, simplexml, xmlreader, xmlwriter, xsl, soap

### 🗄️ MySQL 8.0
- **Porta:** 3306
- **Container:** `mysql80`
- **Credenziali:**
    - Root: `root` / `En3s1sr7!`
    - User: `homestead` / `secret`

### 📊 phpMyAdmin
- **URL:** http://localhost:8080
- **Container:** `pma`
- **Login:** `homestead` / `secret`

### 📡 Redis
- **Porta:** 6379
- **Container:** `redis`

## ⚙️ Configurazione Iniziale

### 1. Configurazione Virtual Hosts Apache

**Windows (PowerShell):**
```powershell
Copy-Item conf/apache/vhosts.conf.example conf/apache/vhosts.conf
Copy-Item conf/apache/vhosts-ssl.conf.example conf/apache/vhosts-ssl.conf
```

**macOS/Linux:**
```bash
cp conf/apache/vhosts.conf.example conf/apache/vhosts.conf
cp conf/apache/vhosts-ssl.conf.example conf/apache/vhosts-ssl.conf
```

### 2. Modifica del Percorso Web

Nel file `docker-compose.yml`, modifica il volume secondo il tuo sistema:

**Windows:**
```yaml
volumes:
  - C:/Users/TuoNome/Web:/var/www/html  # Percorso Windows
```

**macOS/Linux:**
```yaml
volumes:
  - /percorso/alla/tua/directory/web:/var/www/html
```

### 3. Configurazione SSL

**Windows (con mkcert):**
```powershell
# Installa mkcert (una sola volta)
choco install mkcert          # Con Chocolatey
# oppure
scoop install mkcert          # Con Scoop

# Installa CA locale
mkcert -install

# Genera certificati per il tuo dominio
.\utility\windows\makesslcert.ps1
```

**macOS (con mkcert):**
```bash
# Installa mkcert
brew install mkcert
mkcert -install

# Genera certificati
./utility/makesslcert.sh
```

**Linux/Windows (senza mkcert):**
SSL funziona con certificati auto-firmati (avvisi del browser)

## 📦 Installazione mkcert

### Windows

**Opzione 1 - Chocolatey (Consigliato):**
```powershell
# Installa Chocolatey (se necessario)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Installa mkcert
choco install mkcert
mkcert -install
```

**Opzione 2 - Scoop:**
```powershell
# Installa Scoop (se necessario)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Installa mkcert
scoop bucket add extras
scoop install mkcert
mkcert -install
```

**Opzione 3 - Download Manuale:**
1. Vai su: https://github.com/FiloSottile/mkcert/releases
2. Scarica `mkcert-v*-windows-amd64.exe`
3. Rinomina in `mkcert.exe` e metti nel PATH

### macOS
```bash
brew install mkcert
mkcert -install
```

## 🛠️ Comandi Utili

### Import Database

**Windows (PowerShell):**
```powershell
.\utility\windows\import_db.ps1 "backup.sql" "nome_database"
```

**Windows (Prompt dei comandi):**
```batch
utility\windows\import_db.bat backup.sql nome_database
```

**macOS/Linux:**
```bash
./utility/import_db.sh backup.sql nome_database
```

### Generazione Certificati SSL

**Windows (PowerShell):**
```powershell
.\utility\windows\makesslcert.ps1
```

**Windows (Batch):**
```batch
utility\windows\makesslcert.bat
```

**macOS/Linux:**
```bash
./utility/makesslcert.sh
```

### Gestione Container (tutti i sistemi)

```bash
# Avvia tutti i servizi
docker-compose up -d

# Ferma tutti i servizi
docker-compose down

# Visualizza log
docker-compose logs -f

# Ricostruisci l'immagine PHP/Apache
docker-compose build apache-php74

# Riavvia un servizio specifico
docker-compose restart apache-php74
```

### Accesso ai Container (tutti i sistemi)

```bash
# Accesso al container Apache/PHP
docker exec -it apache-php74 bash

# Accesso al container MySQL
docker exec -it mysql80 mysql -u homestead -p

# Accesso al container Redis
docker exec -it redis redis-cli
```

## 🔗 Accessi Rapidi

- **Applicazione Web:** http://localhost:8081
- **Applicazione Web SSL:** https://localhost:8443
- **phpMyAdmin:** http://localhost:8080
- **MySQL:** localhost:3306
- **Redis:** localhost:6379

## 📝 Personalizzazione

### PHP
Modifica `conf/apache/php74-custom.ini` per personalizzare la configurazione PHP.

### MySQL
Modifica `conf/mysql/my.cnf` per personalizzare la configurazione MySQL.

### Apache
Modifica i file `vhosts.conf` e `vhosts-ssl.conf` per configurare i virtual hosts.

## 🚨 Risoluzione Problemi

### Windows Specifici

**Execution Policy Error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Problemi di percorsi:**
- Usa sempre `/` invece di `\` nei path di Docker
- Converti `C:\path` in `/c/path` per Docker volumes
- Racchiudi percorsi con spazi tra virgolette

**Docker Desktop non attivo:**
- Verifica che Docker Desktop sia avviato
- Controlla l'icona nella system tray
- Riavvia Docker Desktop se necessario

**File hosts (per SSL):**
Se lo script non riesce a modificare il file hosts, aggiungi manualmente:
```
127.0.0.1    tuo-dominio.test
```
al file `C:\Windows\System32\drivers\etc\hosts` (come amministratore)

### Problemi Comuni (tutti i sistemi)

**Porte in Uso:**
```yaml
ports:
  - "8082:80"  # Cambia porta se occupata
  - "8444:443" # Cambia porta SSL se occupata
```

**Container non si avviano:**
```bash
# Controlla i log
docker-compose logs -f

# Verifica lo stato
docker-compose ps

# Ricostruisci se necessario
docker-compose build --no-cache
```

**Reset Database:**

**Windows:**
```powershell
docker-compose down
Remove-Item -Recurse -Force data/*
docker-compose up -d
```

**macOS/Linux:**
```bash
docker-compose down
sudo rm -rf data/*
docker-compose up -d
```

## 📋 Note per Sistema

### 🪟 Windows
- **Script PowerShell e Batch** disponibili per tutte le funzioni
- **Setup automatico** con `setup_windows.ps1`
- **SSL completo** con mkcert (certificati fidati dal browser)
- **Percorsi automaticamente convertiti** per Docker
- **File hosts gestito automaticamente** dagli script

### 🍎 macOS
- **Supporto nativo** per tutti gli script bash
- **mkcert via Homebrew** per SSL fidato
- **Percorsi Unix** standard
- **Esperienza ottimale** di sviluppo

### 🐧 Linux
- **Compatibile** con script macOS
- **mkcert installabile** via package manager
- **Potrebbe richiedere sudo** per alcuni comandi
- **Percorsi Unix** standard

## 🆘 Supporto

### Controlli Generali
1. **Docker Desktop** installato e in esecuzione
2. **Porte disponibili** (8081, 8443, 8080, 3306, 6379)
3. **File di configurazione** presenti
4. **Log dei container:** `docker-compose logs`

### Supporto Sistema-Specifico

**Windows:**
- Usa **PowerShell come amministratore** per funzioni avanzate
- Verifica **Docker Desktop** nella system tray
- Controlla **Execution Policy** se gli script non funzionano
- **Antivirus** potrebbe bloccare i container

**macOS:**
- Installa **mkcert via Homebrew** per SSL
- Verifica **Docker Desktop** nelle preferenze di sistema
- Controlla **permessi file** con `chmod +x utility/*.sh`

**Linux:**
- Verifica **permessi Docker** per l'utente corrente
- Potrebbe servire **sudo** per alcune operazioni
- Controlla **SELinux/AppArmor** se i volumi non funzionano

### Script di Utilità Disponibili

| Sistema | Import DB | Genera SSL | Setup |
|---------|-----------|------------|-------|
| **Windows PowerShell** | `import_db.ps1` | `makesslcert.ps1` | `setup_windows.ps1` |
| **Windows Batch** | `import_db.bat` | `makesslcert.bat` | - |
| **macOS/Linux** | `import_db.sh` | `makesslcert.sh` | - |

Tutti gli script includono controlli di errore dettagliati e output informativi per guidare l'utente.