# Ambiente Docker LAMP con PHP 7.4 + MySQL 8.0

Questo repository contiene un ambiente di sviluppo completo basato su Docker che include:

- **Apache 2.4** con PHP 7.4
- **MySQL 8.0**
- **phpMyAdmin**
- **Redis 7**
- **Supporto SSL/HTTPS**

## 📋 Requisiti di Sistema

⚠️ **Attualmente questo progetto è ottimizzato per macOS, su Windows è utilizzabile ma senza supporto SSL**

### Prerequisiti macOS:
- **Docker Desktop per Mac**
- **Homebrew** per l'installazione dei tool
- **mkcert** per la generazione dei certificati SSL locali

### Installazione mkcert:

```bash
# Installa mkcert tramite Homebrew
brew install mkcert

# Installa la CA locale nel sistema
mkcert -install
```


## 🚀 Avvio Rapido

1. **Clona o scarica il repository**
2. **Naviga nella directory del progetto**
3. **Avvia l'ambiente con Docker Compose:**

```bash
docker-compose up -d
```

## 📁 Struttura del Progetto

```
.
├── Dockerfile                 # Immagine personalizzata PHP 7.4 + Apache
├── docker-compose.yml         # Configurazione servizi Docker
├── conf/                      # File di configurazione
│   ├── apache/               # Configurazioni Apache
│   │   ├── vhosts.conf.example
│   │   ├── vhosts-ssl.conf.example
│   │   ├── php74-custom.ini
│   │   └── ssl/             # Certificati SSL
│   └── mysql/               # Configurazioni MySQL
│       └── my.cnf
├── data/                     # Dati persistenti MySQL
├── init/                     # Script di inizializzazione DB
├── utility/                  # Script di utilità
│   ├── import_db.sh         # Import database
│   └── makesslcert.sh       # Generazione certificati SSL
└── www/                     # File web (se presente)
```

## 🔧 Servizi Inclusi

### 🌐 Apache + PHP 7.4
- **Porta HTTP:** 8081
- **Porta HTTPS:** 8443
- **Directory Web:** `/percorso/alla/tua/directory/web` (modificabile)
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

Copia e personalizza i file di configurazione:

```bash
cp conf/apache/vhosts.conf.example conf/apache/vhosts.conf
cp conf/apache/vhosts-ssl.conf.example conf/apache/vhosts-ssl.conf
```

### 2. Modifica del Percorso Web

Nel file `docker-compose.yml`, modifica il volume per puntare alla tua directory di sviluppo:

```yaml
volumes:
  - /percorso/alla/tua/directory/web:/var/www/html
```

### 3. Configurazione SSL (Opzionale)

Per abilitare HTTPS, genera i certificati SSL:

```bash
./utility/makesslcert.sh
```

## 🛠️ Comandi Utili

### Gestione Container

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

### Accesso ai Container

```bash
# Accesso al container Apache/PHP
docker exec -it apache-php74 bash

# Accesso al container MySQL
docker exec -it mysql80 mysql -u homestead -p

# Accesso al container Redis
docker exec -it redis redis-cli
```

### Import Database

Utilizza lo script di utilità per importare un database:

```bash
./utility/import_db.sh nome_database file.sql
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

### Porte in Uso
Se le porte sono già occupate, modifica le porte nel file `docker-compose.yml`:

```yaml
ports:
  - "8082:80"  # Invece di 8081:80
```

### Permessi File
Su sistemi Unix, assicurati che i file abbiano i permessi corretti:

```bash
chmod +x utility/*.sh
```

### Reset Database
Per resettare completamente il database:

```bash
docker-compose down
sudo rm -rf data/*
docker-compose up -d
```

## 📋 Note

- Il database MySQL utilizza l'autenticazione nativa per compatibilità
- I certificati SSL sono auto-firmati (per sviluppo)
- I dati del database sono persistenti nella directory `data/`
- La directory `/Users/emanueletoffolon/Web` deve essere modificata secondo il tuo ambiente

## 🆘 Supporto

Per problemi o domande, verifica:
1. Che Docker e Docker Compose siano installati
2. Che le porte non siano già occupate
3. Che i file di configurazione siano presenti
4. I log dei container con `docker-compose logs`