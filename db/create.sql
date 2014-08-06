-- id: Build number
-- name : Project name.
-- tstart: Build start time (unix epoch)
-- tend: Build end time (unix epoch)
-- build_status/test_status: Current status of the build/test (-1: Queued, 0: Success, 1: Failed, 2: In Progress)
-- logs: Log file name of the build process.

CREATE TABLE IF NOT EXISTS status (
	id integer primary key autoincrement,
	name text,
	tstart integer,
	tend integer,
	build_status integer,
	test_status integer,
	logs text
);

CREATE UNIQUE INDEX IF NOT EXISTS status_tstart on status(tstart);
