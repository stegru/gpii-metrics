# Filebeat installer merge module for GPII

This produces `filebeat.msm`, which is used by gpii-wix-installer to bundle filebeat with the GPII. This will make the
GPII installer install and start the filebeat service.

## Usage

* Create `es-credentials.json`, containing the following:
```json
{
    "host": "the real hostname",
    "username": "the real user name",
    "password": "the real password"
}
```
* Run [build.ps1](build.ps1)
* Take `output/filebeat.msm`.

Don't commit `es-credentials.json`, `filebeat.yml` or `filebeat.msm`, because they contain credentials.
