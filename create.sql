DROP TABLE IF EXISTS status;

-- id: Build number
-- tstart: Build start time (unix epoch)
-- tend: Build end time (unix epoch)
-- build_status/test_status: Current status of the build/test (-1: Queued, 0: Success, 1: Failed, 2: In Progress)
-- logs: Log file name of the build process.
CREATE TABLE status(
	id integer primary key autoincrement,
	tstart integer,
	tend integer,
	build_status integer,
	test_status integer,
	logs text
);
