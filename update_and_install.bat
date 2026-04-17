@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Forge Windows setup script: Python venv + backend/frontend deps + optional local Qwen download.

cd /d "%~dp0"

echo [1/6] Ensuring Python virtual environment exists...
if not exist ".venv\Scripts\python.exe" (
  py -3 -m venv .venv
  if errorlevel 1 (
    echo Failed to create virtualenv with 'py -3'.
    exit /b 1
  )
)

call .venv\Scripts\activate.bat
if errorlevel 1 (
  echo Failed to activate .venv.
  exit /b 1
)

echo [2/6] Upgrading pip/setuptools/wheel...
python -m pip install --upgrade pip setuptools wheel || exit /b 1

echo [3/6] Installing backend dependencies...
pushd apps\backend
python -m pip install -e .[dev] || exit /b 1
popd

echo [4/6] Installing model/runtime helper dependencies...
python -m pip install "huggingface_hub[cli]" unsloth vllm || exit /b 1

echo [5/6] Installing frontend dependencies...
where npm >nul 2>nul
if errorlevel 1 (
  echo npm not found in PATH. Install Node.js 20+ and rerun this script.
  exit /b 1
)
pushd apps\frontend
call npm install || exit /b 1
popd

if not exist ".env" (
  echo [6/6] Creating .env from .env.example
  copy /Y ".env.example" ".env" >nul
)

echo.
set /p OFFLINE_CHOICE="Enable all-local offline mode in .env now? (Y/N): "
if /I "!OFFLINE_CHOICE!"=="Y" (
  powershell -NoProfile -Command "(Get-Content .env) -replace '^ALL_LOCAL_MODE=.*','ALL_LOCAL_MODE=true' -replace '^HF_HUB_OFFLINE=.*','HF_HUB_OFFLINE=1' -replace '^TRANSFORMERS_OFFLINE=.*','TRANSFORMERS_OFFLINE=1' | Set-Content .env"
  echo Set ALL_LOCAL_MODE=true and huggingface offline flags in .env
)

echo.
set /p DOWNLOAD_MODEL="Download Qwen 3.6 from Unsloth now? (Y/N): "
if /I "!DOWNLOAD_MODEL!"=="Y" (
  echo Choose quantization:
  echo   1^) 4-bit (bnb)
  echo   2^) 8-bit/base
  echo   3^) GGUF Q4_K_M
  set /p QUANT_CHOICE="Enter 1, 2, or 3: "

  if "!QUANT_CHOICE!"=="1" (
    set MODEL_REPO=unsloth/Qwen3-6B-Instruct-bnb-4bit
    set INCLUDE_ARGS=
  ) else if "!QUANT_CHOICE!"=="2" (
    set MODEL_REPO=unsloth/Qwen3-6B-Instruct
    set INCLUDE_ARGS=
  ) else if "!QUANT_CHOICE!"=="3" (
    set MODEL_REPO=unsloth/Qwen3-6B-Instruct-GGUF
    set INCLUDE_ARGS=--include *Q4_K_M.gguf
  ) else (
    echo Invalid selection, skipping model download.
    goto :done
  )

  set /p MODEL_DIR="Local target folder for model files [models\qwen3_6]: "
  if "!MODEL_DIR!"=="" set MODEL_DIR=models\qwen3_6

  echo Downloading !MODEL_REPO! to !MODEL_DIR!...
  huggingface-cli download !MODEL_REPO! !INCLUDE_ARGS! --local-dir "!MODEL_DIR!"
  if errorlevel 1 (
    echo Model download failed. Check internet/HF token or choose offline mode.
    exit /b 1
  )
)

:done
echo.
echo Setup complete.
echo - Activate env: .venv\Scripts\activate
echo - Start backend: cd apps\backend ^&^& uvicorn app.main:app --reload --port 8000
echo - Start frontend: cd apps\frontend ^&^& npm run dev
endlocal
