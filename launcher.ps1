param(
    [string]$BaseUrl = "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main",
    [switch]$VerifyOnly
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
function Stop-Launcher([string]$Message, [switch]$Cleanup, [switch]$NoPause) {
    if ($Cleanup -and $scriptRoot -and (Test-Path -LiteralPath $scriptRoot)) {
        Remove-Item -LiteralPath $scriptRoot -Recurse -Force -ErrorAction SilentlyContinue
    } elseif ($Cleanup -and $scriptPath) {
        Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[ERREUR] $Message" -ForegroundColor Red
    if (!$NoPause -and !$VerifyOnly) { Read-Host "Appuyez sur Entree pour quitter" }
    exit 1
}

try {
    $baseUri = [Uri]$BaseUrl
    if (!$baseUri.IsAbsoluteUri) { throw "URI relative" }
    $segments = $baseUri.AbsolutePath.Trim("/").Split("/")
} catch {
    Stop-Launcher "URL de base invalide." -NoPause
}
if ($baseUri.Scheme -ne "https" -or
    $baseUri.Host -ne "raw.githubusercontent.com" -or !$baseUri.IsDefaultPort -or
    $baseUri.UserInfo -or $baseUri.Query -or $baseUri.Fragment -or $segments.Count -ne 3 -or
    $segments[0] -ne "kaylerberserk" -or $segments[1] -ne "WindowsOptimizer" -or
    $segments[2] -notmatch '^(main|[0-9a-fA-F]{40})$') {
    Stop-Launcher "La source doit etre la branche 'main' ou un commit SHA-1 complet du depot officiel WindowsOptimizer." -NoPause
}
$BaseUrl = $baseUri.AbsoluteUri.TrimEnd("/")

$runId = [guid]::NewGuid().ToString("N")
$scriptRoot = Join-Path $env:TEMP ("WindowsOptimizer_aio_{0}" -f $runId)
$scriptPath = Join-Path $scriptRoot "All in One.cmd"
$timerDir = Join-Path $scriptRoot "Tools\Timer & Interrupt"
$timerPath = Join-Path $timerDir "SetTimerResolution.exe"
try {
    New-Item -ItemType Directory -Path $timerDir -Force -ErrorAction Stop | Out-Null
} catch {
    Stop-Launcher "Impossible de preparer le dossier temporaire du launcher : $($_.Exception.Message)" -Cleanup
}
$scriptOrigin = "$BaseUrl/All%20in%20One.cmd"
try {
    Invoke-RestMethod -Uri $scriptOrigin -OutFile $scriptPath -TimeoutSec 60 -ErrorAction Stop
} catch {
    Stop-Launcher "Echec du telechargement du script : $($_.Exception.Message)" -Cleanup
}

if (!(Test-Path -LiteralPath $scriptPath) -or (Get-Item -LiteralPath $scriptPath).Length -eq 0) {
    Stop-Launcher "Le script est vide ou introuvable." -Cleanup
}

try {
    $scriptBytes = [IO.File]::ReadAllBytes($scriptPath)
} catch {
    Stop-Launcher "Impossible de lire le script." -Cleanup
}

$hasInvalidEncoding = $false
foreach ($byte in $scriptBytes) {
    if ($byte -eq 0 -or $byte -gt 0x7F) {
        $hasInvalidEncoding = $true
        break
    }
}
if ($hasInvalidEncoding) {
    Stop-Launcher "Le script doit etre en ASCII sans BOM." -Cleanup
}

$scriptContent = [Text.Encoding]::ASCII.GetString($scriptBytes)
try {
    $scriptContent = [regex]::Replace($scriptContent, "\r\n|\r|\n", "`r`n")
    [IO.File]::WriteAllText($scriptPath, $scriptContent, [Text.Encoding]::ASCII)
} catch {
    Stop-Launcher "Impossible de preparer le script telecharge en CRLF." -Cleanup
}
$firstLine = ($scriptContent -split "\r\n|\r|\n", 2)[0]
if ($firstLine -notmatch '^@echo off\s*$' -or $scriptContent.Length -lt 100000 -or
    $scriptContent -notmatch '(?m)^:MENU_PRINCIPAL\s*$' -or
    $scriptContent -notmatch '(?m)^:END_SCRIPT\s*$') {
    Stop-Launcher "Le fichier recu n'est pas un script WindowsOptimizer valide." -Cleanup
}

if ($VerifyOnly) {
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = ($sha256.ComputeHash([Text.Encoding]::ASCII.GetBytes($scriptContent)) |
            ForEach-Object { $_.ToString("x2") }) -join ""
    } finally {
        $sha256.Dispose()
    }
    Write-Host "[OK] Launcher et batch valides." -ForegroundColor Green
    Write-Host "     Batch : $scriptOrigin"
    Write-Host "     Racine de publication : $BaseUrl"
    Write-Host "     SHA-256 du batch prepare : $hash"
    Remove-Item -LiteralPath $scriptRoot -Recurse -Force -ErrorAction SilentlyContinue
    exit 0
}

$timerTemp = "$timerPath.download"
$timerOrigin = "$BaseUrl/Tools/Timer%20%26%20Interrupt/SetTimerResolution.exe"
try {
    Invoke-WebRequest -Uri $timerOrigin -OutFile $timerTemp -UseBasicParsing -TimeoutSec 45 -ErrorAction Stop
    $timerBytes = [IO.File]::ReadAllBytes($timerTemp)
    $peOffset = [BitConverter]::ToInt32($timerBytes, 60)
    if ($timerBytes.Length -lt 10000 -or $timerBytes[0] -ne 77 -or $timerBytes[1] -ne 90 -or
        $peOffset -lt 64 -or $peOffset + 4 -gt $timerBytes.Length -or
        $timerBytes[$peOffset] -ne 80 -or $timerBytes[$peOffset + 1] -ne 69 -or
        $timerBytes[$peOffset + 2] -ne 0 -or $timerBytes[$peOffset + 3] -ne 0) {
        throw "binaire PE invalide"
    }
    Move-Item -LiteralPath $timerTemp -Destination $timerPath -Force -ErrorAction Stop
} catch {
    Remove-Item -LiteralPath $timerTemp -Force -ErrorAction SilentlyContinue
    Write-Host "[INFO] Prechargement de SetTimerResolution impossible ; le batch tentera curl, BITS puis PowerShell." -ForegroundColor Yellow
}

$exitCode = 1
try {
    $env:WINOPT_RELEASE_BASE_URL = $BaseUrl
    $quote = [char]34
    $cmdArguments = "/d /e:on /v:off /s /c $quote$quote$scriptPath$quote$quote"
    $start = @{
        FilePath = $env:ComSpec
        ArgumentList = $cmdArguments
        WindowStyle = "Normal"
        Wait = $true
        PassThru = $true
        ErrorAction = "Stop"
    }
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $start.Verb = "RunAs"
    }
    $process = Start-Process @start
    $exitCode = $process.ExitCode
} catch {
    Write-Host "[ERREUR] Lancement administrateur annule ou impossible : $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Remove-Item -LiteralPath $scriptRoot -Recurse -Force -ErrorAction SilentlyContinue
}
exit $exitCode
