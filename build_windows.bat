@echo off
echo [1/3] Cleaning project...
call flutter clean

echo [2/3] Getting dependencies...
call flutter pub get

echo [3/3] Building EXE file...
:: بما أن flutter doctor أخضر، سنعتمد على flutter build مباشرة
call flutter build windows

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build failed.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Build successful! The executable can be found in:
echo build\windows\x64\runner\Release\
echo.
pause
