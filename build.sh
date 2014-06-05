#!/bin/bash
# SNAP build script.
# @arg $1 ROOT : Root directory to place target, logs and db
#
# @author:
# Vikesh Khanna (vikesh@stanford.edu)

if [ "$#" -ne 1 ]
then 
	echo "Illegal number of parameters. ROOT directory is a mandatory parameter."
	exit 1
fi

# Root directory. Remove trailing slash, if present.
ROOT=${1%/}
PWD=`dirname "$0"`
CONF=$PWD/conf.yml
SHYAML=$PWD/shyaml

# Include the utils script.
source $PWD/utils.sh

# Check if ROOT directory exists.
if [ ! -d "$ROOT" ]
then
	echo "ROOT directory must be a valid, existing direcotry"
	exit 1
fi

# All projects will be built in TARGET_ROOT/<project_prefix>.<timestamp>/
# See utils for project_prefix
TARGET_ROOT="$ROOT/snap-build-target"

# All project logs will be stoered in LOG_ROOT/<project_prefix>/<project_prefix>.<timestamp>.log
# See utils for pr
LOG_ROOT="$ROOT/snap-build-logs"

# Database file is in this folder.
DB_ROOT="$ROOT/snap-build-db"

# All tables in this DB.
DB_FILE="$DB_ROOT/build.db"

# Check if various root directories are not present.
create_dir_if_not_exists $TARGET_ROOT
create_dir_if_not_exists $LOG_ROOT
create_dir_if_not_exists $DB_ROOT

echo "All logs are present under LOG Root: $LOG_ROOT"
echo "All builds are present under TARGET Root: $TARGET_ROOT" 

# Check if BUILD_DB is not present. Create it using create.sql from the source.
if [ ! -f $DB_FILE ]
then
	sqlite3 $DB_FILE < $PWD/db/create.sql
fi

# Call the build.chilld script for each project.
PROJECT_LIST=`cat $CONF | $SHYAML keys projects`
for PROJECT_NAME in $PROJECT_LIST
do
  PROJECT_CONF=`cat $CONF | $SHYAML get-value projects.$PROJECT_NAME`
  $PWD/build.child.sh $TARGET_ROOT $LOG_ROOT $DB_FILE $PROJECT_NAME "$PROJECT_CONF" &
done;

echo "====== Waiting for project builds.... ========"
wait;
echo "All projects build finished"
