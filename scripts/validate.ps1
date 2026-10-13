param([switch]$SkipInit)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    & terraform fmt -check -recursive
    if ($LASTEXITCODE -ne 0) { throw 'terraform fmt failed' }
    foreach ($template in Get-ChildItem -LiteralPath (Join-Path $repoRoot 'templates') -Directory | Sort-Object Name) {
        Write-Host "Validating $($template.Name)"
        if (-not $SkipInit) {
            & terraform "-chdir=$($template.FullName)" init -backend=false -input=false -lockfile=readonly
            if ($LASTEXITCODE -ne 0) { throw "init failed: $($template.Name)" }
        }
        & terraform "-chdir=$($template.FullName)" validate
        if ($LASTEXITCODE -ne 0) { throw "validate failed: $($template.Name)" }
        & terraform "-chdir=$($template.FullName)" test -no-color
        if ($LASTEXITCODE -ne 0) { throw "tests failed: $($template.Name)" }
    }
    & python -m unittest discover -s tests -v
    if ($LASTEXITCODE -ne 0) { throw 'worker tests failed' }
} finally { Pop-Location }
