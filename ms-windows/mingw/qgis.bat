@echo off
setlocal EnableExtensions
set "HERE=%~dp0"
set "PATH=%HERE%;%PATH%"
start "" "%HERE%qgis.exe"
