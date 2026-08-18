# Validates world map country filter (mirrors GeoJsonLoader logic).
param(
    [string]$GeoJsonPath = "C:\Projects\europa-now\Europa-Now\europa-now\data\ne_110m_admin_0_countries.geojson"
)

$MIN_AREA = 500.0
$EXCLUDED = @("ATA","ATF","NCL","PRI","GRL","FLK","CYN","SOL")
$FORCE = @("TWN","KOS","ISR","PSX","SAH")
$PLAYABLE = @("Sovereign country","Sovereignty","Country","Disputed","Indeterminate")

function Get-RingAreaKm2([object[]]$ring) {
    if ($ring.Count -lt 3) { return 0.0 }
    $area = 0.0
    for ($i = 0; $i -lt $ring.Count; $i++) {
        $j = ($i + 1) % $ring.Count
        $lon1 = [Math]::PI / 180.0 * [double]$ring[$i].Value[0]
        $lat1 = [Math]::PI / 180.0 * [double]$ring[$i].Value[1]
        $lon2 = [Math]::PI / 180.0 * [double]$ring[$j].Value[0]
        $lat2 = [Math]::PI / 180.0 * [double]$ring[$j].Value[1]
        $area += ($lon2 - $lon1) * (2.0 + [Math]::Sin($lat1) + [Math]::Sin($lat2))
    }
    return [Math]::Abs($area) * 6371.0 * 6371.0 * 0.5
}

function Get-GeometryAreaKm2($geometry) {
    $total = 0.0
    if ($geometry.type -eq "Polygon") {
        $total += Get-RingAreaKm2 $geometry.coordinates[0]
    }
    elseif ($geometry.type -eq "MultiPolygon") {
        foreach ($polygon in $geometry.coordinates) {
            $total += Get-RingAreaKm2 $polygon[0]
        }
    }
    return $total
}

function Get-BboxAreaKm2($geometry) {
    $minLon = 999.0; $maxLon = -999.0; $minLat = 999.0; $maxLat = -999.0
    $rings = @()
    if ($geometry.type -eq "Polygon") { $rings = @($geometry.coordinates[0]) }
    elseif ($geometry.type -eq "MultiPolygon") {
        foreach ($polygon in $geometry.coordinates) { $rings += ,$polygon[0] }
    }
    foreach ($ring in $rings) {
        foreach ($coord in $ring) {
            $lon = [double]$coord[0]; $lat = [double]$coord[1]
            if ($lon -lt $minLon) { $minLon = $lon }
            if ($lon -gt $maxLon) { $maxLon = $lon }
            if ($lat -lt $minLat) { $minLat = $lat }
            if ($lat -gt $maxLat) { $maxLat = $lat }
        }
    }
    if ($minLon -gt 900) { return 0.0 }
    $latSpan = [Math]::Abs($maxLat - $minLat)
    $lonSpan = [Math]::Abs($maxLon - $minLon)
    $avgLat = [Math]::PI / 180.0 * (($minLat + $maxLat) * 0.5)
    return $latSpan * 111.0 * $lonSpan * 111.0 * [Math]::Cos($avgLat)
}

$json = Get-Content $GeoJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$included = @()
$excludedSmall = @()
$excludedOther = @()

foreach ($feature in $json.features) {
    $p = $feature.properties
    $iso = $p.ADM0_A3
    if ($iso -eq "-99" -or [string]::IsNullOrWhiteSpace($iso)) { $iso = $p.BRK_A3 }
    $area = Get-GeometryAreaKm2 $feature.geometry
    if ($area -le 0) { $area = Get-BboxAreaKm2 $feature.geometry }

    if ($EXCLUDED -contains $iso) {
        $excludedOther += [PSCustomObject]@{ iso = $iso; name = $p.ADMIN; reason = "excluded list"; area = [int]$area }
        continue
    }
    if ($FORCE -contains $iso) {
        if ($area -ge $MIN_AREA) {
            $included += [PSCustomObject]@{ iso = $iso; name = $p.ADMIN; area = [int]$area; type = $p.TYPE }
        }
        else {
            $excludedSmall += [PSCustomObject]@{ iso = $iso; name = $p.ADMIN; area = [int]$area; type = $p.TYPE }
        }
        continue
    }
    if ($area -lt $MIN_AREA) {
        $excludedSmall += [PSCustomObject]@{ iso = $iso; name = $p.ADMIN; area = [int]$area; type = $p.TYPE }
        continue
    }
    if ($PLAYABLE -notcontains $p.TYPE) {
        $excludedOther += [PSCustomObject]@{ iso = $iso; name = $p.ADMIN; reason = "type=$($p.TYPE)"; area = [int]$area }
        continue
    }
    if ($p.TYPE -eq "Indeterminate" -and $FORCE -notcontains $iso) {
        $excludedOther += [PSCustomObject]@{ iso = $iso; name = $p.ADMIN; reason = "indeterminate"; area = [int]$area }
        continue
    }
    $included += [PSCustomObject]@{ iso = $iso; name = $p.ADMIN; area = [int]$area; type = $p.TYPE }
}

$AUSTRIA_AREA = 83879.0
$provinceTotal = 0
$provinceByCountry = @{}
foreach ($country in $included) {
    $target = [Math]::Max(1, [int][Math]::Round($country.area / $AUSTRIA_AREA * 9.0))
    if ($country.area -lt 2500) { $target = [Math]::Min([Math]::Max($target, 1), 3) }
    elseif ($country.area -lt $AUSTRIA_AREA * 0.35) { $target = [Math]::Min([Math]::Max($target, 1), 5) }
    elseif ($country.area -lt $AUSTRIA_AREA * 1.8) { $target = [Math]::Min([Math]::Max($target, 3), 12) }
    elseif ($country.area -lt $AUSTRIA_AREA * 6.0) { $target = [Math]::Min([Math]::Max($target, 6), 28) }
    elseif ($country.area -lt $AUSTRIA_AREA * 20.0) { $target = [Math]::Min([Math]::Max($target, 10), 45) }
    else { $target = [Math]::Min([Math]::Max($target, 15), 80) }
    if ($country.iso -eq "AUT") { $target = 9 }
    $caps = @{ RUS = 120; USA = 85; CHN = 85; CAN = 75; BRA = 65; IND = 65; AUS = 50; IDN = 50 }
    if ($caps.ContainsKey($country.iso)) { $target = [Math]::Min($target, $caps[$country.iso]) }
    $provinceByCountry[$country.iso] = $target
    $provinceTotal += $target
}

Write-Output "=== WORLD MAP VALIDATION (PowerShell) ==="
Write-Output "Included countries: $($included.Count)"
Write-Output "Estimated provinces: $provinceTotal"
Write-Output "Excluded small (<500 km2): $($excludedSmall.Count)"
$excludedSmall | Sort-Object area -Descending | Format-Table -AutoSize
Write-Output "Excluded other: $($excludedOther.Count)"
$excludedOther | Format-Table -AutoSize
Write-Output "Top province counts:"
$provinceByCountry.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 12 | ForEach-Object { Write-Output ("  {0}: {1}" -f $_.Key, $_.Value) }
