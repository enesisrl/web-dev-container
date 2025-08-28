<#
.SYNOPSIS
    Script di setup automatico per l'ambiente Docker LAMP su Windows

.DESCRIPTION
    Questo script configura automaticamente l'ambiente Docker per Windows:
    - Verifica Docker Desktop
    - Crea i file di configurazione necessari
    - Configura i percorsi per Windows
    - Prepara l'ambiente per il primo avvio
#>

# Colori per output
$ColorTitle = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "White"

# Funzione per creare separatori
function Write-Separator {
    Write-Host ("=" * 60) -ForegroundColor $ColorTitle
}

# Header
Clear-Host
Write-Separator
Write-Host "    SETUP AMBIENTE DOCKER LAMP PER WINDOWS" -ForegroundColor $ColorTitle
Write-Separator
Write-Host ""

# Step 1: Verifica Docker Desktop
Write-Host "STEP 1: Verifica Docker Desktop" -ForegroundColor $ColorTitle
Write-Host "-----------------------------------------------" -ForegroundColor $ColorTitle

try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker command failed"
    }
    Write-Host "[OK] Docker trovato: $dockerVersion" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "[ERR] Docker Desktop non trovato o non in esecuzione!" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Per continuare devi:" -ForegroundColor $ColorWarning
    Write-Host "1. Scaricare Docker Desktop da: https://www.docker.com/products/docker-desktop" -ForegroundColor $ColorInfo
    Write-Host "2. Installarlo e avviarlo" -ForegroundColor $ColorInfo
    Write-Host "3. Rilanciare questo script" -ForegroundColor $ColorInfo
    Write-Host ""
    Read-Host "Premi ENTER per uscire"
    exit 1
}

try {
    $composeVersion = docker-compose --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose command failed"
    }
    Write-Host "[OK] Docker Compose trovato: $composeVersion" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "[WARN] Docker Compose non trovato - verrà usato 'docker compose'" -ForegroundColor $ColorWarning
}

Write-Host ""

# Step 2: Verifica struttura directory
Write-Host "STEP 2: Verifica struttura progetto" -ForegroundColor $ColorTitle
Write-Host "-----------------------------------------------" -ForegroundColor $ColorTitle

$requiredDirs = @("conf", "conf/apache", "conf/mysql", "utility", "data", "init")
$requiredFiles = @("docker-compose.yml", "Dockerfile")

foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "[OK] Creata directory: $dir" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "[INFO] Directory esistente: $dir" -ForegroundColor $ColorInfo
    }
}

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "[OK] File trovato: $file" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "[WARN] File mancante: $file" -ForegroundColor $ColorWarning
    }
}

Write-Host ""

# Step 3: Configurazione file Apache
Write-Host "STEP 3: Configurazione file Apache" -ForegroundColor $ColorTitle
Write-Host "-----------------------------------------------" -ForegroundColor $ColorTitle

$apacheConfigs = @(
    @{
        src = "conf/apache/vhosts.conf.example"
        dst = "conf/apache/vhosts.conf"
        desc = "Virtual Hosts HTTP"
    },
    @{
        src = "conf/apache/vhosts-ssl.conf.example"
        dst = "conf/apache/vhosts-ssl.conf"
        desc = "Virtual Hosts HTTPS"
    }
)

foreach ($config in $apacheConfigs) {
    if (-not (Test-Path $config.dst)) {
        if (Test-Path $config.src) {
            Copy-Item $config.src $config.dst
            Write-Host "[OK] Creato: $($config.dst) ($($config.desc))" -ForegroundColor $ColorSuccess
        } else {
            Write-Host "[WARN] File esempio non trovato: $($config.src)" -ForegroundColor $ColorWarning
        }
    } else {
        Write-Host "[INFO] Già esistente: $($config.dst)" -ForegroundColor $ColorInfo
    }
}

# Crea directory SSL
$sslDir = "conf/apache/ssl"
if (-not (Test-Path $sslDir)) {
    New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
    Write-Host "[OK] Creata directory SSL: $sslDir" -ForegroundColor $ColorSuccess
} else {
    Write-Host "[INFO] Directory SSL esistente: $sslDir" -ForegroundColor $ColorInfo
}

