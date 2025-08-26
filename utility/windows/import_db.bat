@echo off
setlocal enabledelayedexpansion

REM Script Batch per importare database MySQL nel container Docker
REM Equivalente Windows dello script import_db.sh

echo === Import Database MySQL ===
echo.

REM Controllo parametri
if "%~1"=="" (
    echo ERRORE: Parametri mancanti!
    echo.
    echo Uso: %~nx0 ^<file_sql^> ^<database_name^>
    echo.
    echo Esempi:
    echo   %~nx0 backup.sql mio_database
    echo   %~nx0 "C:\path\to\backup.sql" test_db
    echo.
    pause
    exit /b 1
)

if "%~2"=="" (
    echo ERRORE: Nome database mancante!
    echo.
    echo Uso: %~nx0 ^<file_sql^> ^<database_name^>
    echo.
    pause
    exit /b 1
)

set "SQL_FILE=%~1"
set "DB_NAME=%~2"

echo File SQL: !SQL_FILE!
echo Database: !DB_NAME!
echo.

REM Verifica che il file SQL esista
if not exist "!SQL_FILE!" (
    echo ERRORE: File '!SQL_FILE!' non trovato!
    echo Verifica che il percorso sia corretto.
    echo.
    pause
    exit /b 1
)

REM Mostra informazioni file
for %%I in ("!SQL_FILE!") do (
    echo Dimensione file: %%~zI bytes
)
echo.

REM Verifica Docker
echo Verifica Docker...
docker --version >nul 2>&1
if !errorlevel! neq 0 (
    echo ERRORE: Docker Desktop non e' in esecuzione!
    echo Avvia Docker Desktop e riprova.
    echo.
    pause
    exit /b 1
)
echo * Docker attivo

REM Verifica container MySQL
echo Verifica container mysql80...
docker ps --filter "name=mysql80" --quiet >nul 2>&1
if !errorlevel! neq 0 (
    echo ERRORE: Container mysql80 non in esecuzione!
    echo Avvia i container con: docker-compose up -d
    echo.
    pause
    exit /b 1
)
echo * Container mysql80 attivo
echo.

REM Esegui importazione
echo Avvio importazione...
echo Questo potrebbe richiedere alcuni minuti...
echo.

REM Registra tempo inizio
set start_time=%time%

REM Esegui il comando di import
docker exec -i mysql80 mysql -uroot -pEn3s1sr7! --init-command="SET FOREIGN_KEY_CHECKS=0;" !DB_NAME! < "!SQL_FILE!"

REM Controlla il risultato
if !errorlevel! equ 0 (
    echo.
    echo *** IMPORTAZIONE COMPLETATA CON SUCCESSO! ***
    echo Database '!DB_NAME!' aggiornato.
    echo.
) else (
    echo.
    echo *** ERRORE DURANTE L'IMPORTAZIONE! ***
    echo.
    echo Possibili cause:
    echo - File SQL corrotto o non valido
    echo - Database non esistente ^(crealo prima^)
    echo - Problemi di connessione al container
    echo.
    pause
    exit /b 1
)

echo === Import completato ===
echo.
pause
