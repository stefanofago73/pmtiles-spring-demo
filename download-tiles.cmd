@echo off
REM download-tiles.cmd: Download a PMTiles basemap for the demo (Windows).
REM
REM Prerequisites:
REM   - pmtiles.exe: https://github.com/protomaps/go-pmtiles/releases
REM     Download the Windows binary and place it in your PATH or in this folder.
REM
REM Usage:
REM   download-tiles.cmd                     (Italy, zoom 0-6, ~1.6 MB)
REM   download-tiles.cmd --maxzoom 10        (Italy, zoom 0-10, larger file)

setlocal

set "DEST=src\main\resources\static\data\planet_z6.pmtiles"
set "BBOX=6.63,36.62,18.52,47.09"
set "MAXZOOM=6"
REM Protomaps keeps daily builds for one week: default to yesterday's build (UTC).
REM Override before running:  set SOURCE=https://build.protomaps.com/20261005.pmtiles
if not defined SOURCE (
    for /f %%d in ('powershell -NoProfile -Command "[DateTime]::UtcNow.AddDays(-1).ToString('yyyyMMdd')"') do set "SOURCE=https://build.protomaps.com/%%d.pmtiles"
)

if "%~1"=="--maxzoom" if not "%~2"=="" set "MAXZOOM=%~2"

where pmtiles >nul 2>nul
if errorlevel 1 (
    echo Error: 'pmtiles.exe' not found in PATH.
    echo.
    echo Download it from: https://github.com/protomaps/go-pmtiles/releases
    echo Extract pmtiles.exe and place it in this folder or in your PATH.
    exit /b 1
)

echo Extracting tiles for bbox=%BBOX% --maxzoom=%MAXZOOM% ...
echo Source: %SOURCE%
echo.

if not exist "src\main\resources\static\data" mkdir "src\main\resources\static\data"

pmtiles extract "%SOURCE%" "%DEST%" --bbox=%BBOX% --maxzoom=%MAXZOOM%

if errorlevel 1 (
    echo.
    echo Error: extraction failed.
    echo If that build is not available, pick a date from https://maps.protomaps.com/builds
    echo and run:  set SOURCE=https://build.protomaps.com/YYYYMMDD.pmtiles
    echo then run download-tiles.cmd again.
    exit /b 1
)

echo.
echo Done! Saved to: %DEST%
echo.
echo Start the application:
echo   mvnw.cmd spring-boot:run
echo   Then open http://localhost:8080
