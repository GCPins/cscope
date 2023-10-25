@echo off

setlocal enabledelayedexpansion

:: Set the directory name
set "directoryName=Python"

:: Determine the full path
set "directoryPath=%APPDATA%\Godot\app_userdata\C-Scope\%directoryName%"

:: Create the directory if it doesn't exist
if not exist "!directoryPath!" (
    mkdir "!directoryPath!"
    if errorlevel 1 (
        echo Failed to create the directory.
        goto :EOF
    ) else (
        echo Directory created successfully.
    )
)

:: Copy files to the Python directory
copy "courses.py" "!directoryPath!"
copy "submission.py" "!directoryPath!"

if errorlevel 1 (
    echo Failed to copy files to the Python directory.
) else (
    echo Files copied successfully.
)


python --version
pip --version
python.exe -m pip install --upgrade pip
python --version
pip --version

endlocal
