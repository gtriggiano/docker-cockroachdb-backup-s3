#! /bin/bash

set -e

if [ "${AWS_ACCESS_KEY_ID}" == "**None**" ]; then
  echo "Warning: You did not set the AWS_ACCESS_KEY_ID environment variable."
fi

if [ "${AWS_SECRET_ACCESS_KEY}" == "**None**" ]; then
  echo "Warning: You did not set the AWS_SECRET_ACCESS_KEY environment variable."
fi

if [ "${S3_BUCKET}" == "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${S3_REGION}" == "**None**" ]; then
  echo "You need to set the S3_REGION environment variable."
  exit 1
fi

if [ "${DATABASE_USER}" == "**None**" ]; then
  echo "You need to set the DATABASE_USER environment variable."
  exit 1
fi

if [ "${DATABASE_NAME}" == "**None**" ]; then
  echo "You need to set the DATABASE_NAME environment variable."
  exit 1
fi

if [ "${COCKROACH_HOST}" == "**None**" ]; then
  echo "You need to set the COCKROACH_HOST environment variable."
  exit 1
fi

if [ "${COCKROACH_CERTS_DIR}" == "**None**" ]; then
  echo "You need to set the COCKROACH_CERTS_DIR environment variable."
  exit 1
fi

move_to_s3 () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ "${S3_ENDPOINT}" == "**None**" ]; then
    AWS_ARGS=""
  else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  fi

  if [ "${S3_PREFIX}" == "**None**" ]; then
    S3_URI="s3://${S3_BUCKET}/${DEST_FILE}"
  else
    S3_URI="s3://${S3_BUCKET}/${S3_PREFIX}/${DEST_FILE}"
  fi

  if [ "${S3_ENCRYPT}" == "yes" ]; then
    S3_OPTS="--sse"
  else
    S3_OPTS=""
  fi

  echo "Uploading ${DEST_FILE} on S3..."

  cat $SRC_FILE | aws $AWS_ARGS s3 cp - $S3_URI $S3_OPTS

  if [ $? != 0 ]; then
    >&2 echo "Error uploading ${DEST_FILE} on S3"
  fi

  rm $SRC_FILE
}

export AWS_DEFAULT_REGION=$S3_REGION

BACKUP_START_TIME=$(date +"%Y-%m-%dT%H%M%SZ")
S3_FILE="${BACKUP_START_TIME}.sql"

cd /backup
echo "Dumping Database"
su -c "/cockroach/cockroach dump $DATABASE_NAME --user $DATABASE_USER > dump.sql"
echo "Done"

move_to_s3 dump.sql $S3_FILE

echo "Cockroach backup of $DATABASE_NAME finished"
