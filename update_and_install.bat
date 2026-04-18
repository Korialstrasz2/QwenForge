@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Forge Windows setup script: Python venv + backend/frontend deps + optional local Qwen download.

cd /d "%~dp0"

set "LOG_FILE=%~dp0log.txt"
> "%LOG_FILE%" echo ==== update_and_install.bat run started %DATE% %TIME% ====

echo Logging detailed output to "%LOG_FILE%"
call :log "Working directory: %CD%"

echo [1/6] Ensuring Python virtual environment exists...
if not exist ".venv\Scripts\python.exe" (
  call :log "Creating virtual environment with: py -3 -m venv .venv"
  py -3 -m venv .venv >> "%LOG_FILE%" 2>&1
  if errorlevel 1 (
    call :log "ERROR: Failed to create virtualenv with 'py -3'."
    echo Failed to create virtualenv with 'py -3'.
    exit /b 1
  )
) else (
  call :log "Virtual environment already exists."
)

call :log "Activating virtual environment."
call .venv\Scripts\activate.bat >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
  call :log "ERROR: Failed to activate .venv."
  echo Failed to activate .venv.
  exit /b 1
)

echo [2/6] Upgrading pip/setuptools/wheel (with vLLM-compatible setuptools)...
call :log "Running: python -m pip install --upgrade pip \"setuptools<80\" wheel"
python -m pip install --upgrade pip "setuptools<80" wheel >> "%LOG_FILE%" 2>&1 || exit /b 1

echo [3/6] Installing backend dependencies...
call :log "Installing backend dependencies from apps\\backend"
pushd apps\backend
python -m pip install -e .[dev] >> "%LOG_FILE%" 2>&1 || exit /b 1
popd

echo [4/6] Installing model/runtime helper dependencies...
call :log "Running: python -m pip install huggingface_hub unsloth vllm==0.11.0 llama-cpp-python[server]==0.3.16"
python -m pip install huggingface_hub unsloth vllm==0.11.0 llama-cpp-python[server]==0.3.16 >> "%LOG_FILE%" 2>&1 || exit /b 1

set "HF_DL_CMD="
where hf >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
  call :log "'hf' command not found. Model download step will use legacy fallback."
  set "HF_DL_CMD=huggingface-cli"
) else (
  call :log "Using 'hf' CLI for model downloads."
  set "HF_DL_CMD=hf"
)

echo [5/6] Installing frontend dependencies...
where npm >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
  call :log "ERROR: npm not found in PATH."
  echo npm not found in PATH. Install Node.js 20+ and rerun this script.
  exit /b 1
)
pushd apps\frontend
call :log "Running npm install in apps\\frontend"
call npm install >> "%LOG_FILE%" 2>&1 || exit /b 1
popd

if not exist ".env" (
  echo [6/6] Creating .env from .env.example
  call :log "Creating .env from .env.example"
  copy /Y ".env.example" ".env" >nul
)

echo.
set /p OFFLINE_CHOICE="Enable all-local offline mode in .env now? (Y/N): "
call :log "Offline mode choice: !OFFLINE_CHOICE!"
if /I "!OFFLINE_CHOICE!"=="Y" (
  call :log "Enabling offline flags in .env"
  powershell -NoProfile -Command "(Get-Content .env) -replace '^ALL_LOCAL_MODE=.*','ALL_LOCAL_MODE=true' -replace '^HF_HUB_OFFLINE=.*','HF_HUB_OFFLINE=1' -replace '^TRANSFORMERS_OFFLINE=.*','TRANSFORMERS_OFFLINE=1' | Set-Content .env" >> "%LOG_FILE%" 2>&1
  echo Set ALL_LOCAL_MODE=true and huggingface offline flags in .env
)

echo.
set /p DOWNLOAD_MODEL="Download Qwen 3.6 from Unsloth now? (Y/N): "
call :log "Download model choice: !DOWNLOAD_MODEL!"
if /I "!DOWNLOAD_MODEL!"=="Y" (
  echo Choose quantization:
  echo   1^) 4-bit (bnb)
  echo   2^) 8-bit/base
  echo   3^) GGUF Q4_K_M
  set /p QUANT_CHOICE="Enter 1, 2, or 3: "
  call :log "Quantization choice: !QUANT_CHOICE!"

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
    call :log "Invalid quantization selection: !QUANT_CHOICE!"
    echo Invalid selection, skipping model download.
    goto :done
  )

  set /p MODEL_DIR="Local target folder for model files [models\qwen3_6]: "
  if "!MODEL_DIR!"=="" set MODEL_DIR=models\qwen3_6
  call :log "Model target directory: !MODEL_DIR!"

  echo Downloading !MODEL_REPO! to !MODEL_DIR!... 
  call :log "Running: !HF_DL_CMD! download !MODEL_REPO! !INCLUDE_ARGS! --local-dir !MODEL_DIR!"
  !HF_DL_CMD! download !MODEL_REPO! !INCLUDE_ARGS! --local-dir "!MODEL_DIR!" >> "%LOG_FILE%" 2>&1
  if errorlevel 1 (
    call :log "ERROR: Model download failed with !HF_DL_CMD!."
    echo Model download failed. Check internet/HF token or choose offline mode.
    if /I "!HF_DL_CMD!"=="huggingface-cli" (
      echo Hint: install/update huggingface_hub and rerun so this script can use the newer ^'hf^' command.
    )
    exit /b 1
  )
)

echo.
set /p ENGINE_CHOICE="Default inference engine (1=vLLM, 2=GGUF/llama.cpp) [1]: "
if "!ENGINE_CHOICE!"=="" set ENGINE_CHOICE=1
call :log "Engine choice: !ENGINE_CHOICE!"

if "!ENGINE_CHOICE!"=="2" (
  call :log "Configuring .env for GGUF mode"
  powershell -NoProfile -Command "(Get-Content .env) -replace '^DEFAULT_INFERENCE_BACKEND=.*','DEFAULT_INFERENCE_BACKEND=llama_cpp' -replace '^DEFAULT_INFERENCE_BASE_URL=.*','DEFAULT_INFERENCE_BASE_URL=http://localhost:8001/v1' -replace '^DEFAULT_INFERENCE_API_KEY=.*','DEFAULT_INFERENCE_API_KEY=local-key' | Set-Content .env" >> "%LOG_FILE%" 2>&1
) else (
  call :log "Configuring .env for vLLM mode"
  powershell -NoProfile -Command "(Get-Content .env) -replace '^DEFAULT_INFERENCE_BACKEND=.*','DEFAULT_INFERENCE_BACKEND=vllm' -replace '^DEFAULT_INFERENCE_BASE_URL=.*','DEFAULT_INFERENCE_BASE_URL=http://localhost:8001/v1' -replace '^DEFAULT_INFERENCE_API_KEY=.*','DEFAULT_INFERENCE_API_KEY=local-key' | Set-Content .env" >> "%LOG_FILE%" 2>&1
)

:done
call :log "Setup completed successfully."
echo.
echo Setup complete.
echo - Activate env: .venv\Scripts\activate
echo - Start backend: cd apps\backend ^&^& uvicorn app.main:app --reload --port 8000
echo - Start frontend: cd apps\frontend ^&^& npm run dev
echo Detailed logs: "%LOG_FILE%"
exit /b 0

:log
echo [%DATE% %TIME%] %~1>> "%LOG_FILE%"
exit /b 0
