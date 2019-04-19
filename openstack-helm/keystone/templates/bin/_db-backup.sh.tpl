#!/bin/bash

{{/*
Copyright 2017 The Openstack-Helm Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

set -ex

# Creates a backup for a db for an OpenStack Service:
# Set DB_USER, DB_PASSWORD, DB_HOST environment variables to contain strings
# for connection to the database.
# Set DB_NAME environment variable to contain the name of the database to back up.
# Alternateively, leave DB_NAME blank to back up all databases

function fail_if_not_exists() {
  if [ -z "${!1}" ];
  then
    echo "$1 not set"
    exit 1
  fi
}

fail_if_not_exists DB_USER
fail_if_not_exists DB_HOST
fail_if_not_exists DB_PASSWORD

echo "Backing up keystone database"
sql_file=keystone_backup.sql
mysqldump --single-transaction --user=${DB_USER} --password=${DB_PASSWORD} --host=${DB_HOST} keystone > ${sql_file}

echo "Dumped database(s) to ${sql_file}"

backup_dir=/etc/keystone/backups
backup_file=${backup_dir}/$(date -u +%Y%m%dT%H%M%SZbackup.tar.gz)
tar -czf ${backup_file} ${sql_file}
echo "Backed up database(s) in ${backup_file}"


# find is used to get full path lengths
# sort is used to lexicographically sort in reverse. This works because the filenames conform to IOS 8601
# tail will print all but the first 10 files (the most recent)
echo "Deleting old backups"
rm -f $(find ${backup_dir} -regex ".*backup.tar.gz" | sort -r | tail -n+11)
