# session-start-random.ps1
# Hook 2 de SessionStart. Lit le session_id depuis stdin, assigne un pack
# aléatoire pour toute la session (lu par peon.ps1 via session_override).

$ErrorActionPreference = "SilentlyContinue"

$InstallDir = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $InstallDir "config.json"
$StatePath  = Join-Path $InstallDir ".state.json"

# Lire le session ID depuis stdin
$sessionId = $null
try {
    if ([Console]::IsInputRedirected) {
        $reader = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
        $event  = $reader.ReadToEnd() | ConvertFrom-Json
        $reader.Close()
        $sessionId = if ($event.session_id)        { $event.session_id }
                     elseif ($event.conversation_id) { $event.conversation_id }
                     elseif ($event.sessionId)     { $event.sessionId }
                     else                           { $null }
    }
} catch {}

if (-not $sessionId) { exit 0 }

# Choisir un pack aléatoire depuis la rotation
try {
    $config   = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $rotation = @($config.pack_rotation)
    if ($rotation.Count -eq 0) { exit 0 }
} catch { exit 0 }

$chosen = $rotation | Get-Random

# Mettre à jour .state.json
try {
    $state = if (Test-Path $StatePath) { Get-Content $StatePath -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }

    if (-not $state.PSObject.Properties['session_packs']) {
        $state | Add-Member -NotePropertyName 'session_packs' -NotePropertyValue ([PSCustomObject]@{})
    }

    $ts = [int][double]::Parse((Get-Date -UFormat %s))
    $state.session_packs | Add-Member -NotePropertyName $sessionId `
        -NotePropertyValue ([PSCustomObject]@{ pack = $chosen; last_used = $ts }) -Force

    $state | ConvertTo-Json -Depth 10 | Set-Content $StatePath -Encoding UTF8
} catch {}
