<#
.SYNOPSIS
    Script PowerShell per generare certificati SSL con mkcert su Windows

.DESCRIPTION
    Questo script è l'equivalente Windows di makesslcert.sh
    Genera certificati SSL usando mkcert e configura automaticamente
    i virtual hosts Apache per HTTPS
    
.EXAMPLE
    .\makesslcert.ps1
    
.NOTES
    Richiede mkcert installato su Windows
    Installa mkcert da: https://github.com/FiloSottile/mkcert/releases
#>

# Colori per output
$ColorTitle = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "White"

function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host $Text -ForegroundColor $ColorTitle
    Write-Host ("-" * $Text.Length) -ForegroundColor $ColorTitle
}

function Write-Step {
    param([string]$Text)
    Write-Host "► $Text" -ForegroundColor $ColorInfo
}

# Header
Clear-Host
Write-Host "============================================" -ForegroundColor $ColorTitle
Write-Host "    GENERAZIONE CERTIFICATI SSL - WINDOWS" -ForegroundColor $ColorTitle
Write-Host "============================================" -ForegroundColor $ColorTitle
Write-Host ""

# Step 1: Verifica mkcert
Write-Title "STEP 1: Verifica mkcert"

try {
    $mkcertVersion = mkcert -version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "mkcert command failed"
    }
    Write-Host "✓ mkcert trovato: $mkcertVersion" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "✗ mkcert non trovato!" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "Per installare mkcert su Windows:" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "OPZIONE 1 - Chocolatey (consigliato):" -ForegroundColor $ColorInfo
    Write-Host "  1. Installa Chocolatey: https://chocolatey.org/install" -ForegroundColor $ColorInfo
    Write-Host "  2. Apri PowerShell come amministratore" -ForegroundColor $ColorInfo
    Write-Host "  3. Esegui: choco install mkcert" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "OPZIONE 2 - Download manuale:" -ForegroundColor $ColorInfo
    Write-Host "  1. Vai su: https://github.com/FiloSottile/mkcert/releases" -ForegroundColor $ColorInfo
    Write-Host "  2. Scarica mkcert-v*-windows-amd64.exe" -ForegroundColor $ColorInfo
    Write-Host "  3. Rinominalo in mkcert.exe" -ForegroundColor $ColorInfo
    Write-Host "  4. Mettilo in una directory nel PATH (es. C:\Windows)" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "OPZIONE 3 - Scoop:" -ForegroundColor $ColorInfo
    Write-Host "  1. Installa Scoop: https://scoop.sh/" -ForegroundColor $ColorInfo
    Write-Host "  2. Esegui: scoop bucket add extras" -ForegroundColor $ColorInfo
    Write-Host "  3. Esegui: scoop install mkcert" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "Dopo l'installazione, esegui: mkcert -install" -ForegroundColor $ColorWarning
    Write-Host ""
    Read-Host "Premi ENTER per uscire"
    exit 1
}

# Verifica che la CA sia installata
Write-Step "Verifica CA locale..."
$caInstalled = $true
try {
    # Tenta di verificare se la CA è installata
    $caPath = mkcert -CAROOT 2>$null
    if ([string]::IsNullOrEmpty($caPath)) {
        $caInstalled = $false
    }
} catch {
    $caInstalled = $false
}

if (-not $caInstalled) {
    Write-Host "⚠ CA locale non configurata" -ForegroundColor $ColorWarning
    $installCA = Read-Host "Vuoi installare la CA locale ora? (Y/n)"
    if ($installCA -eq "" -or $installCA -eq "Y" -or $installCA -eq "y") {
        try {
            mkcert -install
            Write-Host "✓ CA locale installata" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "✗ Errore nell'installazione della CA" -ForegroundColor $ColorError
        }
    }
}

Write-Host ""

# Step 2: Input parametri
Write-Title "STEP 2: Configurazione dominio"

# Percorso root progetto
do {
    $defaultRootDir = "/var/www/html/esempio"
    Write-Host "Il percorso deve essere quello INTERNO al container Apache" -ForegroundColor $ColorWarning
    $rootDir = Read-Host "Percorso root progetto nel container (es. $defaultRootDir)"
    if ([string]::IsNullOrWhiteSpace($rootDir)) {
        $rootDir = $defaultRootDir
    }
    
    if ($rootDir -notmatch '^/var/www/html/') {
        Write-Host "⚠ Attenzione: il percorso dovrebbe iniziare con /var/www/html/" -ForegroundColor $ColorWarning
        $confirm = Read-Host "Vuoi continuare comunque? (Y/n)"
        if ($confirm -eq "" -or $confirm -eq "Y" -or $confirm -eq "y") {
            break
        }
    } else {
        break
    }
} while ($true)