Write-Host ""

# Step 4: Configurazione percorso directory web
Write-Host "STEP 4: Configurazione directory web" -ForegroundColor $ColorTitle
Write-Host "-----------------------------------------------" -ForegroundColor $ColorTitle

$currentUser = $env:USERNAME
$defaultWebPath = "C:\Users\$currentUser\Web"

Write-Host "Directory web attuale nel docker-compose.yml:" -ForegroundColor $ColorInfo
if (Test-Path "docker-compose.yml") {
    $composeContent = Get-Content "docker-compose.yml" -Raw
    if ($composeContent -match '- ([^:]+):/var/www/html') {
        $currentPath = $matches[1]
        Write-Host "  $currentPath" -ForegroundColor $ColorWarning
    }
}

Write-Host ""
Write-Host "Percorso consigliato per Windows: $defaultWebPath" -ForegroundColor $ColorInfo

$useDefault = Read-Host "Vuoi usare il percorso consigliato? (Y/n)"
if ($useDefault -eq "" -or $useDefault -eq "Y" -or $useDefault -eq "y") {
    $webPath = $defaultWebPath
} else {
    do {
        $webPath = Read-Host "Inserisci il percorso completo della directory web"
        if ([string]::IsNullOrWhiteSpace($webPath)) {
            Write-Host "Percorso non valido!" -ForegroundColor $ColorError
        }
    } while ([string]::IsNullOrWhiteSpace($webPath))
}

# Crea la directory se non esiste
if (-not (Test-Path $webPath)) {
    $create = Read-Host "Directory '$webPath' non esiste. Vuoi crearla? (Y/n)"
    if ($create -eq "" -or $create -eq "Y" -or $create -eq "y") {
        try {
            New-Item -ItemType Directory -Path $webPath -Force | Out-Null
            Write-Host "[OK] Directory creata: $webPath" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "[ERR] Impossibile creare la directory: $_" -ForegroundColor $ColorError
        }
    }
}

# Converti percorso per Docker
$dockerPath = $webPath -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'
$dockerPath = $dockerPath.ToLower()

Write-Host ""
Write-Host "IMPORTANTE: Modifica manuale richiesta" -ForegroundColor $ColorWarning
Write-Host "Nel file docker-compose.yml, sostituisci la riga:" -ForegroundColor $ColorInfo
Write-Host "      - /Users/emanueletoffolon/Web:/var/www/html" -ForegroundColor $ColorError
Write-Host "con:" -ForegroundColor $ColorInfo
Write-Host "      - ${dockerPath}:/var/www/html" -ForegroundColor $ColorSuccess
Write-Host ""

# Step 5: Informazioni finali
Write-Host "STEP 5: Riepilogo configurazione" -ForegroundColor $ColorTitle
Write-Host "-----------------------------------------------" -ForegroundColor $ColorTitle

Write-Host "Configurazione completata!" -ForegroundColor $ColorSuccess
Write-Host ""
Write-Host "Prossimi passi:" -ForegroundColor $ColorInfo
Write-Host "1. Modifica docker-compose.yml con il percorso indicato sopra" -ForegroundColor $ColorInfo
Write-Host "2. Avvia i container: docker-compose up -d" -ForegroundColor $ColorInfo
Write-Host "3. Verifica i servizi:" -ForegroundColor $ColorInfo
Write-Host "   - Web: http://localhost:8081" -ForegroundColor $ColorInfo
Write-Host "   - phpMyAdmin: http://localhost:8080" -ForegroundColor $ColorInfo
Write-Host "   - MySQL: localhost:3306 (user: homestead, pass: secret)" -ForegroundColor $ColorInfo
Write-Host ""

Write-Host "Script di utilita' disponibili:" -ForegroundColor $ColorInfo
Write-Host "- Import database: .\utility\import_db.ps1" -ForegroundColor $ColorInfo
Write-Host "- Import database (batch): .\utility\import_db.bat" -ForegroundColor $ColorInfo
Write-Host ""

Write-Separator
Write-Host "    SETUP COMPLETATO!" -ForegroundColor $ColorSuccess
Write-Separator

Read-Host "Premi ENTER per uscire"
