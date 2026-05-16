# Loads variables from .env.local into the current PowerShell session.
# Usage: . .\scripts\load-env.ps1   (note the leading dot — dot-source so env vars stick)
# Run BEFORE launching `claude` so the MCP server sees JIRA_API_TOKEN.

$envFile = Join-Path $PSScriptRoot "..\.env.local"
if (-not (Test-Path $envFile)) {
    Write-Error ".env.local not found at $envFile. Copy .env.local.example to .env.local and fill it in."
    return
}

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    if ($line -match '^([^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"').Trim("'")
        Set-Item "env:$name" $value
        Write-Host "Loaded $name" -ForegroundColor DarkGray
    }
}
