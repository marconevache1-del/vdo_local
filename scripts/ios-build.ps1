# Lancia la build iOS su GitHub Actions e scarica l'IPA non firmato.
# Poi firma e installa l'IPA con Sideloadly.
#
# Uso:  .\scripts\ios-build.ps1
#       .\scripts\ios-build.ps1 -Commit "messaggio"   (committa e fa push prima)
param([string]$Commit)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI non trovata. Installa con: winget install GitHub.cli  poi: gh auth login"
}
gh auth status *> $null
if ($LASTEXITCODE -ne 0) { throw "Non sei loggato. Esegui: gh auth login" }

$branch = (git rev-parse --abbrev-ref HEAD).Trim()

if ($Commit) {
    git add -A
    git commit -m $Commit
} elseif (git status --porcelain) {
    Write-Warning "Ci sono modifiche non committate: la build usa solo cio' che e' su GitHub. Usa -Commit 'messaggio' per includerle."
}
git push origin $branch

gh workflow run ios-build.yml --ref $branch
Start-Sleep -Seconds 8
$runId = gh run list --workflow ios-build.yml --branch $branch --limit 1 --json databaseId --jq '.[0].databaseId'
Write-Host "Build avviata (run $runId). Attendo il termine..."
gh run watch $runId --exit-status
if ($LASTEXITCODE -ne 0) { throw "Build fallita. Log: gh run view $runId --log-failed" }

$out = Join-Path (Get-Location) 'build\ipa'
New-Item -ItemType Directory -Force $out | Out-Null
gh run download $runId --name vdo_local_claude-ipa --dir $out
Write-Host "IPA pronto: $out\vdo_local_claude.ipa  -> trascinalo in Sideloadly"
