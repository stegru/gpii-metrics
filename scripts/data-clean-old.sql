DROP TABLE IF EXISTS metrics;
DROP TABLE IF EXISTS session;

-- Remove duplicates, add numeric timestamp
CREATE TABLE metrics AS
  SELECT
    *,
    strftime('%s', [json.timestamp]) +
    (substr(strftime('%f', [json.timestamp]), instr(strftime('%f', [json.timestamp]), '.')))
      AS time,
    NULL AS session_duration
  FROM imported
  GROUP BY source, offset, [json.installID]
  ORDER BY [json.timestamp];


-- Session start/stop (for session ID update)
CREATE TABLE session AS
  SELECT
    start.[json.installID] AS installID,
    start.[json.data.session],
    start.time AS startTime,
    start.[json.data.userToken] AS userToken,
    stop.time AS stopTime
  FROM metrics AS start
  INNER JOIN metrics AS stop
    ON stop.[json.data.session] = start.[json.data.session]
  WHERE
    stop.[json.event] = 'SessionStop'
    AND start.[json.event] = 'SessionStart';

-- Session duration
UPDATE metrics
SET session_duration = (
  SELECT round(metrics.time - start.time)
  FROM metrics AS start
  WHERE
    start.[json.data.session] = metrics.[json.data.session]
    AND start.[json.event] = 'SessionStart'
)
WHERE [json.event] = 'SessionStop';

-- Add session ID to events between SessionStart/Stop
UPDATE metrics
SET [json.data.session] = (
  SELECT [json.data.session]
  FROM session
  WHERE
    metrics.time BETWEEN startTime AND stopTime
    AND metrics.[json.installID] = session.installID
)
WHERE [json.event] <> 'SessionStart' AND [json.event] <> 'SessionStop';

-- Also add the userToken (sqlite<3.15 could not do it in the previous statement)
UPDATE metrics
SET [json.data.userToken] = (
  SELECT userToken
  FROM session
  WHERE session.[json.data.session] = metrics.[json.data.session] AND userToken NOTNULL
)
WHERE [json.data.userToken] = '';

-- The output
SELECT
  [json.timestamp] AS utcTime,
  datetime([json.timestamp], '-8 hours') AS localTime,
  [beat.hostname],
  [json.installID] AS installID,
  [json.level] AS level,
  [json.event] AS event,
  [json.module] AS module,
  [json.data.session] AS session,
  [json.data.userToken] AS userToken,
  session_duration AS sessionDuration,
  [json.data.duration] AS duration,
  [json.data.solutionID] AS solutionID,
  [json.data.exe] AS exe,
  [json.data.keyTime] AS keyTime,
  [json.data.key] AS [key],
  [json.data.distance] AS distance,
  [json.data.button] AS button,
  [json.data.error.message] AS error

FROM metrics;

