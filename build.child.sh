#!/bin/bash
# Script to build individual projects.
# Assumes all root directories are created.
# @arg $1 : TARGET_ROOT : Root directory for targets.
# @arg $2 : LOG_ROOT : Root directory for logs
# @arg $3 : DB_FILE : Full path to the build db
# @arg $4 : PROJECT_NAME : Name of the project. MUST match the table name in the DB.
# @arg $5 : CONF : String that defines the project's configuration parameters. (See conf.yml)
#
# @author:
# Vikesh Khanna (vikesh@stanford.edu)

if [ "$#" -ne 5 ]
then 
	echo "Illegal number of parameters. TARGET_ROOT, LOG_ROOT, DB_FILE, PROJECT_NAME and CONF are mandatory parameters."
	exit 1
fi

TARGET_ROOT=${1%/}
LOG_ROOT=${2%/}
DB_FILE=${3%/}
PROJECT_NAME=$4
PROJECT_CONF=$5

PWD=`dirname "$0"`
SHYAML=$PWD/shyaml

# Include the utils directory
source "$PWD/utils.sh"

TSTART=`date +%s`
TARGET_DIR="$TARGET_ROOT/$PROJECT_NAME.$TSTART"
LOG_DIR="$LOG_ROOT/$PROJECT_NAME"
LOG_FILE_NAME="$PROJECT_NAME.$TSTART.log"
LOG_FILE="$LOG_DIR/$LOG_FILE_NAME"

# Source directory to which code will be cloned.
SOURCE_DIR=$TARGET_DIR/$PROJECT_NAME
echo "LOGGING in $LOG_FILE. TSTART=$TSTART"

# ================ Set Variables from CONF ====================
# Git URL for the project
GIT=`echo -e "$PROJECT_CONF" | $SHYAML get-value git | tee -a $LOG_FILE`
# Steps to do before before is trigged. Optional.
BEFORE_BUILD=`echo -e "$PROJECT_CONF" | $SHYAML get-values before_build 2>/dev/null`
# Build Command.
BUILD=`echo -e "$PROJECT_CONF" | $SHYAML get-value build | tee -a $LOGFILE`
# Test Command.
TEST=`echo -e "$PROJECT_CONF" | $SHYAML get-value test | tee -a $LOGFILE`
# Mail 
MAIL_SUCCESS=`echo -e "$PROJECT_CONF" | $SHYAML get-value mail.success 2>/dev/null`
MAIL_FAILURE=`echo -e "$PROJECT_CONF" | $SHYAML get-value mail.failure 2>/dev/null`

# Insert into the project table. Build in progress, test queued. 
do_sql "BEGIN; INSERT INTO status VALUES(NULL, '$PROJECT_NAME', $TSTART, 0, $STATUS_PROGRESS, $STATUS_QUEUED, '$LOG_FILE_NAME'); COMMIT;" $DB_FILE

# Clone the repository.
echo "======================= CLONING $PROJECT_NAME REPOSITORY =======================" | tee -a $LOG_FILE
git clone $GIT $SOURCE_DIR | tee -a $LOG_FILE

# Change directory to SOURCE_DIR. 
# All user-defined commands (like before_build) MUST lead back to SOURCE_DIR
cd $SOURCE_DIR

# Perform before_build steps if present.
if [ ! -z "$BEFORE_BUILD" ]
then
  echo "======================= PERFORMING BEFORE_BUILD STEPS FOR $PROJECT_NAME =======================" | tee -a $LOG_FILE
  echo -e "$BEFORE_BUILD" | while read -r command; 
  do
    # Execute the command as such.
   echo "$command" | tee -a $LOG_FILE
   eval "$command" | tee -a $LOG_FILE
  done 
fi;

# Build
# ========================= BUILD BEGINS ====================================== 
echo "======================= BUILDING $PROJECT_NAME. START TIME = `date` =======================" | tee -a $LOG_FILE
update_build_status $PROJECT_NAME $DB_FILE $TSTART $STATUS_PROGRESS
eval $BUILD >> $LOG_FILE 2>&1
BUILD_RESULT=$?
echo "======================= BUILD $PROJECT_NAME FINISH. TIME = `date` =======================" | tee -a $LOG_FILE

# Check exit status and take appropriate action.
if [ $BUILD_RESULT -ne 0 ]
then
  # Build failed. Update DB entry.
  echo "======================= BUILD $PROJECT_NAME FAILED =======================" | tee -a $LOG_FILE
  update_build_status $PROJECT_NAME $DB_FILE $TSTART $STATUS_FAILED 
else
  # Build succeeded. Update DB entry.
  echo "======================= BUILD $PROJECT_NAME SUCCEEDED =======================" | tee -a $LOG_FILE
  update_build_status $PROJECT_NAME $DB_FILE $TSTART $STATUS_SUCCESS
fi

# Change to SOURCE_DIR again for test.
cd $SOURCE_DIR

# Test
# ========================= TEST BEGINS ====================================== 
echo "======================= TESTING $PROJECT_NAME. START TIME = `date` =======================" | tee -a $LOG_FILE
update_build_status $PROJECT_NAME $DB_FILE $TSTART $STATUS_PROGRESS
eval $TEST >> $LOG_FILE 2>&1
TEST_RESULT=$?
echo "======================= TEST $PROJECT_NAME FINISH. TIME = `date` =======================" | tee -a $LOG_FILE

# Check exit status and take appropriate action.
if [ $TEST_RESULT -ne 0 ]
then
  # Test failed. Update DB entry.
  echo "======================= TEST $PROJECT_NAME FAILED =======================" | tee -a $LOG_FILE
  update_test_status $PROJECT_NAME $DB_FILE $TSTART $STATUS_FAILED 
else
  # Build succeeded. Update DB entry.
  echo "======================= TEST $PROJECT_NAME SUCCEEDED =======================" | tee -a $LOG_FILE
  update_test_status $PROJECT_NAME $DB_FILE $TSTART $STATUS_SUCCESS
fi

# Update end time.
TEND=`date +%s`
do_sql "UPDATE status SET tend = $TEND WHERE name = '$PROJECT_NAME' and tstart = $TSTART;" $DB_FILE

# Send mails.
if [ "$BUILD_RESULT" -ne 0 ] || [ "$TEST_RESULT" -ne 0 ] 
then
  if [ ! -z "$MAIL_FAILURE" ]
  then
    send_mail "$MAIL_FAILURE" "Project $PROJECT_NAME build failed." "Please see the attached log file and take corrective action. The status will be refreshed at http://snap.stanford.edu/snapbuild/ soon." $LOG_FILE
  fi
else
  if [ ! -z "$MAIL_SUCCESS" ]
  then
    send_mail "$MAIL_SUCCESS" "Project $PROJECT_NAME build succeeded." "The status will be refreshed at http://snap.stanford.edu/snapbuild/ soon." $LOG_FILE
  fi
fi
