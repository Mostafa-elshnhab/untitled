@echo off
echo [1/3] Cleaning project...
call flutter clean
echo [2/3] Getting dependencies...
call flutter pub get
echo [3/3] Building EXE file...
call flutter build windows
echo.
echo ======================================================
echo DONE! You can find your EXE in:
echo build\windows\x64\runner\Release\
echo ======================================================
pause
