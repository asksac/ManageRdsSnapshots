#!/usr/bin/env python3

import os, logging, json
from datetime import datetime, timedelta, timezone
import boto3

root = logging.getLogger()
if root.handlers:
    for handler in root.handlers:
        root.removeHandler(handler)
logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s',level=logging.INFO)


def lambda_handler(event, context):
  try: 

    # lets first read a bunch of parameters from environment variables 
    log_level = os.environ.get('LOG_LEVEL')
    if (log_level and log_level in ['CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG']): 
      logging.getLogger().setLevel(log_level)

    db_instance_id = os.environ.get('DB_INSTANCE_ID')
    if (not db_instance_id): 
      raise EnvironmentError('Missing or invalid value for DB_INSTANCE_ID environment variable')

    snapshot_max_age_days = os.environ.get('SNAPSHOT_MAX_AGE_IN_DAYS')
    snapshot_max_age_months = os.environ.get('SNAPSHOT_MAX_AGE_IN_MONTHS')
    if snapshot_max_age_days: 
      max_age = timedelta(days=int(snapshot_max_age_days))
    elif snapshot_max_age_months: 
      max_age = timedelta(days=int(snapshot_max_age_months)*30)
    else: 
      raise EnvironmentError('Valid value for either SNAPSHOT_MAX_AGE_IN_DAYS or SNAPSHOT_MAX_AGE_IN_MONTHS must be specified as environment variable')

    min_days_since_last_snapshot = os.environ.get('MIN_DAYS_SINCE_LAST_SNAPSHOT')
    if min_days_since_last_snapshot: 
      min_delay = timedelta(days=int(min_days_since_last_snapshot))
    else: 
      min_delay = timedelta(0) # creates a new snapshot everytime lammbda is run

    # phew, now that we're configured, let's proceed with real action
    rds_client = boto3.client('rds')

    db_snapshots_list = rds_client.describe_db_snapshots(
      DBInstanceIdentifier=db_instance_id,
      SnapshotType='manual', 
    )

    logging.debug('Response from describe_db_snapshots() call: ' + str(db_snapshots_list))

    current_snapshots_count = len(db_snapshots_list['DBSnapshots'])

    if (not db_snapshots_list): 
      raise RuntimeError('RDS describe_db_snapshots() API did not return a valid response')

    logging.info('Found %s manual snapshots for db instance %s' % (current_snapshots_count, db_instance_id))

    today = datetime.now(timezone.utc)
    today_eod = today.replace(hour=23, minute=59, second=59, microsecond=0)
    last_snapshot_time = datetime(1, 1, 1, tzinfo=timezone.utc) # set to begining of time

    logging.info('Searching for snapshots older than %s days' % max_age)
    for snapshot in db_snapshots_list['DBSnapshots']: 
      # exit if a snapshot is in creating state, and ignore snapshots that are not available
      if (snapshot['Status'] == 'creating'):
        last_snapshot_time = None
        break
      elif (snapshot['Status'] != 'available'):
        continue

      # find the latest snapshot's datetime
      if (snapshot['SnapshotCreateTime'] > last_snapshot_time): 
        last_snapshot_time = snapshot['SnapshotCreateTime']

      # check if snapshot is older than max_age
      if (snapshot['SnapshotCreateTime'] < today_eod - max_age): 
        # snapshot too old, let's mark it for deletion 
        logging.info('Snapshot with id %s was created on %s, which is older than %s day(s). It will be marked for deletion.' % (snapshot['DBSnapshotIdentifier'], snapshot['SnapshotCreateTime'], max_age))
        db_snapshot_delete = rds_client.delete_db_snapshot(
          DBSnapshotIdentifier=snapshot['DBSnapshotIdentifier']
        )
        logging.debug('Response from delete_db_snapshot() call: ' + str(db_snapshot_delete))

    # determine if we should create a new snapshot now
    logging.info('Latest manual snapshot for db instance %s was created on %s' % (db_instance_id, last_snapshot_time))
    new_snapshot_created = False 
    if (last_snapshot_time and last_snapshot_time < today_eod - min_delay): 
      # last snapshot was created more than min_delays days ago, so let's create a new snapshot
      new_snapshot_id = '%s-manual-snapshot-%s' % (db_instance_id, today.strftime('%Y-%m-%d-%H-%M-%S'))
      logging.info('New snapshot with id %s will be created for db instance id %s' % (new_snapshot_id, db_instance_id))
      db_snapshot_create = rds_client.create_db_snapshot(
        DBInstanceIdentifier=db_instance_id,
        DBSnapshotIdentifier=new_snapshot_id, 
      )
      new_snapshot_created = True
      logging.debug('Response from create_db_snapshot() call: ' + str(db_snapshot_create))
    else: 
      logging.info('No new db snapshots were created')

    return dict(
      statusCode = 200,
      headers = { 'Content-Type': 'application/json' }, 
      body = dict(
        previousSnapshotsCount = current_snapshots_count, 
        newSnapshotCreated = new_snapshot_created
      )
    )

  except (OSError, RuntimeError) as err: 
    logging.error(err)
    return dict(
      statusCode = 500,
      headers = { 'Content-Type': 'application/json' }, 
      body = str(err)
    )


# if called from terminal 
if __name__ == '__main__':
  print(lambda_handler(None, None))