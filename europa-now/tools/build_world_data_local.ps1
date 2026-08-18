$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$sourcePath = Join-Path $PSScriptRoot "population_source.md"
$populationPath = Join-Path (Join-Path $root "data") "world_population.json"
$flagsDir = Join-Path (Join-Path $root "data") "flags"
$geojsonPath = Join-Path (Join-Path $root "data") "ne_110m_admin_0_countries.geojson"

if (-not (Test-Path $sourcePath)) {
    throw "Missing population source file: $sourcePath"
}

$text = Get-Content -Path $sourcePath -Raw -Encoding UTF8
$population = @{}
foreach ($line in ($text -split "`n")) {
    if ($line -notmatch '^\|') { continue }
    $cols = @($line -split '\|' | ForEach-Object { $_.Trim() })
    if ($cols.Count -lt 10) { continue }
    $iso3 = $cols[8]
    if ($iso3 -notmatch '^[A-Z]{3}$') { continue }
    $popToken = ($cols[4] -split '\s+')[0]
    $popToken = $popToken -replace '\.', ''
    if ($popToken -match '^\d+$') {
        $population[$iso3] = [int64]$popToken
    }
}

if ($population.ContainsKey("XXK")) { $population["KOS"] = $population["XXK"] }
if ($population.ContainsKey("PSE")) { $population["PSX"] = $population["PSE"] }
if ($population.ContainsKey("ESH")) { $population["SAH"] = $population["ESH"] }
$population["SOL"] = 3500000

$population | ConvertTo-Json -Depth 2 | Set-Content -Path $populationPath -Encoding UTF8
Write-Host "Wrote $($population.Count) population entries."

New-Item -ItemType Directory -Force -Path $flagsDir | Out-Null
$geojson = Get-Content -Path $geojsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$iso2Codes = @{}
foreach ($feature in $geojson.features) {
    $props = $feature.properties
    $iso3 = [string]$props.ADM0_A3
    $a2 = [string]$props.ISO_A2
    if ($a2 -eq "-99" -or [string]::IsNullOrWhiteSpace($a2)) {
        $a2 = [string]$props.ISO_A2_EH
    }
    if ($a2 -match '^([A-Z]{2})') {
        $iso2Codes[$Matches[1].ToLower()] = $true
    }
    if ($iso3 -eq "KOS") { $iso2Codes["xk"] = $true }
}

$downloaded = 0
$failed = 0
foreach ($code in ($iso2Codes.Keys | Sort-Object)) {
    $outPath = Join-Path $flagsDir "$code.png"
    if (Test-Path $outPath) { continue }
    $url = "https://flagcdn.com/w80/$code.png"
    try {
        Invoke-WebRequest -Uri $url -OutFile $outPath -UseBasicParsing
        $downloaded++
        Start-Sleep -Milliseconds 80
    }
    catch {
        Write-Warning "Failed to download flag for $code"
        $failed++
    }
}
Write-Host "Flags downloaded: $downloaded, failed: $failed"
