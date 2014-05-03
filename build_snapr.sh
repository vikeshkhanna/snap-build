#!/bin/bash
# Script to build (make and test) snapr. 
# Assumes all directories are created.
# @arg $1 : TARGET_ROOT : Root directory for targets.
# @arg $2 : LOG_ROOT : Root directory for logs
# @arg $3 : DB_FILE : Full path to the build db

if [ "$#" -ne 3 ]
then 
	echo "Illegal number of parameters. TARGET_ROOT, LOG_ROOT and DB_FILE are mandatory parameters."
	exit 1
fi

TARGET_ROOT=${1%/}
LOG_ROOT=${2%/}
DB_FILE=${3%/}

PWD=`dirname "$0"`
# Include the utils directory
source "$PWD/utils.sh"

TSTART=`date +%s`
# Following the Target path naming convention mentioned in utils.sh - TARGET_ROOT/snapr.<timestamp>/snapr/.git
TARGET_DIR="$TARGET_ROOT/$SNAPR_PREFIX.$TSTART"
SNAPR_DIR="$TARGET_DIR/$SNAPR_PREFIX"
LOG_DIR="$LOG_ROOT/$SNAPR_PREFIX"
LOG_FILE_NAME="$SNAPR_PREFIX.$TSTART.log"
LOG_FILE="$LOG_DIR/$LOG_FILE_NAME"

create_dir_if_not_exists $TARGET_DIR
create_dir_if_not_exists $LOG_DIR

# Insert into the snapr table. Build in progress, test queued. 
echo "INSERT INTO $SNAPR_TBL_NAME VALUES(NULL, $TSTART, 0, $STATUS_PROGRESS, $STATUS_QUEUED, '$LOG_FILE_NAME');" | sqlite3 $DB_FILE

# Clone the repository into the 
echo "======================= CLONING SNAPR REPOSITORYY =======================" | tee -a $LOG_FILE
git clone $SNAPR_GIT $SNAPR_DIR | tee -a $LOG_FILE

build_snapr $SNAPR_DIR $TSTART $DB_FILE $LOG_FILE
test_snapr $SNAPR_DIR $TSTART $DB_FILE $LOG_FILE
