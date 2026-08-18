@echo off
setlocal

if exist build rmdir /s /Q build
if exist dist rmdir /s /Q dist

for /f "delims=" %%P in ('python -c "import onnxruntime, pathlib; print(pathlib.Path(onnxruntime.__file__).parent / 'capi' / 'onnxruntime_providers_shared.dll')"') do set "ONNX_DLL=%%P"
for /f "delims=" %%P in ('python -c "import ddddocr, pathlib; print(pathlib.Path(ddddocr.__file__).parent / 'common_old.onnx')"') do set "DDDDOCR_MODEL=%%P"

if not exist "%ONNX_DLL%" (
    echo Could not find onnxruntime_providers_shared.dll in the active Python environment.
    exit /b 1
)
if not exist "%DDDDOCR_MODEL%" (
    echo Could not find ddddocr common_old.onnx in the active Python environment.
    exit /b 1
)

pyinstaller -F --icon=favicon.ico --hidden-import selenium.webdriver.ie.webdriver --add-data "%ONNX_DLL%;onnxruntime\capi" --add-data "%DDDDOCR_MODEL%;ddddocr" easyspider_executestage.py
if errorlevel 1 exit /b %errorlevel%
if not exist dist\easyspider_executestage.exe exit /b 1

if not exist ..\ElectronJS\chrome_win64 mkdir ..\ElectronJS\chrome_win64
if exist ..\ElectronJS\chrome_win64\easyspider_executestage.exe del /f /q ..\ElectronJS\chrome_win64\easyspider_executestage.exe
copy /Y dist\easyspider_executestage.exe ..\ElectronJS\chrome_win64\easyspider_executestage.exe
if errorlevel 1 exit /b %errorlevel%
echo Windows x64 execution stage packaged successfully.
