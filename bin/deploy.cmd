@echo off
rem Publica la web en personal.us.es (requiere VPN de la US). Ver bin\deploy.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" %*
pause
