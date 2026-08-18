# Downloads flag PNGs and builds world_population.json.
# Population source: Wikipedia "Liste der Staaten der Erde" (DSW 2024), bundled in tools/population_source.md
# Flags source: https://flagcdn.com (CC0)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot "build_world_data_local.ps1")
