<#
.SYNOPSIS
  Instala o ARK globalmente em %USERPROFILE%\.claude (Windows).

.DESCRIPTION
  Equivalente Windows do link-skills.sh, mas cobrindo o kit inteiro:

    - liga cada pasta de .claude/skills/*   -> ~/.claude/skills/<nome>
    - liga cada pasta de .claude/commands/* -> ~/.claude/skills/<nome>
      (o diretorio ~/.claude/commands/ so aceita arquivos .md soltos; pastas com
       SKILL.md nao registram nada la, entao os comandos do ARK viram skills
       pessoais e continuam sendo chamados como /commit, /start-issue, ...)
    - registra os hooks do ARK em ~/.claude/settings.json com caminho absoluto
    - define os toggles (BOARD_SYNC, AUTO_BRANCH, ...) e ARK_HOME no bloco env
    - importa as rules genericas (karpathy-principles.md, code-conventions.md)
      em ~/.claude/CLAUDE.md

  Nada e copiado: sao links para o clone, entao "git pull" aqui atualiza tudo.
  Links existentes sao refeitos; pastas REAIS de mesmo nome em ~/.claude/skills
  nunca sao apagadas (o script avisa e pula).

  Nao requer administrador: tenta symlink e, se o Windows recusar (sem Modo
  Desenvolvedor), cai para junction, que dispensa privilegio.

.PARAMETER DryRun
  Mostra o que faria, sem escrever nada.

.PARAMETER Uninstall
  Remove os links do ARK, o bloco de hooks e a linha de import. Nao apaga o clone.

.NOTES
  Roda no Windows PowerShell 5.1 (executavel "powershell") e no PowerShell 7+
  ("pwsh"). Se o "pwsh" nao existir na sua maquina, use "powershell".

.EXAMPLE
  powershell -File .\.claude\scripts\install-global.ps1
  powershell -File .\.claude\scripts\install-global.ps1 -DryRun
  powershell -File .\.claude\scripts\install-global.ps1 -Uninstall
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Uninstall,
    [string]$ClaudeHome = (Join-Path $HOME '.claude')
)

$ErrorActionPreference = 'Stop'
# Identifica os hooks deste kit pelo NOME DO ARQUIVO .sh, nao por um comentario no
# comando: em cmd.exe o '#' nao e comentario e viraria argumento do bash.
$ARK_HOOK_FILES = @('stop-commit-reminder.sh', 'grill-log.sh')

# O script mora em .claude/scripts/, entao .. e a propria pasta .claude.
$ArkHome  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RepoRoot = (Resolve-Path (Join-Path $ArkHome '..')).Path
if (-not (Test-Path (Join-Path $ArkHome 'skills'))) {
    throw "Nao encontrei $ArkHome\skills. Rode o script de dentro do clone do ARK."
}

# Caminho no formato que o bash do Git para Windows entende (C:/... com barras normais)
function ConvertTo-PosixPath([string]$p) { ($p -replace '\\', '/') }

function Write-Step($msg) { Write-Host "  $msg" }
function Write-Head($msg) { Write-Host ""; Write-Host $msg -ForegroundColor Cyan }

# ---------------------------------------------------------------- links

# Pasta real em ~/.claude/skills cujo conteudo e byte-a-byte igual ao do clone e
# copia redundante de uma instalacao antiga: trocar por link nao perde nada. Qualquer
# diferenca, por menor que seja, faz a pasta ser respeitada como conteudo do usuario.
function Test-SameTree {
    param([string]$A, [string]$B)

    $fa = @(Get-ChildItem -LiteralPath $A -Recurse -File -Force -ErrorAction SilentlyContinue)
    $fb = @(Get-ChildItem -LiteralPath $B -Recurse -File -Force -ErrorAction SilentlyContinue)
    if ($fa.Count -ne $fb.Count -or $fa.Count -eq 0) { return $false }

    # Caminho relativo normalizado: os dois lados passam pela mesma conta, entao o
    # separador inicial que sobra e o mesmo nos dois e nao atrapalha a comparacao.
    $rel = { param($root, $f) (ConvertTo-PosixPath $f.FullName.Substring($root.Length)) }
    $mapB = @{}
    foreach ($f in $fb) { $mapB[(& $rel $B $f)] = $f.FullName }

    foreach ($f in $fa) {
        $key = & $rel $A $f
        if (-not $mapB.ContainsKey($key)) { return $false }
        $ha = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        $hb = (Get-FileHash -LiteralPath $mapB[$key] -Algorithm SHA256).Hash
        if ($ha -ne $hb) { return $false }
    }
    return $true
}

function New-DirLink {
    param([string]$Link, [string]$Target)

    $item = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
    if ($item) {
        $isLink = $item.LinkType -in @('SymbolicLink', 'Junction')
        if (-not $isLink) {
            if (-not (Test-SameTree $item.FullName $Target)) {
                Write-Warning "PULADO: $Link existe como pasta real e diferente do clone. Mova/apague na mao se quiser linkar."
                return 'skipped'
            }
            if ($DryRun) { Write-Step "trocaria por link $($item.Name) (copia identica ao clone)"; return 'adopted' }
            Remove-Item -LiteralPath $item.FullName -Recurse -Force
            Write-Step "copia identica trocada por link: $($item.Name)"
            $item = $null
        }
    }
    if ($item) {
        if ($DryRun) { Write-Step "religaria $($item.Name)"; return 'relinked' }
        # Remove-Item em link de diretorio: -Recurse aqui apaga so o link, nao o alvo,
        # mas .Delete() e mais explicito e seguro.
        $item.Delete()
    }

    if ($DryRun) { Write-Step "criaria  $(Split-Path $Link -Leaf) -> $Target"; return 'created' }

    try {
        New-Item -ItemType SymbolicLink -Path $Link -Target $Target -Force | Out-Null
        return 'created'
    } catch {
        New-Item -ItemType Junction -Path $Link -Target $Target -Force | Out-Null
        return 'created-junction'
    }
}

# Links em ~/.claude/skills que apontam para dentro deste clone. Base tanto da
# poda (skill renomeada/removida do ARK deixa link orfao) quanto do -Uninstall.
# So mexe em link cujo alvo esta sob $ArkHome, nunca em skill de outra origem.
function Get-ArkLinks([string]$SkillsDir) {
    if (-not (Test-Path $SkillsDir)) { return @() }
    Get-ChildItem -LiteralPath $SkillsDir -Force | Where-Object {
        $_.LinkType -in @('SymbolicLink', 'Junction')
    } | Where-Object {
        $t = @($_.Target)[0]
        $t -and ((ConvertTo-PosixPath $t) -like "$(ConvertTo-PosixPath $ArkHome)/*")
    }
}

function Get-ArkSkillDirs {
    $dirs = @()
    foreach ($sub in @('skills', 'commands')) {
        $base = Join-Path $ArkHome $sub
        if (-not (Test-Path $base)) { continue }
        Get-ChildItem -LiteralPath $base -Directory | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName 'SKILL.md')) { $dirs += $_ }
        }
    }
    $dirs
}

# --------------------------------------------------------------- settings

# ConvertFrom-Json devolve PSCustomObject; hashtable e mais facil de mesclar e
# funciona igual no Windows PowerShell 5.1 (que nao tem -AsHashtable).
function ConvertTo-Hashtable($obj) {
    if ($null -eq $obj) { return $null }
    if ($obj -is [System.Collections.IDictionary]) {
        $h = @{}; foreach ($k in $obj.Keys) { $h[$k] = ConvertTo-Hashtable $obj[$k] }; return $h
    }
    if ($obj -is [System.Management.Automation.PSCustomObject]) {
        $h = @{}; foreach ($p in $obj.PSObject.Properties) { $h[$p.Name] = ConvertTo-Hashtable $p.Value }; return $h
    }
    if ($obj -is [System.Collections.IEnumerable] -and $obj -isnot [string]) {
        return @(foreach ($i in $obj) { ConvertTo-Hashtable $i })
    }
    return $obj
}

function Read-Settings([string]$Path) {
    if (-not (Test-Path $Path)) { return @{} }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
    ConvertTo-Hashtable (ConvertFrom-Json $raw)
}

function Save-Settings([string]$Path, $Data) {
    $json = ($Data | ConvertTo-Json -Depth 20)
    if ($DryRun) { Write-Step "gravaria $Path"; return }
    # UTF8 sem BOM: o parser de settings do Claude Code nao gosta de BOM.
    [System.IO.File]::WriteAllText($Path, $json + "`n", (New-Object System.Text.UTF8Encoding $false))
}

# Set-Content -Encoding UTF8 grava BOM no Windows PowerShell 5.1, e o CLAUDE.md
# com BOM nao e lido direito. Escrever pelo .NET da UTF-8 sem BOM nas duas versoes.
function Write-Utf8Lines([string]$Path, $Lines) {
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllLines($Path, [string[]]@($Lines), (New-Object System.Text.UTF8Encoding $false))
}

# Remove entradas de hook cujo command carrega o marcador do ARK.
function Remove-ArkHooks($settings) {
    if (-not $settings.ContainsKey('hooks')) { return }
    foreach ($event in @($settings.hooks.Keys)) {
        $kept = @()
        foreach ($group in @($settings.hooks[$event])) {
            $inner = @()
            foreach ($h in @($group.hooks)) {
                $isArk = $false
                foreach ($f in $ARK_HOOK_FILES) { if ("$($h.command)" -like "*$f*") { $isArk = $true } }
                if (-not $isArk) { $inner += $h }
            }
            if ($inner.Count -gt 0) { $group.hooks = $inner; $kept += $group }
        }
        if ($kept.Count -gt 0) { $settings.hooks[$event] = $kept } else { $settings.hooks.Remove($event) }
    }
    if ($settings.hooks.Count -eq 0) { $settings.Remove('hooks') }
}

function Add-ArkHooks($settings) {
    $hooksDir = ConvertTo-PosixPath (Join-Path $ArkHome 'hooks')
    if (-not $settings.ContainsKey('hooks')) { $settings.hooks = @{} }

    $stop = @{ type = 'command'; command = "bash `"$hooksDir/stop-commit-reminder.sh`"" }
    $grill = @{ type = 'command'; command = "bash `"$hooksDir/grill-log.sh`"" }

    if (-not $settings.hooks.ContainsKey('Stop')) { $settings.hooks.Stop = @() }
    $settings.hooks.Stop = @(@($settings.hooks.Stop) + @(@{ hooks = @($stop) }))

    if (-not $settings.hooks.ContainsKey('UserPromptExpansion')) { $settings.hooks.UserPromptExpansion = @() }
    $settings.hooks.UserPromptExpansion = @(@($settings.hooks.UserPromptExpansion) +
        @(@{ matcher = 'grill-(me|with-docs)'; hooks = @($grill) }))
}

# ------------------------------------------------------------- CLAUDE.md

# As rules genericas do ARK entram por import, nao por copia: assim melhoria no clone
# vale em toda sessao, e o .claude/ do projeto so guarda o que descreve o projeto.
$ARK_RULE_IMPORTS = @('karpathy-principles.md', 'code-conventions.md')

function Set-RulesImport([string]$ClaudeMd, [bool]$Remove) {
    $lines = @($ARK_RULE_IMPORTS | ForEach-Object {
        "@$(ConvertTo-PosixPath (Join-Path $ArkHome "rules/$_"))"
    })
    $pattern = '(' + (($ARK_RULE_IMPORTS | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')$'
    $existing = if (Test-Path $ClaudeMd) { Get-Content -LiteralPath $ClaudeMd -Encoding UTF8 } else { @() }
    $clean = @($existing | Where-Object { $_ -notmatch $pattern -and $_ -ne '<!-- ARK -->' })

    if ($Remove) {
        if ($clean.Count -eq $existing.Count) { return $false }
        if (-not $DryRun) { Write-Utf8Lines $ClaudeMd $clean }
        return $true
    }

    # Reescreve sempre que faltar qualquer um dos imports: assim uma rule nova entra
    # numa reinstalacao, em vez de depender de -Uninstall antes.
    if (-not ($lines | Where-Object { $existing -notcontains $_ })) { return $false }
    $out = @($clean + @('<!-- ARK -->') + $lines)
    if (-not $DryRun) { Write-Utf8Lines $ClaudeMd $out }
    return $true
}

# ============================================================== execucao

$skillsDir   = Join-Path $ClaudeHome 'skills'
$settingsPath = Join-Path $ClaudeHome 'settings.json'
$claudeMd     = Join-Path $ClaudeHome 'CLAUDE.md'

Write-Host ""
Write-Host "ARK -> $ClaudeHome" -ForegroundColor Green
Write-Host "clone: $RepoRoot"
if ($DryRun) { Write-Host "(dry-run: nada sera escrito)" -ForegroundColor Yellow }

if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null }

$settings = Read-Settings $settingsPath

if ($Uninstall) {
    Write-Head "Removendo links"
    foreach ($item in Get-ArkLinks $skillsDir) {
        Write-Step "removendo $($item.Name)"
        if (-not $DryRun) { $item.Delete() }
    }

    Write-Head "Limpando settings.json e CLAUDE.md"
    Remove-ArkHooks $settings
    if ($settings.ContainsKey('env')) {
        foreach ($k in @('ARK_HOME', 'GRILL_LOG', 'BOARD_SYNC', 'PR_REVIEW_PARALLEL', 'AUTO_BRANCH')) {
            $settings.env.Remove($k) | Out-Null
        }
        if ($settings.env.Count -eq 0) { $settings.Remove('env') }
    }
    Save-Settings $settingsPath $settings
    Set-RulesImport $claudeMd $true | Out-Null
    Write-Host ""
    Write-Host "Desinstalado. O clone em $RepoRoot nao foi tocado." -ForegroundColor Green
    return
}

Write-Head "Skills e comandos"
$created = 0; $skipped = 0; $junctions = 0
foreach ($d in Get-ArkSkillDirs) {
    $r = New-DirLink -Link (Join-Path $skillsDir $d.Name) -Target $d.FullName
    switch ($r) {
        'skipped'          { $skipped++ }
        'created-junction' { $junctions++; $created++; Write-Step "$($d.Name)  (junction)" }
        default            { $created++; Write-Step "$($d.Name)" }
    }
}

# Poda: skill renomeada ou removida do ARK deixaria um link apontando para o vazio,
# e o Claude Code reclamaria dela em toda sessao. Comparar pelo alvo (e nao pelo
# nome) tambem cobre o caso de a pasta ter mudado de skills/ para commands/.
$valid = @{}
foreach ($d in Get-ArkSkillDirs) { $valid[$d.FullName] = $true }
$pruned = 0
foreach ($item in Get-ArkLinks $skillsDir) {
    $t = @($item.Target)[0]
    if ($valid.ContainsKey($t) -or (Test-Path $t)) { continue }
    Write-Step "removendo orfao $($item.Name)"
    if (-not $DryRun) { $item.Delete() }
    $pruned++
}

Write-Head "settings.json"
if (-not $settings.ContainsKey('env')) { $settings.env = @{} }
$settings.env.ARK_HOME           = ConvertTo-PosixPath $ArkHome
$settings.env.GRILL_LOG          = 'on'
$settings.env.BOARD_SYNC         = 'on'
$settings.env.PR_REVIEW_PARALLEL = 'on'
$settings.env.AUTO_BRANCH        = 'on'
Write-Step "env: ARK_HOME + 4 toggles"
Remove-ArkHooks $settings
Add-ArkHooks $settings
Write-Step "hooks: Stop + UserPromptExpansion (caminho absoluto)"
Save-Settings $settingsPath $settings

Write-Head "CLAUDE.md"
if (Set-RulesImport $claudeMd $false) { Write-Step "imports das rules genericas atualizados ($($ARK_RULE_IMPORTS -join ', '))" }
else { Write-Step "import ja presente" }

Write-Host ""
Write-Host "Pronto: $created link(s), $pruned orfao(s) removido(s), $skipped pulado(s)." -ForegroundColor Green
if ($junctions -gt 0) {
    Write-Host "$junctions criado(s) como junction (Modo Desenvolvedor desligado). Funciona igual." -ForegroundColor Yellow
}
Write-Host "Skill alterada: nada a fazer, o link ja aponta para o clone."
Write-Host "Skill nova, renomeada ou removida: git pull e rode este script de novo."
Write-Host "Confira com: claude  ->  /help"
