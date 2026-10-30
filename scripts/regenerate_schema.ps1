# Regenerates src/Database/DieVix_Schema_Firebird5.sql from migrations/V*.sql
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$target = Join-Path $repoRoot 'src\Database\DieVix_Schema_Firebird5.sql'
$migrationsDir = Join-Path $repoRoot 'migrations'

$header = @"
/* =============================================================================
   DieVix - Rotary Die & Keyline Manager
   Firebird 5.0 Database Consolidated Schema & Migrations
   AUTO-GENERATED FILE. DO NOT EDIT DIRECTLY.
   Regenerate using: scripts\regenerate_schema.bat
   Source: migrations\V*.sql
============================================================================= */

"@

$builder = New-Object System.Text.StringBuilder
[void]$builder.Append($header)

$versionEntries = New-Object System.Collections.Generic.List[PSObject]

$files = Get-ChildItem -Path $migrationsDir -Filter 'V*.sql' | Sort-Object Name
foreach ($file in $files) {
    [void]$builder.AppendLine("/* --- Begin Migration: $($file.Name) --- */")
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
    [void]$builder.AppendLine($content)
    [void]$builder.AppendLine("/* --- End Migration: $($file.Name) --- */`r`n")

    if ($file.Name -match '^V(\d+)') {
        $verNum = [int]$matches[1]
        $versionEntries.Add([PSCustomObject]@{
            VersionNum = $verNum
            ScriptName = $file.Name
        })
    }
}

# Append SCHEMA_VERSION registrations so databases created from this file
# are recognized as fully up to date by ApplyMigrations.
[void]$builder.AppendLine("/* =============================================================================")
[void]$builder.AppendLine("   Consolidated Schema Version Registration")
[void]$builder.AppendLine("   Pre-populates SCHEMA_VERSION so migration runner recognizes all applied scripts.")
[void]$builder.AppendLine("============================================================================= */")

foreach ($entry in $versionEntries) {
    [void]$builder.AppendLine("UPDATE OR INSERT INTO SCHEMA_VERSION (VERSION_NUM, SCRIPT_NAME) VALUES ($($entry.VersionNum), '$($entry.ScriptName)') MATCHING (VERSION_NUM);")
}
[void]$builder.AppendLine("")

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($target, $builder.ToString(), $utf8NoBom)
Write-Host "[SUCCESS] Consolidated schema regenerated at $target"
