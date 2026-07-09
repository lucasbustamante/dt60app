@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Terminal Control + App WebSocket

echo ============================================================
echo  Abrindo Terminal Control original...
echo ============================================================
start "Terminal Control" "%~dp0TerminalControlLauncher.exe"

echo.
echo ============================================================
echo  Iniciando ponte WebSocket para o aplicativo...
echo ============================================================
echo.
echo Aguarde alguns segundos. A tela abaixo vai mostrar:
echo  - IP que deve colocar no aplicativo
echo  - Porta que deve colocar no aplicativo
echo.
"%~dp0TerminalControlWebSocketBridge.exe"

pause
