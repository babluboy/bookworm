#!/bin/bash
CRONTAB_BACKUPFILE=$1
CRONTAB_TEMPFILE=$2
CRONTAB_BOOKWORM_DAILY_SCHEDULE="0 1 * * * /usr/bin/bookworm --discover"
#This section removes any schedule for bookworm book discovery from user's crontab
crontab -l > $CRONTAB_BACKUPFILE
sed '/bookworm/ d' $CRONTAB_BACKUPFILE > $CRONTAB_TEMPFILE
crontab $CRONTAB_TEMPFILE
#This section is executed to add bookworm book discovery monitoring for every 24 hours
echo "$CRONTAB_BOOKWORM_DAILY_SCHEDULE" >> $CRONTAB_TEMPFILE
crontab $CRONTAB_TEMPFILE
#Remove the temp crontab file
rm $CRONTAB_TEMPFILE

