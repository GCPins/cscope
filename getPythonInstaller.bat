@echo off
setlocal

REM Specify the Python version and architecture you want to download
set PYTHON_VERSION=3.9.7
set PYTHON_ARCH=64

REM Specify the Python installer URL
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-amd%PYTHON_ARCH%-embed-amd64.zip

REM Specify the download location
set DOWNLOAD_DIR=%USERPROFILE%\Downloads
set PYTHON_INSTALLER=%DOWNLOAD_DIR%\python-installer.zip

REM Create the download directory if it doesn't exist
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

REM Download the Python installer
curl -o "%PYTHON_INSTALLER%" "%PYTHON_URL%"

REM Check if the download was successful
if %errorlevel% neq 0 (
    echo Download failed.
) else (
    echo Download successful. Python installer saved to %PYTHON_INSTALLER%
)

endlocal
