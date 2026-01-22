@echo off
setlocal EnableExtensions
set "QGIS_DEBUG=1"
set "QGIS_LOG_FILE=%TEMP%\qgis.log"
set "HERE=%~dp0"
set "PATH=%HERE%;%PATH%"
start "" "%HERE%qgis.exe"
