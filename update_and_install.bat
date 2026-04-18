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

REM Force UTF-8 for Python-based CLIs (hf/huggingface-cli) to avoid Windows codepage
REM errors when unicode status symbols (e.g., ✓) are printed during downloads.
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
call :log "Configured UTF-8 console env for Python CLIs (PYTHONUTF8=1, PYTHONIOENCODING=utf-8)."

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
  echo Choose model selector:
  echo   1^) Qwen3.6-35B-A3B (base)
  echo   2^) Qwen3.6-35B-A3B-Instruct
  echo   3^) Qwen3.6-35B-A3B-GGUF
  echo   4^) Custom Hugging Face repo ID
  set /p MODEL_CHOICE="Enter 1, 2, 3, or 4: "
  call :log "Model selector choice: !MODEL_CHOICE!"

  if "!MODEL_CHOICE!"=="1" (
    set MODEL_REPO=unsloth/Qwen3.6-35B-A3B
    set INCLUDE_ARGS=
  ) else if "!MODEL_CHOICE!"=="2" (
    set MODEL_REPO=unsloth/Qwen3.6-35B-A3B-Instruct
    set INCLUDE_ARGS=
  ) else if "!MODEL_CHOICE!"=="3" (
    set MODEL_REPO=unsloth/Qwen3.6-35B-A3B-GGUF
    set /p GGUF_FILTER="GGUF file filter [*Q4_K_M.gguf]: "
    if "!GGUF_FILTER!"=="" set "GGUF_FILTER=*Q4_K_M.gguf"
    set "INCLUDE_ARGS=--include !GGUF_FILTER!"
  ) else if "!MODEL_CHOICE!"=="4" (
    set /p MODEL_REPO="Enter repo ID (example: unsloth/Qwen3.6-35B-A3B-GGUF): "
    if "!MODEL_REPO!"=="" (
      call :log "Empty custom repo id. Skipping model download."
      echo Empty repo ID, skipping model download.
      goto :done
    )
    set /p IS_GGUF="Is this a GGUF repo? (Y/N) [N]: "
    if /I "!IS_GGUF!"=="Y" (
      set /p GGUF_FILTER="GGUF file filter [*Q4_K_M.gguf]: "
      if "!GGUF_FILTER!"=="" set "GGUF_FILTER=*Q4_K_M.gguf"
      set "INCLUDE_ARGS=--include !GGUF_FILTER!"
    ) else (
      set INCLUDE_ARGS=
    )
  ) else (
    call :log "Invalid model selector: !MODEL_CHOICE!"
    echo Invalid selection, skipping model download.
    goto :done
  )

  set /p MODEL_DIR="Local target folder for model files [models\qwen3_6_35b_a3b]: "
  if "!MODEL_DIR!"=="" set MODEL_DIR=models\qwen3_6_35b_a3b
  call :log "Model target directory: !MODEL_DIR!"

  if exist "!MODEL_DIR!" (
    set /a MODEL_FILE_COUNT=0
    for /f %%I in ('dir /a-d /b "!MODEL_DIR!" 2^>nul ^| find /c /v ""') do set /a MODEL_FILE_COUNT=%%I
    if !MODEL_FILE_COUNT! GTR 0 (
      echo Found !MODEL_FILE_COUNT! existing file^(s^) in !MODEL_DIR!.
      set /p SKIP_EXISTING_DOWNLOAD="Skip download and keep existing files? (Y/N) [Y]: "
      if "!SKIP_EXISTING_DOWNLOAD!"=="" set SKIP_EXISTING_DOWNLOAD=Y
      call :log "Skip existing model download choice: !SKIP_EXISTING_DOWNLOAD! (files found: !MODEL_FILE_COUNT!)"
      if /I "!SKIP_EXISTING_DOWNLOAD!"=="Y" (
        call :log "Skipping model download because files already exist."
        goto :after_model_download
      )
    )
  )

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

:after_model_download
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
