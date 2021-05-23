#!/usr/bin/bash
# ##############
#
# aws-s3-jumpcloud.sh
#
# ######
#
# (c) 2021, LogRhythm
#
# ######
#
# tony.masse@logrhythm.com
#
# ######
# Versions:
#
# v1 - 2021.05.21 - tony.masse@logrhythm.com
# - Initial version
# v2 - 2021.05.22 - tony.masse@logrhythm.com
# - Enhanced logging
# v3 - 2021.05.23 - tony.masse@logrhythm.com
# - Call Node from its full path (not relying on PATH)

# Steps:
# 1. AWS CLI S3 Sync > sync_log.txt
# 2. parse sync_log.txt to extract the name of the newly downloaded files
# 3. For each of these file name
#  3.1 gunzip to a temp file
#  3.2 extract each log from temp file
#   3.2.1 stringify log into a single line
#   3.2.2 append single line JSON log into filebeat input file (/var/export/jc/input_XYZ.log)

# CONFIGURATION

readonly JOB_NAME="jumpcloud"
readonly S3_BUCKET_NAME="PUT THE NAME OF THE BUCKET RECEIVING JUMPCLOUD LOGS HERE"

# 0. Prep and Housekeeping

readonly PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly JS_PROJECT_ROOT="$PROJECT_ROOT/../js"
readonly EXTRACT_SCRIPT="$JS_PROJECT_ROOT/extract-export-logs.js"
readonly IMPORT_ROOT="/var/import"
readonly BUCKET_IMPORT_ROOT="$IMPORT_ROOT/from_bucket"
readonly EXPORT_ROOT="$IMPORT_ROOT/to_SIEM"
readonly SYNC_LOG="$IMPORT_ROOT/sync_$JOB_NAME.log"
readonly TEMP_ROOT="/tmp"
readonly JOB_LOG="$IMPORT_ROOT/sync_$JOB_NAME.job.log"

# Creating our directories
if [ ! -d "$IMPORT_ROOT" ]; then
  mkdir "$IMPORT_ROOT" 2>/dev/null
fi
if [ ! -d "$BUCKET_IMPORT_ROOT" ]; then
  mkdir "$BUCKET_IMPORT_ROOT" 2>/dev/null
fi
if [ ! -d "$EXPORT_ROOT" ]; then
  mkdir "$EXPORT_ROOT" 2>/dev/null
fi
if [ ! -d "$EXPORT_ROOT/$JOB_NAME" ]; then
  mkdir "$EXPORT_ROOT/$JOB_NAME" 2>/dev/null
fi

echo -e "---------------------- START" >> "$JOB_LOG"
date --rfc-3339=seconds >> "$JOB_LOG"

# Check Node is installed
NodeIsInstalled=1
/usr/bin/node -v >/dev/null 2>/dev/null || NodeIsInstalled=0
# And bail if not
if [ $NodeIsInstalled -eq 0 ]; then
  echo -e "NodeJS is not installed. Exiting."
  echo -e "NodeJS is not installed. Exiting." >> "$JOB_LOG"
  exit 1
fi

cd "$TEMP_ROOT"
pwd

# 1. AWS CLI S3 Sync > sync_log.txt
echo -e "1. AWS CLI S3 Sync..."
echo -e "1. AWS CLI S3 Sync..." >> "$JOB_LOG"

/usr/local/bin/aws s3 sync "s3://$S3_BUCKET_NAME" "$BUCKET_IMPORT_ROOT/$JOB_NAME" > "$SYNC_LOG" 2>> "$JOB_LOG"

echo -e "Number of Synced files:"
cat "$SYNC_LOG" | wc -l
echo -e "Number of Synced files:" >> "$JOB_LOG"
cat "$SYNC_LOG" | wc -l >> "$JOB_LOG"

# 2. parse sync_log.txt to extract the name of the newly downloaded files
echo -e "2. Extract the name of the newly downloaded files..."
echo -e "2. Extract the name of the newly downloaded files..." >> "$JOB_LOG"
for COMPRESSEDLOGFILE in $(cat "$SYNC_LOG" | grep "download: s3:" | sed -n "s/.* to .*\?from_bucket\/$JOB_NAME\/\(.\+\)/\1/p")
do
  # 3. For each of these file name
  echo -e "3. Processing $BUCKET_IMPORT_ROOT/$JOB_NAME/$COMPRESSEDLOGFILE ..."
  echo -e "3. Processing $BUCKET_IMPORT_ROOT/$JOB_NAME/$COMPRESSEDLOGFILE ..." >> "$JOB_LOG"
  #  3.1 gunzip to a temp file
  gunzip --keep --stdout $BUCKET_IMPORT_ROOT/$JOB_NAME/$COMPRESSEDLOGFILE > "$TEMP_ROOT/$JOB_NAME.temp.json" 2>> "$JOB_LOG"

  #  3.2 extract each log from temp file
  #   3.2.1 stringify log into a single line
  #   3.2.2 append single line JSON log into filebeat input file (/var/export/jc/input_XYZ.log)
  /usr/bin/node "$EXTRACT_SCRIPT" "$TEMP_ROOT/$JOB_NAME.temp.json" "$EXPORT_ROOT/$JOB_NAME" "$COMPRESSEDLOGFILE" >> "$JOB_LOG" 2>> "$JOB_LOG"
done

# Clean up
if [ -f "$TEMP_ROOT/$JOB_NAME.temp.json" ]; then
  rm "$TEMP_ROOT/$JOB_NAME.temp.json" 2>/dev/null
fi

echo -e "DONE" >> "$JOB_LOG"

date --rfc-3339=seconds >> "$JOB_LOG"
echo -e "---------------------- STOP" >> "$JOB_LOG"
