param(
    [Parameter(Mandatory = $true)]
    [string]$ProgressLog
)

$resolvedLog = [System.IO.Path]::GetFullPath($ProgressLog)
if (-not (Test-Path -LiteralPath $resolvedLog -PathType Leaf)) {
    throw "Progress log does not exist: $resolvedLog"
}

$host.UI.RawUI.WindowTitle = "COMSOL Progress (read-only) - $resolvedLog"
Write-Host "Read-only COMSOL progress monitor"
Write-Host $resolvedLog
Get-Content -LiteralPath $resolvedLog -Encoding UTF8 -Tail 80 -Wait
