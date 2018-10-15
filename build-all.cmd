pushd %~dp0

del /s /q output
mkdir output

:: Create the filebeat merge module
call filebeat-installer\build.cmd

move filebeat-installer\output\filebeat.msm output\filebeat.msm
copy output\filebeat.msm gpii-standalone-metrics\installer\filebeat.msm

:: Build the standalone metrics
pushd gpii-standalone-metrics
call npm install

:: Build the installer
pushd provisioning
powershell -ExecutionPolicy ByPass .\Installer.ps1
popd

popd

move gpii-standalone-metrics\output\morphic-metrics.msi output

popd


