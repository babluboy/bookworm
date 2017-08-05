#!/bin/bash
#Written by Siddhartha Das (bablu.boy@gmail.com) as part of Bookworm (eBook Reader)
#This script adds an entry into the user's crontab for Bookworm background tasks if it is not already present
#The Bookworm background tasks are for adding new books into the library from the folders set up as "watched" and
#remove any un-necessary cached data and cover images used by Bookworm
#The inputs into this script are : (1) file where current crontab will be back-ed up (2) file for temporary use to add entry for bookworm
CRONTAB_BACKUPFILE=$1
CRONTAB_TEMPFILE=$2
CRONTAB_BOOKWORM_DAILY_SCHEDULE="0 */2 * * * /usr/bin/bookworm --discover"
#This section removes any schedule for bookworm book discovery from user's crontab
crontab -l > $CRONTAB_BACKUPFILE
sed '/bookworm/ d' $CRONTAB_BACKUPFILE > $CRONTAB_TEMPFILE
crontab $CRONTAB_TEMPFILE
#This section is executed to add bookworm book discovery monitoring for every 24 hours
echo "$CRONTAB_BOOKWORM_DAILY_SCHEDULE" >> $CRONTAB_TEMPFILE
crontab $CRONTAB_TEMPFILE
#Remove the temp crontab file
rm $CRONTAB_TEMPFILE
