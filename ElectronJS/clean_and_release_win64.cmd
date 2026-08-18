move out\EasySpider-win32-x64 out\EasySpider
rmdir /s /Q out\EasySpider\resources\app\chrome_win32
rmdir /s /Q out\EasySpider\resources\app\chromedrivers
rmdir /s /Q out\EasySpider\resources\app\Data
rmdir /s /Q out\EasySpider\resources\app\.idea
rmdir /s /Q out\EasySpider\resources\app\tasks
rmdir /s /Q out\EasySpider\resources\app\execution_instances
rmdir /s /Q out\EasySpider\resources\app\user_data
rmdir /s /Q ..\.temp_to_pub\EasySpider_windows_x64\EasySpider
del out\EasySpider\resources\app\vs_BuildTools.exe
move out\EasySpider ..\.temp_to_pub\EasySpider_windows_x64\EasySpider
rmdir /s /Q ..\.temp_to_pub\EasySpider_windows_x64\Code
mkdir ..\.temp_to_pub\EasySpider_windows_x64\Code
@REM copy ..\ExecuteStage\easyspider_executestage.py ..\.temp_to_pub\EasySpider_windows_x64\Code
@REM copy ..\ExecuteStage\myChrome.py ..\.temp_to_pub\EasySpider_windows_x64\Code
@REM copy ..\ExecuteStage\utils.py ..\.temp_to_pub\EasySpider_windows_x64\Code
copy ..\ExecuteStage\*.py ..\.temp_to_pub\EasySpider_windows_x64\Code
copy ..\ExecuteStage\requirements.txt ..\.temp_to_pub\EasySpider_windows_x64\Code
copy ..\ExecuteStage\Readme.md ..\.temp_to_pub\EasySpider_windows_x64\Code
copy ..\ExecuteStage\myCode.py ..\.temp_to_pub\EasySpider_windows_x64
xcopy ..\ExecuteStage\undetected_chromedriver_ES ..\.temp_to_pub\EasySpider_windows_x64\Code\undetected_chromedriver_ES /E /I /Y
if exist ..\.temp_to_pub\EasySpider_windows_x64\Code\undetected_chromedriver_ES\__pycache__ rmdir /s /Q ..\.temp_to_pub\EasySpider_windows_x64\Code\undetected_chromedriver_ES\__pycache__
xcopy ..\ExecuteStage\.vscode ..\.temp_to_pub\EasySpider_windows_x64\Code\.vscode /E /I /Y
rmdir /s /Q ..\.temp_to_pub\EasySpider_windows_x64\user_data
rmdir /s /Q ..\.temp_to_pub\EasySpider_windows_x64\execution_instances
rmdir /s /Q ..\.temp_to_pub\EasySpider_windows_x64\TempUserDataFolder
mkdir ..\.temp_to_pub\EasySpider_windows_x64\execution_instances
rmdir /s /Q ..\.temp_to_pub\EasySpider_windows_x64\Data
mkdir ..\.temp_to_pub\EasySpider_windows_x64\Data
if exist ..\.temp_to_pub\EasySpider_windows_x64\tasks rmdir /s /Q ..\.temp_to_pub\EasySpider_windows_x64\tasks
mkdir ..\.temp_to_pub\EasySpider_windows_x64\tasks
powershell -NoProfile -Command "$repo = (Resolve-Path '..').Path; $stage = (Resolve-Path '..\.temp_to_pub\EasySpider_windows_x64\tasks').Path; $files = @(git -C $repo -c 'safe.directory=*' ls-files -- 'ElectronJS/tasks'); if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; foreach ($file in $files) { $relative = $file -replace '^ElectronJS/tasks[\\/]', ''; $destination = Join-Path $stage $relative; $null = New-Item -ItemType Directory -Force -Path (Split-Path $destination); Copy-Item -LiteralPath (Join-Path $repo $file) -Destination $destination -Force }"
if errorlevel 1 exit /b %errorlevel%