# Dominio locale
do {
    $defaultDomain = "esempio.test"
    $domain = Read-Host "Dominio locale (es. $defaultDomain)"
    if ([string]::IsNullOrWhiteSpace($domain)) {
        $domain = $defaultDomain
    }
    
    if ($domain -notmatch '\.(test|local|dev)$') {
        Write-Host "⚠ Consiglio di usare domini .test, .local o .dev per sviluppo" -ForegroundColor $ColorWarning
        $confirm = Read-Host "Vuoi continuare con '$domain'? (Y/n)"
        if ($confirm -eq "" -or $confirm -eq "Y" -or $confirm -eq "y") {
            break
        }
    } else {
        break
    }
} while ($true)

Write-Host ""
Write-Host "Configurazione:" -ForegroundColor $ColorInfo
Write-Host "  Dominio: $domain" -ForegroundColor $ColorInfo
Write-Host "  Directory: $rootDir" -ForegroundColor $ColorInfo
Write-Host ""

# Step 3: Creazione directory SSL
Write-Title "STEP 3: Preparazione directory"

$sslDir = "conf\apache\ssl"
$sslDirUnix = "../../conf/apache/ssl"
$sslDirVhost = "/etc/apache2/ssl"

if (-not (Test-Path $sslDir)) {
    New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
    Write-Host "✓ Creata directory: $sslDir" -ForegroundColor $ColorSuccess
} else {
    Write-Host "○ Directory esistente: $sslDir" -ForegroundColor $ColorInfo
}

Write-Host ""

# Step 4: Generazione certificati
Write-Title "STEP 4: Generazione certificati SSL"

$certFile = "$sslDir\$domain.crt"
$keyFile = "$sslDir\$domain.key"

Write-Step "Generazione certificati per $domain e *.$domain..."

try {
    # Usa percorsi Windows per mkcert
    $mkcertArgs = @(
        "-cert-file", $certFile,
        "-key-file", $keyFile,
        $domain,
        "*.$domain"
    )
    
    & mkcert @mkcertArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Certificati generati con successo!" -ForegroundColor $ColorSuccess
        Write-Host "  - Certificato: $certFile" -ForegroundColor $ColorInfo
        Write-Host "  - Chiave: $keyFile" -ForegroundColor $ColorInfo
    } else {
        throw "mkcert exit code: $LASTEXITCODE"
    }
} catch {
    Write-Host "✗ Errore durante la generazione dei certificati!" -ForegroundColor $ColorError
    Write-Host "Dettagli: $_" -ForegroundColor $ColorError
    Read-Host "Premi ENTER per uscire"
    exit 1
}

Write-Host ""

# Step 5: Configurazione VirtualHost
Write-Title "STEP 5: Configurazione Apache VirtualHost"

$vhostSslConf = "conf\apache\vhosts-ssl.conf"

# Controlla se il file esiste
if (-not (Test-Path $vhostSslConf)) {
    Write-Host "⚠ File $vhostSslConf non trovato!" -ForegroundColor $ColorWarning
    $createFile = Read-Host "Vuoi crearlo? (Y/n)"
    if ($createFile -eq "" -or $createFile -eq "Y" -or $createFile -eq "y") {
        # Crea il file vuoto
        New-Item -ItemType File -Path $vhostSslConf -Force | Out-Null
        Write-Host "✓ File creato: $vhostSslConf" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "⚠ VirtualHost non configurato automaticamente" -ForegroundColor $ColorWarning
        Write-Host "Aggiungi manualmente la configurazione al file vhosts-ssl.conf" -ForegroundColor $ColorWarning
        Read-Host "Premi ENTER per continuare"
        exit 0
    }
}

# Crea la configurazione VirtualHost
$vhostConfig = @"

<VirtualHost *:443>
    ServerName $domain
    DocumentRoot $rootDir

    SSLEngine on
    SSLCertificateFile $sslDirVhost/$domain.crt
    SSLCertificateKeyFile $sslDirVhost/$domain.key

    <Directory "$rootDir">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

"@

try {
    # Aggiungi la configurazione al file
    Add-Content -Path $vhostSslConf -Value $vhostConfig -Encoding UTF8
    Write-Host "✓ VirtualHost SSL aggiunto a: $vhostSslConf" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "✗ Errore nella scrittura del file VirtualHost!" -ForegroundColor $ColorError
    Write-Host "Dettagli: $_" -ForegroundColor $ColorError
}

