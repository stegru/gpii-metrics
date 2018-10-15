
Push-Location (Split-Path -parent $PSCommandPath)

if (!(Test-Path -Path es-credentials.json)) {
    Write-Output ""
    Write-Output "Please provide es-credentials.json"
    Write-Output ""
    exit 1
}

$templateFile = Join-Path $PWD filebeat-template.yml
$outputFile = Join-Path $PWD filebeat\filebeat.yml

# Load the credentials file
$creds = (Get-Content -Raw -Path es-credentials.json | ConvertFrom-Json)

if (!$creds.username -or !$creds.password -or !$creds.host) {
    Write-Output "es-credentials.json doesn't contain enough information (username, password, host)"
    exit 1
}

# Read the template config file
$content = [System.IO.File]::ReadAllText($templateFile)

# Replace the insertion points
$creds.PSObject.Properties | ForEach-Object {
    $content = $content.Replace("<%" + $_.Name + "%>", $_.Value)
}

# Write to the output config file
[System.IO.File]::WriteAllText($outputFile, $content)

function Clean {
    rm *.wixobj, output\*.wixpdb
}

Clean

Remove-Item -Recurse output
mkdir output

candle -out filebeat.wixobj filebeat.wxs

light filebeat.wixobj -sacl -o output/filebeat.msm


Clean
Pop-Location

