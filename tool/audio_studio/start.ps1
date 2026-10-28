$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$StudioRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$RuntimeRoot = Join-Path $StudioRoot 'build\audio-studio-runtime'
$UvExe = Join-Path $RuntimeRoot 'uv.exe'
$UvHash = 'a2a8820d5eea32f08ef467ef3b7f66883a9b076d5737a2fc2fbb5f458d1bb50f'
$UvVersion = '0.13.6'
try {
    if (-not [Environment]::Is64BitOperatingSystem) { throw '64-bit Windows is required.' }
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { throw 'This launcher currently supports x64 Windows, not ARM64.' }
    New-Item -ItemType Directory -Force -Path $RuntimeRoot | Out-Null
    if (-not (Test-Path $UvExe)) {
        Write-Host '[1/3] Downloading the pinned uv environment manager from astral-sh/uv...'
        $Archive = Join-Path $RuntimeRoot 'uv.zip'
        $Expanded = Join-Path $RuntimeRoot 'uv-download'
        Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/astral-sh/uv/releases/download/$UvVersion/uv-x86_64-pc-windows-msvc.zip" -OutFile $Archive
        if ((Get-FileHash $Archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $UvHash) {
            throw 'uv download integrity check failed. Do not run the downloaded file.'
        }
        Expand-Archive -Path $Archive -DestinationPath $Expanded -Force
        $DownloadedUv = Get-ChildItem -Path $Expanded -Filter 'uv.exe' -Recurse | Select-Object -First 1
        if (-not $DownloadedUv) { throw 'Downloaded archive has no uv.exe.' }
        Copy-Item -LiteralPath $DownloadedUv.FullName -Destination $UvExe
    }
    # Private runtime directories: do not install Python globally or alter PATH.
    $env:UV_PYTHON_INSTALL_DIR = Join-Path $RuntimeRoot 'python'
    $env:UV_CACHE_DIR = Join-Path $RuntimeRoot 'uv-cache'
    $env:PYTHONUTF8 = '1'
    $env:PYTHONIOENCODING = 'utf-8'
    $Venv = Join-Path $RuntimeRoot 'venv'
    $Python = Join-Path $Venv 'Scripts\python.exe'
    if (-not (Test-Path $Python)) {
        Write-Host '[2/3] Preparing private Python 3.11 (first launch only)...'
        & $UvExe venv --python 3.11 --managed-python $Venv
        if ($LASTEXITCODE -ne 0) { throw 'Python setup failed. Check your internet connection and rerun.' }
    }
    $Requirements = Join-Path $PSScriptRoot 'requirements.txt'
    $RequirementsHash = (Get-FileHash $Requirements -Algorithm SHA256).Hash
    $ReadyFile = Join-Path $RuntimeRoot 'packages-ready.txt'
    $PackagesReady = (Test-Path $ReadyFile) -and ((Get-Content -LiteralPath $ReadyFile -Raw).Trim() -eq $RequirementsHash)
    if (-not $PackagesReady) {
        Write-Host '[3/3] Installing audio packages (first launch or package update)...'
        & $UvExe pip install --python $Python --only-binary :all: -r $Requirements
        if ($LASTEXITCODE -ne 0) { throw 'Package setup failed. Check the message above and rerun.' }
        Set-Content -LiteralPath $ReadyFile -Value $RequirementsHash -Encoding ASCII
    } else {
        Write-Host '[3/3] Audio packages already installed. No package download needed.'
    }
    Write-Host 'Opening Thai Audio Studio in your default browser...'
    Set-Location -LiteralPath $StudioRoot
    & $Python (Join-Path $PSScriptRoot 'server.py')
    if ($LASTEXITCODE -ne 0) { throw 'Studio exited with an error.' }
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'You can copy this error message for help. No screenshot or cloud credentials are needed.'
    exit 1
}
