#!/bin/bash
# SNAP build script.
# @arg $1 ROOT : Root director to place target, logs and db

if [ "$#" -ne 1 ]
then 
	echo "Illegal number of parameters. ROOT directory is a mandatory parameter."
	exit 1
fi

# Root directory. Remove trailing slash, if present.
ROOT=${1%/}
PWD=`dirname "$0"`

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

# Start time
LOG_FILE="build.$TSTART.log"
BUILD_LOG="$LOGBASE_DIR""$LOG_FILE"

function gtest() {
}

# Check if various root directories are not present.
create_dir_if_not_exists $TARGET_ROOT
create_dir_if_not_exists $LOG_ROOT
create_dir_if_not_exists $DB_ROOT

# Check if BUILD_DB is not present. Create it using create.sql from the source..
if [ ! -f $DB_FILE ]
then
	sqlite3 $DB_FILE < $PWD/db/create.sql
fi
exit 0

# If snapr directory is already present, remove it and clone again.
if [ -e "$SNAPR_DIR" ]
then
	rm -rf $SNAPR_DIR
fi

# Make
# build
# GTest
# gtest

# Update tend
TEND=`date +%s`
echo "UPDATE status SET tend=$TEND WHERE tstart = $TSTART;" | sqlite3 $BUILD_DB
