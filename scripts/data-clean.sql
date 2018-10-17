DROP TABLE IF EXISTS metrics;
DROP TABLE IF EXISTS session;
DROP TABLE IF EXISTS installations;

CREATE TABLE IF NOT EXISTS metrics
(
  uniq                    TEXT
    CONSTRAINT metrics_pk
    UNIQUE,
  hostname                TEXT,
  beat_name               TEXT,
  data_button             INT,
  data_cores              TEXT,
  data_cpu                TEXT,
  data_distance           INT,
  data_duration           TEXT,
  data_error_address      TEXT,
  data_error_code         TEXT,
  data_error_dest         TEXT,
  data_error_errno        TEXT,
  data_error_hostname     TEXT,
  data_error_host         TEXT,
  data_error_isError      TEXT,
  data_error_message      TEXT,
  data_error_path         TEXT,
  data_error_port         TEXT,
  data_error_returnCode   TEXT,
  data_error_stack        TEXT,
  data_error_syscall      TEXT,
  data_exe                TEXT,
  data_gpiiKey            TEXT,
  data_key                TEXT,
  data_keyTime            INT,
  data_memory             TEXT,
  data_modifierKeys       TEXT,
  data_name               TEXT,
  data_osBits             TEXT,
  data_osEdition          TEXT,
  data_osRelease          TEXT,
  data_resolution         TEXT,
  data_scale              TEXT,
  data_session            TEXT,
  data_solutionID         TEXT,
  data_systemMfr          TEXT,
  data_systemName         TEXT,
  data_userToken          TEXT,
  "data_value.0"          TEXT,
  data_value              TEXT,
  data_wheel              TEXT,
  data_window             TEXT,
  data_ver_windowsMetrics TEXT,
  data_ver_app            TEXT,
  data_ver_universal      TEXT,
  data_ver_windows        TEXT,
  event                   TEXT,
  installID               TEXT,
  level                   TEXT,
  module                  TEXT,
  event_timestamp         TEXT,
  offset                  INT,
  source                  TEXT,
  fb_timestamp            TEXT,
  type                    TEXT,
  session_duration        INT,
  metricsVersion          TEXT,
  timestamp               TEXT
);


/*
Transfer the imported table into metrics.
- Remove duplicates: filebeat has been re-uploading files - use source+offset+installId to determine unique lines
- Add a numeric timestamp
- Improve column names
 */
INSERT INTO metrics
    --CREATE TABLE metrics AS
  SELECT
      -- effectively a composite key of (installID, source, offset, timestamp). However, source+offset can be null and
      -- timestamp can be legitimately duplicated.
      coalesce(
          -- Pilots 1/2 have some duplication.
          -- source & offset is the log filename & byte offset, this can be used to identify unique lines.
        source || offset || "json.installID",
        -- source being null means GPII sent logs via TCP, and duplication (by re-reading log files) isn't likely.
        -- The timestamp is used (along with the row id for when events are sent quickly together)
        "json.installID" || "json.timestamp" || _ROWID_
          )
      AS uniq,
      "beat.hostname" AS "hostname",
      "beat.name" AS "beat_name",
      "json.data.button" AS "data_button",
      "json.data.cores" AS "data_cores",
      "json.data.cpu" AS "data_cpu",
      "json.data.distance" AS "data_distance",
      "json.data.duration" AS "data_duration",
      "json.data.error.address" AS "data_error_address",
      "json.data.error.code" AS "data_error_code",
      "json.data.error.dest" AS "data_error_dest",
      "json.data.error.errno" AS "data_error_errno",
      "json.data.error.hostname" AS "data_error_hostname",
      "json.data.error.host" AS "data_error_host",
      "json.data.error.isError" AS "data_error_isError",
      "json.data.error.message" AS "data_error_message",
      "json.data.error.path" AS "data_error_path",
      "json.data.error.port" AS "data_error_port",
      "json.data.error.returnCode" AS "data_error_returnCode",
      "json.data.error.stack" AS "data_error_stack",
      "json.data.error.syscall" AS "data_error_syscall",
      "json.data.exe" AS "data_exe",
      "json.data.gpiiKey" AS "data_gpiiKey",
      "json.data.key" AS "data_key",
      "json.data.keyTime" AS "data_keyTime",
      "json.data.memory" AS "data_memory",
      ("json.data.modifierKeys.0" ||
       coalesce(',' || "json.data.modifierKeys.1", '') ||
       coalesce(',' || "json.data.modifierKeys.2", '')) AS "data_modifierKeys",
      "json.data.name" AS "data_name",
      "json.data.osBits" AS "data_osBits",
      "json.data.osEdition" AS "data_osEdition",
      "json.data.osRelease" AS "data_osRelease",
      "json.data.resolution" AS "data_resolution",
      "json.data.scale" AS "data_scale",
      "json.data.session" AS "data_session",
      "json.data.solutionID" AS "data_solutionID",
      "json.data.systemMfr" AS "data_systemMfr",
      "json.data.systemName" AS "data_systemName",
      "json.data.userToken" AS "data_userToken",
      "json.data.value.0" AS "data_value.0",
      "json.data.value" AS "data_value",
      "json.data.wheel" AS "data_wheel",
      "json.data.window" AS "data_window",
      "json.data.windowsMetrics" AS "data_ver_windowsMetrics",
      "json.data.gpii-app" AS "data_ver_app",
      "json.data.gpii-universal" AS "data_ver_universal",
      "json.data.gpii-windows" AS "data_ver_windows",
      "json.event" AS "event",
      "json.installID" AS "installID",
      "json.level" AS "level",
      "json.module" AS "module",
      "json.timestamp" AS "event_timestamp",
      "offset" AS "offset",
      "source" AS "source",
      "@timestamp" AS "fb_timestamp",
      "type" AS "type",
      NULL AS session_duration,
      -- Detect the version (there is no version field when filebeat 5.4.1 is used)
      CASE "beat.version"
        WHEN '5.4.1' THEN '0.1.0'
        ELSE coalesce("json.version", '0.2.0') END
      AS "metricsVersion",
      -- Numeric timestamp
      strftime('%s', "json.timestamp") +
      (substr(strftime('%f', "json.timestamp"), instr(strftime('%f', "json.timestamp"), '.'))) AS timestamp

  FROM imported
  GROUP BY uniq
  ORDER BY timestamp
  ON CONFLICT DO NOTHING;

