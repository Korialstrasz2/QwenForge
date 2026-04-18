@echo off
setlocal EnableExtensions EnableDelayedExpansion

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

set "ENGINE_CHOICE=1"
echo.
echo Choose inference mode:
echo   1^) vLLM / safetensors
echo   2^) GGUF / llama.cpp server
set /p ENGINE_CHOICE="Enter 1 or 2 [1]: "
if "!ENGINE_CHOICE!"=="" set ENGINE_CHOICE=1

set "DEFAULT_MODEL_ID=Qwen/Qwen2.5-Coder-7B-Instruct"
set "VLLM_MODEL_ID=%VLLM_MODEL_ID%"
if "!VLLM_MODEL_ID!"=="" set "VLLM_MODEL_ID=!DEFAULT_MODEL_ID!"

set "GGUF_MODEL_FILE=%GGUF_MODEL_FILE%"
if "!GGUF_MODEL_FILE!"=="" (
  for %%F in ("%~dp0models\qwen3_6\*.gguf") do (
    set "GGUF_MODEL_FILE=%%~fF"
    goto :have_gguf
  )
)
:have_gguf

if "!ENGINE_CHOICE!"=="2" (
  if "!GGUF_MODEL_FILE!"=="" (
    echo WARNING: No GGUF file found in models\qwen3_6\*.gguf and GGUF_MODEL_FILE not set.
    echo Falling back to vLLM mode.
    set "ENGINE_CHOICE=1"
  )
)

if "!ENGINE_CHOICE!"=="2" (
  echo Starting GGUF server on http://localhost:8001/v1 ...
  start "Forge Inference (GGUF)" cmd /k "cd /d %~dp0 && call %~dp0.venv\Scripts\activate.bat && set DEFAULT_INFERENCE_BACKEND=llama_cpp && set DEFAULT_INFERENCE_BASE_URL=http://localhost:8001/v1 && set DEFAULT_INFERENCE_API_KEY=local-key && python -m llama_cpp.server --host 0.0.0.0 --port 8001 --model \"!GGUF_MODEL_FILE!\" --api_key local-key --chat_format chatml"
) else (
  echo Starting vLLM server on http://localhost:8001/v1 ...
  start "Forge Inference (vLLM)" cmd /k "cd /d %~dp0 && call %~dp0.venv\Scripts\activate.bat && set DEFAULT_INFERENCE_BACKEND=vllm && set DEFAULT_INFERENCE_BASE_URL=http://localhost:8001/v1 && set DEFAULT_INFERENCE_API_KEY=local-key && python -m vllm.entrypoints.openai.api_server --host 0.0.0.0 --port 8001 --model !VLLM_MODEL_ID! --dtype auto --max-model-len 32768"
)

echo Starting backend on http://localhost:8000 ...
start "Forge Backend" cmd /k "cd /d %~dp0apps\backend && call %~dp0.venv\Scripts\activate.bat && uvicorn app.main:app --reload --port 8000"

echo Starting frontend on http://localhost:3000 ...
start "Forge Frontend" cmd /k "cd /d %~dp0apps\frontend && npm run dev"

echo.
echo Forge startup commands launched in separate windows.
echo Backend docs: http://localhost:8000/docs
echo Frontend:    http://localhost:3000
echo Inference:   http://localhost:8001/v1

exit /b 0
