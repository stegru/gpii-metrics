pushd %~dp0
powershell -ExecutionPolicy ByPass .\build.ps1
popd