-- Installations
DROP TABLE IF EXISTS installations;
CREATE TABLE installations AS
  SELECT installID,
      (data_ver_app) AS data_ver_app2,
      *,
      max(data_ver_app) AS data_ver_app,
      max(data_ver_universal) AS data_ver_universal,
      max(data_ver_windows) AS data_ver_windows,
      max(data_ver_windowsMetrics) AS data_ver_windowsMetrics,
      max(data_cpu) AS data_cpu,
      max(data_cores) AS data_cores,
      max(data_memory) AS data_memory,
      max(data_resolution) AS data_resolution,
      max(data_scale) AS data_scale,
      max(data_osRelease) AS data_osRelease,
      max(data_osEdition) AS data_osEdition,
      max(data_osBits) AS data_osBits,
      max(data_systemMfr) AS data_systemMfr,
      max(data_systemName) AS data_systemName

    FROM metrics
    WHERE event = 'version'
       OR event = 'system-info'
    GROUP BY installID;

---------------------------
-- Upgrade older metrics
---------------------------

-- 0 -> 0.3.0
UPDATE metrics
  SET data_gpiiKey = data_value
  WHERE metricsVersion < '0.3.0'
    AND (event = 'SessionBegin' OR event = 'SessionEnd');

---------------------------
-- Sessions
---------------------------

DROP TABLE IF EXISTS session;

-- Connect SessionStart and SessionStop events
CREATE TABLE session AS
  SELECT start.installID,
      start.data_session,
      start.timestamp AS startTime,
      start.data_gpiiKey,
      stop.timestamp AS stopTime,
      (stop.timestamp - start.timestamp) AS duration,
      0 AS implied
    FROM metrics AS start
           INNER JOIN metrics AS stop ON stop.data_session = start.data_session AND stop.installID = start.installID
    WHERE stop.event = 'SessionStop'
      AND start.event = 'SessionStart';

--------
-- Insert implied session stops (for sessions without a SessionStop due to shutdown)

DROP TABLE IF EXISTS session_tmp;

-- Get the next 'Start' event after a 'SessionStart'
CREATE TABLE session_tmp AS
  SELECT start.installID,
      start.data_session,
      start.timestamp AS startTime,
      start.data_gpiiKey,
      min(stop.timestamp) AS stopTime
    FROM metrics AS start
           INNER JOIN metrics AS stop ON stop.installID = start.installID AND stop.timestamp > start.timestamp
    WHERE stop.event = 'Start'
      AND start.event = 'SessionStart'
      AND NOT exists(SELECT 1
                       FROM session AS S
                       WHERE S.data_session = start.data_session)
    GROUP BY start.data_session;

-- Get the last event before the 'Start' event
INSERT INTO session
  SELECT S.installID,
      S.data_session,
      S.startTime,
      S.data_gpiiKey,
      max(metrics.timestamp) AS stopTime,
      (max(metrics.timestamp) - S.startTime) AS duration,
      1 AS implied
  FROM metrics
         INNER JOIN session_tmp AS S ON metrics.installID = S.installID AND metrics.data_session ISNULL
  WHERE metrics.timestamp < S.stopTime
    AND metrics.timestamp > S.startTime
  GROUP BY S.data_session;

DROP TABLE session_tmp;

-- Session duration
-- UPDATE metrics
--   SET session_duration = (SELECT round(metrics.timestamp - start.timestamp)
--                             FROM metrics AS start
--                             WHERE start.data_session = metrics.data_session
--                               AND start.event = 'SessionStart')
--   WHERE event = 'SessionStop';

-- sqlite doesn't support JOINs with UPDATE, need to use painfully slow sub-queries instead.

-- Add session ID to events between SessionStart/Stop
UPDATE metrics
  SET data_session = (SELECT data_session
                        FROM session
                        WHERE metrics.timestamp BETWEEN startTime AND stopTime
                          AND metrics.installID = session.installID)
  WHERE data_session ISNULL;

-- Also add the gpiiKey (sqlite<3.15 could not do it in the previous statement)
UPDATE metrics
  SET data_gpiiKey = (SELECT session.data_gpiiKey
                        FROM session
                        WHERE session.data_session = metrics.data_session
                          AND session.data_gpiiKey NOTNULL)
  WHERE data_gpiiKey = '';

-- The output (needs updating)

-- SELECT tim AS utcTime,
--     datetime("json.timestamp", '-8 hours') AS localTime,
--     "beat.hostname",
--     "json.installID" AS installID,
--     "json.level" AS level,
--     "json.event" AS event,
--     "json.module" AS module,
--     "json.data.session" AS session,
--     "json.data.gpiiKey" AS gpiiKey,
--     session_duration AS sessionDuration,
--     "json.data.duration" AS duration,
--     "json.data.solutionID" AS solutionID,
--     "json.data.exe" AS exe,
--     "json.data.keyTime" AS keyTime,
--     "json.data.key" AS "key",
--     "json.data.distance" AS distance,
--     "json.data.button" AS button,
--     "json.data.error.message" AS error
--
--   FROM metrics;

SELECT count(1) FROM metrics
