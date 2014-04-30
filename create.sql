DROP TABLE IF EXISTS status;

-- id: Build number
-- tstart: Build start time (unix epoch)
-- tend: Build end time (unix epoch)
-- status: Current status of the build (0: Success, 1: Failed, 2: In Progress)
-- logs: Logs of the build process.
CREATE TABLE status(
	id integer primary key autoincrement,
	tstart integer,
	tend integer,
	status integer,
	logs text
);
