@REM Maven Wrapper: downloads Maven if not present, then runs it.
@REM https://maven.apache.org/wrapper/
@echo off
setlocal

set "MAVEN_PROJECTBASEDIR=%~dp0"
set "WRAPPER_PROPERTIES=%MAVEN_PROJECTBASEDIR%.mvn\wrapper\maven-wrapper.properties"

if not exist "%WRAPPER_PROPERTIES%" (
    echo Error: .mvn\wrapper\maven-wrapper.properties not found. >&2
    exit /b 1
)

for /f "tokens=1,* delims==" %%a in ('findstr /b "distributionUrl" "%WRAPPER_PROPERTIES%"') do set "DIST_URL=%%b"

if not defined MAVEN_USER_HOME set "MAVEN_USER_HOME=%USERPROFILE%\.m2"
set "WRAPPER_DIR=%MAVEN_USER_HOME%\wrapper\dists"

@REM Extract version from URL
for /f "delims=" %%v in ('echo %DIST_URL% ^| findstr /r "[0-9]\.[0-9]\.[0-9]"') do (
    for %%i in (%%v) do set "URL_FILE=%%~ni"
)
set "MVN_VERSION=%URL_FILE:apache-maven-=%"
set "MVN_VERSION=%MVN_VERSION:-bin=%"
set "MAVEN_HOME=%WRAPPER_DIR%\apache-maven-%MVN_VERSION%"

if not exist "%MAVEN_HOME%\bin\mvn.cmd" (
    echo Downloading Maven %MVN_VERSION%...
    mkdir "%WRAPPER_DIR%" 2>nul
    set "TMP_FILE=%WRAPPER_DIR%\maven-%MVN_VERSION%.zip"
    curl -fsSL -o "%TMP_FILE%" "%DIST_URL%"
    if errorlevel 1 (
        echo Error: failed to download Maven. >&2
        exit /b 1
    )
    powershell -Command "Expand-Archive -Path '%TMP_FILE%' -DestinationPath '%WRAPPER_DIR%' -Force"
    del /q "%TMP_FILE%" 2>nul
)

"%MAVEN_HOME%\bin\mvn.cmd" %*
