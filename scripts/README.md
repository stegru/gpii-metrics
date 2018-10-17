# GPII Metrics scripts

A collection of scripts to deal with the download and import of metrics data.

## get-data

```text
Gets some data from elastic search, saving to a CSV file.

Usage: get-data [URL] DATE FILE

  URL:    https://<user>:<pass>@<host>:9243/
  DATE:   "today", "yesterday", "this-month", "last-month", or yyyy.mm
  FILE:   The output csv file.

URL is ignored if ~/.metrics-credentials exists, which should contain ES_USER, ES_PASS, and ES_HOST key=value pairs.

es2csv is required.
```

## data-clean

```text
 Usage:
  data-clean [FILE]...
 or
  data-clean < infile.csv > outfile.csv

 Requires the "sqlite3" package (https://sqlite.org/cli.html).

 Performs the following tidy-ups:
  - Removes duplicate entries (same log data uploaded)
  - Sort by timestamp
  - Add session duration column for SessionStop events
  - Adds a session ID and userToken to all events between SessionStart and SessionStop
  - Renames columns (removes the json_ prefix)

```
