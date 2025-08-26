@echo off
setlocal enabledelayedexpansion

title Generazione Certificati SSL - Windows

echo ============================================
echo     GENERAZIONE CERTIFICATI SSL - WINDOWS
echo ============================================
echo.

REM Verifica mkcert
echo Verifica mkcert...
mkcert -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRORE: mkcert non trovato!
    echo.
    echo Per installare mkcert su Windows:
    echo.
    echo OPZIONE 1 - Chocolatey ^(consigliato^):
    echo   1. Installa Chocolatey: https://chocolatey.org/install
    echo   2. Apri PowerShell come amministratore
    echo   3. Esegui: choco install mkcert
    echo.
    echo OPZIONE 2 - Download manuale:
    echo   1. Vai su: https://github.com/FiloSottile/mkcert/releases
    echo   2. Scarica mkcert-v*-windows-amd64.exe
    echo   3. Rinominalo in mkcert.exe
    echo   4. Mettilo nel PATH ^(es. C:\Windows^)
    echo.
    echo Dopo l'installazione, esegui: mkcert -install
    echo.
    pause
    exit /b 1
)
echo * mkcert trovato

REM Input parametri
echo.
echo Configurazione dominio:
echo Il percorso deve essere quello INTERNO al container Apache
set /p "ROOT_DIR=Percorso root progetto nel container (es. /var/www/html/esempio): "
if "!ROOT_DIR!"=="" set "ROOT_DIR=/var/www/html/esempio"

set /p "DOMAIN=Dominio locale (es. esempio.test): "
if "!DOMAIN!"=="" set "DOMAIN=esempio.test"

echo.
echo Configurazione:
echo   Dominio: !DOMAIN!
echo   Directory: !ROOT_DIR!
echo.

REM Creazione directory SSL
set "SSL_DIR=..\..\conf\apache\ssl"
set "SSL_DIR_VHOST=/etc/apache2/ssl"

if not exist "!SSL_DIR!" (
    mkdir "!SSL_DIR!"
    echo * Creata directory: !SSL_DIR!
) else (
    echo * Directory esistente: !SSL_DIR!
)

REM Generazione certificati
echo.
echo Generazione certificati SSL...
set "CERT_FILE=!SSL_DIR!\!DOMAIN!.crt"
set "KEY_FILE=!SSL_DIR!\!DOMAIN!.key"

mkcert -cert-file "!CERT_FILE!" -key-file "!KEY_FILE!" "!DOMAIN!" "*.!DOMAIN!"

if %errorlevel% equ 0 (
    echo * Certificati generati con successo!
    echo   - Certificato: !CERT_FILE!
    echo   - Chiave: !KEY_FILE!
) else (
    echo ERRORE durante la generazione dei certificati!
    pause
    exit /b 1
)

REM Configurazione VirtualHost
echo.
echo Configurazione Apache VirtualHost...
set "VHOST_SSL_CONF=conf\apache\vhosts-ssl.conf"

if not exist "!VHOST_SSL_CONF!" (
    echo. > "!VHOST_SSL_CONF!"
    echo * File creato: !VHOST_SSL_CONF!
)

REM Crea configurazione VirtualHost
echo. >> "!VHOST_SSL_CONF!"
echo ^<VirtualHost *:443^> >> "!VHOST_SSL_CONF!"
echo     ServerName !DOMAIN! >> "!VHOST_SSL_CONF!"
echo     DocumentRoot !ROOT_DIR! >> "!VHOST_SSL_CONF!"
echo. >> "!VHOST_SSL_CONF!"
echo     SSLEngine on >> "!VHOST_SSL_CONF!"
echo     SSLCertificateFile !SSL_DIR_VHOST!/!DOMAIN!.crt >> "!VHOST_SSL_CONF!"
echo     SSLCertificateKeyFile !SSL_DIR_VHOST!/!DOMAIN!.key >> "!VHOST_SSL_CONF!"
echo. >> "!VHOST_SSL_CONF!"
echo     ^<Directory "!ROOT_DIR!"^> >> "!VHOST_SSL_CONF!"
echo         AllowOverride All >> "!VHOST_SSL_CONF!"
echo         Require all granted >> "!VHOST_SSL_CONF!"
echo     ^</Directory^> >> "!VHOST_SSL_CONF!"
echo ^</VirtualHost^> >> "!VHOST_SSL_CONF!"
echo. >> "!VHOST_SSL_CONF!"

echo * VirtualHost SSL aggiunto a: !VHOST_SSL_CONF!

REM Configurazione hosts
echo.
echo Configurazione file hosts:
echo Per far funzionare il dominio '!DOMAIN!' localmente,
echo e' necessario aggiungerlo al file hosts di Windows.
echo.
set /p "ADD_HOSTS=Vuoi aggiungere '!DOMAIN!' al file hosts? (Y/n): "
if /i "!ADD_HOSTS!"=="n" goto :skip_hosts

REM Tenta di aggiungere al file hosts
set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"
echo 127.0.0.1	!DOMAIN! >> "!HOSTS_FILE!" 2>nul
if %errorlevel% equ 0 (
    echo * Dominio '!DOMAIN!' aggiunto al file hosts
) else (
    echo ATTENZIONE: Impossibile modificare il file hosts!
    echo Esegui questo script come amministratore oppure
    echo aggiungi manualmente questa riga al file hosts:
    echo 127.0.0.1	!DOMAIN!
)

:skip_hosts

REM Riepilogo finale
echo.
echo ============================================
echo     CONFIGURAZIONE COMPLETATA!
echo ============================================
echo.
echo Riepilogo:
echo   Dominio: !DOMAIN!
echo   Directory: !ROOT_DIR!
echo   Certificato: !CERT_FILE!
echo   Chiave: !KEY_FILE!
echo.
echo Prossimi passi:
echo 1. Riavvia i container Docker:
echo    docker-compose down ^&^& docker-compose up -d
echo.
echo 2. Testa il sito:
echo    HTTP:  http://!DOMAIN!:8081
echo    HTTPS: https://!DOMAIN!:8443
echo.
pause
