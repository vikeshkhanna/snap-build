-- Common notation for each table.
-- id: Build number
-- tstart: Build start time (unix epoch)
-- tend: Build end time (unix epoch)
-- build_status/test_status: Current status of the build/test (-1: Queued, 0: Success, 1: Failed, 2: In Progress)
-- logs: Log file name of the build process.

CREATE TABLE IF NOT EXISTS snap (
	id integer primary key autoincrement,
	tstart integer,
	tend integer,
	build_status integer,
	test_status integer,
	logs text
);

CREATE UNIQUE INDEX IF NOT EXISTS snap_tstart on snap(tstart);

CREATE TABLE IF NOT EXISTS snapr (
	id integer primary key autoincrement,
	tstart integer,
	tend integer,
	build_status integer,
	test_status integer,
	logs text
);

CREATE UNIQUE INDEX IF NOT EXISTS snapr_tstart on snap(tstart);

CREATE TABLE IF NOT EXISTS snappy (
	id integer primary key autoincrement,
	tstart integer,
	tend integer,
	build_status integer,
	test_status integer,
	logs text
);

CREATE UNIQUE INDEX IF NOT EXISTS snappy_tstart on snap(tstart);

CREATE TABLE IF NOT EXISTS ringo (
	id integer primary key autoincrement,
	tstart integer,
	tend integer,
	build_status integer,
	test_status integer,
	logs text
);

CREATE UNIQUE INDEX IF NOT EXISTS ringo_tstart on ringo(tstart);
