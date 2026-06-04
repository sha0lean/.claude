# Choisit un pack aléatoire pour la session, l'écrit dans .state.json,
# puis délègue à peon.ps1 en rejouant le même stdin.
$ErrorActionPreference = 'SilentlyContinue'

$peonDir    = if ($env:CLAUDE_CONFIG_DIR) { "$env:CLAUDE_CONFIG_DIR/hooks/peon-ping" } else { "$env:USERPROFILE/.claude/hooks/peon-ping" }
$configPath = Join-Path $peonDir "config.json"
$statePath  = Join-Path $peonDir ".state.json"

# Lire stdin une seule fois
$raw = [Console]::In.ReadToEnd()

# Extraire l'identifiant de session
$sessionId = "default"
try {
    $data = $raw | ConvertFrom-Json
    if     ($data.session_id)       { $sessionId = $data.session_id }
    elseif ($data.conversation_id)  { $sessionId = $data.conversation_id }
    elseif ($data.sessionId)        { $sessionId = $data.sessionId }
} catch {}

# Lire la liste de rotation
$rotation = @()
$config = $null
try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    if ($config.pack_rotation -and $config.pack_rotation.Count -gt 0) {
        $rotation = @($config.pack_rotation)
    }
} catch {}

if ($rotation.Count -gt 0) {
    # Vérifier si ce session_id a déjà un pack assigné
    $state = $null
    try { $state = Get-Content $statePath -Raw | ConvertFrom-Json } catch {}
    if (-not $state) { $state = [PSCustomObject]@{} }

    $sessionPacks = $state.session_packs
    $alreadyAssigned = $sessionPacks -and $sessionPacks.PSObject.Properties[$sessionId]

    if (-not $alreadyAssigned) {
        $chosen = $rotation | Get-Random

        if (-not $sessionPacks) {
            $state | Add-Member -NotePropertyName "session_packs" -NotePropertyValue ([PSCustomObject]@{}) -Force
            $sessionPacks = $state.session_packs
        }
        $packData = @{ pack = $chosen; last_used = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
        $sessionPacks | Add-Member -NotePropertyName $sessionId -NotePropertyValue $packData -Force
        $state | ConvertTo-Json -Depth 10 | Set-Content $statePath -NoNewline
        Add-Content $statePath "`n"
    }
}

# Déléguer à peon.ps1 en rejouant stdin
$peonScript = Join-Path $peonDir "peon.ps1"
$raw | & powershell -NoProfile -NonInteractive -File $peonScript
exit $LASTEXITCODE
