<#
.SYNOPSIS
    Script PowerShell per importare database MySQL nel container Docker

.DESCRIPTION
    Questo script importa un file SQL in un database MySQL che gira nel container Docker.
    È l'equivalente Windows dello script import_db.sh per macOS/Linux.

.PARAMETER SqlFile
    Percorso del file SQL da importare

.PARAMETER DatabaseName
    Nome del database di destinazione

.EXAMPLE
    .\import_db.ps1 "backup.sql" "mio_database"
    
.EXAMPLE
    .\import_db.ps1 "C:\path\to\backup.sql" "test_db"
#>

param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Percorso del file SQL da importare")]
    [string]$SqlFile,
    
    [Parameter(Mandatory=$true, Position=1, HelpMessage="Nome del database di destinazione")]
    [string]$DatabaseName
)

# Colori per l'output
$ColorInfo = "Cyan"
$ColorSuccess = "Green" 
$ColorWarning = "Yellow"
$ColorError = "Red"

Write-Host "=== Import Database MySQL ===" -ForegroundColor $ColorInfo
Write-Host "File SQL: $SqlFile" -ForegroundColor $ColorInfo
Write-Host "Database: $DatabaseName" -ForegroundColor $ColorInfo
Write-Host ""

# Verifica che il file SQL esista
if (-not (Test-Path $SqlFile)) {
    Write-Host "ERRORE: File '$SqlFile' non trovato!" -ForegroundColor $ColorError
    Write-Host "Verifica che il percorso sia corretto." -ForegroundColor $ColorWarning
    exit 1
}

# Ottieni informazioni sul file
$fileInfo = Get-Item $SqlFile
Write-Host "Dimensione file: $([math]::Round($fileInfo.Length/1MB, 2)) MB" -ForegroundColor $ColorInfo

# Verifica che Docker sia in esecuzione
Write-Host "Verifica Docker..." -ForegroundColor $ColorInfo
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker non risponde"
    }
    Write-Host "✓ Docker attivo" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "✗ Docker Desktop non è in esecuzione!" -ForegroundColor $ColorError
    Write-Host "Avvia Docker Desktop e riprova." -ForegroundColor $ColorWarning
    exit 1
}

# Verifica che il container MySQL sia attivo
Write-Host "Verifica container mysql80..." -ForegroundColor $ColorInfo
try {
    $containerStatus = docker ps --filter "name=mysql80" --format "{{.Status}}" 2>$null
    if ([string]::IsNullOrEmpty($containerStatus)) {
        throw "Container mysql80 non trovato"
    }
    Write-Host "✓ Container mysql80 attivo: $containerStatus" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "✗ Container mysql80 non in esecuzione!" -ForegroundColor $ColorError
    Write-Host "Avvia i container con: docker-compose up -d" -ForegroundColor $ColorWarning
    exit 1
}

# Esegui l'importazione
Write-Host ""
Write-Host "Avvio importazione..." -ForegroundColor $ColorInfo
Write-Host "Questo potrebbe richiedere alcuni minuti..." -ForegroundColor $ColorWarning

try {
    # Usa Get-Content per leggere il file e inviarlo via pipeline a docker exec
    $startTime = Get-Date
    
    Get-Content $SqlFile -Raw | docker exec -i mysql80 mysql -uroot -pEn3s1sr7! --init-command="SET FOREIGN_KEY_CHECKS=0;" $DatabaseName
    
    if ($LASTEXITCODE -eq 0) {
        $endTime = Get-Date
        $duration = $endTime - $startTime
        Write-Host ""
        Write-Host "✓ IMPORTAZIONE COMPLETATA CON SUCCESSO!" -ForegroundColor $ColorSuccess
        Write-Host "Tempo impiegato: $($duration.ToString('mm\:ss'))" -ForegroundColor $ColorInfo
        Write-Host "Database '$DatabaseName' aggiornato." -ForegroundColor $ColorSuccess
    } else {
        throw "Errore durante l'esecuzione del comando MySQL"
    }
} catch {
    Write-Host ""
    Write-Host "✗ ERRORE DURANTE L'IMPORTAZIONE!" -ForegroundColor $ColorError
    Write-Host "Dettagli errore: $_" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Possibili cause:" -ForegroundColor $ColorWarning
    Write-Host "- File SQL corrotto o non valido" -ForegroundColor $ColorWarning
    Write-Host "- Database non esistente (crealo prima)" -ForegroundColor $ColorWarning
    Write-Host "- Problemi di connessione al container" -ForegroundColor $ColorWarning
    exit 1
}

Write-Host ""
Write-Host "=== Import completato ===" -ForegroundColor $ColorSuccess