Write-Host ""

# Step 6: Configurazione hosts file (opzionale)
Write-Title "STEP 6: Configurazione file hosts"

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsEntry = "127.0.0.1`t$domain"

Write-Host "Per far funzionare il dominio '$domain' localmente," -ForegroundColor $ColorInfo
Write-Host "è necessario aggiungerlo al file hosts di Windows." -ForegroundColor $ColorInfo
Write-Host ""

$addToHosts = Read-Host "Vuoi aggiungere automaticamente '$domain' al file hosts? (Y/n)"
if ($addToHosts -eq "" -or $addToHosts -eq "Y" -or $addToHosts -eq "y") {
    try {
        # Controlla se l'entry esiste già
        $hostsContent = Get-Content $hostsPath -ErrorAction Stop
        $entryExists = $hostsContent | Where-Object { $_ -match "^\s*127\.0\.0\.1\s+$([regex]::Escape($domain))" }
        
        if (-not $entryExists) {
            # Aggiungi l'entry
            Add-Content -Path $hostsPath -Value $hostsEntry -Encoding ASCII
            Write-Host "✓ Dominio '$domain' aggiunto al file hosts" -ForegroundColor $ColorSuccess
        } else {
            Write-Host "○ Dominio '$domain' già presente nel file hosts" -ForegroundColor $ColorInfo
        }
    } catch {
        Write-Host "✗ Errore nell'accesso al file hosts!" -ForegroundColor $ColorError
        Write-Host "Esegui PowerShell come amministratore per modificare il file hosts" -ForegroundColor $ColorWarning
        Write-Host ""
        Write-Host "Aggiungi manualmente questa riga al file $hostsPath :" -ForegroundColor $ColorInfo
        Write-Host "$hostsEntry" -ForegroundColor $ColorWarning
    }
} else {
    Write-Host ""
    Write-Host "Aggiungi manualmente questa riga al file $hostsPath :" -ForegroundColor $ColorInfo
    Write-Host "$hostsEntry" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "Per modificare il file hosts:" -ForegroundColor $ColorInfo
    Write-Host "1. Apri Blocco Note come amministratore" -ForegroundColor $ColorInfo
    Write-Host "2. Apri il file $hostsPath" -ForegroundColor $ColorInfo
    Write-Host "3. Aggiungi la riga alla fine del file" -ForegroundColor $ColorInfo
    Write-Host "4. Salva il file" -ForegroundColor $ColorInfo
}

Write-Host ""

# Step 7: Riepilogo finale
Write-Title "COMPLETAMENTO"

Write-Host "✅ CERTIFICATI SSL CONFIGURATI CON SUCCESSO!" -ForegroundColor $ColorSuccess
Write-Host ""
Write-Host "Riepilogo configurazione:" -ForegroundColor $ColorInfo
Write-Host "  📜 Dominio: $domain" -ForegroundColor $ColorInfo
Write-Host "  📂 Directory: $rootDir" -ForegroundColor $ColorInfo
Write-Host "  🔐 Certificato: $certFile" -ForegroundColor $ColorInfo
Write-Host "  🔑 Chiave: $keyFile" -ForegroundColor $ColorInfo
Write-Host "  ⚙️  VirtualHost: $vhostSslConf" -ForegroundColor $ColorInfo
Write-Host ""

Write-Host "Prossimi passi:" -ForegroundColor $ColorTitle
Write-Host "1. 🔄 Riavvia i container Docker:" -ForegroundColor $ColorInfo
Write-Host "   docker-compose down && docker-compose up -d" -ForegroundColor $ColorWarning
Write-Host ""
Write-Host "2. 🌐 Testa il sito:" -ForegroundColor $ColorInfo
Write-Host "   HTTP:  http://$domain:8081" -ForegroundColor $ColorWarning
Write-Host "   HTTPS: https://$domain:8443" -ForegroundColor $ColorWarning
Write-Host ""
Write-Host "3. ✅ Verifica certificato:" -ForegroundColor $ColorInfo
Write-Host "   Il browser dovrebbe mostrare il lucchetto verde per HTTPS" -ForegroundColor $ColorWarning
Write-Host ""

Write-Host "============================================" -ForegroundColor $ColorSuccess
Write-Host "    CONFIGURAZIONE COMPLETATA!" -ForegroundColor $ColorSuccess
Write-Host "============================================" -ForegroundColor $ColorSuccess

Read-Host "Premi ENTER per uscire"
