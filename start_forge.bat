@echo off
setlocal EnableExtensions

REM Starts Forge services for local Windows development.
REM - Optionally starts docker infra (postgres + redis).
REM - Launches backend (uvicorn) and frontend (next dev) in separate terminals.

cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo ERROR: .venv was not found. Run update_and_install.bat first.
  exit /b 1
)

if not exist "apps\frontend\node_modules" (
  echo ERROR: apps\frontend\node_modules is missing. Run update_and_install.bat first.
  exit /b 1
)

where docker >nul 2>&1
if not errorlevel 1 (
  docker compose up -d postgres redis >nul 2>&1
  if errorlevel 1 (
    echo WARNING: Could not start docker services (postgres/redis). If already running, you can ignore this.
  ) else (
    echo Started postgres and redis via docker compose.
  )
) else (
  echo WARNING: docker not found. Ensure postgres/redis are running before using backend features.
)

echo Starting backend on http://localhost:8000 ...
start "Forge Backend" cmd /k "cd /d %~dp0apps\backend && call %~dp0.venv\Scripts\activate.bat && uvicorn app.main:app --reload --port 8000"

echo Starting frontend on http://localhost:3000 ...
start "Forge Frontend" cmd /k "cd /d %~dp0apps\frontend && npm run dev"

echo.
echo Forge startup commands launched in separate windows.
echo Backend docs: http://localhost:8000/docs
echo Frontend:    http://localhost:3000

exit /b 0
